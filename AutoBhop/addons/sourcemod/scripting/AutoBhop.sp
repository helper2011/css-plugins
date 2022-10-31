#include <sourcemod>

//#define STAMINA

#pragma newdecls required

bool AutoBhop;

#if defined STAMINA
int g_iVelocity, g_iStamina;
#endif

public Plugin myinfo = 
{
	name		= "Simple AutoBunnyhop",
	version		= "1.0",
	description	= "",
	author		= "hEl"
}

public void OnPluginStart()
{
	#if defined STAMINA
	g_iVelocity = FindSendPropInfo("CCSPlayer", "m_flVelocityModifier");
	g_iStamina = FindSendPropInfo("CCSPlayer", "m_flStamina");
	#endif
	ConVar cvar = CreateConVar("sm_autobhop", "0");
	cvar.AddChangeHook(OnConVarChanged);
	AutoBhop = cvar.BoolValue;
}

public void OnConVarChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	AutoBhop = !!(StringToInt(newValue));
}

public Action OnPlayerRunCmd(int iClient, int& iButtons)
{
	if (!AutoBhop || !IsPlayerAlive(iClient) || GetEntityMoveType(iClient) & MOVETYPE_LADDER)
		return Plugin_Continue;
	
	static int initButtons;
	initButtons = iButtons;
	#if defined STAMINA
	if (GetEntDataFloat(iClient, g_iVelocity) < 1.0)
	{
		SetEntDataFloat(iClient, g_iVelocity, 1.0, true);
	}
	#endif
	if (iButtons & IN_JUMP && !(GetEntityFlags(iClient) & FL_ONGROUND) && GetEntProp(iClient, Prop_Data, "m_nWaterLevel") <= 1)
	{
		#if defined STAMINA
		SetEntDataFloat(iClient, g_iStamina, 0.0);
		#endif
		iButtons &= ~IN_JUMP;
	}
	
	return initButtons != iButtons ? Plugin_Changed:Plugin_Continue;
}

