#include <sourcemod>
#include <sdktools_stringtables>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#include <BossHP>
#define REQUIRE_PLUGIN


#pragma newdecls required

Handle g_hCookie;
bool Overlay[MAXPLAYERS + 1];
int Hitmarker[MAXPLAYERS + 1] = {7, ...};

enum
{
	HITMARKER_SOUND = 1,
	HITMARKER_ZOMBIE = 2,
	HITMARKER_BOSS = 4
}

static const char g_sFiles[][] = 
{
	"sibgamers/hitmarker.vmt",
	"sibgamers/hitmarker.vtf",
	"sibgamers/other/hit.mp3"
};

public Plugin myinfo = 
{
	name		= "Hitmarker",
	version		= "1.0",
	description	= "",
	author		= "hEl"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("hitmarker.phrases");
	
	HookEvent("player_hurt", OnPlayerHurt);
	
	SetCookieMenuItem(CookieMenuH, 0, "Hitmarker");
	
	RegConsoleCmd("sm_hm", Command_Hitmarker);
	RegConsoleCmd("sm_hitmarker", Command_Hitmarker);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
	g_hCookie = RegClientCookie("Hitmarker", "", CookieAccess_Private);
}

public void OnMapStart()
{
	char szBuffer[256];
	for(int i; i < 3; i++)
	{
		FormatEx(szBuffer, 256, "%s/%s", i > 1 ? "sound":"materials", g_sFiles[i]);
		AddFileToDownloadsTable(szBuffer);
		
		if(i > 1)	PrecacheSound(g_sFiles[i],	true);
		else		PrecacheModel(szBuffer,		true);
	}
}

public void CookieMenuH(int iClient, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlen, "%T", "Item", iClient);
		}
		case CookieMenuAction_SelectOption:
		{
			HitmarkerMenu(iClient);
		}
	}
}

void HitmarkerMenu(int iClient)
{
	char szBuffer[256];
	Menu hMenu = new Menu(HitmarkerMenuH);
	SetGlobalTransTarget(iClient);
	hMenu.SetTitle("%t", "Title");
	FormatEx(szBuffer, 256, "%t: %t", "Sound", (Hitmarker[iClient] & HITMARKER_SOUND) ? "On":"Off"); hMenu.AddItem("", szBuffer);
	FormatEx(szBuffer, 256, "%t: %t", "Zombie", (Hitmarker[iClient] & HITMARKER_ZOMBIE) ? "On":"Off"); hMenu.AddItem("", szBuffer);
	FormatEx(szBuffer, 256, "%t: %t", "Boss", (Hitmarker[iClient] & HITMARKER_BOSS) ? "On":"Off"); hMenu.AddItem("", szBuffer);
	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, 0);
}

public int HitmarkerMenuH(Menu hMenu, MenuAction action, int iClient, int iItem)
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
			char szBuffer[16];
			Hitmarker[iClient] ^= (1 << iItem);
			IntToString(Hitmarker[iClient], szBuffer, 16);
			SetClientCookie(iClient, g_hCookie, szBuffer);
			HitmarkerMenu(iClient);
		}
	}
}

public Action Command_Hitmarker(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient) && AreClientCookiesCached(iClient))
	{
		HitmarkerMenu(iClient);
	}
	
	return Plugin_Handled;
}

public void OnBossDamaged(CBoss Boss, CConfig Config, int client, float damage)
{
	Hitmark(client, false);
}


public void OnPlayerHurt(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	
	if(iAttacker != GetClientOfUserId(hEvent.GetInt("userid")))
	{
		Hitmark(iAttacker, true);
	}
}

void Hitmark(int iClient, bool bZombie)
{
	if(0 < iClient <= MaxClients && ((bZombie && Hitmarker[iClient] & HITMARKER_ZOMBIE) || (!bZombie && Hitmarker[iClient] & HITMARKER_BOSS)))
	{
		if(!Overlay[iClient])
		{
			ClientCommand(iClient, "r_screenoverlay %s", g_sFiles[0]);
			Overlay[iClient] = view_as<bool>(CreateTimer(0.2, Timer_RemoveHitMarker, iClient));
		}
		
		if(Hitmarker[iClient] & HITMARKER_SOUND)
		{
			ClientCommand(iClient, "playgamesound %s", g_sFiles[2]);
		}
	}
}

public Action Timer_RemoveHitMarker(Handle hTimer, int iClient)
{
	Overlay[iClient] = false;
	if(IsClientInGame(iClient)) 
		ClientCommand(iClient, "r_screenoverlay off");
}

public void OnClientCookiesCached(int iClient)
{
	if(!IsFakeClient(iClient))
	{
		char szBuffer[16];
		GetClientCookie(iClient, g_hCookie, szBuffer, 16);
		
		if(szBuffer[0])
		{
			Hitmarker[iClient] = StringToInt(szBuffer);
		}
	}
}

public void OnClientDisconnect(int iClient)
{
	Hitmarker[iClient] = false;
	Overlay[iClient] = false;
	Hitmarker[iClient] = 7;
}