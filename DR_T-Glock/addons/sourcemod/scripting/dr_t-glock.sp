#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#pragma newdecls required

int Weapon = -1;

bool Pressed[2048], Toggle[MAXPLAYERS + 1];

Handle TimerInit, CookieSet;

public Plugin myinfo = 
{
	name		= "[DR] T-Glock",
	version		= "1.0",
	description	= "",
	author		= "hEl"
}

public void OnPluginStart()
{
    CookieSet = RegClientCookie("tglock", "", CookieAccess_Private);
    SetCookieMenuItem(CookieMenuH, 0, "T-Glock");
    HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);

    HookEntityOutput("func_button", "OnPressed", OnPressed);

    RegConsoleCmd("sm_tglock", Command_TGlock);

    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i))
        {
            OnClientPutInServer(i);

            if(AreClientCookiesCached(i))
            {
                OnClientCookiesCached(i);
            }
        }
    }
}

public void OnPluginEnd()
{
    if(Weapon != -1)
    {
        int iClient = GetEntPropEnt(Weapon, Prop_Data, "m_hOwnerEntity");
        if(iClient != -1)
        {
            RemovePlayerItem(iClient, Weapon);
        }
        RemoveEntity(Weapon);
    }
}

public void OnClientDisconnect(int iClient)
{
	Toggle[iClient] = false;
}

public void OnClientPutInServer(int iClient)
{
    SDKHook(iClient, SDKHook_TraceAttack, OnTraceAttack);
    if(!IsFakeClient(iClient) && !AreClientCookiesCached(iClient))
	{
		Toggle[iClient] = false;
	}
}

public void OnClientCookiesCached(int iClient)
{
	if(IsFakeClient(iClient))
		return;
		
	char szBuffer[4];
	GetClientCookie(iClient, CookieSet, szBuffer, 4);
	Toggle[iClient] = (szBuffer[0] != 0);
}

public Action Command_TGlock(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient))
	{
        Toggle[iClient] = !Toggle[iClient];
        PrintHintText(iClient, "T-Glock: [%s]", Toggle[iClient] ? "✔":"×");
        if(AreClientCookiesCached(iClient))
        {
        	SetClientCookie(iClient, CookieSet, Toggle[iClient] ? "1":"");
        }
	}
	
	return Plugin_Handled;
}

public void CookieMenuH(int iClient, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlen, "T-Glock: [%s]", Toggle[iClient] ? "✔":"×");
		}
		case CookieMenuAction_SelectOption:
		{
			Toggle[iClient] = !Toggle[iClient];
			SetClientCookie(iClient, CookieSet, Toggle[iClient] ? "1":"");
			ShowCookieMenu(iClient);
		}
	}
}

public void OnPressed(const char[] output, int caller, int activator, float delay)
{
    if(caller > MaxClients && caller < 2048)
    {
        Pressed[caller] = true;
    }
}

public void OnRoundStart(Event hEvent, const char[] name, bool bDontBroadcast)
{
    delete TimerInit;
    for(int i = MaxClients + 1; i < 2048; i++)
    {
        Pressed[i] = false;
    }
    bool bInit;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && Toggle[i])
        {
            bInit = true;
            Weapon = GivePlayerItem(i, "weapon_glock");
            break;
        }
    }

    if(bInit)
    {
        TimerInit = CreateTimer(1.0, Timer_InitEntities);
    }
}

public void OnRoundEnd(Event hEvent, const char[] name, bool bDontBroadcast)
{
    delete TimerInit;
}

public Action Timer_InitEntities(Handle hTimer)
{
    TimerInit = null;

    char szBuffer[32];
    for(int i = MaxClients + 1; i < 2048; i++)
    {
        if(IsValidEntity(i) && GetEntityClassname(i, szBuffer, 32) && !strcmp(szBuffer, "func_button", false))
        {
            SDKHook(i, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
        }
    }
}

public void OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
    if(attacker > 0 && attacker <= MaxClients && !Pressed[victim] && GetClientTeam(attacker) == 2 && Weapon != -1 && Weapon == GetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon"))
    {
        DataPack hPack = new DataPack();
        hPack.WriteCell(attacker);
        hPack.WriteCell(EntIndexToEntRef(victim));
        RequestFrame(OnButtonUse, hPack);
    }
}

void OnButtonUse(DataPack hPack)
{
    hPack.Reset();
    int iAttacker = hPack.ReadCell(), iButton = EntRefToEntIndex(hPack.ReadCell());
    delete hPack;

    if(IsClientInGame(iAttacker) && IsPlayerAlive(iAttacker) && iButton != INVALID_ENT_REFERENCE && !Pressed[iButton])
    {
        AcceptEntityInput(iButton, "Press", iAttacker, iButton);
    }
}

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
    return (Weapon != -1 && (0 < attacker <= MaxClients) && GetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon") == Weapon) ? Plugin_Handled:Plugin_Continue;
}

public Action CS_OnCSWeaponDrop(int iClient, int iWeapon)
{
    if(Weapon != -1 && Weapon == iWeapon)
    {
        RequestFrame(OnWeaponDroppedNext, EntIndexToEntRef(iWeapon));

    }
}

void OnWeaponDroppedNext(int iWeapon)
{
    if((iWeapon = EntRefToEntIndex(iWeapon)) != INVALID_ENT_REFERENCE && GetEntPropEnt(iWeapon, Prop_Data, "m_hOwnerEntity") == -1)
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