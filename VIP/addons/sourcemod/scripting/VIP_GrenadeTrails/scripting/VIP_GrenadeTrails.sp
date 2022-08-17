#include <sourcemod>
#include <vip_core>
#include <sdktools>
#include <clientprefs>

#pragma newdecls required

static const char g_sFeature[] = "GrenadeTrails";

Handle 
	g_hCookie;
Menu 
	ColorsMenu;

bool 
    HideOppositeTeam,
    ClientIsVIP[MAXPLAYERS + 1];

int 
    m_hThrower,
	Sprite, 
    SpriteFadeLength,
	GrenadeColor[MAXPLAYERS + 1][4], 
	Item[MAXPLAYERS + 1] = {-1, ...};

float 
	SpriteLife, 
	SpriteStartWidth, 
	SpriteEndWidth;

char 
	SpriteModel[256];


public Plugin myinfo = 
{
	name = "[VIP] Grenade Trails [Edited]",
	author = "R1KO",
	version = "1.0.2"
};

public void OnPluginStart() 
{
	m_hThrower = FindSendPropInfo("CBaseGrenade", "m_hThrower");
	LoadTranslations("vip_grenade_trails.phrases");

	g_hCookie = RegClientCookie("VIP_GrenadeTrails", "", CookieAccess_Private);

	ColorsMenu = new Menu(Handler_ColorsMenu, MenuAction_Select|MenuAction_Cancel|MenuAction_Display|MenuAction_DisplayItem);
	ColorsMenu.ExitBackButton = true;
	
	char szBuffer[256];

	KeyValues hKeyValues = new KeyValues("GrenadeTrails");
	BuildPath(Path_SM, szBuffer, 256, "data/vip/modules/grenade_trails.ini");

	if (!hKeyValues.ImportFromFile(szBuffer))
	{
		SetFailState("Config file \"%s\" doesnt exists", szBuffer);
	}
	SpriteLife = hKeyValues.GetFloat("Life", 0.2);
	SpriteStartWidth = hKeyValues.GetFloat("StartWidth", 2.0);
	SpriteEndWidth = hKeyValues.GetFloat("EndWidth", 5.0);
	SpriteFadeLength = hKeyValues.GetNum("FadeLength", 5);

	hKeyValues.GetString("Material", SpriteModel, 256, "materials/sprites/laserbeam.vmt");
	
	if(!SpriteModel[0])
	{
		SetFailState("Can`t parse \"material\" value");
	}
	
	szBuffer[0] = 0;
	
	hKeyValues.Rewind();
	if(hKeyValues.JumpToKey("Colors") && hKeyValues.GotoFirstSubKey(false))
	{
		char szColor[16];
		do
		{
			hKeyValues.GetSectionName(szBuffer, 256);
			hKeyValues.GetString(NULL_STRING, szColor, 16);
			ColorsMenu.AddItem(szColor, szBuffer);
		}
		while (hKeyValues.GotoNextKey(false));
	}
	delete hKeyValues;

	if(!szBuffer[0])
    {
		ColorsMenu.AddItem("", "No availbale colors", ITEMDRAW_DISABLED);
    }

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(AreClientCookiesCached(i))
			{
				OnClientCookiesCached(i);
			}
			if(VIP_IsClientVIP(i))
			{
				VIP_OnVIPClientLoaded(i);
			}
		}
	}
}

public void OnMapStart()
{
	Sprite = PrecacheModel(SpriteModel);
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
	if(Item[iClient] != -1)
	{
		char szBuffer[64];
		ColorsMenu.GetItem(Item[iClient], "", 0, _, szBuffer, 64);
		FormatEx(szDisplay, iMaxLength, "%T [%s]", szFeature, iClient, szBuffer);
		return true;
	}
	
	return false;
}

public bool OnSelectItem(int iClient, const char[] sFeatureName)
{
	ColorsMenu.Display(iClient, 0);
	return false;
}

public int Handler_ColorsMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack) VIP_SendClientVIPMenu(iClient);
		}
        case MenuAction_Display:
        {
            char szTitle[128];
            FormatEx(szTitle, sizeof(szTitle), "%T", "Title", iClient);
            (view_as<Panel>(iItem)).SetTitle(szTitle);
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
				char szColor[16];
				hMenu.GetItem(iItem, szColor, 16);
				if(GetClientNadeColor(iClient, szColor))
				{
					Item[iClient] = iItem;
					SetClientCookie(iClient, g_hCookie, szColor);
				}
			}
			
			ColorsMenu.DisplayAt(iClient, hMenu.Selection, 0);
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
    ClientIsVIP[iClient] = false;
}

public void OnClientCookiesCached(int iClient)
{
    if(IsFakeClient(iClient))
        return;

    if(ClientIsVIP[iClient])
    {
        LoadClientSettings(iClient);
    }
}

public void VIP_OnVIPClientLoaded(int iClient)
{
    ClientIsVIP[iClient] = true;

    if(AreClientCookiesCached(iClient))
    {
        LoadClientSettings(iClient);
    }
}

void LoadClientSettings(int iClient)
{
    if(VIP_GetClientFeatureStatus(iClient, g_sFeature) != NO_ACCESS)
	{
		char szBuffer[16];
		GetClientCookie(iClient, g_hCookie, szBuffer, 16);
		if(!szBuffer[0] || ((Item[iClient] = GetTracerIndex(szBuffer)) != -1 && !GetClientNadeColor(iClient, szBuffer)))
		{
			Item[iClient] = -1;
		}
	}
}

bool GetClientNadeColor(int iClient, const char[] color)
{
	char szBuffers[4][4];
	if(ExplodeString(color, " ", szBuffers, 4, 4) == 4)
	{
		for(int i; i < 4; i++)
		{
			GrenadeColor[iClient][i] = StringToInt(szBuffers[i]);
		}
		return true;
	}
	return false;
}


int GetTracerIndex(const char[] color)
{
	char szColor[16];
	int iCount = ColorsMenu.ItemCount;
	for(int i; i < iCount; i++)
	{
		ColorsMenu.GetItem(i, szColor, 16);
		if(!strcmp(color, szColor, false))
		{
			return i;
		}
	}

	return -1;
}

public void OnEntityCreated(int iEntity, const char[] classname)
{
	if(!IsValidEntity(iEntity) || strlen(classname) < 20)
		return;
	
	switch(classname[0])
	{
		case 'h', 'f', 's':
		{
			if(classname[10] == 'p' || classname[13] == 'p')
			{
				RequestFrame(OnGrenadeSpawned, EntIndexToEntRef(iEntity));
			}
		}
	}
}

void OnGrenadeSpawned(int iEntity)
{
	if ((iEntity = EntRefToEntIndex(iEntity)) == INVALID_ENT_REFERENCE)
        return;

	int iClient = GetEntDataEnt2(iEntity, m_hThrower);
	if(0 < iClient <= MaxClients && Item[iClient] != -1)
	{
        TE_SetupBeamFollow(iEntity, Sprite, 0, SpriteLife, SpriteStartWidth, SpriteEndWidth, SpriteFadeLength, GrenadeColor[iClient]);
        int iCount, iTeam = GetClientTeam(iClient);
        int[] Clients = new int[MaxClients];
        for(int i = 1; i <= MaxClients; i++)
        {
            if(IsClientInGame(i) && !IsFakeClient(i) && (!HideOppositeTeam || GetClientTeam(i) == iTeam))
            {
                Clients[iCount++] = i;
            }
        }
        TE_Send(Clients, iCount);
	}
}