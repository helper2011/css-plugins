#include <cstrike>

#pragma newdecls required

bool Switch[MAXPLAYERS + 1];

public Plugin myinfo = 
{
    name = "Beautiful Screenshot",
    version = "1.0",
	description = "Beautiful screenshot at the end of the round",
    author = "hEl",
	url = ""
};

public void OnPluginStart()
{
	AddCommandListener(Command_ChangeTeam, "jointeam");
	HookEvent("round_start", OnRoundStart, EventHookMode_Pre);
	HookEvent("round_end", OnRoundEnd);
}

public void OnPluginEnd()
{
	ChangeClientsTeamToSpec();
}

public Action Command_ChangeTeam(int iClient, const char[] command, int iArgs)
{
	if(Switch[iClient] && iArgs > 0)
	{
		OnClientDisconnect(iClient);
	}
	return Plugin_Continue;
}

public void OnRoundStart(Event hEvent, const char[] event, bool bDontBroadcast)
{
	ChangeClientsTeamToSpec();
}

public void OnRoundEnd(Event hEvent, const char[] event, bool bDontBroadcast)
{
	if(hEvent.GetInt("winner") != 3)
		return;
		
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) > 1)
			continue;
			
		CS_SwitchTeam(i, 2);
		Switch[i] = true;
	}
}

public void OnClientDisconnect(int iClient)
{
	Switch[iClient] = false;
}

void ChangeClientsTeamToSpec()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Switch[i])
		{
			if(IsClientInGame(i))
			{
				ChangeClientTeam(i, 1);
			}
			Switch[i] = false;
		
		}
	}
}