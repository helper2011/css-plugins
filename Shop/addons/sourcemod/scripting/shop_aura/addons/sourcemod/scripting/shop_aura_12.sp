#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <shop>

new g_iClientColor[MAXPLAYERS+1][4];
new bool:g_bHasAura[MAXPLAYERS+1];
new bool:g_bHide;
new Handle:g_hKeyValues,
	Handle:g_hTimer[MAXPLAYERS+1];
new g_BeamSprite,
	g_HaloSprite;

public Plugin:myinfo =
{
	name = "[Shop] Aura",
	author = "R1KO",
	version = "1.2"
};

public OnPluginStart()
{
	HookEvent("player_spawn", Event_OnPlayerSpawn);

	if (Shop_IsStarted()) Shop_Started();
}

public OnMapStart() 
{
	g_BeamSprite = PrecacheModel("materials/sprites/blueflare1.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/glow08.vmt");

	decl String:buffer[PLATFORM_MAX_PATH];
	if (g_hKeyValues != INVALID_HANDLE) CloseHandle(g_hKeyValues);
	
	g_hKeyValues = CreateKeyValues("Aura_Colors");
	
	Shop_GetCfgFile(buffer, sizeof(buffer), "aura_colors.txt");
	
	if (!FileToKeyValues(g_hKeyValues, buffer)) SetFailState("Couldn't parse file %s", buffer);
}

public OnPluginEnd() Shop_UnregisterMe();

public Shop_Started()
{
	if (g_hKeyValues == INVALID_HANDLE) OnMapStart();

	KvRewind(g_hKeyValues);
	decl String:sName[64], String:sDescription[64];

	g_bHide = bool:KvGetNum(g_hKeyValues, "Hide_Opposite_Team");
	
	KvGetString(g_hKeyValues, "name", sName, sizeof(sName), "Aura");
	KvGetString(g_hKeyValues, "description", sDescription, sizeof(sDescription));

	new CategoryId:category_id = Shop_RegisterCategory("aura", sName, sDescription);

	KvRewind(g_hKeyValues);

	if (KvGotoFirstSubKey(g_hKeyValues))
	{
		do
		{
			if (KvGetSectionName(g_hKeyValues, sName, sizeof(sName)) && Shop_StartItem(category_id, sName))
			{
				KvGetString(g_hKeyValues, "name", sDescription, sizeof(sDescription), sName);
				Shop_SetInfo(sDescription, "", KvGetNum(g_hKeyValues, "price", -1), KvGetNum(g_hKeyValues, "sellprice", -1), Item_Togglable, KvGetNum(g_hKeyValues, "duration", 604800));
				Shop_SetCallbacks(_, OnEquipItem);
				Shop_EndItem();
			}
		} while (KvGotoNextKey(g_hKeyValues));
	}
	
	KvRewind(g_hKeyValues);
}

public ShopAction:OnEquipItem(iClient, CategoryId:category_id, const String:category[], ItemId:item_id, const String:sItem[], bool:isOn, bool:elapsed)
{
	if (isOn || elapsed)
	{
		OnClientDisconnect(iClient);
		return Shop_UseOff;
	}
	
	Shop_ToggleClientCategoryOff(iClient, category_id);

	if (KvJumpToKey(g_hKeyValues, sItem, false))
	{
		new iColor[4];
		KvGetColor(g_hKeyValues, "color", iColor[0], iColor[1], iColor[2], iColor[3]);
		KvRewind(g_hKeyValues);

		for(new i=0; i < 4; i++) g_iClientColor[iClient][i] = iColor[i];
		
		g_bHasAura[iClient] = true;
		SetClientAura(iClient);
		
		return Shop_UseOn;
	}
	
	PrintToChat(iClient, "Failed to use \"%s\"!.", sItem);
	
	return Shop_Raw;
}

public OnClientDisconnect(iClient) 
{
	g_bHasAura[iClient] = false;
	if(g_hTimer[iClient] != INVALID_HANDLE)
	{
		KillTimer(g_hTimer[iClient]);
		g_hTimer[iClient] = INVALID_HANDLE;
	}
}

public OnClientPostAdminCheck(iClient) g_bHasAura[iClient] = false;

public Event_OnPlayerSpawn(Handle:hEvent, const String:sName[], bool:bSilent)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient > 0 && g_bHasAura[iClient] && IsPlayerAlive(iClient)) SetClientAura(iClient);
}

stock SetClientAura(iClient)
{
	if(g_hTimer[iClient] == INVALID_HANDLE) g_hTimer[iClient] = CreateTimer(0.1, Timer_Beacon, iClient, TIMER_REPEAT);
}

public Action:Timer_Beacon(Handle:hTimer, any:iClient)
{
	if(IsClientInGame(iClient) && IsPlayerAlive(iClient) && g_bHasAura[iClient])
	{
		static Float:fVec[3], iClients, i;
		decl iClientsArray[MaxClients];
		GetClientAbsOrigin(iClient, fVec);
		fVec[2] += 10.0;
		TE_SetupBeamRingPoint(fVec, 50.0, 60.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.1, 10.0, 0.0, g_iClientColor[iClient], 10, 0);
		i = 1;
		iClients = 0;
		
		if(g_bHide) 
		{
			decl iTeam;
			iTeam = GetClientTeam(iClient);
			while(i <= MaxClients)
			{ 
				if(IsClientInGame(i) && IsFakeClient(i) == false && GetClientTeam(i) == iTeam)
				{
					iClientsArray[iClients++] = i;
				}
				++i;
			}
		}
		else while(i <= MaxClients)
		{ 
			if(IsClientInGame(i) && IsFakeClient(i) == false)
			{
				iClientsArray[iClients++] = i;
			}
			++i;
		}
		TE_Send(iClientsArray, iClients);
		return Plugin_Continue;
	} else
	{
		KillTimer(g_hTimer[iClient]);
		g_hTimer[iClient] = INVALID_HANDLE;
	}
	return Plugin_Stop;
}