#include <sourcemod>
#include <sdkhooks>
#include <profiler>

#pragma newdecls required

ConVar Cooldown;

float Time[MAXPLAYERS + 1];
float fCooldown;

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
    Cooldown.AddChangeHook(OnConVarChange);
    fCooldown = Cooldown.FloatValue;
    HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);

    Test1();
}

public void OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
    fCooldown = convar.FloatValue;
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

void Test1()
{
    Profiler profiler = new Profiler();
    profiler.Start();
    for(int i = 0; i < 100000; i++)
    {
        Test_1();
    }
    profiler.Stop();
    PrintToConsoleAll("test1 = %f", profiler.Time);
    delete profiler;
    
    Test2();
}

void Test2()
{
    Profiler profiler = new Profiler();
    profiler.Start();
    for(int i = 0; i < 100000; i++)
    {
        Test_2();
    }
    profiler.Stop();
    PrintToConsoleAll("test2 = %f", profiler.Time);
    delete profiler;
}


void Test_1()
{
    if(Cooldown.FloatValue <= 0.0)
        return;
}

void Test_2()
{
    if(fCooldown <= 0.0)
        return;
}

