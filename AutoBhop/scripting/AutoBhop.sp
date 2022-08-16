//int g_iVelocity, g_iStamina;

public Plugin myinfo = 
{
	name		= "Simple AutoBunnyhop",
	version		= "1.0",
	description	= "",
	author		= "hEl"
}

public void OnPluginStart()
{
	/*g_iVelocity = FindSendPropInfo("CCSPlayer", "m_flVelocityModifier");
	g_iStamina = FindSendPropInfo("CCSPlayer", "m_flStamina");*/
}



public Action OnPlayerRunCmd(int iClient, int& iButtons)
{
	if (!IsPlayerAlive(iClient) || GetEntityMoveType(iClient) & MOVETYPE_LADDER)
		return Plugin_Continue;
	
	static int initButtons;
	initButtons = iButtons;
	/*if (GetEntDataFloat(iClient, g_iVelocity) < 1.0)
	{
		SetEntDataFloat(iClient, g_iVelocity, 1.0, true);
	}*/
	if (iButtons & IN_JUMP && !(GetEntityFlags(iClient) & FL_ONGROUND) && GetEntProp(iClient, Prop_Data, "m_nWaterLevel") <= 1)
	{
		//SetEntDataFloat(iClient, g_iStamina, 0.0);
		iButtons &= ~IN_JUMP;
	}
	
	return initButtons != iButtons ? Plugin_Changed:Plugin_Continue;
}

