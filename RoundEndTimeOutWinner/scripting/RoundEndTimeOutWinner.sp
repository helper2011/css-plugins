#include <sourcemod>
#include <cstrike>
#include <sdktools_functions>
#pragma newdecls required

ConVar TeamOfWinner;
Handle Timer;
int MapTarget = -1;

public Plugin myinfo = 
{
	name		= "RoundEndTimeOutWinner",
	version		= "1.0",
	description	= "",
	author		= "hEl"
}

public void OnPluginStart()
{
	TeamOfWinner = CreateConVar("round_end_timeout_winner", "0", "2 - T, 3 - CT, otherwise Draw");
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
}

public void OnMapEnd()
{
	MapTarget = -1;
	Timer = null;
}

public void OnRoundStart(Event hEvent, const char[] szName, bool bDontBroadCast)
{
	if(MapTarget <= 0)
	{
		delete Timer;
		Timer = CreateTimer((FindConVar("mp_freezetime")).FloatValue + (FindConVar("mp_roundtime")).FloatValue * 60.0, Timer_RoundEndTimeout, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}
public void OnRoundEnd(Event hEvent, const char[] szName, bool bDontBroadCast)
{
	delete Timer;
}

public Action Timer_RoundEndTimeout(Handle hTimer)
{
	Timer = null;
	if(MapTarget != -1 || FindMapTarget() == 0)
	{
		CSRoundEndReason reason;
		switch(TeamOfWinner.IntValue)
		{
			case 2:
			{
				reason = CSRoundEnd_TerroristWin;
			}
			case 3:
			{
				reason = CSRoundEnd_CTWin;
			}
			default:
			{
				reason = CSRoundEnd_Draw;
			}
		}
		CS_TerminateRound(5.0, reason, true);
	}
}

int FindMapTarget()
{
	int iEntity = -1;
	if(FindEntityByClassname(iEntity, "func_hostage_rescue") != -1 || FindEntityByClassname(iEntity, "func_bomb_target") != -1)
	{
		MapTarget = 1;
	}
	else
	{
		MapTarget = 0;
	}
	return MapTarget;
}