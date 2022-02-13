#include <sourcemod>
#include <cstrike>
#include <clientprefs>
#include <sdktools_sound>
#include <sdktools_stringtables>
#include <sdktools_functions>

#pragma newdecls required

static const char DefaultSounds[][] = {"", "radio/rounddraw.wav", "radio/twin.wav", "radio/ctwin.wav"};

Handle CookieRes;
ConVar CooldownBetween, CooldownMap, StopSounds;
int Flags[MAXPLAYERS + 1], Volume[MAXPLAYERS + 1], Next, CD;
bool ReloadSongs;
ArrayList SongsList;

enum struct SongData
{
	char Title[128];
	char Path[256];
	float Duration;
}

public Plugin myinfo = 
{
	name		= "Round End Sound",
	version		= "1.3",
	description	= "",
	author		= "hEl"
}

public void OnPluginStart()
{
	SongsList = new ArrayList(ByteCountToCells(512));
	CookieRes = RegClientCookie("Res", "", CookieAccess_Private);
	LoadTranslations("res.phrases");
	RegConsoleCmd("sm_res", Command_Res);
	RegServerCmd("res_reload", Command_ResReload);
	HookEvent("round_end", OnRoundEnd);
	SetCookieMenuItem(RESMenuHandler, 0, "Round End Sound");
	
	CooldownBetween = CreateConVar("res_cooldown_between", "60");
	CooldownMap = CreateConVar("res_cooldown_map_start", "45");
	StopSounds = CreateConVar("res_stop_sounds", "1");
	AutoExecConfig(true, "plugin.Res");
	
	LoadSongs();
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
			
			if(AreClientCookiesCached(i))
			{
				OnClientCookiesCached(i);
			}
		}
	}
}

public void OnMapStart()
{
	if(ReloadSongs)
	{
		SongsList.Clear();
		ReloadSongs = false;
		LoadSongs();
	}
	
	PrecacheSongs();
}

public void OnConfigsExecuted()
{
	CD = GetTime() + CooldownMap.IntValue;
}

public void RESMenuHandler(int iClient, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlen, "%T", "Title", iClient);
		}
		case CookieMenuAction_SelectOption:
		{
			Res(iClient, true);
		}
	}
}

public void OnRoundEnd(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iWinner = hEvent.GetInt("winner");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && Flags[i] & (1 << 0))
		{
			StopSound(i, SNDCHAN_STATIC, DefaultSounds[iWinner]);
		}
	}
}

public Action Command_ResReload(int iArgs)
{
	ReloadSongs = true;
	return Plugin_Handled;
}

void LoadSongs()
{
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, 256, "configs/res.cfg");
	KeyValues hKeyValues = new KeyValues("Sounds");
	if(!hKeyValues.ImportFromFile(szBuffer) || !hKeyValues.GotoFirstSubKey())
	{
		SetFailState("[RoundEndSound] Config file \"%s\" does not exists...", szBuffer);
	}
	
	do
	{
		SongData Song;
		hKeyValues.GetString("title", Song.Title, 128);
		hKeyValues.GetString("sound", Song.Path, 256);
		Song.Duration = hKeyValues.GetFloat("duration", 10.0);
		SongsList.PushArray(Song, sizeof(Song));
	}
	while(hKeyValues.GotoNextKey());
	delete hKeyValues;
	
	if(SongsList.Length == 0)
	{
		SetFailState("No sounds ...");
	}

	MixSongs();
}

void PrecacheSongs()
{
	for(int i = 1; i < sizeof(DefaultSounds); i++)
	{
		PrecacheSound(DefaultSounds[i], true);
	}
	SongData Song;
	int iLength = SongsList.Length;
	char szBuffer[256];
	for(int i;i < iLength; i++)
	{
		SongsList.GetArray(i, Song, sizeof(Song));
		PrecacheSound(Song.Path, true);
		FormatEx(szBuffer, 256, "sound/%s", Song.Path);
		AddFileToDownloadsTable(szBuffer);
	}
}

public Action CS_OnTerminateRound(float& delay, CSRoundEndReason& reason)
{
	int iTime = GetTime();
	if(iTime > CD)
	{
		CD = iTime + CooldownBetween.IntValue;
		if(Next >= SongsList.Length)
		{
			Next = 0;
		}
		if(StopSounds.BoolValue)
		{
			StopAllSounds();
		}
		SongData Song;
		SongsList.GetArray(Next, Song, sizeof(Song));
		int iLen = strlen(Song.Title);
		for(int i = 1;i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && Flags[i] & (1 << 0))
			{
				EmitSoundToClient(i, Song.Path, _, _, _, _, float(Volume[i]) / 100.0);
			
				if(iLen > 3 && Flags[i] & (1 << 1))
				{
					PrintToChat2(i, "%t:{C}FFB273 %s", "Current Song", Song.Title);
				}
			}
		}
		Next++;
		delay = Song.Duration;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action Command_Res(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient))
		Res(iClient);
	
	return Plugin_Handled;
}

void Res(int iClient, bool bBackButton = false)
{
	char szBuffer[256];
	SetGlobalTransTarget(iClient);
	
	Menu hMenu = new Menu(ResMenu);
	hMenu.SetTitle("%t", "Title");
	FormatEx(szBuffer, 256, "%t: [%s]", "Toggle", Flags[iClient] & (1 << 0) ? "✔":"×");					hMenu.AddItem(bBackButton ? "1":"0", szBuffer);
	FormatEx(szBuffer, 256, "%t: [%s]", "Messages", Flags[iClient] & (1 << 1) ? "✔":"×");				hMenu.AddItem("", szBuffer);
	FormatEx(szBuffer, 256, "%t: [%i%%]", "Volume", Volume[iClient]);	hMenu.AddItem("", szBuffer);
	hMenu.ExitBackButton = bBackButton;
	hMenu.Display(iClient, 0);
}

public int ResMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete hMenu;
		}
		case MenuAction_Cancel:
		{
			if(iItem != MenuCancel_Disconnected)
			{
				char szBuffer[32];
				FormatEx(szBuffer, 32, "%i_%i_%i", (Flags[iClient] & (1 << 0)) ? 1:0, (Flags[iClient] & (1 << 1)) ? 1:0, Volume[iClient]);
				SetClientCookie(iClient, CookieRes, szBuffer);
			}
			if(iItem == MenuCancel_ExitBack)
			{
				ShowCookieMenu(iClient);
			}
		}
		case MenuAction_Select:
		{
			if(iItem < 2)
			{
				Flags[iClient] ^= (1 << iItem);
			}
			else if(++Volume[iClient] > 100)
			{
				Volume[iClient] = 70;
			}
			char szBuffer[4];
			hMenu.GetItem(0, szBuffer, 4);
			Res(iClient, !!(StringToInt(szBuffer)));
		}
	}

}

public void OnClientPutInServer(int iClient)
{
	if(!IsFakeClient(iClient) && !AreClientCookiesCached(iClient))
	{
		Flags[iClient] |= (1 << 0) | (1 << 1);
		Volume[iClient] = 100;
	}
}

public void OnClientCookiesCached(int iClient)
{
	if(IsFakeClient(iClient))
		return;
		
	char szBuffer[16];
	GetClientCookie(iClient, CookieRes, szBuffer, 16);
	
	if(szBuffer[0])
	{
		int iSymbol = FindCharInString(szBuffer, '_', true);
		
		if(iSymbol != -1)
		{
			Volume[iClient] = StringToInt(szBuffer[iSymbol + 1]);
			szBuffer[iSymbol] = 0;
			
			if((iSymbol = FindCharInString(szBuffer, '_')) != -1)
			{
				int iFlags;
				
				if(StringToInt(szBuffer[iSymbol + 1]))
				{
					iFlags |= (1 << 1);
				}
				szBuffer[iSymbol] = 0;
				
				if(StringToInt(szBuffer))
				{
					iFlags |= (1 << 0);
				}
				
				Flags[iClient] = iFlags;
			}
		}
	}
	else
	{
		Flags[iClient] |= (1 << 0) | (1 << 1);
		Volume[iClient] = 100;
	}
}


void PrintToChat2(int iClient, const char[] message, any ...)
{
	int iLen = strlen(message) + 255;
	char[] szBuffer = new char[iLen];
	SetGlobalTransTarget(iClient);
	VFormat(szBuffer, iLen, message, 3);
	if(iClient == 0)
	{
		PrintToConsole(iClient, szBuffer);
	}
	else
	{
		SendMessage(iClient, szBuffer, iLen);
	}
}

stock void PrintToChatAll2(const char[] message, any ...)
{
	int iLen = strlen(message) + 255;
	char[] szBuffer = new char[iLen];
	for(int i = 1;i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			SetGlobalTransTarget(i);
			VFormat(szBuffer, iLen, message, 2);
			SendMessage(i, szBuffer, iLen);
		}
	}
}


void SendMessage(int iClient, char[] szBuffer, int iSize)
{
	static int mode = -1;
	if(mode == -1)
	{
		mode = view_as<int>(GetUserMessageType() == UM_Protobuf);
	}
	SetGlobalTransTarget(iClient);
	Format(szBuffer, iSize, "\x01%s", szBuffer);
	ReplaceString(szBuffer, iSize, "{C}", "\x07");

	
	Handle hMessage = StartMessageOne("SayText2", iClient, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	switch(mode)
	{
		case 0:
		{
			BfWrite bfWrite = UserMessageToBfWrite(hMessage);
			bfWrite.WriteByte(iClient);
			bfWrite.WriteByte(true);
			bfWrite.WriteString(szBuffer);
		}
		case 1:
		{
			Protobuf protoBuf = UserMessageToProtobuf(hMessage);
			protoBuf.SetInt("ent_idx", iClient);
			protoBuf.SetBool("chat", true);
			protoBuf.SetString("msg_name", szBuffer);
			for(int k;k < 4;k++)	
				protoBuf.AddString("params", "");
		}
	}
	EndMessage();
}

void MixSongs()
{
	SongData Song[2];
	int iIndex, iLength = SongsList.Length;
	for(int i; i < iLength; i++)
	{
		if((iIndex = GetRandomInt(i, iLength - 1)) != i)
		{
			SongsList.GetArray(i, Song[0], sizeof(Song[]));
			SongsList.GetArray(iIndex, Song[1], sizeof(Song[]));
			SongsList.SetArray(i, Song[1], sizeof(Song[]));
			SongsList.SetArray(iIndex, Song[0], sizeof(Song[]));
		}
	}
}

stock void StopAllSounds()
{
	char szBuffer[256];
	int iEntity = -1, iLen;
	while((iEntity = FindEntityByClassname(iEntity, "ambient_generic")) != -1)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && Flags[i] & (1 << 0))
			{
				GetEntPropString(iEntity, Prop_Data, "m_iszSound", szBuffer, 256);
				if((iLen = strlen(szBuffer) - 4) > 0 && (!strcmp(szBuffer[iLen], ".mp3", false) || !strcmp(szBuffer[iLen], ".wav", false)))
				{
					EmitSoundToClient(i, szBuffer, iEntity, SNDCHAN_STATIC, SNDLEVEL_NONE, SND_STOP, 0.0, SNDPITCH_NORMAL, _, _, _, true);
				}
			}
		}
	}
}