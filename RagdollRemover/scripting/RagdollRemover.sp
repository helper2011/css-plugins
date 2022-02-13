#include <sourcemod>

#pragma newdecls required

public Plugin myinfo = 
{
	name		= "RagdollRemover",
	version		= "1.0",
	description	= "",
	author		= "hEl"
}

public void OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
}

public void OnPlayerDeath(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	//int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	int iRagdoll = GetEntPropEnt(GetClientOfUserId(hEvent.GetInt("userid")), Prop_Send, "m_hRagdoll");
	if(iRagdoll && IsValidEdict(iRagdoll))
	{
		RemoveEntity(iRagdoll);
	}
}
