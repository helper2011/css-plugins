#include <sourcemod>
#include <sdkhooks>

#pragma newdecls required

ConVar Cooldown;

float Time[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name		= "[DR] Button Press Interval",
	version		= "1.0",
	description	= "",
	author		= "hEl",
	url			= ""
};

public void OnPluginStart()
{
    Cooldown = CreateConVar("dr_button_use_cd", "0.1");
    HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
}

public void OnRoundStart(Event hEvent, const char[] szName, bool bDontBroadcast)
{
    if(Cooldown.FloatValue <= 0.0)
        return;

    char szBuffer[16];
    for(int i = MaxClients + 1; i < 2048; i++)
    {
        if(!IsValidEntity(i) || !GetEntityClassname(i, szBuffer, 16) || strcmp(szBuffer, "func_button", false))
            continue;

        SDKHook(i, SDKHook_Use, OnButtonUse);
    }
}

public Action OnButtonUse(int entity, int activator, int caller, UseType type, float value)
{
    if(activator > 0 && activator <= MaxClients)
    {
        float fTime = GetGameTime();
        if(fTime >= Time[activator])
        {
            Time[activator] = fTime + Cooldown.FloatValue;
            return Plugin_Continue;
        }
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public void OnClientDisconnect(int iClient)
{
    Time[iClient] = 0.0;
}