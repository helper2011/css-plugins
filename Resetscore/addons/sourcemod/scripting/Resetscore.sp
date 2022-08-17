#include <sourcemod>

#pragma newdecls required

public Plugin myinfo = 
{
	name		= "Resetscore",
	version		= "1.0"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_rs", Command_Resetscore);
	RegConsoleCmd("sm_resetscore", Command_Resetscore);
}

public Action Command_Resetscore(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient))
	{
		SetEntProp(iClient, Prop_Data, "m_iFrags", 0);
		SetEntProp(iClient, Prop_Data, "m_iDeaths", 0);
	}
	
	return Plugin_Handled;
}