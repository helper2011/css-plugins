#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#include <vip_core>

#pragma newdecls required

KeyValues	g_hKeyValues;
Handle		g_hCookie[2];
Menu		g_hTrailsMenu;
bool		g_bHide, Hide[MAXPLAYERS + 1], SaveCookie[MAXPLAYERS + 1][2];
int			Team[MAXPLAYERS + 1],
			g_iClientTrail[MAXPLAYERS + 1] = {-1, ...},
			g_iClientItem[MAXPLAYERS + 1] = {-1, ...};

public void OnPluginStart()
{
	g_hCookie[0] = RegClientCookie("Trails", "", CookieAccess_Private);
	g_hCookie[1] = RegClientCookie("HideTrails", "", CookieAccess_Private);
	
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_team", OnPlayerTeam);
	
	RegAdminCmd("sm_trails", Trails_Command, ADMFLAG_CUSTOM3);
	RegConsoleCmd("sm_hidetrails", HideTrails_Command);
	
	g_hTrailsMenu = new Menu(Handler_TrailsMenu, MenuAction_Select|MenuAction_DisplayItem);
	g_hTrailsMenu.SetTitle("Trails");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			Team[i] = GetClientTeam(i);
			OnClientPostAdminCheck(i);
		}
	}
}

public void OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientDisconnect(i);
		}
	}
}

public Action HideTrails_Command(int iClient, int iArgs)
{
	if(iClient > 0 && !IsFakeClient(iClient))
	{
		PrintToChat(iClient, "[Trails] You have %s trails", (Hide[iClient] = !Hide[iClient]) ? "disabled":"enabled");
		SaveCookie[iClient][1] = true;
	}
	
	return Plugin_Handled;
}

public Action Trails_Command(int iClient, int iArgs)
{
	if(iClient > 0 && !IsFakeClient(iClient))
	{
		g_hTrailsMenu.Display(iClient, 0);
	}
	
	return Plugin_Handled;
}

public void OnMapStart()
{
	char szBuffer[256];

	delete g_hKeyValues;
	
	g_hTrailsMenu.RemoveAllItems();

	g_hKeyValues = new KeyValues("Trails");
	BuildPath(Path_SM, szBuffer, 256, "configs/trails.ini");

	if (!g_hKeyValues.ImportFromFile(szBuffer))
	{
		SetFailState("[Trails] Config file \"%s\" does exists...", szBuffer);
	}

	g_hKeyValues.Rewind();
	
	g_bHide = view_as<bool>(g_hKeyValues.GetNum("Hide_Opposite_Team", 0));
	if (g_hKeyValues.GotoFirstSubKey())
	{
		do
		{
			g_hKeyValues.GetString("Material", szBuffer, 256);
			if(szBuffer[0] && FileExists(szBuffer) && strcmp(szBuffer[strlen(szBuffer)-4], ".vmt") == 0)
			{
				PrecacheModel(szBuffer, true);
				AddFileToDownloadsTable(szBuffer);
				ReplaceString(szBuffer, sizeof(szBuffer), ".vmt", ".vtf", false);
				if(FileExists(szBuffer))
				{
					AddFileToDownloadsTable(szBuffer);
					g_hKeyValues.GetSectionName(szBuffer, sizeof(szBuffer));
					g_hTrailsMenu.AddItem("", szBuffer);
					continue;
				}
			}

			g_hKeyValues.DeleteThis();
		}
		while (g_hKeyValues.GotoNextKey());
	}

	if(!g_hTrailsMenu.ItemCount)
	{
		g_hTrailsMenu.AddItem("", "No available", ITEMDRAW_DISABLED);
	}
}

public int Handler_TrailsMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(g_iClientItem[iClient] == iItem)
			{
				UTIL_KillTrail(iClient);
				g_iClientItem[iClient] = -1;
			}
			else
			{
				
				g_iClientItem[iClient] = iItem;
				if(IsPlayerAlive(iClient))
				{
					UTIL_CreateTrail(iClient);
				}
			}
			SaveCookie[iClient][0] = true;
			g_hTrailsMenu.DisplayAt(iClient, hMenu.Selection, 0);
			
		}
		case MenuAction_DisplayItem:
		{
			if(g_iClientItem[iClient] == iItem)
			{
				char szBuffer[64];
				hMenu.GetItem(iItem, "", 0, _, szBuffer, 64);
				
				Format(szBuffer, 64, "%s [X]", szBuffer);

				return RedrawMenuItem(szBuffer);
			}
		}
	}

	return 0;
}

public void OnClientPostAdminCheck(int iClient)
{
	g_iClientTrail[iClient] = g_iClientItem[iClient] = -1;
	CreateTimer(5.0, Timer_Auth, GetClientUserId(iClient));
}

public Action Timer_Auth(Handle hTimer, int iClient)
{
	if((iClient = GetClientOfUserId(iClient)) > 0 && IsClientInGame(iClient))
	{
		char szBuffer[64];
		GetClientCookie(iClient, g_hCookie[1], szBuffer, 64);
		if(szBuffer[0])
		{
			Hide[iClient] = view_as<bool>(StringToInt(szBuffer));
		}
		if(CheckCommandAccess(iClient, "trails", ADMFLAG_CUSTOM3))
		{
			GetClientCookie(iClient, g_hCookie[0], szBuffer, 64);
			if(szBuffer[0] && (g_iClientItem[iClient] = UTIL_GetItemIndex(szBuffer)) != -1 && IsPlayerAlive(iClient))
			{
				UTIL_CreateTrail(iClient);
			}
		}
	}

	return Plugin_Continue;
}

public void OnClientDisconnect(int iClient)
{
	if(SaveCookie[iClient][0])
	{
		char szBuffer[64];
		if(g_iClientItem[iClient] != -1)
		{
			g_hTrailsMenu.GetItem(g_iClientItem[iClient], "", 0, _, szBuffer, 64);
		}
		SetClientCookie(iClient, g_hCookie[0], szBuffer);
		SaveCookie[iClient][0] = false;
	}
	if(SaveCookie[iClient][1])
	{
		SetClientCookie(iClient, g_hCookie[1], Hide[iClient] ? "1":"0");
		SaveCookie[iClient][1] = false;
	}
	Hide[iClient] = false;
	UTIL_KillTrail(iClient);
	g_iClientTrail[iClient] = g_iClientItem[iClient] = -1;
}

int UTIL_GetItemIndex(const char[] szTrail)
{
	char szBuffer[64], iTrails;
	iTrails = g_hTrailsMenu.ItemCount;
	for(int i; i < iTrails; i++)
	{
		g_hTrailsMenu.GetItem(i, "", 0, _, szBuffer, 64);
		if(strcmp(szTrail, szBuffer, false) == 0)
		{
			return i;
		}
	}

	return -1;
}

public void OnRoundStart(Event hEvent, const char[] event, bool bDontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(g_iClientItem[i] != -1)
		{
			UTIL_KillTrail(i);
		}
	}
}

public void OnPlayerSpawn(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iUserID = hEvent.GetInt("userid"), iClient = GetClientOfUserId(iUserID);
	if(g_iClientItem[iClient] != -1)
	{
		UTIL_KillTrail(iClient);
		CreateTimer(0.1, Timer_CreateTrail, iUserID);
	}
}

public void OnPlayerDeath(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iUserID = hEvent.GetInt("userid"), iClient = GetClientOfUserId(iUserID);
	if(UTIL_KillTrail(iClient))
	{
		CreateTimer(0.1, Timer_CreateTrail, iUserID);
	}
}

public Action Timer_CreateTrail(Handle hTimer, int iClient)
{
	if((iClient = GetClientOfUserId(iClient)) > 0 && IsClientInGame(iClient) && IsPlayerAlive(iClient) && g_iClientItem[iClient] != -1)
	{
		UTIL_CreateTrail(iClient);
	}
	
	return Plugin_Continue;
}


public void OnPlayerTeam(Event hEvent, const char[] event, bool bDontBroadcast)
{
	Team[GetClientOfUserId(hEvent.GetInt("userid"))] = hEvent.GetInt("team");
}


bool UTIL_KillTrail(int iClient)
{
	if(g_iClientTrail[iClient] > 0)
	{
		if(IsValidEdict(g_iClientTrail[iClient]))
		{
			AcceptEntityInput(g_iClientTrail[iClient], "Kill");
			SDKUnhook(g_iClientTrail[iClient], SDKHook_SetTransmit, SetTransmit);
		}
		g_iClientTrail[iClient] = -1;
		return true;
	}
	return false;
}

void UTIL_CreateTrail(int iClient)
{
	UTIL_KillTrail(iClient);

	if ((g_iClientTrail[iClient] = CreateEntityByName("env_spritetrail")) == -1)
	{
		return;
	}
	char szBuffer[64];
	g_hTrailsMenu.GetItem(g_iClientItem[iClient], "", 0, _, szBuffer, 64);
	g_hKeyValues.Rewind();
	if(!g_hKeyValues.JumpToKey(szBuffer))
	{
		return;
	}
	
	
	g_hKeyValues.GetString("Material", szBuffer, 64);
	DispatchKeyValue(g_iClientTrail[iClient], "spritename", szBuffer);
	
	g_hKeyValues.GetString("StartWidth", szBuffer, 12, "10");
	DispatchKeyValue(g_iClientTrail[iClient], "startwidth", szBuffer);
	
	g_hKeyValues.GetString("EndWidth", szBuffer, 12, "6");
	DispatchKeyValue(g_iClientTrail[iClient], "endwidth", szBuffer);
	
	DispatchKeyValueFloat(g_iClientTrail[iClient], "lifetime", g_hKeyValues.GetFloat("LifeTime", 1.0));

	DispatchKeyValue(g_iClientTrail[iClient], "renderamt", "255");
	
	g_hKeyValues.GetString("Color", szBuffer, 64, "255 255 255");
	DispatchKeyValue(g_iClientTrail[iClient], "rendercolor", "255 255 255");

	DispatchKeyValue(g_iClientTrail[iClient], "rendermode", "1");

	FormatEx(szBuffer, 64, "trails_%d", g_iClientTrail[iClient]);
	DispatchKeyValue(g_iClientTrail[iClient], "targetname", szBuffer);

	DispatchSpawn(g_iClientTrail[iClient]);

	float fPosition[3], fOrigin[3];
	GetClientAbsOrigin(iClient, fOrigin);
	g_hKeyValues.GetVector("Position", fPosition, view_as<float>({0.0, 0.0, 10.0}));
	if(fPosition[0] != 0.0 || fPosition[1] != 0.0 || fPosition[2] != 0.0)
	{
		float fAngles[3], fForward[3], fRight[3], fUp[3];
		GetClientAbsAngles(iClient, fAngles);
		GetAngleVectors(fAngles, fForward, fRight, fUp);
		fOrigin[0] += fRight[0]*fPosition[0] + fForward[0]*fPosition[1] + fUp[0]*fPosition[2];
		fOrigin[1] += fRight[1]*fPosition[0] + fForward[1]*fPosition[1] + fUp[1]*fPosition[2];
		fOrigin[2] += fRight[2]*fPosition[0] + fForward[2]*fPosition[1] + fUp[2]*fPosition[2];
	}

	TeleportEntity(g_iClientTrail[iClient], fOrigin, NULL_VECTOR, NULL_VECTOR);
	
	SetVariantString("!activator");
	AcceptEntityInput(g_iClientTrail[iClient], "SetParent", iClient); 
	SetEntPropFloat(g_iClientTrail[iClient], Prop_Send, "m_flTextureRes", 0.05);
	SetEntPropEnt(g_iClientTrail[iClient], Prop_Send, "m_hOwnerEntity", iClient);
	
	SDKHook(g_iClientTrail[iClient], SDKHook_SetTransmit, SetTransmit);
}

public Action SetTransmit(int iEntity, int iClient)
{
	if(Hide[iClient])
	{
		return Plugin_Handled;
	}
	else if(!g_bHide || g_iClientTrail[iClient] == iEntity || Team[iClient] < 2)
	{
		return Plugin_Continue;
	}

	static int iOwner;
	iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
	return (iOwner != -1 && Team[iOwner] != Team[iClient]) ? Plugin_Handled:Plugin_Continue;
}