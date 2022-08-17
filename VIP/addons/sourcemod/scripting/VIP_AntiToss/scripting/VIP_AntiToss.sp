#include <sourcemod>
#include <sdkhooks>
#include <vip_core>
#pragma newdecls required

static const char Feature[] = "AntiToss";
bool Hook[MAXPLAYERS + 1], Use[MAXPLAYERS + 1];

bool RoundIsStarted;

int Owner[2048];
float DropClientTime[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name		= "[VIP] Anti Toss",
	version		= "1.0",
	author		= "hEl"
}

public void OnPluginStart()
{
	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}

	HookEvent("round_start", OnRoundFire, EventHookMode_PostNoCopy);
	HookEvent("round_end", OnRoundFire, EventHookMode_PostNoCopy);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
			if(!IsFakeClient(i) && VIP_IsClientVIP(i))
			{
				VIP_OnVIPClientLoaded(i);
			}
		}
	}
}

public void OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(Feature);
	}
}

public void OnEntityDestroyed(int iEntity)
{
	if(MaxClients < iEntity < 2048)
	{
		Owner[iEntity] = 0;
	}
}

public void OnClientPutInServer(int iClient)
{
	if(!IsFakeClient(iClient))
	{
		SDKHook(iClient, SDKHook_WeaponDropPost, OnWeaponDropPost);
	}
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(Feature, BOOL, TOGGLABLE, OnClientToggleItem);
}

public Action OnClientToggleItem(int iClient, const char[] feature, VIP_ToggleState oldstatus, VIP_ToggleState &newstatus)
{
	Use[iClient] = (newstatus == ENABLED);
}

public void VIP_OnVIPClientLoaded(int iClient)
{
	if(VIP_GetClientFeatureStatus(iClient, Feature) < NO_ACCESS)
	{
		Use[iClient] = VIP_IsClientFeatureUse(iClient, Feature);
		if(!Hook[iClient])
		{
			SDKHook(iClient, SDKHook_WeaponCanUse, OnWeaponCanUse);
			Hook[iClient] = true;
		}
	}
}

public void OnWeaponDropPost(int iClient, int iWeapon)
{
	if(MaxClients < iWeapon <= 2048)
	{
		Owner[iWeapon] = iClient;
		
		if(Use[iClient])
		{
			DropClientTime[iClient] = GetEngineTime() + 2.0;
		}
	}
}

public Action OnWeaponCanUse(int iClient, int iWeapon)
{
	return (RoundIsStarted && Use[iClient] && 0 < Owner[iWeapon] <= MaxClients && Owner[iWeapon] != iClient && DropClientTime[iClient] > GetEngineTime() && !GetEntProp(iWeapon, Prop_Data, "m_iHammerID")) ? Plugin_Handled:Plugin_Continue;
}

public void OnClientDisconnect(int iClient)
{
	Use[iClient] = false;
	Hook[iClient] = false;
	DropClientTime[iClient] = 0.0;
}

public void OnRoundFire(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	RoundIsStarted = false;
	for(int i = MaxClients + 1; i < 2048; i++)
	{
		Owner[i] = 0;
	}

	CreateTimer(1.0, Timer_RoundStart);
}

public Action Timer_RoundStart(Handle hTimer)
{
	RoundIsStarted = true;
}