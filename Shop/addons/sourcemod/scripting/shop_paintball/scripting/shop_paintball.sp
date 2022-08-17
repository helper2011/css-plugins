#include <sourcemod>
#include <sdktools>
#include <shop>

#pragma newdecls required

const int MAX_DECALS = 10;

static const char Category[] = "stuff";
static const char Item[] = "paintball";

ItemId 
	id = INVALID_ITEM;
	
int
	DecalIndex[MAX_DECALS],
	Decals = -1,
	RussianLanguageId;

bool 
	Enable[MAXPLAYERS + 1];

ConVar
	Price,
	Sell,
	Duration;
	
char
	Decal[MAX_DECALS][256];

public Plugin myinfo =
{
	name			= "[Shop] Paintball (Edited)",
	author			= "FrozDark (HLModders LLC)",
	description 	= "Paintball component for Shop",
	version			= "2.1.1",
	url			 	= "www.hlmod.ru"
};

public void OnPluginStart()
{
	if((RussianLanguageId = GetLanguageByCode("ru")) == -1)
	{
		SetFailState("Cant find russian language (see languages.cfg)");
	}
	LoadDecals();
	
	Price = CreateConVar("sm_shop_paintball_price", "500", "Price for the paintball.");
	Sell = CreateConVar("sm_shop_paintball_sellprice", "250", "Sell price for the paintball. -1 to make unsaleable");
	Duration = CreateConVar("sm_shop_paintball_duration", "86400", "The paintball duration. 0 to make it forever");
	Price.AddChangeHook(OnConVarChange);
	Sell.AddChangeHook(OnConVarChange);
	Duration.AddChangeHook(OnConVarChange);
	
	LoadTranslations("shop_paintball.phrases");
	AutoExecConfig(true, "shop_paintball", "shop");
	HookEvent("bullet_impact", Event_BulletImpact);	
	
	if (Shop_IsStarted()) 
	{
		Shop_Started();
	}
}

public void OnPluginEnd()
{
	Shop_UnregisterMe();
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(id == INVALID_ITEM)
		return;
		
	int iNewValue = StringToInt(newValue);
	if (cvar == Price)
	{
		Shop_SetItemPrice(id, iNewValue);
	}
	else if (cvar == Sell)
	{
		Shop_SetItemSellPrice(id, iNewValue);
	}
	else if (cvar == Duration)
	{
		Shop_SetItemValue(id, iNewValue);
	}
}


public void Shop_Started()
{
	CategoryId category_id = Shop_RegisterCategory(Category, "Stuff", "");
	if (Shop_StartItem(category_id, Item))
	{
		Shop_SetInfo("Paintball", "", Price.IntValue, Sell.IntValue, Item_Togglable, Duration.IntValue);
		Shop_SetCallbacks(OnItemRegistered, OnPaintballUsed, _, OnDisplay);
		Shop_EndItem();
	}
}

public void OnItemRegistered(CategoryId category_id, const char[] category, const char[] item, ItemId item_id)
{
	id = item_id;
}

public bool OnDisplay(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ShopMenu menu, bool &disabled, const char[] name, char[] buffer, int maxlen)
{
	strcopy(buffer, maxlen, (GetClientLanguage(client) == RussianLanguageId ? "Пэйнтбол":"Paintball"));
	return true;
}

public void OnMapStart()
{
	for(int i; i <= Decals; i++)
	{
		DecalIndex[i] = PrecacheDecal(Decal[i][10]);
		AddFileToDownloadsTable(Decal[i]);
	}
}

public void OnClientDisconnect(int client)
{
	Enable[client] = false;
}

public ShopAction OnPaintballUsed(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, bool isOn, bool elapsed)
{
	Enable[client] = !isOn;
	if (isOn || elapsed)
	{
		return Shop_UseOff;
	}
	return Shop_UseOn;
}

public void Event_BulletImpact(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	static int client;
	static float pos[3];
	client = GetClientOfUserId(hEvent.GetInt("userid"));
	
 	if (Enable[client])
	{
		pos[0] = hEvent.GetFloat("x");
		pos[1] = hEvent.GetFloat("y");
		pos[2] = hEvent.GetFloat("z");
		TE_Start("World Decal");
		TE_WriteVector("m_vecOrigin", pos);
		TE_WriteNum("m_nIndex", DecalIndex[GetRandomInt(0, Decals)]);
		TE_SendToAll();
	}
}

void LoadDecals()
{
	char buffer[256];
	Shop_GetCfgFile(buffer, sizeof(buffer), "paintball.txt");
	
	File hFile = OpenFile(buffer, "r");
	
	if (hFile)
	{
		while (!hFile.EndOfFile() && Decals < MAX_DECALS)
		{
			if (!hFile.ReadLine(buffer, 256) || TrimString(buffer) <= 0 || strlen(buffer) < 10)
				continue;
			

			Decal[++Decals] = buffer;
		}
		delete hFile;
	}
	else
	{
		SetFailState("File \"%s\" doesnt exists", buffer);
	}
	
	if(Decals == -1)
	{
		SetFailState("No decals");
	}
}