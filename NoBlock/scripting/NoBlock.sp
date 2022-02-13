#include <sourcemod>

#pragma newdecls required

int m_CollisionGroup;

ConVar ConVars[3];
bool Toggle[3];

public Plugin myinfo = 
{
	name		= "NoBlock",
	version		= "1.0",
	description	= "",
	author		= "hEl"
}

public void OnPluginStart()
{
	if ((m_CollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup")) == -1)
	{
		SetFailState("[NoBlock] Failed to get offset for CBaseEntity::m_CollisionGroup.");
	}
	
	CreateConVar2(0, "sm_noblock", "1", "Removes player vs. player collisions");
	CreateConVar2(1, "sm_noblock_nades", "1", "Removes player vs. nade collisions");
	CreateConVar2(2, "sm_noblock_hostages", "1", "Removes player vs. hostage collisions");
	AutoExecConfig(true, "plugin.NoBlock");
	
	if(Toggle[0])
	{
		HookEvent("player_spawn", OnPlayerSpawn);
		SetClientsBlock(false);
	}
	if(Toggle[2])
	{
		HookEvent("round_start", OnRoundStart);
		SetHostagesBlock(false);
	}
}

public void OnPluginEnd()
{
	if(Toggle[0])
	{
		SetClientsBlock(true);
	}
	if(Toggle[2])
	{
		SetHostagesBlock(true);
	}
}

void CreateConVar2(int iId, const char[] cvar, const char[] value, const char[] description)
{
	ConVars[iId] = CreateConVar(cvar, value, description);
	Toggle[iId] = ConVars[iId].BoolValue;
	ConVars[iId].AddChangeHook(OnConVarChange);
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	for(int i; i < 3; i++)
	{
		if(cvar == ConVars[i])
		{
			bool bOldValue = view_as<bool>(StringToInt(oldValue));
			Toggle[i] = ConVars[i].BoolValue;
			
			if(i == 0)
			{
				if(Toggle[i] != bOldValue)
				{
					HookEvent2(0, "player_spawn", OnPlayerSpawn);
				}
				SetClientsBlock(!Toggle[i]);
			}
			else if(i == 2)
			{
				if(Toggle[i] != bOldValue)
				{
					HookEvent2(2, "round_start", OnRoundStart);
				}
				SetHostagesBlock(!Toggle[i]);
			}
			
			break;
		}
	}
}

void SetEntityBlock(int iEntity, bool bBlock)
{
	SetEntData(iEntity, m_CollisionGroup, bBlock ? 5:2, 4, true);
}

void SetClientsBlock(bool bBlock)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntityBlock(i, bBlock);
		}
	}
}

void SetHostagesBlock(bool bBlock)
{
	int iEntities = GetMaxEntities();
	
	for(int i = MaxClients + 1; i <= iEntities; i++)
	{
		if(!IsValidEntity(i))
			continue;
			
		char szBuffer[32];
		if(GetEntityClassname(i, szBuffer, 32) && !strcmp(szBuffer, "hostage_entity", false))
		{
			SetEntityBlock(i, bBlock);
		}
	}
}

public void OnEntityCreated(int iEntity, const char[] classname)
{
	if(IsValidEntity(iEntity) && Toggle[1] && strlen(classname) > 19)
	{
		switch(classname[0])
		{
			case 'h', 'f', 's':
			{
				if(classname[10] == 'p' || classname[13] == 'p')
				{
					SetEntityBlock(iEntity, false);
				}
			}
		}
	}
}

void HookEvent2(int iId, const char[] event, EventHook callback)
{
	if(Toggle[iId])
	{
		HookEvent(event, callback);
	}
	else
	{
		UnhookEvent(event, callback);
	}
}

public void OnPlayerSpawn(Event hEvent, const char[] event, bool bDontBroadcast)
{
	CreateTimer(0.0, Timer_OnPlayerSpawn, GetClientOfUserId(hEvent.GetInt("userid")));
}

public Action Timer_OnPlayerSpawn(Handle hTimer, int iClient)
{
	if(IsClientInGame(iClient) && IsPlayerAlive(iClient))
	{
		SetEntityBlock(iClient, false);
	}
}

public void OnRoundStart(Event hEvent, const char[] event, bool bDontBroadcast)
{
	CreateTimer(1.0, Timer_OnRoundStart);
}


public Action Timer_OnRoundStart(Handle hTimer, int iClient)
{
	SetHostagesBlock(false);
}