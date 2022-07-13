#pragma semicolon 1
#include <sourcemod>
#include <SteamWorks>

public Plugin:myinfo = 
{
	name = "Check Steam Player",
	author = "KOROVKA", // Plugin by KOROVKA
	description = "Checks the status of the game client (Steam/No-Steam)",
	version = "2.0.0",
	url = ""
};

new String:sSteamID[MAXPLAYERS+1][20], bool:bClientSteam[MAXPLAYERS+1], bool:bVAC[MAXPLAYERS+1], bool:bConnectFail[MAXPLAYERS+1];

public OnPluginStart() RegConsoleCmd("steam", Cmd_CheckSteamPlayer);

public OnClientPostAdminCheck(client)
{
	if(!IsFakeClient(client))
	{
		GetClientAuthId(client, AuthId_SteamID64, sSteamID[client], 20);
		bClientSteam[client] = false;
		bVAC[client] = false;
		bConnectFail[client] = false;
		
		Get_SteamWorks(client);
	}
}

Get_SteamWorks(client)
{
	decl String:sURL[70];
	FormatEx(sURL, 70, "https://steamcommunity.com/profiles/%s?xml=1", sSteamID[client]);
	
	new Handle:hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, sURL);
	SteamWorks_SetHTTPCallbacks(hRequest, OnSteamWorksHTTPComplete);
	SteamWorks_SetHTTPRequestContextValue(hRequest, client);
	SteamWorks_SendHTTPRequest(hRequest);
}

public OnSteamWorksHTTPComplete(Handle:hRequest, bool:bFailure, bool:bRequestSuccessful, EHTTPStatusCode:eStatusCode, any:client)
{
	if (bRequestSuccessful && eStatusCode == k_EHTTPStatusCode200OK) SteamWorks_GetHTTPResponseBodyCallback(hRequest, SteamWorksHTTPBodyCallback, client);
	else bConnectFail[client] = true;
	
	CloseHandle(hRequest);
}

public SteamWorksHTTPBodyCallback(const String:sData[], any:client)
{
	if(StrContains(sData, "<profile>", false) != -1) 
	{
		bClientSteam[client] = true;
		
		if(StrContains(sData, "<vacBanned>0</vacBanned>", false) == -1) 
			bVAC[client] = true;
	}
}

public Action:Cmd_CheckSteamPlayer(client, args)
{
	if(client > 0) ShowMenu(client);
	return Plugin_Handled;
}

ShowMenu(client, pos = 0)
{
	new Handle:menu = CreateMenu(MenuHandler_PlayersList);
	
	new ClientsSteam, ClientsNoSteam;
	decl String:buffer[100], String:info[10];
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			FormatEx(buffer, 100, "%N [%s]%s", i, bClientSteam[i] ? "Steam":bConnectFail[i] ? "Unknown":"No-Steam", !bVAC[client] ? "":" - Имеет VAC");
			if(bConnectFail[i] == false)
			{
				if(bClientSteam[i]) 
				{
					IntToString(GetClientUserId(i), info, 10);
					AddMenuItem(menu, info, buffer);
					ClientsSteam++;
				}
				else 
				{
					AddMenuItem(menu, "", buffer, ITEMDRAW_DISABLED);
					ClientsNoSteam++;
				}
			}
			else AddMenuItem(menu, "", buffer, ITEMDRAW_DISABLED);
		}
	}

	SetMenuTitle(menu, "[%i - Steam | %i - No-Steam] Статус клиентов игры:", ClientsSteam, ClientsNoSteam);

	DisplayMenuAtItem(menu, client, pos, MENU_TIME_FOREVER);
}

public MenuHandler_PlayersList(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:info[10];
			GetMenuItem(menu, param2, info, 10);
			new target;
			
			if((target = GetClientOfUserId(StringToInt(info))) != 0)
			{
				decl String:sProfileInfo[100], String:sNameMotd[120], String:sSteamID3[20];
				GetClientAuthId(target, AuthId_Steam3, sSteamID3, 20);
				FormatEx(sProfileInfo, 100, "- steamcommunity.com/profiles/%s\n- SteamID3: %s", sSteamID[target], sSteamID3);
				FormatEx(sNameMotd, 120, "Профиль игрока %N в steam:", target);
				ShowMOTDPanel(param1, sNameMotd, sProfileInfo, MOTDPANEL_TYPE_TEXT);
			}
			else PrintToChat(param1, "\x04[Check Steam Player] \x01Игрок вышел!");
			
			ShowMenu(param1, GetMenuSelectionPosition());
		}
		case MenuAction_End: CloseHandle(menu);
	}
}