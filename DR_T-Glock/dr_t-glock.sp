#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <sdktools>

#pragma newdecls required

int Weapon = -1;

bool Pressed[2048];

public void OnPluginStart()
{
    HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);

    HookEntityOutput("func_button", "OnDamaged", OnButtonDamaged);
    HookEntityOutput("func_button", "OnPressed", OnPressed);


    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i))
        {
            SDKHook(i, SDKHook_TraceAttack, OnTraceAttack);
        }
    }
}

public void OnPluginEnd()
{
    if(Weapon != -1)
    {
        RemoveEntity(Weapon);
    }
}

public void OnPressed(const char[] output, int caller, int activator, float delay)
{
    if(caller > MaxClients && caller < 2048)
    {
        Pressed[caller] = true;
    }
}
public void OnButtonDamaged(const char[] output, int caller, int activator, float delay)
{
	PrintToChatAll("%i", GetEntPropEnt(activator, Prop_Data, "m_hActiveWeapon"));
    if(Weapon != -1 && caller > MaxClients && caller < 2048 && !Pressed[caller] && activator > 0 && activator <= MaxClients && GetEntPropEnt(activator, Prop_Data, "m_hActiveWeapon") == Weapon)
    {
        AcceptEntityInput(caller, "Press");
    }
}

public void OnRoundStart(Event hEvent, const char[] name, bool bDontBroadcast)
{
    for(int i = MaxClients + 1; i < 2048; i++)
    {
        Pressed[i] = false;
    }
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
        {
            Weapon = GivePlayerItem(i, "weapon_glock");
            return;
        }
    }
}

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
    PrintToChatAll("%i", inflictor);
    return (Weapon != -1 && (0 < attacker <= MaxClients) && GetEntProp(attacker, Prop_Data, "m_hActiveWeapon") == Weapon) ? Plugin_Handled:Plugin_Continue;
}

public Action CS_OnCSWeaponDrop(int iClient, int iWeapon)
{
    RequestFrame(OnWeaponDroppedNext, EntIndexToEntRef(iWeapon));
}

void OnWeaponDroppedNext(int iWeapon)
{
    if((iWeapon = EntRefToEntIndex(iWeapon)) != INVALID_ENT_REFERENCE && GetEntProp(iWeapon, Prop_Data, "m_hOwnerEntity") != -1)
    {
        RemoveEntity(iWeapon);
    }
}

public void OnEntityDestroyed(int iEntity)
{
    if(Weapon == iEntity)
    {
        Weapon = -1;
    }
}