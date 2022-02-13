#include <sourcemod>
#include <sdktools_entinput>
#include <cstrike>

#pragma newdecls required

const int WEAPONS_MAX = 10;
const int WEAPON_LIFETIME = 15;

Handle Timer, StartRoundTimer;
int Weapon[WEAPONS_MAX], Time[WEAPONS_MAX];

bool RoundIsStarted;

public Plugin myinfo = 
{
    name = "Weapon Cleaner",
    version = "1.0",
    author = "hEl"
};


public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
	
	(FindConVar("mp_restartgame")).AddChangeHook(OnConVarChange);
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(!StringToInt(oldValue) && StringToInt(newValue) > 0)
	{
		OnRoundEnd(null, "", false);
	}
}

public void OnRoundStart(Event hEvent, const char[] event, bool bDontBroadcast)
{
	ClearWeapons();
	delete StartRoundTimer;
	StartRoundTimer = CreateTimer(10.0, Timer_StartRound);
}

public Action Timer_StartRound(Handle hTimer)
{
	StartRoundTimer = null;
	RoundIsStarted = true;
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

void InsertWeapon(int iWeapon)
{
	if(!IsValidEntity(iWeapon) || GetEntPropEnt(iWeapon, Prop_Data, "m_hOwnerEntity") != -1 || GetEntProp(iWeapon, Prop_Data, "m_iHammerID"))
	{
		return;
	}
	ToggleTimer(true);
	int iTime, iMode, iId = -1;
	for(int i; i < WEAPONS_MAX; i++)
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

bool RemoveWeapon(int iWeapon, bool bForce = false)
{
	if(!bForce && GetTime() - Time[iWeapon] <= WEAPON_LIFETIME)
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
	RequestFrame(OnWeaponDropped, weaponIndex);
}

public void OnWeaponDropped(int weapon)
{
	InsertWeapon(weapon);
}

void ClearWeapons()
{
	for(int i; i < WEAPONS_MAX; i++)
	{
		Weapon[i] = 0;
	}
}