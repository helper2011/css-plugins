#include <sourcemod>
#include <sdktools_tempents>

#pragma newdecls required

public Plugin myinfo = 
{
	name	= "Spray Blocker",
	author	= "wS / Schmidt",
	version	= "1.0"
};

public void OnPluginStart()
{
	AddTempEntHook("Player Decal", wS);
}

public Action wS(const char[] name, const int[] Players, int iPlayersCount, float delay)
{
	return Plugin_Stop;
}