#include <sourcemod>
#include <clientprefs>

#pragma newdecls required

Handle	g_hCookie;
int		Damage[MAXPLAYERS + 1], Victim[MAXPLAYERS + 1];
bool	NoFake[MAXPLAYERS + 1], Toggle[MAXPLAYERS + 1][3], Save[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "ze showdamage",
	version = "1.0",
	author = "hEl"
};

public void OnPluginStart()
{
	g_hCookie = RegClientCookie("ShowDamage", "Damage display", CookieAccess_Private);
	HookEvent("player_hurt", OnPlayerHurt);
	
	SetCookieMenuItem(CookieMenuH, 0, "Show Damage");
	
	RegConsoleCmd("sm_sd", Command_ShowDamage, "Damage display settings");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
			
			if(AreClientCookiesCached(i))
			{
				OnClientCookiesCached(i);
			}
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

public void OnClientPutInServer(int iClient)
{
	Victim[iClient] = 0;
	Damage[iClient] = 0;
	NoFake[iClient] = !IsFakeClient(iClient);
	if(!AreClientCookiesCached(iClient))
	{
		SetClientDefaultSettings(iClient);
	}
}

public void OnClientCookiesCached(int iClient)
{
	SetClientDefaultSettings(iClient);
	char szBuffer[8];
	GetClientCookie(iClient, g_hCookie, szBuffer, 8);
	if(szBuffer[0])
	{
		for(int i = 2;i >= 0; i--)
		{
			Toggle[iClient][i] = view_as<bool>(StringToInt(szBuffer[i]));
			szBuffer[i] = 0;
		}
	}

}

public void OnClientDisconnect(int iClient)
{
	if(Save[iClient])
	{
		Save[iClient] = false;
		
		char szBuffer[8];
		FormatEx(szBuffer, 8, "%i%i%i",	view_as<int>(Toggle[iClient][0]), 
										view_as<int>(Toggle[iClient][1]),
										view_as<int>(Toggle[iClient][2]));
										
		SetClientCookie(iClient, g_hCookie, szBuffer);
	}
}


void SetClientDefaultSettings(int iClient)
{
	Toggle[iClient][0] = true;
	Toggle[iClient][1] = true;
	Toggle[iClient][2] = true;

}

public Action Command_ShowDamage(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient))
	{
		ShowDamageMenu(iClient, false);
	}
	
	return Plugin_Handled;
}

public void CookieMenuH(int iClient, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_SelectOption:
		{
			ShowDamageMenu(iClient, true);
		}
	}
}

void ShowDamageMenu(int iClient, bool bExitBackButton)
{
	char szBuffer[256], szBuffer2[8];
	IntToString(view_as<int>(bExitBackButton), szBuffer2, 8);
	Menu hMenu = new Menu(ShowDamageMenuH);
	hMenu.SetTitle("Show Damage\n ");
	FormatEx(szBuffer, 256, "Nick [%s]", Toggle[iClient][0] ? "✔":"×"); hMenu.AddItem(szBuffer2, szBuffer);
	FormatEx(szBuffer, 256, "Damage [%s]", Toggle[iClient][1] ? "✔":"×"); hMenu.AddItem(szBuffer2, szBuffer);
	FormatEx(szBuffer, 256, "Health [%s]", Toggle[iClient][2] ? "✔":"×"); hMenu.AddItem(szBuffer2, szBuffer);
	hMenu.ExitBackButton = bExitBackButton;
	hMenu.Display(iClient, 0);
}

public int ShowDamageMenuH(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete hMenu;
		}
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack)
			{
				ShowCookieMenu(iClient);
			}
		}
		case MenuAction_Select:
		{
			char szBuffer[8];
			hMenu.GetItem(iItem, szBuffer, 8);
			Save[iClient] = true;
			Toggle[iClient][iItem] = !Toggle[iClient][iItem];
			ShowDamageMenu(iClient, view_as<bool>(StringToInt(szBuffer)));
		}
	}
}



public void OnPlayerHurt(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker")), iClient;
	
	if(0 < iAttacker <= MaxClients && NoFake[iAttacker] && iAttacker != (iClient = GetClientOfUserId(hEvent.GetInt("userid"))))
	{
		if(!Damage[iAttacker])
		{
			RequestFrame(ShowDamage, iAttacker);
		}
		Damage[iAttacker] += hEvent.GetInt("dmg_health");
		Victim[iAttacker] = iClient;
	}
}

public void ShowDamage(int iClient)
{
	char szBuffer[256];
	bool bValidVictim = (Victim[iClient] && IsClientInGame(Victim[iClient]));
	if(Toggle[iClient][0] && bValidVictim)
	{
		FormatEx(szBuffer, 256, "Nick: %N", Victim[iClient]);
	}
	if(Toggle[iClient][1])
	{
		Format(szBuffer, 256, "%s\nDamage: %i", szBuffer, Damage[iClient]);
	}
	if(Toggle[iClient][2] && bValidVictim)
	{
		Format(szBuffer, 256, "%s\nHealth: %i", szBuffer, IsPlayerAlive(Victim[iClient]) ? GetEntProp(Victim[iClient], Prop_Send, "m_iHealth"):0);
	}
	PrintCenterText(iClient, szBuffer);
	Damage[iClient] = 0;
	Victim[iClient] = 0;
	
}
