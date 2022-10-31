#include <sourcemod>
#include <sdktools>

#define DEBUG 0
#define DEBUG_ADV 0

#pragma newdecls required

#include "rsp/debug.sp"
#include "rsp/convars.sp"
#include "rsp/point.sp"
#include "rsp/ff.sp"
#include "rsp/search.sp"
#include "rsp/commands.sp"

public Plugin myinfo = 
{
	name		= "RandomSpawnPoints",
	version		= "1.0",
	description	= "",
	author		= "hEl",
	url			= ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    Debug_FileInit()
    return APLRes_Success;
}

public void OnPluginStart()
{
    DebugMessage("OnPluginStart")
    CreateConVars();
    RegCommands();
    Point_DataInit();
    Search_DataInit();
    HookEvent("player_spawn", OnPlayerSpawn_Pre, EventHookMode_Pre);
    AutoExecConfig(true, "plugin.RandomSpawnPoints");
}

public void OnPluginEnd()
{
    DebugMessage("OnPluginEnd")

    OnMapEnd();
}

public void OnMapStart()
{
    DebugMessage("OnMapStart")

    Point_LoadPoints();
    Search_OnMapStart();
}

public void OnMapEnd()
{
    DebugMessage("OnMapEnd")

    Debug_FileInit()
    Search_OnMapEnd();
    Point_OnMapEnd();
}

public void OnPlayerSpawn_Pre(Event hEvent, const char[] szName, bool bDontBroadcast)
{
    DebugMessage("OnPlayerSpawn_Pre")

    Point_TeleportClientToRandomPoint(GetClientOfUserId(hEvent.GetInt("userid")));
}