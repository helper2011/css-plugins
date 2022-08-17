#include <sdkhooks>
#include <vip_core>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#include <leader>
#define REQUIRE_PLUGIN

Menu HideMenu;
Handle g_hCookie;
int Team[MAXPLAYERS + 1];
bool Admin[MAXPLAYERS + 1], VIP[MAXPLAYERS + 1], Hide[MAXPLAYERS + 1][5], Message[MAXPLAYERS + 1], Save[MAXPLAYERS + 1], Leader[MAXPLAYERS + 1], LeaderIsLoaded;

static const char g_sFeature[] = "Hide";

enum
{
	HIDE_PLAYERS,
	HIDE_VIPS,
	HIDE_ADMINS,
	HIDE_LEADER,
	HIDE_TOGGLE
}

public Plugin myinfo = 
{
	name		= "[VIP] Hide",
	version		= "1.0",
	description	= "Selectively hiding players",
	author		= "hEl"
}

public void OnPluginStart()
{
	LoadTranslations("vip_hide.phrases");
	HideMenu = new Menu(MenuHandler, MenuAction_Cancel|MenuAction_Select|MenuAction_Display|MenuAction_DisplayItem);
	HideMenu.AddItem("", "Players");
	HideMenu.AddItem("", "Vips");
	HideMenu.AddItem("", "Admins");
	HideMenu.AddItem("", "Leader");

	HideMenu.ExitBackButton = true;
	
	g_hCookie = RegClientCookie("VIP_Hide", "", CookieAccess_Private);
	HookEvent("player_team", OnPlayerTeam);
	
	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
	
	RegConsoleCmd("sm_hide", Hide_Command);
	RegConsoleCmd("sm_unhide", Hide_Command);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			Team[i] = GetClientTeam(i);
			OnClientPutInServer(i);
			OnClientPostAdminCheck(i);
			if(VIP_IsClientVIP(i))
			{
				VIP_OnVIPClientLoaded(i);
			}
		}
	}
	
	LeaderIsLoaded = LibraryExists("Leader");
}

public void OnLibraryAdded(const char[] name)
{
	if(strcmp(name, "leader", false) == 0)
	{
		LeaderIsLoaded = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if(strcmp(name, "leader", false) == 0)
	{
		LeaderIsLoaded = false;
	}
}

public void Leader_OnClientActionLeader(int iClient, bool bBecame)
{
	Leader[iClient] = bBecame;
}

public OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && Save[i])
		{
			OnClientDisconnect(i);
		}
	}
}

public Action Hide_Command(int iClient, int iArgs)
{
	if(!iClient || IsFakeClient(iClient) || !VIP[iClient] || iArgs > 1 || VIP_GetClientFeatureStatus(iClient, g_sFeature) > ENABLED)
		return Plugin_Handled;

	if(iArgs == 1)
	{
		char szBuffer[32];
		GetCmdArg(0, szBuffer, 32);
		bool bToggle = (szBuffer[3] == 'h');
		GetCmdArg(1, szBuffer, 32);
		
		if(szBuffer[0] != '@')
		{
			return Plugin_Handled;
		}
		if(strcmp(szBuffer[1], "all", false) == 0)
		{
			for(int i; i < HIDE_TOGGLE; i++)
			{
				Hide[iClient][i] = bToggle;
			}
		}
		else if(strcmp(szBuffer[1], "players", false) == 0)
		{
			Hide[iClient][HIDE_PLAYERS] = bToggle;
		}
		else if(strcmp(szBuffer[1], "vips", false) == 0)
		{
			Hide[iClient][HIDE_VIPS] = bToggle;
		}
		else if(strcmp(szBuffer[1], "leader", false) == 0)
		{
			Hide[iClient][HIDE_LEADER] = bToggle;
		}
		CheckClientHide(iClient);
	}
	else
	{
		HideMenu.Display(iClient, 0);
	}

	return Plugin_Handled;
}


public void VIP_OnVIPLoaded() 
{
	VIP_RegisterFeature(g_sFeature, BOOL, SELECTABLE, ItemSelect);
}

public Action ItemSelect(int iClient, const char[] szFeature, VIP_ToggleState eOldStatus, VIP_ToggleState &eNewStatus)
{
	HideMenu.Display(iClient, 0);
}

public int MenuHandler(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			Save[iClient] = true;
			Hide[iClient][iItem] = !Hide[iClient][iItem];
			CheckClientHide(iClient);
			HideMenu.Display(iClient, 0);
		}
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack)
			{
				VIP_SendClientVIPMenu(iClient);
			}
		}
		case MenuAction_Display:
		{
			char szBuffer[256];
			FormatEx(szBuffer, 256, "%T", "Title", iClient);
			(view_as<Panel>(iItem)).SetTitle(szBuffer);
		}
		case MenuAction_DisplayItem:
		{
			char szBuffer[256];
			hMenu.GetItem(iItem, "", 0, _, szBuffer, 256);
			Format(szBuffer, 256, "%T [%s]", szBuffer, iClient, Hide[iClient][iItem] ? "✔":"×");
			return RedrawMenuItem(szBuffer);
		}

	}
	return 0;
}

public void VIP_OnVIPClientLoaded(int iClient)
{
	VIP[iClient] = true;
	
	if(VIP_GetClientFeatureStatus(iClient, g_sFeature) <= ENABLED && AreClientCookiesCached(iClient))
	{
		GetClientHideSettings(iClient);
	}
}

public void OnClientCookiesCached(int iClient)
{
	if(IsClientInGame(iClient) && VIP[iClient] && VIP_GetClientFeatureStatus(iClient, g_sFeature) <= ENABLED)
	{
		GetClientHideSettings(iClient);
	}
}

void GetClientHideSettings(int iClient)
{
	char szBuffer[64];
	GetClientCookie(iClient, g_hCookie, szBuffer, 64);
	
	if(!szBuffer[0])
		return;
	
	for(int i = 3; i >= 0; i--)
	{
		Hide[iClient][i] = view_as<bool>(StringToInt(szBuffer[i]));
		szBuffer[i] = 0;
	
	}
	
	CheckClientHide(iClient);
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_SetTransmit, SetTransmit);
}

public void OnClientPostAdminCheck(int iClient)
{
	int iFlags = GetUserFlagBits(iClient);
	Admin[iClient] = view_as<bool>(iFlags & ADMFLAG_GENERIC || iFlags & ADMFLAG_ROOT);
}


public void OnClientDisconnect(int iClient)
{
	if(Save[iClient])
	{
		Save[iClient] = false;
		char szBuffer[64];
		FormatEx(szBuffer, 64, "%i%i%i%i",	view_as<int>(Hide[iClient][HIDE_PLAYERS]),
											view_as<int>(Hide[iClient][HIDE_VIPS]),
											view_as<int>(Hide[iClient][HIDE_ADMINS]),
											view_as<int>(Hide[iClient][HIDE_LEADER]));
		
		SetClientCookie(iClient, g_hCookie, szBuffer);
	}
	
	VIP[iClient] =
	Admin[iClient] =
	Leader[iClient] =
	Message[iClient] =
	
	Hide[iClient][HIDE_PLAYERS] =
	Hide[iClient][HIDE_VIPS] =
	Hide[iClient][HIDE_ADMINS] =
	Hide[iClient][HIDE_LEADER] =
	Hide[iClient][HIDE_TOGGLE] = false;
}

public Action SetTransmit(int iEntity, int iClient)
{
	if(0 < iEntity <= MaxClients && iEntity != iClient && Hide[iClient][HIDE_TOGGLE] && Team[iClient] > 1 && Team[iClient] == Team[iEntity])
	{
		return (Leader[iEntity]) ? ((LeaderIsLoaded && Hide[iClient][HIDE_LEADER]) ? Plugin_Handled:Plugin_Continue):Admin[iEntity] ? (Hide[iClient][HIDE_ADMINS] ? Plugin_Handled:Plugin_Continue):VIP[iEntity] ? (Hide[iClient][HIDE_VIPS] ? Plugin_Handled:Plugin_Continue):Hide[iClient][HIDE_PLAYERS] ? Plugin_Handled:Plugin_Continue;
	}
	return Plugin_Continue;
}

public void OnPlayerTeam(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iUserID = hEvent.GetInt("userid"), iClient = GetClientOfUserId(iUserID);
	if((Team[iClient] = hEvent.GetInt("team")) > 1 && !Message[iClient] && VIP_IsClientVIP(iClient) && VIP_GetClientFeatureStatus(iClient, g_sFeature) <= ENABLED && hEvent.GetInt("oldteam") < 2)
	{
		Message[iClient] = true;
		CreateTimer(2.0, Timer_SendMessage, iUserID);
	}
}

public Action Timer_SendMessage(Handle hTimer, int iClient)
{
	if((iClient = GetClientOfUserId(iClient)) > 0 && IsClientInGame(iClient) && VIP_IsClientVIP(iClient) && VIP_GetClientFeatureStatus(iClient, g_sFeature) <= ENABLED)
	{
		//VIP_PrintToChatClient(iClient, "Hide is %s", Hide[iClient] ? "enabled":"disabled");
	}
}

void CheckClientHide(int iClient)
{
	Hide[iClient][HIDE_TOGGLE] = (Hide[iClient][HIDE_ADMINS] || Hide[iClient][HIDE_VIPS] || Hide[iClient][HIDE_PLAYERS] || Hide[iClient][HIDE_LEADER]);
}