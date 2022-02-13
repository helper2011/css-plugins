#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <shop>
#include <clientprefs>

#pragma newdecls required

#define PLUGIN_VERSION	"2.2.3"
#define CATEGORY	"trails"
Handle HideCookie;
bool HideTrails[MAXPLAYERS + 1];
bool HideOppositeTeam;

KeyValues Config;

int Team[MAXPLAYERS+1];
int Entity[MAXPLAYERS + 1];
ItemId Trail[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "[Shop] Trails [Edited]",
	author = "FrozDark (HLModders LLC)",
	description = "Trails that folows a player",
	version = PLUGIN_VERSION,
	url = "http://www.hlmod.ru/"
};

public void OnPluginStart()
{
	LoadConfig();
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_team", OnPlayerTeam);
	HideCookie = RegClientCookie("ShopHideTrails", "", CookieAccess_Private);
	RegConsoleCmd("sm_hidetrails", Command_HideTrails);
	RegAdminCmd("sm_trails_reload", Command_TrailsReload, ADMFLAG_ROOT, "Reloads trails config list");
	SetCookieMenuItem(HideTrailsMenuHandler, 0, "Hide Trails");
	if (Shop_IsStarted()) Shop_Started();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			Team[i] = GetClientTeam(i);
			
			if(AreClientCookiesCached(i))
			{
				OnClientCookiesCached(i);
			}
		}
	}
}

public void OnPluginEnd()
{
	Shop_UnregisterMe();
	for (int i = 1; i <= MaxClients; i++)
	{
		KillTrail(i);
	}
}

public void OnMapStart()
{
	char szBuffer[256];
	Config.Rewind();
	Config.GotoFirstSubKey();
	do
	{
		Config.GetString("material", szBuffer, 256);
		PrecacheModel(szBuffer, true);
	}
	while(Config.GotoNextKey());
}

public Action Command_HideTrails(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient))
	{
		SetClientCookieBool(iClient);
	}
	return Plugin_Handled;
}

public void HideTrailsMenuHandler(int iClient, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlen, "%s: [%s]", GetClientLanguage(iClient) == 22 ? "Скрытие трейлов":"Hide trails", HideTrails[iClient] ? "✔":"×");
		}
		case CookieMenuAction_SelectOption:
		{
			SetClientCookieBool(iClient);
			ShowCookieMenu(iClient);
		}
	}
}

void SetClientCookieBool(int iClient)
{
	HideTrails[iClient] = !HideTrails[iClient];
	PrintHintText(iClient, "%s: [%s]", GetClientLanguage(iClient) == 22 ? "Скрытие трейлов":"Hide trails", HideTrails[iClient] ? "✔":"×");
	if(AreClientCookiesCached(iClient))
	{
		SetClientCookie(iClient, HideCookie, HideTrails[iClient] ? "1":"");
	}
}


void LoadConfig()
{
	char szBuffer[256];
	Config = new KeyValues("Trails");
	Shop_GetCfgFile(szBuffer, 256, "trails.txt");
	if (!Config.ImportFromFile(szBuffer))
	{
		SetFailState("Config file \"%s\" not found", szBuffer);
	}
	
	if(!Config.GotoFirstSubKey())
	{
		SetFailState("No trails");
	}
}

public void Shop_Started()
{
	Config.Rewind();
	char name[64], description[64];
	Config.GetString("name", name, 64, "Trails");
	Config.GetString("description", description, 64);
	
	CategoryId category_id = Shop_RegisterCategory(CATEGORY, name, description);
	
	char item[64], item_name[64], item_description[64], buffer[256];
	HideOppositeTeam = !!(Config.GetNum("hide_opposite_team", 1));
	Config.GotoFirstSubKey();
	do
	{
		Config.GetString("material", buffer, sizeof(buffer));
		
		Config.GetSectionName(item, sizeof(item));
		
		if (Shop_StartItem(category_id, item))
		{
			Config.GetString("name", item_name, sizeof(item_name), item);
			Config.GetString("description", item_description, sizeof(item_description));
			Shop_SetInfo(item_name, item_description, Config.GetNum("price", 500), Config.GetNum("sell_price", -1), Item_Togglable, Config.GetNum("duration", 86400));
			Shop_SetCallbacks(OnItemRegistered, OnEquipItem);
			Shop_EndItem();
		}
	}
	while (Config.GotoNextKey());
}

public void OnItemRegistered(CategoryId category_id, const char[] category, const char[] item, ItemId item_id)
{
	Config.Rewind();
	if (Config.JumpToKey(item))
	{
		char buffer[256];
		Config.GetString("material", buffer, sizeof(buffer));
		PrecacheModel(buffer, true);
		Config.SetNum("id", view_as<int>(item_id));
	}
}

public Action Command_TrailsReload(int client, int args)
{
	delete Config;
	LoadConfig();
	OnPluginEnd();
	Shop_Started();
	
	ReplyToCommand(client, "Trails config list reloaded successfully!");
	
	return Plugin_Handled;
}

public ShopAction OnEquipItem(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, bool isOn, bool elapsed)
{
	if (isOn || elapsed)
	{
		OnClientDisconnect(client);
		Trail[client] = INVALID_ITEM;
		return Shop_UseOff;
	}
	
	Shop_ToggleClientCategoryOff(client, category_id);
	Trail[client] = item_id;
	SpriteTrail(client);
	return Shop_UseOn;
}

public void OnClientCookiesCached(int iClient)
{
	if(!IsFakeClient(iClient))
	{
		char szBuffer[4];
		GetClientCookie(iClient, HideCookie, szBuffer, 4);
		HideTrails[iClient] = (szBuffer[0] != 0);
	}
}

public void OnClientDisconnect(int client)
{
	KillTrail(client);
}

public void OnClientDisconnect_Post(int client)
{
	Team[client] = 0;
	Trail[client] = INVALID_ITEM;
	Entity[client] = 0;
	HideTrails[client] = false;
}

public void OnPlayerSpawn(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(Trail[iClient] && iClient && Team[iClient] > 1)
	{
		RequestFrame(OnPlayerSpawnNextTick, iClient);
	}
}

void OnPlayerSpawnNextTick(int iClient)
{
	if(!IsClientInGame(iClient) || Trail[iClient] == INVALID_ITEM)
		return;
	
	SpriteTrail(iClient);
}

public void OnPlayerTeam(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	Team[GetClientOfUserId(hEvent.GetInt("userid"))] = hEvent.GetInt("team");
}

public void OnPlayerDeath(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	KillTrail(GetClientOfUserId(hEvent.GetInt("userid")));
}

bool SpriteTrail(int client)
{
	KillTrail(client);
	
	if(!IsPlayerAlive(client) || HideTrails[client])
	{
		return false;
	}
	char szBuffer[256];
	Shop_GetItemById(Trail[client], szBuffer, 256);
	Config.Rewind();
	if (!szBuffer[0] || !Config.JumpToKey(szBuffer))
	{
		PrintToServer("Item %s is not exists");
		return false;
	}
	
	int iEntity = CreateEntityByName("env_spritetrail");
	if (iEntity != -1) 
	{
		Entity[client] = EntIndexToEntRef(iEntity);
		float dest_vector[3];
		
		DispatchKeyValueFloat(iEntity, "lifetime", Config.GetFloat("lifetime", 1.0));
		
		Config.GetString("startwidth", szBuffer, sizeof(szBuffer), "10");
		DispatchKeyValue(iEntity, "startwidth", szBuffer);
		
		Config.GetString("endwidth", szBuffer, sizeof(szBuffer), "6");
		DispatchKeyValue(iEntity, "endwidth", szBuffer);
		
		Config.GetString("material", szBuffer, sizeof(szBuffer));
		DispatchKeyValue(iEntity, "spritename", szBuffer);
		DispatchKeyValue(iEntity, "renderamt", "255");
		
		Config.GetString("color", szBuffer, sizeof(szBuffer));
		DispatchKeyValue(iEntity, "rendercolor", szBuffer);
		
		IntToString(Config.GetNum("rendermode", 1), szBuffer, sizeof(szBuffer));
		DispatchKeyValue(iEntity, "rendermode", szBuffer);
		
		// We give the name for our entities here
		Format(szBuffer, sizeof(szBuffer), "shop_trails_%d", iEntity);
		DispatchKeyValue(iEntity, "targetname", szBuffer);
		
		DispatchSpawn(iEntity);
		
		Config.GetVector("position", dest_vector);
		
		float or[3], ang[3], fForward[3], fRight[3], fUp[3];
		
		GetClientAbsOrigin(client, or);
		GetClientAbsAngles(client, ang);
		
		GetAngleVectors(ang, fForward, fRight, fUp);

		or[0] += fRight[0]*dest_vector[0] + fForward[0]*dest_vector[1] + fUp[0]*dest_vector[2];
		or[1] += fRight[1]*dest_vector[0] + fForward[1]*dest_vector[1] + fUp[1]*dest_vector[2];
		or[2] += fRight[2]*dest_vector[0] + fForward[2]*dest_vector[1] + fUp[2]*dest_vector[2];
		
		TeleportEntity(iEntity, or, NULL_VECTOR, NULL_VECTOR);
		
		SetVariantString("!activator");
		AcceptEntityInput(iEntity, "SetParent", client); 
		SetEntPropFloat(iEntity, Prop_Send, "m_flTextureRes", 0.05);
		SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);
		
		SDKHook(iEntity, SDKHook_SetTransmit, Hook_TrailShouldHide);
	}
	return true;
}

public Action Hook_TrailShouldHide(int entity, int client)
{
	static int iOwner;
	
	if(HideTrails[client])
		return Plugin_Handled;
	
	return (HideOppositeTeam && (iOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")) != -1 && Team[client] > 1 && Team[client] != Team[iOwner]) ? Plugin_Handled:Plugin_Continue;
}

void KillTrail(int client)
{
	if (Entity[client])
	{
		int iEntity = EntRefToEntIndex(Entity[client]);
		if(iEntity && IsValidEdict(iEntity))
		{
			RemoveEntity(iEntity);
		}
		
		Entity[client] = 0;
	}
}