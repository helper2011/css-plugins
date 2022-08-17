#pragma semicolon 1

#include <sourcemod>
#include <sdktools_functions>
#include <sdktools_entinput>
#include <sdktools_engine>

#pragma newdecls required

public Plugin myinfo = 
{
	name	= "Look At Your Model [Edited]",
	author	= "wS",
	url		= "http://world-source.ru/",
	version = "1.0"
};

int Entity[MAXPLAYERS + 1];

public void OnPluginStart()
{
	HookEvent("player_death", OnPlayerFire);
	HookEvent("player_team",  OnPlayerFire);
	HookEvent("round_start",  OnRoundStart, EventHookMode_PostNoCopy);

	RegConsoleCmd("sm_look", Command_Look);
}

public void OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		StopClientLook(i);
	}
}

public void OnMapStart()
{
	PrecacheModel("models/error.mdl");
}

public Action Command_Look(int iClient, int iArgs)
{
	if (iClient && !IsFakeClient(iClient) && IsPlayerAlive(iClient) && !StopClientLook(iClient))
	{
		int iEntity = CreateEntityByName("prop_dynamic");
		if (iEntity != -1)
		{
		
			float fEye[3], fAng[3], fDirection[3];
			Entity[iClient] = EntIndexToEntRef(iEntity);
			
			DispatchKeyValue(iEntity, "model", "models/error.mdl");
			DispatchKeyValue(iEntity, "solid", "0");
			//DispatchKeyValue(iEntity, "spawnflags", "256");
			
			GetClientEyePosition(iClient, fEye);
			GetClientAbsAngles(iClient, fAng);
			
			fAng[0] = 0.0;
			fAng[2] = 0.0;
			
			GetAngleVectors(fAng, fDirection, NULL_VECTOR, NULL_VECTOR);
			fEye[0] += fDirection[0] * 100.0;
			fEye[1] += fDirection[1] * 100.0;
			fEye[2] -= 20.0;
			DispatchKeyValueVector(iEntity, "origin", fEye);
			fAng[1] += 180.0;
			DispatchKeyValueVector(iEntity, "angles", fAng);
			
			DispatchSpawn(iEntity);
			
			SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(iEntity, 255, 255, 255, 0);
			
			SetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget", 0);
			SetEntProp(iClient, Prop_Send, "m_iObserverMode", 1);
			SetEntProp(iClient, Prop_Send, "m_bDrawViewmodel", 0);
			SetEntProp(iClient, Prop_Send, "m_iFOV", 50);
			
			SetClientViewEntity(iClient, iEntity);
		}
		
	}
	return Plugin_Handled;
}

bool StopClientLook(int iClient, bool bDisconnect = false)
{
	if (!Entity[iClient])
		return false;
	
	if ((Entity[iClient] = EntRefToEntIndex(Entity[iClient])) != INVALID_ENT_REFERENCE)
		RemoveEntity(Entity[iClient]);
	
	Entity[iClient] = 0;
	
	if (!bDisconnect)
	{
		SetClientViewEntity(iClient, iClient);
		
		SetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(iClient, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(iClient, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(iClient, Prop_Send, "m_iFOV", 90);
	}
	
	return true;
}

public void OnClientDisconnect(int iClient)
{
	StopClientLook(iClient, true);
}

public void OnPlayerFire(Event hEvent, const char[] name, bool bDontBroadcasrt)
{
	StopClientLook(GetClientOfUserId(hEvent.GetInt("userid")));
}

public void OnRoundStart(Event hEvent, const char[] name, bool bDontBroadstart)
{
	OnPluginEnd();
}