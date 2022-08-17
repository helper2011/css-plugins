#include <sourcemod>
#include <cstrike>

#pragma newdecls required

bool Restrict;

public Plugin myinfo = 
{
    name = "Fix Buying Weapons",
	description = "Fixes a bug when you can buy weapons at the round start outside the buyzone",
    version = "1.0",
    author = "hEl"
};

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
}

public void OnRoundStart(Event hEvent, const char[] szName, bool bDontBroadCast)
{
	Restrict = true;
	RequestFrame(DisableRestrict);
}

void DisableRestrict()
{
	Restrict = false;
}

public Action CS_OnBuyCommand(int client, const char[] weapon)
{
	return Restrict ? Plugin_Handled:Plugin_Continue;
}