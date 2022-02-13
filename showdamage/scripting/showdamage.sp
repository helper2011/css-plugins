#include <sourcemod>
#pragma newdecls required

int	LastClient[MAXPLAYERS + 1], Damage[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name		= "ShowDamage",
	version		= "1.0",
	author		= "hEl"
};

public void OnPluginStart()
{
	HookEvent("player_hurt", OnPlayerHurt);
}

public void OnClientPutInServer(int iClient)
{
	Damage[iClient] = 0;
	LastClient[iClient] = 0;
}


public void OnPlayerHurt(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker")), iClient;
	
	if(0 < iAttacker <= MaxClients && !IsFakeClient(iAttacker) && iAttacker != (iClient = GetClientOfUserId(hEvent.GetInt("userid"))))
	{
		if(!Damage[iAttacker])
		{
			RequestFrame(ShowDamage, iAttacker);
		}
		LastClient[iAttacker] = iClient;
		Damage[iAttacker] += hEvent.GetInt("dmg_health");
	}
}

public void ShowDamage(int iClient)
{
	PrintCenterText(iClient, "-%i · %i", Damage[iClient], GetEntProp(LastClient[iClient], Prop_Send, "m_iHealth"));
	Damage[iClient] = 0;
}