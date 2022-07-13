#define ZOMBIE

#include <sourcemod>
#include <vip_core>

#pragma newdecls required

static const char g_sFeature[] = "RegenHP";

Handle Timer;

int m_iHealth, 
	Health[MAXPLAYERS + 1] = {100, ...};

#define REGEN_COUNT 1
#define REGEN_DELAY 3.0

public Plugin myinfo =
{
	name = "[VIP] Regen Health",
	author = "hEl",
	version = "1.0"
};

public void OnPluginStart()
{
	LoadTranslations("vip_modules.phrases");
	m_iHealth = FindSendPropInfo("CCSPlayer", "m_iHealth");
	
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_hurt", OnPlayerHurt);
	
	ToggleTimer();
	Timer_GetClientHealths(null);
	
	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, BOOL, _, _, OnItemDisplay);
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
	Timer = null;
}

public bool OnItemDisplay (int iClient, const char[] szFeature, char[] szDisplay, int iMaxLength)
{
	if(VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		FormatEx(szDisplay, iMaxLength, "%T [%i HP/%.0f%c]", g_sFeature, iClient, REGEN_COUNT, REGEN_DELAY, GetClientLanguage(iClient) == 22 ? 'c':'s');
		return true;
	}
	return false;
}

public void OnRoundStart(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	CreateTimer(1.5, Timer_GetClientHealths);
}

public Action Timer_GetClientHealths(Handle hTimer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && VIP_IsClientVIP(i) && VIP_IsClientFeatureUse(i, g_sFeature) && (Health[i] = GetEntData(i, m_iHealth)) < 100)
		{
			Health[i] = 100;
		}
	}
}

public void OnPlayerHurt(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	ToggleTimer();
}

void ToggleTimer()
{
	if(!Timer)
	{
		Timer = CreateTimer(REGEN_DELAY, Timer_Regen, _, TIMER_REPEAT);
	}
}
#if defined ZOMBIE
public Action Timer_Regen(Handle hTimer)
{
	int iCount, iHealth;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 3 && VIP_IsClientVIP(i) && VIP_IsClientFeatureUse(i, g_sFeature) && (iHealth = GetEntData(i, m_iHealth)) < Health[i])
		{
			SetEntData(i, m_iHealth, (iHealth += REGEN_COUNT) >= Health[i] ? Health[i]:iHealth);
			iCount++;
		}
	}
	
	if(iCount == 0)
	{
		Timer = null;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}
#else
public Action Timer_Regen(Handle hTimer)
{
	int iCount, iHealth;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && VIP_IsClientVIP(i) && VIP_IsClientFeatureUse(i, g_sFeature) && (iHealth = GetEntData(i, m_iHealth)) < Health[i])
		{
			SetEntData(i, m_iHealth, (iHealth += REGEN_COUNT) >= Health[i] ? Health[i]:iHealth);
			iCount++;
		}
	}
	
	if(iCount == 0)
	{
		Timer = null;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}
#endif