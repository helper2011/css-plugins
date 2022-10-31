#include <sourcemod>
#include <sdktools_entinput>
#include <sdktools_functions>
#include <cstrike>

#pragma newdecls required

const int WEAPONS_MAX = 100;

Handle Timer, StartRoundTimer;
int Weapon[WEAPONS_MAX], Time[WEAPONS_MAX];

ConVar cvarFlags, cvarLifeTime, cvarMaxWeapons;

int Flags, LifeTime, MaxWeapons;

bool RoundIsStarted;

enum
{
	IGNORE_SPECIAL_WEAPONS	=	(1 << 0),
	IGNORE_C4 				=	(1 << 1),
	DROP_REMOVE_INSTANTLY	=	(1 << 2)
}

public Plugin myinfo = 
{
    name = "Weapon Cleaner",
    version = "1.1",
    author = "hEl"
};


public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
	
	(FindConVar("mp_restartgame")).AddChangeHook(OnConVarChange);
	
	cvarFlags = CreateConVar("sm_weapon_cleaner_flags", "3", "1 = Ignore special weapons\n2 = Ignore C4\n4 = Remove drop instantly");
	cvarLifeTime = CreateConVar("sm_weapon_cleaner_lifetime", "15", "Weapon life");
	cvarMaxWeapons = CreateConVar("sm_weapon_cleaner_max_weapons", "10", "Max dropped weapons", _, true, 0.0, true, float(WEAPONS_MAX));
	
	cvarFlags.AddChangeHook(OnConVarChange);
	cvarLifeTime.AddChangeHook(OnConVarChange);
	cvarMaxWeapons.AddChangeHook(OnConVarChange);
	
	AutoExecConfig(true, "plugin.WeaponCleaner");
}

public void OnConfigsExecuted()
{
	Flags = cvarFlags.IntValue;
	LifeTime = cvarLifeTime.IntValue;
	MaxWeapons = cvarMaxWeapons.IntValue;
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(cvar == cvarFlags)
	{
		Flags = cvarFlags.IntValue;
	}
	else if(cvar == cvarLifeTime)
	{
		LifeTime = cvarLifeTime.IntValue;
	}
	else if(cvar == cvarMaxWeapons)
	{
		MaxWeapons = cvarMaxWeapons.IntValue;
	}
	else
	{
		if(!StringToInt(oldValue) && StringToInt(newValue) > 0)
		{
			OnRoundEnd(null, "", false);
		}
	}
}

public void OnRoundStart(Event hEvent, const char[] event, bool bDontBroadcast)
{
	ClearWeapons();
	delete StartRoundTimer;
	StartRoundTimer = CreateTimer(2.0, Timer_StartRound);
}

public Action Timer_StartRound(Handle hTimer)
{
	StartRoundTimer = null;
	RoundIsStarted = true;

	return Plugin_Continue;
}

public void OnRoundEnd(Event hEvent, const char[] event, bool bDontBroadcast)
{
	delete StartRoundTimer;
	RoundIsStarted = false;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(RoundIsStarted && IsValidEntity(entity) && classname[0] == 'w' && classname[6] == '_')
	{
		CreateTimer(0.1, Timer_OnEntitySpawned, EntIndexToEntRef(entity))
	}
}

public Action Timer_OnEntitySpawned(Handle hTimer, int entity)
{
	if((entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE)
	{
		InsertWeapon(entity);
	}

	return Plugin_Continue;
}

void ToggleTimer(bool bToggle)
{
	if(!bToggle)
	{
		delete Timer;
	}
	else if(!Timer)
	{
		Timer = CreateTimer(10.0, Timer_WeaponCleaner, _, TIMER_REPEAT);
	}
}

public void OnMapEnd()
{
	ClearWeapons();
	ToggleTimer(false);
}

public Action Timer_WeaponCleaner(Handle hTimer)
{
	int iCount;
	for(int i; i < WEAPONS_MAX; i++)
	{
		if(Weapon[i])
		{
			iCount++;
			RemoveWeapon(i);
		}
	}
	
	if(iCount == 0)
	{
		Timer = null;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

void InsertWeapon(int iWeapon, bool bDrop = false)
{
	if(	!IsValidEntity(iWeapon) || 
		(!bDrop && GetEntPropEnt(iWeapon, Prop_Data, "m_hOwnerEntity") != -1) || 
		(Flags & IGNORE_SPECIAL_WEAPONS && GetEntProp(iWeapon, Prop_Data, "m_iHammerID")) ||
		(Flags & IGNORE_C4 && Weapon_IsC4(iWeapon)))	
			return;
	
	if(bDrop && Flags & DROP_REMOVE_INSTANTLY)
	{
		RemoveEntity(iWeapon);
		return;
	}

	ToggleTimer(true);
	int iTime, iMode, iId = -1;
	for(int i; i < MaxWeapons; i++)
	{
		if(Weapon[i])
		{
			if(RemoveWeapon(i))
			{
				iMode = 1;
				iId = i;
				break;
			}
			else if(iId == -1 || Time[i] < iTime)
			{
				iId = i;
				iTime = Time[i];
			}
		}
		else
		{
			iMode = 2;
			iId = i;
			break;
		}
	}
	
	if(iId != -1)
	{
		if(!iMode)
		{
			RemoveWeapon(iId, true);
		}
		Time[iId] = GetTime();
		Weapon[iId] = EntIndexToEntRef(iWeapon);
	}
}

bool Weapon_IsC4(int iWeapon)
{
	char szBuffer[16];
	GetEntityClassname(iWeapon, szBuffer, 16);
	return (strcmp(szBuffer, "weapon_c4", false) == 0);
}

bool RemoveWeapon(int iWeapon, bool bForce = false)
{
	if(!bForce && GetTime() - Time[iWeapon] <= LifeTime)
	{
		return false;
	}
	int iEntity = EntRefToEntIndex(Weapon[iWeapon]);
	Time[iWeapon] = Weapon[iWeapon] = 0;
	if(iEntity != INVALID_ENT_REFERENCE && IsValidEntity(iEntity) && GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity") == -1)
	{
		RemoveEntity(iEntity);
	}
	return true;
	
}

public Action CS_OnCSWeaponDrop(int client, int weaponIndex)
{
	InsertWeapon(weaponIndex, true);
	return Plugin_Continue;
}

void ClearWeapons()
{
	for(int i; i < WEAPONS_MAX; i++)
	{
		Weapon[i] = 0;
	}
}