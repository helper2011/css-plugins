#include <sourcemod>
#include <sdktools_entoutput>
#include <sdktools_entinput>

#pragma newdecls required

public Plugin myinfo = 
{
    name = "Fix Trap Buttons",
    version = "1.0",
    author = "hEl"
};

public void OnPluginStart()
{
	HookEntityOutput("func_button", "OnPressed", OnPressed);
}

public void OnMapStart()
{
	char szBuffer[256];
	
	GetCurrentMap(szBuffer, 16);
	if (strncmp(szBuffer, "dr_", 3, false) && strncmp(szBuffer, "deathrun_", 9, false))
	{
		GetPluginFilename(GetMyHandle(), szBuffer, 256);
		ServerCommand("sm plugins unload %s", szBuffer);
	}
}


public void OnPressed(const char[] sOutput, int iCaller, int iClient, float fDelay)
{
	if(0 < iClient <= MaxClients && IsClientInGame(iClient) && IsPlayerAlive(iClient) && GetClientTeam(iClient) == 2 && IsValidEntity(iCaller))
	{
		RemoveEntity(iCaller);
	}
}
