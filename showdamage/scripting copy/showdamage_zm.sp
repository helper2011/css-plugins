#include <sourcemod>
#pragma newdecls required


public Plugin myinfo =
{
	name		= "ShowDamage zm",
	version		= "1.0",
	author		= "hEl"
};

public void OnPluginStart()
{
	HookEvent("player_hurt", OnPlayerHurt);
}

public void OnPlayerHurt(Event hEvent, const char[] event, bool bDontBroadcast)
{
	static int iHealth;
	static int iAttacker;
	iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	
	if(0 < iAttacker <= MaxClients && !IsFakeClient(iAttacker) && iAttacker != GetClientOfUserId(hEvent.GetInt("userid")))
	{
		iHealth = hEvent.GetInt("health");
		if(iHealth > 0)
		{
			PrintCenterText(iAttacker, "%i", iHealth);
		}
	}
}