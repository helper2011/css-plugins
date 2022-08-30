#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <shop>
#include <helco>

#define PLUGIN_VERSION	"2.1.2"

new ItemId:id;

#define MEDIC_SOUND "items/smallmedkit1.wav"
#define CATEGORY	"stuff"
#define MEDKIT		"medkit"

#define ADD	0
#define SET	1

new Handle:g_hHealth, g_iHealth,
	Handle:g_hMaxHealth, g_iMaxHealth,
	Handle:g_hRoundUse, g_iRoundUse,
	Handle:g_hPrice, g_iPrice;
new Handle:g_hSellPrice, g_iSellPrice;

new g_iMedkitMode = SET;

new iRoundUsed[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "[Shop] Medkit",
	author = "FrozDark (HLModders LLC)",
	description = "Medkit component for Shop",
	version = PLUGIN_VERSION,
	url = "http://www.hlmod.ru/"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("GetUserMessageType");
	return APLRes_Success;
}

public OnPluginStart()
{
	g_hHealth = CreateConVar("sm_shop_medkit_health", "100", "Medkit health. Raw numbers just set health to that value and + adds");
	g_iHealth = GetConVarInt(g_hHealth);
	HookConVarChange(g_hHealth, OnConVarChange);
	
	g_hMaxHealth = CreateConVar("sm_shop_medkit_max_health", "100", "Max amount of health a player can hold", 0, true, 0.0);
	g_iMaxHealth = GetConVarInt(g_hMaxHealth);
	HookConVarChange(g_hMaxHealth, OnConVarChange);
	
	g_hRoundUse = CreateConVar("sm_shop_medkit_per_round", "1", "How many medkits available per round.");
	g_iRoundUse = GetConVarInt(g_hRoundUse);
	HookConVarChange(g_hRoundUse, OnConVarChange);
	
	g_hPrice = CreateConVar("sm_shop_medkit_price", "25", "The price of the medkit.");
	g_iPrice = GetConVarInt(g_hPrice);
	HookConVarChange(g_hPrice, OnConVarChange);
	
	g_hSellPrice = CreateConVar("sm_shop_medkit_sellprice", "5", "Sell price for the medkit. -1 to make unsaleable");
	g_iSellPrice = GetConVarInt(g_hSellPrice);
	HookConVarChange(g_hSellPrice, OnConVarChange);
	
	AutoExecConfig(true, "shop_medkit", "shop");
	
	RegConsoleCmd("sm_medic", Command_Medic);
	RegConsoleCmd("sm_medkit", Command_Medic);
	
	LoadTranslations("shop_medkit.phrases.txt");
	
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	
	if (Shop_IsStarted()) Shop_Started();
}

public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_hHealth)
	{
		g_iHealth = StringToInt(newValue);
		if (newValue[0] == '+')
		{
			g_iMedkitMode = ADD;
		}
		else
		{
			g_iMedkitMode = SET;
		}
	}
	else if (convar == g_hMaxHealth)
	{
		g_iMaxHealth = StringToInt(newValue);
	}
	else if (convar == g_hRoundUse)
	{
		g_iRoundUse = StringToInt(newValue);
	}
	else if (convar == g_hPrice)
	{
		g_iPrice = StringToInt(newValue);
		if (id != INVALID_ITEM)
		{
			Shop_SetItemPrice(id, g_iPrice);
		}
	}
	else if (convar == g_hSellPrice)
	{
		g_iSellPrice = StringToInt(newValue);
		if (id != INVALID_ITEM)
		{
			Shop_SetItemSellPrice(id, g_iSellPrice);
		}
	}
}

public OnRoundStart(Handle:event, const String:name[], bool:donBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		iRoundUsed[i] = 0;
	}
}

public Action:Command_Medic(client, args)
{
	if (!client)
	{
		return Plugin_Continue;
	}
	
	if (!Shop_UseClientItem(client, id))
	{
		PrintToChat2(client, "%t", "NoMedkit");
	}
	
	return Plugin_Handled;
}

public OnMapStart()
{
	PrecacheSound(MEDIC_SOUND, true);
}

public OnPluginEnd()
{
	Shop_UnregisterMe();
}

public Shop_Started()
{
	new CategoryId:category_id = Shop_RegisterCategory(CATEGORY, "Stuff", "", OnCategoryDisplay, OnCategoryDescription);
	if (Shop_StartItem(category_id, MEDKIT))
	{
		Shop_SetInfo("Medkit", "", g_iPrice, g_iSellPrice, Item_Finite);
		Shop_SetCallbacks(OnItemRegistered, OnMedkitChoose, _, OnDisplay, OnDescription, _, _);
		Shop_EndItem();
	}
}

public OnItemRegistered(CategoryId:category_id, const String:category[], const String:item[], ItemId:item_id)
{
	id = item_id;
}

public bool:OnCategoryDisplay(int client, CategoryId category_id, const char[] category, const char[] name, char[] buffer, int maxlen, ShopMenu menu)
{
	FormatEx(buffer, maxlen, "%T", "display", client);
	return true;
}

public bool:OnCategoryDescription (int client, CategoryId category_id, const char[] category, const char[] description, char[] buffer, int maxlen, ShopMenu menu)
{
	FormatEx(buffer, maxlen, "%T", "description", client);
	return true;
}

public bool:OnDisplay(client, CategoryId:category_id, const String:category[], ItemId:item_id, const String:item[], ShopMenu:menu, &bool:disabled, const String:name[], String:buffer[], maxlen)
{
	FormatEx(buffer, maxlen, "%T", "medkit", client);
	return true;
}

public bool:OnDescription(client, CategoryId:category_id, const String:category[], ItemId:item_id, const String:item[], ShopMenu:menu, const String:description[], String:buffer[], maxlen)
{
	FormatEx(buffer, maxlen, "%T", "medkit_description", client);
	return true;
}

public ShopAction:OnMedkitChoose(client, CategoryId:category_id, const String:category[], ItemId:item_id, const String:item[])
{
	if (g_iRoundUse > 0 && iRoundUsed[client] >= g_iRoundUse)
	{
		PrintToChat2(client, "%t", "RoundUsed", g_iRoundUse);
		return Shop_Raw;
	}
	if (IsPlayerAlive(client))
	{
		new health = GetClientHealth(client);
		if (health < g_iMaxHealth)
		{
			if (g_iMedkitMode == ADD)
			{
				health += g_iHealth;
			}
			else
			{
				health = g_iHealth;
			}
			if (health > g_iMaxHealth)
			{
				health = g_iMaxHealth;
			}
			
			SetEntityHealth(client, health);
			PrintToChat2(client, "%t", "UsedMedkit");
			EmitSoundToAll(MEDIC_SOUND, client);
			iRoundUsed[client]++;
			
			return Shop_UseOn;
		}
		else
		{
			PrintToChat2(client, "%t", "EnoughHealth");
		}
	}
	else
	{
		PrintToChat2(client, "%t", "MustAlive");
	}
	return Shop_Raw;
}