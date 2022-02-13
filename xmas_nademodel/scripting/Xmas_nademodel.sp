#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[Xmas] nade model",
	version = "1.0",
	author = "hEl"
}

public void OnMapStart()
{
	PrecacheModel("models/zombieden/xmode/marisa/ball.mdl", true);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(IsValidEntity(entity) && strlen(classname) > 15 && classname[0] == 'h' && !strncmp(classname[10], "proj", 4, true))
	{
		RequestFrame(OnSpawnHE, EntIndexToEntRef(entity));
	}
}

void OnSpawnHE(int iEntity)
{
	if((iEntity = EntRefToEntIndex(iEntity)) != INVALID_ENT_REFERENCE)
	{
		SetEntityModel(iEntity, "models/zombieden/xmode/marisa/ball.mdl");
	}
}