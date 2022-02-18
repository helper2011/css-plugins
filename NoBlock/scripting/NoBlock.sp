#include <sourcemod>
#include <cstrike>

#pragma newdecls required

enum
{
	PLAYERS,
	NADES,
	HOSTAGES,
	WEAPONS,
	
	TOTAL
}

int		m_CollisionGroup;
ConVar	ConVars[TOTAL];
bool	Toggle[TOTAL];

public Plugin myinfo = 
{
	name		= "NoBlock",
	version		= "1.1",
	description	= "",
	author		= "hEl"
}

public void OnPluginStart()
{
	if ((m_CollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup")) == -1)
	{
		SetFailState("[NoBlock] Failed to get offset for CBaseEntity::m_CollisionGroup.");
	}
	
	CreateConVar2(PLAYERS,	"sm_noblock",			"1",	"Removes players collision");
	CreateConVar2(NADES,	"sm_noblock_nades",		"1",	"Removes nades collision");
	CreateConVar2(HOSTAGES,	"sm_noblock_hostages",	"1",	"Removes hostages collision");
	CreateConVar2(WEAPONS,	"sm_noblock_weapons",	"1",	"Removes weapons collision");
	
	AutoExecConfig(true, "plugin.NoBlock");
}

public void OnPluginEnd()
{
	if(Toggle[PLAYERS])
	{
		SetClientsBlock(true);
	}
	if(Toggle[HOSTAGES])
	{
		SetHostagesBlock(true);
	}
}

public void OnConfigsExecuted()
{
	for(int i; i < TOTAL; i++)
	{
		Toggle[i] = ConVars[i].BoolValue;
	}
	if(Toggle[PLAYERS])
	{
		HookEvent("player_spawn", OnPlayerSpawn);
		SetClientsBlock(false);
	}
	if(Toggle[HOSTAGES])
	{
		HookEvent("round_start", OnRoundStart);
		SetHostagesBlock(false);
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
	for(int i; i < TOTAL; i++)
	{
		if(cvar == ConVars[i])
		{
			bool bOldValue = view_as<bool>(StringToInt(oldValue));
			Toggle[i] = ConVars[i].BoolValue;
			switch(i)
			{
				case PLAYERS:
				{
					if(Toggle[i] != bOldValue)
					{
						HookEvent2(0, "player_spawn", OnPlayerSpawn);
					}
					SetClientsBlock(!Toggle[i]);
					break;
				
				}
				case HOSTAGES:
				{
					if(Toggle[i] != bOldValue)
					{
						HookEvent2(2, "round_start", OnRoundStart);
					}
					SetHostagesBlock(!Toggle[i]);
					break;
				}
			}
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
	char szBuffer[32];
	int iEntities = GetMaxEntities();
	
	for(int i = MaxClients + 1; i <= iEntities; i++)
	{
		if(!IsValidEntity(i) || !GetEntityClassname(i, szBuffer, 32) || strcmp(szBuffer, "hostage_entity", false))
			continue;
			
		SetEntityBlock(i, bBlock);
	}
}

public void OnEntityCreated(int iEntity, const char[] classname)
{
	if(!IsValidEntity(iEntity))
		return;
	
	if(Toggle[NADES])
	{
		if(strlen(classname) > 19)
		{
			switch(classname[0])
			{
				case 'h', 'f', 's':
				{
					if(classname[10] == 'p' || classname[13] == 'p')
					{
						SetEntityBlock(iEntity, false);
						return;
					}
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
	RequestFrame(OnPlayerSpawnNextTick, GetClientOfUserId(hEvent.GetInt("userid")));
}

void OnPlayerSpawnNextTick(int iClient)
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

public Action CS_OnCSWeaponDrop(int iClient, int iWeapon)
{
	if(Toggle[WEAPONS])
	{
		SetEntityBlock(iWeapon, false);
	}
}