#include <sourcemod>
#include <sdkhooks>

#pragma newdecls required

ConVar cvar;

public Plugin myinfo = 
{
	name		= "NoFallDamage",
	version		= "1.0",
	description	= "",
	author		= "hEl"
}

public void OnPluginStart()
{
	cvar = CreateConVar("sm_nofalldamage", "1");
	if(cvar.BoolValue)
	{
		ToggleHook(true);
	}
	
	cvar.AddChangeHook(OnConVarChange);
}

public void OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	bool bNew = !!StringToInt(newValue);
	
	if(bNew != (!!StringToInt(oldValue)))
	{
		ToggleHook(bNew);
	}
}

void ToggleHook(bool bNew)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(bNew)
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
			else
			{
				SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}
}

public void OnClientPutInServer(int iClient)
{
	if(cvar.BoolValue)
	{
		SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	
}

public Action OnTakeDamage(int iClient, int& iAttacker, int& inflictor, float& fDamage, int& damagetype)
{
	return damagetype & DMG_FALL ? Plugin_Handled:Plugin_Continue;
}