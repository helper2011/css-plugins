#include <sourcemod>
#include <clientprefs>
#include <sdktools_sound>
#include <sdktools_stringtables>

#pragma newdecls required

enum
{
	SOUND_ROUND_START,
	SOUND_KILL,
	SOUND_KNIFE,
	SOUND_HEADSHOT,
	SOUND_HEGRENADE,

	SOUND_TOTAL
}

static const char soundsKeys[][] = 
{
	"round_start",
	"kill",
	"knife",
	"headshot",
	"hegrenade"
}

Handle Ccookie;

bool Toggle[MAXPLAYERS + 1] = {true, ...};

ArrayList Sounds[SOUND_TOTAL];

int Chance[SOUND_TOTAL] = {100, ...};

float Cooldown, CooldownClient, CooldownKeys[SOUND_TOTAL], NextTimeKeyPlay[SOUND_TOTAL], NextTimePlay, NextTimeClientPlay[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name		= "Kill Sounds",
	version		= "2.0",
	description	= "",
	author		= "hEl"
}

public void OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	SetCookieMenuItem(CookieMenuH, 0, "Kill Sounds");
	Ccookie = RegClientCookie("KillSoundsSets", "", CookieAccess_Private);
	
	RegConsoleCmd("killsounds", Command_KillSounds);

	LoadSounds();

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
			continue;

		if(AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
}

public void OnMapStart()
{
	PrecacheSounds();
}

public void OnMapEnd()
{
	NextTimePlay = 0.0;
	
	for(int i; i < SOUND_TOTAL; i++)
	{
		NextTimeKeyPlay[i] = 0.0;
	}
}

public void CookieMenuH(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlen, "Kill Sounds: [%s]", Toggle[client] ? "✔":"×");
		}
		case CookieMenuAction_SelectOption:
		{
			ToggleClientKillSounds(client);
			ShowCookieMenu(client);
		}
	}
}

public Action Command_KillSounds(int iClient, int iArgs)
{
	ToggleClientKillSounds(iClient);
	return Plugin_Handled;
}

public void OnClientCookiesCached(int iClient)
{
	if(IsFakeClient(iClient))
	{
		return;
	}
	
	char szBuffer[4];
	GetClientCookie(iClient, Ccookie, szBuffer, 4);
	Toggle[iClient] = (szBuffer[0] == 0);
}

public void OnClientDisconnect(int iClient)
{
	Toggle[iClient] = true;
	NextTimeClientPlay[iClient] = 0.0;
}

public void OnRoundStart(Event hEvent, const char[] event, bool bDontBroadcast)
{
	PlaySound(SOUND_ROUND_START);
}

public void OnPlayerDeath(Event hEvent, const char[] event, bool bDontBroadcast)
{
	static int iAttacker;
	static int iClient;
	static int iType;
	if(!(0 < (iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"))) <= MaxClients) || GetClientTeam(iAttacker) != 3 || iAttacker == (iClient = GetClientOfUserId(hEvent.GetInt("userid"))) || GetClientTeam(iClient) != 2)
		return;

	if(hEvent.GetBool("headshot"))
	{
		iType = SOUND_HEADSHOT;
	}
	else
	{
		iType = GetEventWeapon(hEvent);
	}
	
	PlaySound(iType, iAttacker);
}

int GetEventWeapon(Event hEvent)
{
	char szBuffer[4];
	hEvent.GetString("weapon", szBuffer, 4);
	if(szBuffer[0] == 'k')								// knife
		return SOUND_KNIFE;
	else if(szBuffer[0] == 'h') 						// hegrenade
		return SOUND_HEGRENADE;
		
	return SOUND_KILL;
}

void LoadSounds()
{
	char szBuffer[256];

	KeyValues hKeyValues = new KeyValues("KillSounds");
	BuildPath(Path_SM, szBuffer, 256, "configs/killsounds.cfg");
	if(!hKeyValues.ImportFromFile(szBuffer))
		SetFailState("[Killsounds] Config \"%s\" does exists...", szBuffer);
		
	for(int i; i < SOUND_TOTAL; i++)
	{
		delete Sounds[i];
		Sounds[i] = new ArrayList(ByteCountToCells(256));
	}


	if(hKeyValues.JumpToKey("Cooldowns"))
	{
		Cooldown = hKeyValues.GetFloat("cooldown");
		CooldownClient = hKeyValues.GetFloat("cooldown_client");

		for(int i; i < SOUND_TOTAL; i++)
		{
			CooldownKeys[i] = hKeyValues.GetFloat(soundsKeys[i]);
		}
		hKeyValues.Rewind();
	}
	if(hKeyValues.JumpToKey("Chances"))
	{
		for(int i; i < SOUND_TOTAL; i++)
		{
			Chance[i] = hKeyValues.GetNum(soundsKeys[i], 100);
		}
		hKeyValues.Rewind();
	}
	
	if(hKeyValues.JumpToKey("Sounds") && hKeyValues.GotoFirstSubKey(false))
	{
		int iIndex;
		do
		{
			hKeyValues.GetSectionName(szBuffer, 256);
			
			if((iIndex = GetSoundKeyIndex(szBuffer)) == -1)
				continue;

			hKeyValues.GetString(NULL_STRING, szBuffer, 256);
			Sounds[iIndex].PushString(szBuffer);
		}
		while(hKeyValues.GotoNextKey(false));
	}

	
	delete hKeyValues;
}

void PrecacheSounds()
{
	int iLength;
	char szBuffer[256];
	for(int i; i < 5; i++)
	{
		iLength = Sounds[i].Length;
		for(int j; j < iLength; j++)
		{
			Sounds[i].GetString(j, szBuffer, 256);
			PrecacheSound(szBuffer, true);
			Format(szBuffer, 256, "sound/%s", szBuffer);
			AddFileToDownloadsTable(szBuffer);
		}
	}
}

void PlaySound(int iType, int iEntity = SOUND_FROM_PLAYER)
{
	if(Chance[iType] < GetRandomInt(1, 100))
		return;

	static float fTime;
	fTime = GetGameTime();

	if(fTime < NextTimeKeyPlay[iType])
		return;

	if(fTime < NextTimePlay)
		return;

	if(iEntity != SOUND_FROM_PLAYER)
	{
		if(!Toggle[iEntity])
		{
			return;
		}
		if(fTime < NextTimeClientPlay[iEntity])
		{
			return;
		}

		NextTimeClientPlay[iEntity] = fTime + CooldownClient;
	}

	NextTimePlay = fTime + Cooldown;
	NextTimeKeyPlay[iType] = fTime + CooldownKeys[iType];

	static int iLength;
	static char szBuffer[256];
	iLength = Sounds[iType].Length;
	
	if(iLength)
	{
		Sounds[iType].GetString(GetRandomInt(0, iLength - 1), szBuffer, 256);
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && Toggle[i])
			{
				EmitSoundToClient(i, szBuffer, iEntity, SNDCHAN_STATIC, SNDLEVEL_NORMAL, _, 1.0);
			}
		}
	}
}

stock void ToggleClientKillSounds(int iClient)
{
	Toggle[iClient] = !Toggle[iClient];
	PrintHintText(iClient, "Kill Sounds: [%s]", Toggle[iClient] ? "✔":"×")

	if(AreClientCookiesCached(iClient))
	{
		SetClientCookie(iClient, Ccookie, Toggle[iClient] ? "":"0");
	}
}

stock int GetSoundKeyIndex(const char[] key)
{
	for(int i; i < SOUND_TOTAL; i++)
	{
		if(strcmp(key, soundsKeys[i], false) == 0)
		{
			return i;
		}
	}

	return -1;
}