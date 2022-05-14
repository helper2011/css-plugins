#include <sourcemod>
#include <sdkhooks>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#tryinclude <leader>
#define REQUIRE_PLUGIN

#pragma newdecls required

Handle
	g_hCookie;
int
	Team[MAXPLAYERS + 1];
bool
	Toggle[MAXPLAYERS + 1],
	IsLeader[MAXPLAYERS + 1],
	IsHidden[MAXPLAYERS + 1][MAXPLAYERS + 1];

static const char Phrases[][] =
{
	"Скрытие союзников",
	"Hide teammates"
}

public Plugin myinfo = 
{
	name		= "Hide",
	version		= "2.0",
	description	= "Simple hiding players",
	author		= "hEl"
}

public void OnPluginStart()
{
	g_hCookie = RegClientCookie("Hide", "", CookieAccess_Private);
	HookEvent("player_team", OnPlayerTeam);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_spawn", OnPlayerSpawn);
	RegConsoleCmd("sm_hide", Hide_Command);
	SetCookieMenuItem(HideMenuHandler, 0, "Hide");
	bool bLeaderIsLoaded = LibraryExists("Leader");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			Team[i] = GetClientTeam(i);
			IsLeader[i] = (bLeaderIsLoaded && Leader_IsClientLeader(i));
		}
	}
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void HideMenuHandler(int iClient, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlen, "%s: [%s]", Phrases[GetClientLanguage(iClient) == 22 ? 0:1], Toggle[iClient] ? "✔":"×");
		}
		case CookieMenuAction_SelectOption:
		{
			ToggleHide(iClient);
			ShowCookieMenu(iClient);
		}
	}
}

public Action Hide_Command(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient))
	{
		ToggleHide(iClient);
	}
	return Plugin_Handled;
}

public void Leader_OnClientActionLeader(int iClient, bool bBecame)
{
	IsLeader[iClient] = bBecame;
}

void GetClientHideCookie(int iClient)
{
	char szBuffer[4];
	GetClientCookie(iClient, g_hCookie, szBuffer, 4);
	Toggle[iClient] = (szBuffer[0] != 0);
	if(Toggle[iClient] && Team[iClient] > 1 && IsPlayerAlive(iClient))
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			IsHidden[iClient][i] = (IsClientInGame(i) && IsPlayerAlive(i) && i != iClient && !IsLeader[i] && Team[iClient] == Team[i]);
		}
	}
}

public void OnClientCookiesCached(int iClient)
{
	if(IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		GetClientHideCookie(iClient);
	}
}

public void OnClientPutInServer(int iClient)
{
	if(!IsFakeClient(iClient) && AreClientCookiesCached(iClient))
	{
		GetClientHideCookie(iClient);
	}
	SDKHook(iClient, SDKHook_SetTransmit, SetTransmit);
}


public void OnClientDisconnect(int iClient)
{
	if(Toggle[iClient])
	{
		ClearClientHiddenPlayers(iClient);
		Toggle[iClient] = false;
	}
}

public Action SetTransmit(int iEntity, int iClient)
{
	return IsHidden[iClient][iEntity] ? Plugin_Handled:Plugin_Continue;
}

public void OnPlayerTeam(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	Team[iClient] = hEvent.GetInt("team");
	if(!iClient || !IsPlayerAlive(iClient))
	{
		return;
	}
	if(Toggle[iClient])
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(i == iClient)
				continue;
				
			if(IsHidden[iClient][i])
			{
				if(Team[iClient] != Team[i])
				{
					IsHidden[iClient][i] = false;
				}
			}
			else if(IsClientHiddenPlayer(iClient, i))
			{
				IsHidden[iClient][i] = true;
			}
		}
	}
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i == iClient || !Toggle[i] || !IsPlayerAlive(i))
			continue;
		
		if(IsHidden[i][iClient])
		{
			if(Team[iClient] != Team[i])
			{
				IsHidden[i][iClient] = false;
			}
		}
		else if(!IsLeader[i] && Team[i] == Team[iClient])
		{
			IsHidden[i][iClient] = true;
		}
	}
}

public void OnPlayerSpawn(Event hEvent, const char[] event, bool bDontBroadcast)
{
	RequestFrame(OnPlayerSpawnNextTick, GetClientOfUserId(hEvent.GetInt("userid")));
}

void OnPlayerSpawnNextTick(int iClient)
{
	if(!IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return;
	
	if(Toggle[iClient])
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(i == iClient)
				continue;
				
			IsHidden[iClient][i] = IsClientHiddenPlayer(iClient, i);
		}
	}
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i == iClient)
			continue;
		
		if(Toggle[i] && IsPlayerAlive(i) && !IsLeader[iClient] && Team[iClient] == Team[i])
		{
			IsHidden[i][iClient] = true;
		}
	}
}

public void OnPlayerDeath(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(IsPlayerAlive(iClient))
	{
		return;
	}
	if(Toggle[iClient])
	{
		ClearClientHiddenPlayers(iClient);
	}
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Toggle[i])
		{
			IsHidden[i][iClient] = false;
		}
	}
}



void ToggleHide(int iClient)
{
	int iLanguage = (GetClientLanguage(iClient) == 22) ? 0:1;
	if(Toggle[iClient])
	{
		OnClientDisconnect(iClient);
	}
	else
	{
		if(Team[iClient] > 1 && IsPlayerAlive(iClient))
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				IsHidden[iClient][i] = (i != iClient && IsClientHiddenPlayer(iClient, i));
			}
		}
		Toggle[iClient] = true;
	}
	
	if(AreClientCookiesCached(iClient))
	{
		SetClientCookie(iClient, g_hCookie, Toggle[iClient] ? "1":"");
	}
	PrintHintText(iClient, "%s: [%s]", Phrases[iLanguage == 0 ? 0:1], Toggle[iClient] ? "✔":"×");
}

void ClearClientHiddenPlayers(int iClient)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		IsHidden[iClient][i] = false;
	}
}

bool IsClientHiddenPlayer(int iClient, int iPlayer)
{
	return (IsClientInGame(iPlayer) && IsPlayerAlive(iPlayer) && !IsLeader[iPlayer] && Team[iClient] == Team[iPlayer]);
}