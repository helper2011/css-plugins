#pragma semicolon 1

#include <sourcemod>
#include <sdktools_tempents>

public Plugin:myinfo = 
{
	name	= "Spray Blocker",
	author	= "wS / Schmidt",
	version	= "1.0"
};

public OnPluginStart()
{
	AddTempEntHook("Player Decal", wS);
}

public Action:wS(const String:te_name[], const Players[], numClients, Float:delay)
{
	return Plugin_Stop;
}