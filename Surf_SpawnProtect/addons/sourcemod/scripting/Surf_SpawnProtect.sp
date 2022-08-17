#include <sourcemod>

float SpawnProtectTime;

ConVar ProtectTime;

Handle Timer;

int RussianLanguageId;

public Plugin myinfo =
{
	name		= "[Surf] Spawn Protect",
	version		= "1.0",
	author		= "hEl"
};

public void OnPluginStart()
{
	if((RussianLanguageId = GetLanguageByCode("ru")) == -1)
	{
		SetFailState("Cant find russian language (see languages.cfg)");
	}
	ProtectTime = CreateConVar("sm_spawn_protect_time", "20.0");
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
}

public void OnPluginEnd()
{
	if(Timer)
	{
		delete Timer;
		Timer_Protect(null);
	}
}

public void OnMapStart()
{
	char szBuffer[256];
	GetCurrentMap(szBuffer, 256);
	if (strncmp(szBuffer, "surf_", 5, false))
	{
		GetPluginFilename(GetMyHandle(), szBuffer, 256);
		ServerCommand("sm plugins unload %s", szBuffer);
	}
	SpawnProtectTime = 0.0;
}

public void OnRoundStart(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	delete Timer;
	float fProtectTime = ProtectTime.FloatValue;
	SpawnProtectTime = GetGameTime() + fProtectTime;
	Timer = CreateTimer(fProtectTime, Timer_Protect);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		ToggleClientProtect(i, 0);
	}
}

public void OnRoundEnd(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	delete Timer;
}

public void OnPlayerSpawn(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	RequestFrame(OnPlayerSpawnNextTick, GetClientOfUserId(hEvent.GetInt("userid")));
}

void OnPlayerSpawnNextTick(int iClient)
{
	if(SpawnProtectTime > GetGameTime())
	{
		ToggleClientProtect(iClient, 0);
	}
	
}

void ToggleClientProtect(int iClient, int iValue)
{
	if(!IsClientInGame(iClient) || !IsPlayerAlive(iClient) || iValue == GetEntProp(iClient, Prop_Data, "m_takedamage"))
		return;
	
	SetEntProp(iClient, Prop_Data, "m_takedamage", iValue, 1);
		
	if(!IsFakeClient(iClient))
	{
		if(iValue)
		{
			PrintToChat(iClient, GetClientLanguage(iClient) == RussianLanguageId ? "Защита отключена":"Protection is disabled");
		}
		else
		{
			PrintToChat(iClient, GetClientLanguage(iClient) == RussianLanguageId ? "Вы защищены на %i сек":"You are protected for %i seconds", RoundToNearest(SpawnProtectTime - GetGameTime()));
		}
	}
}

public Action Timer_Protect(Handle hTimer)
{
	Timer = null;
	for(int i = 1; i <= MaxClients; i++)
	{
		ToggleClientProtect(i, 2);
	}
}