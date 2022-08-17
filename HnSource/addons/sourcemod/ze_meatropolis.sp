#include <sourcemod>
#include <sdktools>

new Collision = -1;
#define Version "1.0.1"
public Plugin:myinfo = 
{
	name 		= "[CSS] Weapon Noblock",
	author 		= "Kingo",
	description = "Noblock for weapons.",
	version 	= Version,
	url 		= "N/A"
}


bool Ball[2048];

public OnPluginStart()
{
	Collision = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	if(Collision == -1)
	{
		SetFailState("Cannot find m_CollisionGroup Offset.");
	}
} 

public void OnGameFrame()
{
    for(int i = MaxClients + 1; i < 2048; i++)
    {
        if(Ball[i])
            SetEntData(i, Collision, 1, 4, true);
    }
}


public void OnEntitySpawned(int entity, const char[] classname)
{
    if(GetEntProp(entity, Prop_Data, "m_iHammerID") == 1044277)
    {
        Ball[entity] = true;
        

    }
}

public void OnEntityDestroyed(int entity)
{
    if(MaxClients < entity < 2048)
        Ball[entity] = false;
}