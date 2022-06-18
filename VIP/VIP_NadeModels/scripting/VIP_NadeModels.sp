#define SM_BOTOX 1

#include <sourcemod>
#include <vip_core>
#include <sdktools>
#include <clientprefs>

#pragma newdecls required

static const char g_sFeature[] = "NadeModels";


Handle 
	g_hCookie;
Menu 
	ModelsMenu;
int 
	Item[MAXPLAYERS + 1] = {-1, ...};

public Plugin myinfo = 
{
	name = "[VIP] Nade Models [Edited]",
	author = "R1KO",
	version = "1.1"
};

public void OnPluginStart() 
{
	LoadTranslations("common.phrases");

	g_hCookie = RegClientCookie("VIP_HeModel", "", CookieAccess_Private);

	ModelsMenu = new Menu(Handler_ModelsMenu, MenuAction_Select|MenuAction_Cancel|MenuAction_DisplayItem);
	ModelsMenu.SetTitle("Модели гранат");
	ModelsMenu.ExitBackButton = true;
	
	char szBuffer[256];

	KeyValues hKeyValues = new KeyValues("NadeModels");
	BuildPath(Path_SM, szBuffer, 256, "data/vip/modules/nade_models.ini");

	if (!hKeyValues.ImportFromFile(szBuffer) || !hKeyValues.GotoFirstSubKey(false))
	{
		SetFailState("Не удалось открыть файл \"%s\"", szBuffer);
	}
	
	char szBuffer2[256];
	do
	{
		hKeyValues.GetSectionName(szBuffer, 256);
		hKeyValues.GetString(NULL_STRING, szBuffer2, 256);
		ModelsMenu.AddItem(szBuffer2, szBuffer);
	}
	while (hKeyValues.GotoNextKey(false));
	delete hKeyValues;

	if(!szBuffer[0])
    {
		ModelsMenu.AddItem("", "No availbale models", ITEMDRAW_DISABLED);
    }

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			
			if(AreClientCookiesCached(i) && VIP_IsClientVIP(i))
			{
				VIP_OnVIPClientLoaded(i);
			}
		}
	}
}

public void OnMapStart()
{
	char szBuffer[256];
	int iItems = ModelsMenu.ItemCount;
	
	for(int i; i < iItems; i++)
	{
		ModelsMenu.GetItem(i, szBuffer, 256);
		PrecacheModel(szBuffer, true);
	}
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, BOOL, SELECTABLE, OnSelectItem, OnDisplayItem);
}

public void OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
}

public bool OnDisplayItem(int iClient, const char[] szFeature, char[] szDisplay, int iMaxLength)
{
	if(IsValidClientItem(iClient))
	{
		char szBuffer[64];
		ModelsMenu.GetItem(Item[iClient], "", 0, _, szBuffer, 64);
		FormatEx(szDisplay, iMaxLength, "%T [%s]", szFeature, iClient, szBuffer);
		return true;
	}
	
	return false;
}

public bool OnSelectItem(int iClient, const char[] sFeatureName)
{
	ModelsMenu.Display(iClient, 0);
	return false;
}

public int Handler_ModelsMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack) VIP_SendClientVIPMenu(iClient);
		}
		case MenuAction_Select:
		{
			if(iItem == Item[iClient])
			{
				Item[iClient] = -1;
				SetClientCookie(iClient, g_hCookie, "");
			}
			else
			{
				Item[iClient] = iItem;
				
				char szBuffer[32];
				hMenu.GetItem(iItem, "", 0, _, szBuffer, 32);
				SetClientCookie(iClient, g_hCookie, szBuffer);
			}
			
			ModelsMenu.DisplayAt(iClient, hMenu.Selection, 0);
		}
		case MenuAction_DisplayItem:
		{
			if(Item[iClient] == iItem)
			{
				char szBuffer[128];
				hMenu.GetItem(iItem, "", 0, _, szBuffer, 128);
				Format(szBuffer, 128, "%s [X]", szBuffer);
				return RedrawMenuItem(szBuffer);
			}
		}
	}

	return 0;
}

public void OnClientDisconnect(int iClient)
{
	Item[iClient] = -1;
}

public void VIP_OnVIPClientLoaded(int iClient)
{
	if(VIP_GetClientFeatureStatus(iClient, g_sFeature) != NO_ACCESS && !IsValidClientItem(iClient))
	{
		char szBuffer[32];
		GetClientCookie(iClient, g_hCookie, szBuffer, 32);
		if(szBuffer[0])
		{
			Item[iClient] = GetModelIndex(szBuffer);
		}
	}
}

int GetModelIndex(const char[] name)
{
	char szBuffer[32];
	int iCount = ModelsMenu.ItemCount;
	for(int i; i < iCount; i++)
	{
		ModelsMenu.GetItem(i, "", 0, _, szBuffer, 16);
		if(!strcmp(name, szBuffer, false))
		{
			return i;
		}
	}

	return -1;
}

#if SM_BOTOX 1
public void OnEntitySpawned(int entity, const char[] classname)
{
	if(strlen(classname) > 10 && classname[0] == 'h' && !strncmp(classname[10], "proj", 4, true))
	{
		int iClient = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(0 < iClient <= MaxClients && IsValidClientItem(iClient))
		{
			char szBuffer[256];
			ModelsMenu.GetItem(Item[iClient], szBuffer, 256);
			SetEntityModel(entity, szBuffer);
		}	
		
	}
}
#else
public void OnEntityCreated(int entity, const char[] classname)
{
	if(IsValidEntity(entity) && strlen(classname) > 10 && classname[0] == 'h' && !strncmp(classname[10], "proj", 4, true))
	{
		RequestFrame(OnEntityCreatedNextTick, EntIndexToEntRef(entity));
	}
}

stock void OnEntityCreatedNextTick(int entity)
{
	if ((entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE && entity && IsValidEntity(entity))
	{
		int iClient = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(0 < iClient <= MaxClients && IsValidClientItem(iClient))
		{
			char szBuffer[256];
			ModelsMenu.GetItem(Item[iClient], szBuffer, 256);
			SetEntityModel(entity, szBuffer);
		}	
	}
}

#endif


bool IsValidClientItem(int iClient)
{
	return (Item[iClient] != -1 && Item[iClient] < ModelsMenu.ItemCount);
}