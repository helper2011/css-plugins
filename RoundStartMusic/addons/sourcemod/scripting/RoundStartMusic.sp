#include <sourcemod>
#include <clientprefs>
#include <sdktools_sound>
#include <sdktools_stringtables>

#pragma newdecls required

const int MAX_SOUNDS = 50;

Handle CookieRsm;

int Sounds, Next, RussianLanguageId;
char Sound[MAX_SOUNDS][256];

bool Toggle[MAXPLAYERS + 1], ReloadSongs, Mix;

ConVar Path;

public Plugin myinfo = 
{
	name		= "Round Start Music",
	version		= "1.2",
	description	= "",
	author		= "hEl"
}

public void OnPluginStart()
{
	if((RussianLanguageId = GetLanguageByCode("ru")) == -1)
	{
		SetFailState("Cant find russian language (see languages.cfg)");
	}
	Path = CreateConVar("rsm_path", "sexwbhop/deathrun/xmas2/rsm/");
	CookieRsm = RegClientCookie("Rsm", "", CookieAccess_Private);
	RegConsoleCmd("sm_rsm", Command_Rsm);
	RegServerCmd("rsm_reload", Command_RsmReload);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	SetCookieMenuItem(RSMMenuHandler, 0, "Round Start Music");
	AutoExecConfig(true, "plugin.Rsm");
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
		Sounds = 0;
		ReloadSongs = false;
		LoadSongs();
	}
	else if(Mix)
	{
		Mix = false;
		MixSongs();
	}
	
	PrecacheSongs();
}

public void RSMMenuHandler(int iClient, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlen, "%s: [%s]", (GetClientLanguage(iClient) == RussianLanguageId) ? "Музыка в начале раунда":"Round start music", Toggle[iClient] ? "✔":"×");
		}
		case CookieMenuAction_SelectOption:
		{
			Toggle[iClient] = !Toggle[iClient];
			SetClientCookie(iClient, CookieRsm, Toggle[iClient] ? "":"0");
			ShowCookieMenu(iClient);
		}
	}
}

public void OnRoundStart(Event hEvent, const char[] event, bool bDontBroadcast)
{
	if(Next >= Sounds)
	{
		Next = 0;
		Mix = true;
	}
	for(int i = 1;i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && Toggle[i])
		{
			EmitSoundToClient(i, Sound[Next]);
		}
	}
	Next++;
}

public Action Command_RsmReload(int iArgs)
{
	ReloadSongs = true;
	return Plugin_Handled;
}

void LoadSongs()
{
	char szBuffer[256];
	Path.GetString(szBuffer, 256);
	
	int len = strlen(szBuffer);
	if(len == 0)
		return;
	
	ReplaceString(szBuffer, 256, "\\", "/");
	ReplaceString(szBuffer, 256, "sound/", "", false);
	Format(szBuffer, 256, "sound/%s", szBuffer);
		
	if (DirExists(szBuffer))
	{
		if (szBuffer[len - 1] == '/') 
		{
			szBuffer[len - 1] = 0; 
		}
		LoadSoundsFromDir(szBuffer);
	}
	else if (IsValidFile(szBuffer, len)) 
	{
		LoadSound(szBuffer);
	}
	
	if(Sounds == 0)
	{
		SetFailState("No sounds");
	}
	
	MixSongs();
}

void LoadSoundsFromDir(const char[] path)
{
	DirectoryListing hDir = OpenDirectory(path);
	if (!hDir)
		return;
	
	char file[256], sound[256]; FileType iFileType;
	while (hDir.GetNext(file, 256, iFileType))
	{
		if (iFileType == FileType_File && IsValidFile(file, strlen(file)))
		{
			FormatEx(sound, 256, "%s/%s", path, file);
			LoadSound(sound);
		}
		else if (iFileType == FileType_Directory && strcmp(file, ".", true) && strcmp(file, "..", true))
		{
			FormatEx(sound, 256, "%s/%s", path, file);
			LoadSoundsFromDir(sound);
		}
	}
	
	delete hDir;
}


void LoadSound(const char[] path)
{
	if(Sounds < MAX_SOUNDS)
	{
		AddFileToDownloadsTable(path);
		strcopy(Sound[Sounds], 64, path[6]);
		PrecacheSound(Sound[Sounds++], true);
	}
}

bool IsValidFile(const char[] path, int length)
{
	int i = length;
	while (--i > -1)
	{
		if (path[i] == '.') {
			return i > 0 && ((i + 1) != length) && strcmp(path[i + 1], "ztmp", false) && strcmp(path[i + 1], "bz2", false);
		}
	}
	return false;
}

void PrecacheSongs()
{
	char szBuffer[256];
	for(int i;i < Sounds; i++)
	{
		PrecacheSound(Sound[i], true);
		FormatEx(szBuffer, 256, "sound/%s", Sound[i]);
		AddFileToDownloadsTable(szBuffer);
	}
}

public Action Command_Rsm(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient))
	{
		Toggle[iClient] = !Toggle[iClient];
		SetClientCookie(iClient, CookieRsm, Toggle[iClient] ? "":"0");
		PrintHintText(iClient, "%s: [%s]", (GetClientLanguage(iClient) == RussianLanguageId) ? "Музыка в начале раунда":"Round start music", Toggle[iClient] ? "✔":"×");
	}
	
	return Plugin_Handled;
}



public void OnClientDisconnect(int iClient)
{
	Toggle[iClient] = true;
}

public void OnClientPutInServer(int iClient)
{
	if(!IsFakeClient(iClient) && !AreClientCookiesCached(iClient))
	{
		Toggle[iClient] = true;
	}
}

public void OnClientCookiesCached(int iClient)
{
	if(IsFakeClient(iClient))
		return;
		
	char szBuffer[4];
	GetClientCookie(iClient, CookieRsm, szBuffer, 4);
	Toggle[iClient] = (szBuffer[0] == 0);
}

void MixSongs()
{
	int iIndex;
	char szBuffer[256];
	
	for(int i; i < Sounds; i++)
	{
		if((iIndex = GetRandomInt(i, Sounds - 1)) == i)
			continue;
			
		szBuffer = Sound[i];
		Sound[i] = Sound[iIndex];
		Sound[iIndex] = szBuffer;
	}
}