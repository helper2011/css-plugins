#include <sourcemod>
#include <sdktools>

#pragma newdecls required

bool MapIsStarted;

public Plugin myinfo = 
{
	name		= "Hegrenade Effect",
	version		= "1.0",
	description	= "",
	author		= "hEl"
};

public void OnMapStart()
{
	MapIsStarted = true;
}

public void OnMapEnd()
{
	MapIsStarted = false;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(MapIsStarted && IsValidEntity(entity) && !strcmp(classname, "hegrenade_projectile", false))
	{
		int particle = CreateEntityByName("info_particle_system");
		
		if (IsValidEdict(particle))
		{
			float pos[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
			DispatchKeyValue(particle, "effect_name", "fire_small_02");
			DispatchSpawn(particle);
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", entity);
			ActivateEntity(particle);
			AcceptEntityInput(particle, "Start"); 
			
			CreateTimer(2.0, Timer_DeleteEntity, EntIndexToEntRef(particle));
		}
	}
}

public Action Timer_DeleteEntity(Handle hTimer, int entity)
{
	if((entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(entity, "kill");
	}

	return Plugin_Continue;
}