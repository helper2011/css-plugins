#include <sdktools>

#pragma newdecls required

const float Threshold = 0.73;

Handle Timer;

int Hammer, BlinkDelay, BlinkTicks;
float Frequency, BlinkTime, BlinkDuration, PosX, PosY;

public Plugin myinfo =
{
	name		= "SCP",
	version		= "1.0",
	description	= "Plugin for map ze_scp_escape by dima047",
	author		= "hEl"
};

public void OnPluginStart()
{
	ConVar cvar;
	cvar = CreateConVar("sm_scp_frequency", "0.1");
	Frequency = cvar.FloatValue;
	cvar.AddChangeHook(OnConVarFreqChanged);
	
	cvar = CreateConVar("sm_scp_hammer", "538345");
	Hammer = cvar.IntValue;
	cvar.AddChangeHook(OnConVarHammerChanged);
	
	cvar = CreateConVar("sm_scp_blink_delay", "4");
	BlinkDelay = cvar.IntValue;
	cvar.AddChangeHook(OnConVarBlinkDelayChanged);
	
	cvar = CreateConVar("sm_scp_blink_duration", "1.5");
	BlinkDuration = cvar.FloatValue;
	cvar.AddChangeHook(OnConVarBlinkDurationChanged);
	
	cvar = CreateConVar("sm_scp_blink_posx", "0.81");
	PosX = cvar.FloatValue;
	cvar.AddChangeHook(OnConVarBlinkPosXChanged);
	
	cvar = CreateConVar("sm_scp_blink_posy", "0.825");
	PosY = cvar.FloatValue;
	cvar.AddChangeHook(OnConVarBlinkPosYChanged);
	

}

public void OnConVarFreqChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Frequency = convar.FloatValue;
	
	delete Timer;
	Timer = CreateTimer(Frequency, Timer_Tick, _, TIMER_REPEAT);
}

public void OnConVarHammerChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Hammer = convar.IntValue;
}

public void OnConVarBlinkDelayChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	BlinkDelay = convar.IntValue;
}
public void OnConVarBlinkDurationChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	BlinkDuration = convar.FloatValue;
}

public void OnConVarBlinkPosXChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	PosX = convar.FloatValue;
}

public void OnConVarBlinkPosYChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	PosY = convar.FloatValue;
}





public void OnMapStart()
{
	char szBuffer[256];
	
	GetCurrentMap(szBuffer, 32);

	if (strncmp(szBuffer, "ze_scp_escape", 13, false))
	{
		GetPluginFilename(GetMyHandle(), szBuffer, 256);
		ServerCommand("sm plugins unload %s", szBuffer);
	}
	
	BlinkTicks = 0;
	BlinkTime = 0.0;
	CreateTimer(1.0, Timer_Tick, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	Timer = CreateTimer(Frequency, Timer_Tick2, _, TIMER_REPEAT);
	
	
}

public void OnMapEnd()
{
	delete Timer;
}

public Action Timer_Tick(Handle hTimer)
{
	char szBuffer[256];
	
	for(int i; i < BlinkDelay; i++)
	{
		StrCat(szBuffer, 256, BlinkTicks > i ? "●":"○");
	}
	
	PrintBlinkTicksAll(szBuffer);
	
	if(GetGameTime() > BlinkTime && ++BlinkTicks > BlinkDelay)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && IsValidKnife(i))
			{
				for(int j = 1; j <= MaxClients; j++)
				{
					if(IsClientInGame(j) && !IsFakeClient(j) && IsPlayerAlive(j) && GetClientTeam(j) == 3)
					{
						Client_ScreenFade(j, ClientViews(j, i));
					}
					
				}
			}
		}
	
		BlinkTime = GetGameTime() + BlinkDuration;
		BlinkTicks = 0;
	}
}

public Action Timer_Tick2(Handle hTimer)
{
	static bool LastViwed[MAXPLAYERS + 1];
	float Time = GetGameTime();
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && IsValidKnife(i))
		{
			bool bView;
			
			if(Time > BlinkTime)
			{
				for(int j = 1; j <= MaxClients; j++)
				{
					if(IsClientInGame(j) && IsPlayerAlive(j) && GetClientTeam(j) == 3)
					{
						if(ClientViews(j, i))
						{
							bView = true;
							break;
						}
					}
					
				}
			}

			
			if(!bView && LastViwed[i])
			{
				SetEntityMoveType(i, MOVETYPE_WALK);
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
				
			}
			if(bView && !LastViwed[i])
			{
				SetEntityMoveType(i, MOVETYPE_NONE);
				
			}
			LastViwed[i] = bView;
		}
		else
		{
			LastViwed[i] = false;
		}
	}
}

bool IsValidKnife(int iClient)
{
	if(Hammer)
	{
		int iWeapon = GetPlayerWeaponSlot(iClient, 2);
	
		return (iWeapon != -1 && GetEntProp(iWeapon, Prop_Data, "m_iHammerID") == Hammer);
	}
	
	return true;
}

// https://forums.alliedmods.net/showpost.php?p=973411&postcount=4

stock bool ClientViews(int iClient, int iTarget)
{
	float fViewPos[3], fViewAng[3], fViewDir[3], fTargetPos[3], fTargetDir[3], fDistance[3];
	
	GetClientEyePosition(iClient, fViewPos);
	GetClientEyeAngles(iClient, fViewAng);
	GetClientEyePosition(iTarget, fTargetPos);

	fViewAng[0] = fViewAng[2] = 0.0;
	GetAngleVectors(fViewAng, fViewDir, NULL_VECTOR, NULL_VECTOR);
	
	// Calculate distance to viewer to see if it can be seen.
	fDistance[0] = fTargetPos[0]-fViewPos[0];
	fDistance[1] = fTargetPos[1]-fViewPos[1];
	fDistance[2] = 0.0;
	
	// Check dot product. If it's negative, that means the viewer is facing
	// backwards to the target.
	NormalizeVector(fDistance, fTargetDir);
	if (GetVectorDotProduct(fViewDir, fTargetDir) < Threshold) return false;
	
	// Now check if there are no obstacles in between through raycasting
	Handle hTrace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, ClientViewsFilter);
	if (TR_DidHit(hTrace)) 
	{
		CloseHandle(hTrace); 
		return false; 
	}
	CloseHandle(hTrace);
	
	return true;
}


public bool ClientViewsFilter(int Entity, int Mask, int Junk)
{
    return !(Entity >= 1 && Entity <= MaxClients);
}

void PrintBlinkTicksAll(const char[] buffer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) == 2)
		{
			continue;
		}
		
		Handle hMessage = StartMessageOne("HudMsg", i);
		if (hMessage)
		{
			BfWriteByte(hMessage, 1);
	
			BfWriteFloat(hMessage, PosX);
			BfWriteFloat(hMessage, PosY);
	
			BfWriteByte(hMessage, 95);
			BfWriteByte(hMessage, 95);
			BfWriteByte(hMessage, 95);
			BfWriteByte(hMessage, 255);
			BfWriteByte(hMessage, 216);
			BfWriteByte(hMessage, 128);
			BfWriteByte(hMessage, 39);
			BfWriteByte(hMessage, 255);
			BfWriteByte(hMessage, 0);
	
			BfWriteFloat(hMessage, 0.05);
			BfWriteFloat(hMessage, 1.0);
			BfWriteFloat(hMessage, 0.05);
			BfWriteFloat(hMessage, 0.25);
	
			BfWriteString(hMessage, buffer);
			EndMessage();
		}
	}


}

public Action OnPlayerRunCmd(int iClient, int& iButtons)
{
	if (!IsPlayerAlive(iClient) || !IsValidKnife(iClient))
		return Plugin_Continue;
	
	int tempButtons = iButtons;
	if (iButtons & IN_ATTACK)
	{
		iButtons &= ~IN_ATTACK;
	}
	if (iButtons & IN_ATTACK2)
	{
		iButtons &= ~IN_ATTACK2;
	}

	
	return tempButtons != iButtons ? Plugin_Changed:Plugin_Continue;
}

stock void Client_ScreenFade(int iClient, bool bView)
{
	int iClients[1];
	iClients[0] = iClient;
	Handle hMessage = StartMessage("Fade", iClients, 1); 

	BfWriteShort(hMessage, RoundToNearest(BlinkDuration * 1000.0));
	BfWriteShort(hMessage, 0);
	BfWriteShort(hMessage, (0x0001));
	BfWriteByte(hMessage, 0);
	BfWriteByte(hMessage, 0);
	BfWriteByte(hMessage, 0);
	BfWriteByte(hMessage, bView ? 250:100);
	
	EndMessage(); 
}