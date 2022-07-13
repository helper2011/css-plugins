#define ZOMBIE

#include <sourcemod>
#include <vip_core>

#pragma newdecls required

int m_iHealth, Health[MAXPLAYERS + 1];

static const char Feature[] = "Health";

public Plugin myinfo = 
{
	name		= "[VIP] Health",
	version		= "1.0",
	author		= "hEl"
}

public void OnPluginStart()
{
	LoadTranslations("vip_modules.phrases");
	m_iHealth = FindSendPropInfo("CCSPlayer", "m_iHealth");
	
	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && VIP_IsClientVIP(i))
		{
			VIP_OnVIPClientLoaded(i);
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

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(Feature, INT, TOGGLABLE, _, OnItemDisplay);
}

public bool OnItemDisplay(int iClient, const char[] feature, char[] display, int maxlength)
{
	if (VIP_IsClientFeatureUse(iClient, feature))
	{
		FormatEx(display, maxlength, "%T: [%i HP]", feature, iClient, Health[iClient]);
		return true;
	}

	return false;
}

public void VIP_OnVIPClientLoaded(int iClient)
{
	if(VIP_GetClientFeatureStatus(iClient, Feature) < NO_ACCESS)
	{
		Health[iClient] = VIP_GetClientFeatureInt(iClient, Feature);
	}
}

public void OnClientDisconnect(int iClient)
{
	Health[iClient] = 0;
}

public void VIP_OnPlayerSpawn(int iClient, int iTeam, bool bIsVip)
{
	if(bIsVip && Health[iClient])
	{
		#if defined ZOMBIE
		if(GetClientTeam(iClient) == 3)
		{
			SetEntData(iClient, m_iHealth, Health[iClient]);
		}
		#else
		SetEntData(iClient, m_iHealth, Health[iClient]);
		#endif
	}
}