#include <sourcemod>
#pragma newdecls required

int	Damage[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name		= "ShowDamage",
	version		= "1.1",
	author		= "hEl"
};

public void OnPluginStart()
{
	HookEvent("player_hurt", OnPlayerHurt);
}

public void OnClientDisconnect(int iClient)
{
	Damage[iClient] = 0;
}

public void OnPlayerHurt(Event hEvent, const char[] event, bool bDontBroadcast)
{
	static int iAttacker;
	iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	
	if(0 < iAttacker <= MaxClients && !IsFakeClient(iAttacker) && iAttacker != GetClientOfUserId(hEvent.GetInt("userid")))
	{
		Damage[iAttacker] += hEvent.GetInt("dmg_health");
	}
}

public void OnGameFrame()
{
	static bool bShowNextTick[MAXPLAYERS + 1];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(bShowNextTick[i])
		{
			bShowNextTick[i] = false;
			if(IsClientInGame(i))
			{
				PrintCenterText(i, "-%i", Damage[i]);
				Damage[i] = 0;
			}
		}
		else if(Damage[i])
		{
			bShowNextTick[i] = true;
		}
	}
}