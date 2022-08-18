#include <sourcemod>

#pragma newdecls required

ArrayList SteamIDs;
Handle TimerResetSpawnData;
bool RoundIsEnd, Bug[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name		= "FixRespawnBug",
	version		= "1.0",
	description	= "",
	author		= "hEl"
};

public void OnPluginStart()
{
	SteamIDs = new ArrayList(ByteCountToCells(4));
	AddCommandListener(Command_Joinclass, "joinclass");
	
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("round_start", OnRoundFire, EventHookMode_PostNoCopy);
	HookEvent("round_end", OnRoundFire, EventHookMode_PostNoCopy);
	
	(FindConVar("mp_restartgame")).AddChangeHook(OnConVarChange);
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	OnRoundFire(null, "round_end", true);
}

public void OnPlayerSpawn(Event hEvent, const char[] szEvent, bool bDontBroadcast)
{
	RequestFrame(OnPlayerSpawnNextTick, GetClientOfUserId(hEvent.GetInt("userid")));
}

void OnPlayerSpawnNextTick(int iClient)
{
	if(RoundIsEnd || !IsClientInGame(iClient) || !IsPlayerAlive(iClient) || IsFakeClient(iClient))
		return;
	
	SteamIDs.Push(GetSteamAccountID(iClient));
}

public void OnRoundFire(Event hEvent, const char[] szEvent, bool bDontBroadcast)
{
	delete TimerResetSpawnData;
	if((RoundIsEnd = (szEvent[6] == 'e')))
	{
		ResetSpawnData();
	}
	else
	{
		TimerResetSpawnData = CreateTimer((FindConVar("mp_freezetime")).FloatValue + 21.0, Timer_ResetSpawnData);
	}
}

public Action Timer_ResetSpawnData(Handle hTimer)
{
	TimerResetSpawnData = null;
	ResetSpawnData();

	return Plugin_Continue;
}

public Action Command_Joinclass(int iClient, const char[] command, int iArgs)
{
	if(RoundIsEnd || iClient == 0 || IsFakeClient(iClient) || !GetClientsCount(GetClientTeam(iClient), 1) || SteamIDs.FindValue(GetSteamAccountID(iClient)) == -1)
		return Plugin_Continue;
	
		
	Bug[iClient] = true;
	FakeClientCommandEx(iClient, "spec_mode");
	return Plugin_Handled;
}

void ResetSpawnData()
{
	SteamIDs.Clear();
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Bug[i])
		{
			Bug[i] = false;
			FakeClientCommandEx(i, "joinclass 0");
		}
	}
}

public void OnClientDisconnect(int iClient)
{
	Bug[iClient] = false;
}

stock int GetClientsCount(int iTeam = -1, int iAlive = -1, int iBots = -1)
{
	if(iTeam < 2 && iAlive == 1)
		return 0;

	int iCount;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i)	&& (iTeam == -1 || GetClientTeam(i) == iTeam)
								&& (iAlive == -1 || IsPlayerAlive(i) == !!iAlive)
								&& (iBots == -1 || IsFakeClient(i) == !!iBots))
		{
			iCount++;
		}
	}
	return iCount;
}