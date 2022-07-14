#define ZOMBIE

#include <sourcemod>
#include <vip_core>

#pragma newdecls required

static const char g_sFeature[] = "RegenArmor";

Handle Timer;

int m_ArmorValue, RussianLanguageId;

#define REGEN_COUNT 1
#define REGEN_DELAY 3.0

public Plugin myinfo =
{
	name = "[VIP] Regen Armor",
	author = "hEl",
	version = "1.0"
};

public void OnPluginStart()
{
	if((RussianLanguageId = GetLanguageByCode("ru")) == -1)
	{
		SetFailState("Cant find russian language (see languages.cfg)");
	}
	LoadTranslations("vip_modules.phrases");
	m_ArmorValue = FindSendPropInfo("CCSPlayer", "m_ArmorValue");
	
	HookEvent("player_hurt", OnPlayerHurt);
	
	ToggleTimer();
	
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
		FormatEx(szDisplay, iMaxLength, "%T [%i AR/%.0f%c]", g_sFeature, iClient, REGEN_COUNT, REGEN_DELAY, GetClientLanguage(iClient) == RussianLanguageId ? 'c':'s');
		return true;
	}
	return false;
}

public void OnPlayerHurt(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	ToggleTimer();
}

void ToggleTimer()
{
	if(!Timer)
	{
		Timer = CreateTimer(REGEN_DELAY, Timer_Regen, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

#if defined ZOMBIE
public Action Timer_Regen(Handle hTimer)
{
	int iCount, iArmor;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 3 && VIP_IsClientVIP(i) && VIP_IsClientFeatureUse(i, g_sFeature) && (iArmor = GetEntData(i, m_ArmorValue)) < 100)
		{
			SetEntData(i, m_ArmorValue, (iArmor += REGEN_COUNT) >= 100 ? 100:iArmor);
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
		Timer = null;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}
#endif