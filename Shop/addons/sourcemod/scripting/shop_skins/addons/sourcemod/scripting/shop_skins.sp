#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <shop>

#define PLUGIN_VERSION "2.1.3"

#define CATEGORY	"skins"

#pragma newdecls required

KeyValues Config;
ItemId ClientItem[MAXPLAYERS + 1] = {INVALID_ITEM, ...};

ConVar cvarTeamsToggle, cvarSetDelay;

int TeamsToggle;
float SetDelay;

public Plugin myinfo =
{
	name = "[Shop] Skins [Edited]",
	author = "FrozDark",
	description = "Adds ability to buy skins",
	url = "www.hlmod.ru"
}

public void OnPluginStart()
{
	HookEvent("player_spawn", OnPlayerFireEvent);
	HookEvent("player_team", OnPlayerFireEvent);
	cvarTeamsToggle = CreateConVar("shop_skins_team_toggle", "3", "1 = T, 2 = CT, 3 = T&CT");
	cvarTeamsToggle.AddChangeHook(OnConVarChange);
	TeamsToggle = cvarTeamsToggle.IntValue;
	cvarSetDelay = CreateConVar("shop_skins_set_delay", "0.3");
	cvarSetDelay.AddChangeHook(OnConVarChange);
	SetDelay = cvarSetDelay.FloatValue;
	AutoExecConfig(true, "skins", "shop");
	if (Shop_IsStarted())
	{
		Shop_Started();
	}
	else
	{
		Config = new KeyValues("Skins");
	}
}

public void OnPluginEnd()
{
	Shop_UnregisterMe();
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(cvar == cvarTeamsToggle)
	{
		TeamsToggle = cvar.IntValue;
	}
	else if(cvar == cvarSetDelay)
	{
		SetDelay = cvar.FloatValue;
		if(SetDelay)
		{
			
		}
	}
}

public void OnMapStart()
{
	Config.Rewind();
	if(Config.GotoFirstSubKey())
	{
		char szBuffer[PLATFORM_MAX_PATH];
		do
		{
			Config.GetString("ModelT", szBuffer, sizeof(szBuffer));
			if(szBuffer[0])
			{
				PrecacheModel(szBuffer, true);
			}
			Config.GetString("ModelCT", szBuffer, sizeof(szBuffer));
			if(szBuffer[0])
			{
				PrecacheModel(szBuffer, true);
			}
		}
		while(Config.GotoNextKey());
	}
}

public void OnClientDisconnect_Post(int client)
{
	ClientItem[client] = INVALID_ITEM;
}

public void Shop_Started()
{
	delete Config;

	CategoryId category_id = Shop_RegisterCategory(CATEGORY, "Скины", "");
	char szBuffer[PLATFORM_MAX_PATH];
	Shop_GetCfgFile(szBuffer, sizeof(szBuffer), "skins.txt");
	Config = new KeyValues("Skins");

	if (!Config.ImportFromFile(szBuffer))
	{
		ThrowError("\"%s\" not parsed", szBuffer);
	}
	
	char item[64], item_name[64], desc[64];
	if (Config.GotoFirstSubKey())
	{
		do
		{
			if(!Config.GetSectionName(item, sizeof(item)))
				continue;
			
			Config.GetString("ModelT", szBuffer, sizeof(szBuffer));
			bool result = false;
			if (szBuffer[0])
			{
				PrecacheModel(szBuffer);
				result = true;
			}
			
			
			Config.GetString("ModelCT", szBuffer, sizeof(szBuffer));
			if (szBuffer[0])
			{
				PrecacheModel(szBuffer, true);
				result = true;
			}

			if (!result)
			{
				continue;
			}
			
			if (Shop_StartItem(category_id, item))
			{
				Config.GetString("name", item_name, sizeof(item_name), item);
				Config.GetString("description", desc, sizeof(desc));
				Shop_SetInfo(item_name, desc, Config.GetNum("price", 5000), Config.GetNum("sell_price", 2500), Item_Togglable, Config.GetNum("duration", 86400));
				Shop_SetCallbacks(_, OnEquipItem);
				
				if (Config.JumpToKey("Attributes", false))
				{
					Shop_KvCopySubKeysCustomInfo(Config);
					Config.GoBack();
				}
				
				Shop_EndItem();
			}
		}
		while (Config.GotoNextKey());
	}
}

public ShopAction OnEquipItem(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, bool isOn, bool elapsed)
{
	if (isOn || elapsed)
	{
		if(IsPlayerAlive(client) && IsValidClientTeam(client))
		{
			CS_UpdateClientModel(client);
		}
		
		ClientItem[client] = INVALID_ITEM;
		
		return Shop_UseOff;
	}
	
	Shop_ToggleClientCategoryOff(client, category_id);
	
	ClientItem[client] = item_id;
	
	ProcessPlayer(client);
	
	return Shop_UseOn;
}

public void OnPlayerFireEvent(Event event, const char[] name, bool dontBroadcast)
{
	ProcessPlayer(GetClientOfUserId(GetEventInt(event, "userid")));
}

void ProcessPlayer(int client)
{
	if (!client || ClientItem[client] == INVALID_ITEM || IsFakeClient(client) || !IsPlayerAlive(client) || !IsValidClientTeam(client))
	{
		return;
	}
	
	CreateTimer(0.0, Timer_SetClientModel, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_SetClientModel(Handle timer, any client)
{
	if(ClientItem[client] == INVALID_ITEM)
		return Plugin_Continue;
		
	char szBuffer[PLATFORM_MAX_PATH];
	
	Shop_GetItemById(ClientItem[client], szBuffer, sizeof(szBuffer));
	
	Config.Rewind();
	if (!Config.JumpToKey(szBuffer, false))
	{
		LogError("It seems that registered item \"%s\" not exists in the settings", szBuffer);
		return Plugin_Continue;
	}
	
	switch (GetClientTeam(client))
	{
		case 2:
		{
			Config.GetString("ModelT", szBuffer, sizeof(szBuffer));
		}
		case 3:
		{
			Config.GetString("ModelCT", szBuffer, sizeof(szBuffer));
		}
		default:
		{
			szBuffer[0] = '\0';
		}
	}
	if (szBuffer[0])
	{
		SetEntityModel(client, szBuffer);
		
		Config.GetString("color", szBuffer, sizeof(szBuffer));
		if (strlen(szBuffer) > 7)
		{
			int color[4];
			Config.GetColor4("color", color);
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
		}
	}
	return Plugin_Continue;
}

bool IsValidClientTeam(int iClient)
{
	if(!TeamsToggle)
		return false;
		
	int iTeam = GetClientTeam(iClient);
	return ((iTeam == 2 && TeamsToggle & 1) || (iTeam == 3 && TeamsToggle & 2));
}