#include <sourcemod>
#include <vip_core>
#include <sdktools>
#include <clientprefs>

#pragma newdecls required

static const char g_sFeature[] = "Tracers";


Handle 
	g_hCookie[2];
Menu 
	ColorsMenu;
bool 
	ClientIsVIP[MAXPLAYERS + 1],
	Hide[MAXPLAYERS + 1];
int 
	Sprite, 
	TracerColor[MAXPLAYERS + 1][4], 
	Item[MAXPLAYERS + 1] = {-1, ...};

float 
	SpriteLife, 
	SpriteStartWidth, 
	SpriteEndWidth, 
	SpriteAmplitude;

char 
	SpriteModel[256];


public Plugin myinfo = 
{
	name = "[VIP] Tracers [Edited]",
	author = "R1KO",
	version = "1.1"
};

public void OnPluginStart() 
{
	LoadTranslations("vip_tracers.phrases");
	HookEvent("bullet_impact",	Event_BulletImpact);

	g_hCookie[0] = RegClientCookie("VIP_Tracers", "", CookieAccess_Private);
	g_hCookie[1] = RegClientCookie("VIP_TracersHide", "", CookieAccess_Private);

	ColorsMenu = new Menu(Handler_ColorsMenu, MenuAction_Select|MenuAction_Cancel|MenuAction_Display|MenuAction_DisplayItem);
	ColorsMenu.ExitBackButton = true;
	
	char szBuffer[256];

	KeyValues hKeyValues = new KeyValues("Tracers");
	BuildPath(Path_SM, szBuffer, 256, "data/vip/modules/tracers.ini");

	if (!hKeyValues.ImportFromFile(szBuffer))
	{
		SetFailState("Не удалось открыть файл \"%s\"", szBuffer);
	}
	SpriteLife = hKeyValues.GetFloat("Life", 0.2);
	SpriteStartWidth = hKeyValues.GetFloat("StartWidth", 2.0);
	SpriteEndWidth = hKeyValues.GetFloat("EndWidth", 2.0);
	SpriteAmplitude = hKeyValues.GetFloat("Amplitude", 0.0);

	hKeyValues.GetString("Material", SpriteModel, 256, "materials/sprites/laserbeam.vmt");
	
	if(!SpriteModel[0])
	{
		SetFailState("Не удалось получить значение параметра \"material\"");
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
	SetCookieMenuItem(TracerHideMenuHandler, 0, "Hide tracers");
	
	RegConsoleCmd("sm_tracers", Command_TracersMenu);
	RegConsoleCmd("sm_hidetracers", Command_HideTracersMenu);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
			
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

public void TracerHideMenuHandler(int iClient, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlen, "%T: [%s]", "Hide Tracers", iClient, Hide[iClient] ? "✔":"×");
		}
		case CookieMenuAction_SelectOption:
		{
			ToggleClientHideTracers(iClient);
			ShowCookieMenu(iClient);
		}
	}
}

public Action Command_TracersMenu(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient) && VIP_GetClientFeatureStatus(iClient, g_sFeature) != NO_ACCESS)
	{
		ColorsMenu.Display(iClient, 0);
	}
	
	return Plugin_Handled;
}

public Action Command_HideTracersMenu(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient))
	{
		ToggleClientHideTracers(iClient);
	}
	
	return Plugin_Handled;
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
				SetClientCookie(iClient, g_hCookie[0], "");
			}
			else
			{
				char szColor[16];
				hMenu.GetItem(iItem, szColor, 16);
				if(GetClientTracerColor(iClient, szColor))
				{
					Item[iClient] = iItem;
					SetClientCookie(iClient, g_hCookie[0], szColor);
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

public void OnClientPutInServer(int iClient)
{
	if(IsFakeClient(iClient))
	{
		Hide[iClient] = true;
	}
}

public void OnClientCookiesCached(int iClient)
{
	if(IsFakeClient(iClient))
		return;
		
	char szBuffer[16];
	GetClientCookie(iClient, g_hCookie[1], szBuffer, 16);
	Hide[iClient] = szBuffer[0] ? view_as<bool>(StringToInt(szBuffer)):false;

	if(ClientIsVIP[iClient])
	{
		LoadClientVIPSettings(iClient);
	}
}

public void OnClientDisconnect(int iClient)
{
	Item[iClient] = -1;
	Hide[iClient] = false;
	ClientIsVIP[iClient] = false;
}

public void VIP_OnVIPClientLoaded(int iClient)
{
	ClientIsVIP[iClient] = true;
	if(AreClientCookiesCached(iClient))
	{
		LoadClientVIPSettings(iClient);
	}
}

void LoadClientVIPSettings(int iClient)
{
	if(VIP_GetClientFeatureStatus(iClient, g_sFeature) != NO_ACCESS)
	{
		char szBuffer[16];
		GetClientCookie(iClient, g_hCookie[0], szBuffer, 16);
		if(!szBuffer[0] || ((Item[iClient] = GetTracerIndex(szBuffer)) != -1 && !GetClientTracerColor(iClient, szBuffer)))
		{
			Item[iClient] = -1;
		}
	}
}

bool GetClientTracerColor(int iClient, const char[] color)
{
	char szBuffers[4][4];
	if(ExplodeString(color, " ", szBuffers, 4, 4) == 4)
	{
		for(int i; i < 4; i++)
		{
			TracerColor[iClient][i] = StringToInt(szBuffers[i]);
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

public void Event_BulletImpact(Event hEvent, const char[] eventName, bool bDontBroadcast)
{
	static int iClient;
	static float ClientOrigin[3];
	static float StartPos[3];
	static float EndPos[3];
	static float Percentage;
	iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(iClient && !Hide[iClient] && Item[iClient] != -1)
	{
		int Players;
		int[] Player = new int[MaxClients];
		
		GetClientEyePosition(iClient, ClientOrigin);
		
		EndPos[0] = hEvent.GetFloat("x");
		EndPos[1] = hEvent.GetFloat("y");
		EndPos[2] = hEvent.GetFloat("z");
		
		Percentage = 0.4 / (GetVectorDistance(ClientOrigin, EndPos) / 100.0);

		StartPos[0] = ClientOrigin[0] + ((EndPos[0] - ClientOrigin[0]) * Percentage); 
		StartPos[1] = ClientOrigin[1] + ((EndPos[1] - ClientOrigin[1]) * Percentage) -0.08; 
		StartPos[2] = ClientOrigin[2] + ((EndPos[2] - ClientOrigin[2]) * Percentage);

		TE_SetupBeamPoints(StartPos, EndPos, Sprite, 0, 0, 0, SpriteLife, SpriteStartWidth, SpriteEndWidth, 1, SpriteAmplitude, TracerColor[iClient], 0);
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !Hide[i])
			{
				Player[Players++] = i;
			}
		}

		TE_Send(Player, Players);
	}
}

void SetClientCookieBool(int iClient, bool bToggle)
{
	SetClientCookie(iClient, g_hCookie[1], bToggle ? "1":"0");
}

void ToggleClientHideTracers(int iClient)
{
	Hide[iClient] = !Hide[iClient];
	SetClientCookieBool(iClient, Hide[iClient]);
	
	SetGlobalTransTarget(iClient);
	PrintHintText(iClient, "%t: [%s]", "Hide Tracers", Hide[iClient] ? "✔":"×");
}