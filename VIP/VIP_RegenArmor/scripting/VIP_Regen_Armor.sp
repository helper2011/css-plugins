#include <sourcemod>
#include <vip_core>

#pragma newdecls required

static const char g_sFeature[] = "RegenArmor";

Handle Timer;

int m_ArmorValue;

#define REGEN_COUNT 1
#define REGEN_DELAY 1.0

public Plugin myinfo =
{
	name = "[VIP] Regen Armor",
	author = "hEl",
	version = "1.0"
};

public void OnPluginStart()
{
	m_ArmorValue = FindSendPropInfo("CCSPlayer", "m_ArmorValue");
	
	HookEvent("player_hurt", OnPlayerHurt);
	
	ToggleTimer(true);
	
	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, BOOL);
}


public void OnPluginEnd()
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
}

public void OnMapEnd()
{
	ToggleTimer(false);
}

public void OnPlayerHurt(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	ToggleTimer(true);
}

void ToggleTimer(bool bToggle)
{
	if(!bToggle)
	{
		delete Timer;
	}
	else if(!Timer)
	{
		Timer = CreateTimer(REGEN_DELAY, Timer_Regen, _, TIMER_REPEAT);
	}
}

public Action Timer_Regen(Handle hTimer)
{
	int iCount, iArmor;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && VIP_IsClientVIP(i) && VIP_IsClientFeatureUse(i, g_sFeature) && (iArmor = GetEntData(i, m_ArmorValue)) < 100)
		{
			SetEntData(i, m_ArmorValue, (iArmor += REGEN_COUNT) >= 100 ? 100:iArmor);
			iCount++;
		}
	}
	
	if(iCount == 0)
	{
		ToggleTimer(false);
	}
}