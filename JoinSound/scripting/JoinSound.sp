#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#pragma newdecls required

const int MAX_SOUNDS = 15;

int Sounds, PlayType, RandomSound, Cooldown;
char Sound[MAX_SOUNDS][256];

bool Play[MAXPLAYERS + 1];

Handle g_hCookie;

ConVar cvarPath, cvarPlayType, cvarCooldown;

StringMap CooldownMap;

public Plugin myinfo = 
{
	name		= "JoinSound",
	version		= "1.0",
	description	= "",
	author		= "hEl"
};

public void OnPluginStart()
{
	CooldownMap = new StringMap();
	LoadTranslations("common.phrases");
	LoadTranslations("joinsound.phrases");
	cvarPath = CreateConVar("joinsnd_path", "sound/sexwbhop/joinsnd/");
	cvarPlayType = CreateConVar("joinsnd_playtype", "0", "0 - Random for every client, 1 - Random sound on map session");
	cvarPlayType.AddChangeHook(OnConVarChange);
	PlayType = cvarPlayType.IntValue;
	cvarCooldown = CreateConVar("joinsnd_cooldown", "7200", "Play sound cooldown for client");
	cvarCooldown.AddChangeHook(OnConVarChange);
	Cooldown = cvarCooldown.IntValue;
	HookEvent("player_team", OnPlayerTeam);
	g_hCookie = RegClientCookie("JoinSound", "", CookieAccess_Private);
	SetCookieMenuItem(JoinSndMenuHandler, 0, "Join Sound");
	AutoExecConfig(true, "plugin.JoinSound");
}

public void JoinSndMenuHandler(int iClient, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlen, "%T: %T", "Join Sound", iClient, GetClientCookieBool(iClient) ? "On":"Off", iClient);
		}
		case CookieMenuAction_SelectOption:
		{
			SetClientCookieBool(iClient, !GetClientCookieBool(iClient));
			ShowCookieMenu(iClient);
		}
	}
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(cvar == cvarCooldown)
	{
		Cooldown = cvar.IntValue;
	}
}

public void OnMapStart()
{
	char szBuffer[256];
	cvarPath.GetString(szBuffer, 256);
	
	int len = strlen(szBuffer);
	
	if(!len)
		return;
		
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
	if(Sounds)
	{
		RandomSound = GetRandomInt(0, Sounds - 1);
		
	}
}


public void OnMapEnd()
{
	Sounds = 0;
	
	char szBuffer[40];
	int iTime = GetTime(), iCooldown;
	StringMapSnapshot snapshot = CooldownMap.Snapshot();
	int iLength = snapshot.Length;
	for(int i; i < iLength; i++)
	{
		snapshot.GetKey(i, szBuffer, 40);
		if(CooldownMap.GetValue(szBuffer, iCooldown) && iTime >= iCooldown)
		{
			CooldownMap.Remove(szBuffer);
		}
	}
	delete snapshot;
}

public void OnPlayerTeam(Event hEvent, const char[] event, bool bDontBroadcast)
{
	if(Sounds)
	{
		int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
		if(Play[iClient] && hEvent.GetInt("team") > 1)
		{
			Play[iClient] = false;
			CreateTimer(1.5, Timer_PlayJoinSound, GetClientUserId(iClient));
		}
	}

}

public void OnClientCookiesCached(int iClient)
{
	if(Sounds && !IsFakeClient(iClient))
	{
		if(Cooldown)
		{
			int iAccount = GetSteamAccountID(iClient);
			if(iAccount)
			{
				int iTime;
				char szBuffer[40];
				IntToString(iAccount, szBuffer, 40);
				if(CooldownMap.GetValue(szBuffer, iTime) && iTime > GetTime())
				{
					return;
				}
			}
		}
		Play[iClient] = GetClientCookieBool(iClient);
		if(Play[iClient] && IsClientInGame(iClient) && GetClientTeam(iClient) > 1)
		{
			Play[iClient] = false;
			CreateTimer(1.5, Timer_PlayJoinSound, GetClientUserId(iClient));
		}
	}
}

public Action Timer_PlayJoinSound(Handle hTimer, int iClient)
{
	if((iClient = GetClientOfUserId(iClient)) && IsClientInGame(iClient) && GetClientTeam(iClient) > 1)
	{
		if(Cooldown)
		{
			int iAccount = GetSteamAccountID(iClient);
			if(iAccount)
			{
				char szBuffer[40];
				IntToString(iAccount, szBuffer, 40);
				CooldownMap.SetValue(szBuffer, GetTime() + Cooldown, true);
			}
		}
		EmitSoundToClient(iClient, Sound[PlayType ? RandomSound:GetRandomInt(0, Sounds - 1)]);
	}
}

public void OnClientDisconnect(int iClient)
{
	Play[iClient] = false;
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

bool GetClientCookieBool(int iClient)
{
	char szBuffer[4];
	GetClientCookie(iClient, g_hCookie, szBuffer, 4);
	return szBuffer[0] ? (!!(StringToInt(szBuffer))):true;
}

bool SetClientCookieBool(int iClient, bool bToggle)
{
	SetClientCookie(iClient, g_hCookie, bToggle ? "1":"0");
}