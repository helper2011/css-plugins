#include <sourcemod>
#include <sdktools_stringtables>
#include <sdktools_sound>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#include <BossHP>
#define REQUIRE_PLUGIN

#pragma newdecls required

enum
{
	HITMARKER_SOUND = 1,
	HITMARKER_ZOMBIE = 2,
	HITMARKER_BOSS = 4,

	HITMARKER_ALL = HITMARKER_SOUND + HITMARKER_ZOMBIE + HITMARKER_BOSS
}

Handle hCookie;
float OverlayTime[MAXPLAYERS + 1];
int Hitmarker[MAXPLAYERS + 1] = {HITMARKER_ALL, ...}, RussianLanguageId;

static const char g_sFiles[][] = 
{
	"sexwbhop/hitmarker.vmt",
	"sexwbhop/hitmarker.vtf",
	"sexwbhop/hitmarker/hit.mp3"
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
	if((RussianLanguageId = GetLanguageByCode("ru")) == -1)
	{
		SetFailState("Cant find russian language (see languages.cfg)");
	}
	HookEvent("player_hurt", OnPlayerHurt);
	SetCookieMenuItem(CookieMenuH, 0, "Hitmarker");
	RegConsoleCmd("sm_hitmarker", Command_Hitmarker);
	hCookie = RegClientCookie("Hitmarker", "", CookieAccess_Private);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
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

public void OnGameFrame()
{
	static float fTime;
	fTime = GetGameTime();
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
			continue;

		if(OverlayTime[i] && fTime > OverlayTime[i])
		{
			DisplayClientOverlay(i);
			OverlayTime[i] = 0.0;
		}
	}
}

public void CookieMenuH(int iClient, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlen, "%s [%s]", GetClientLanguage(iClient) == RussianLanguageId ? "Хитмаркер":"Hitmarker", Hitmarker[iClient] == HITMARKER_ALL ? "✔":Hitmarker[iClient] == 0 ? "×":"◼");
		}
		case CookieMenuAction_SelectOption:
		{
			HitmarkerMenu(iClient);
		}
	}
}

void HitmarkerMenu(int iClient)
{
	bool bRussian = (GetClientLanguage(iClient) == RussianLanguageId);
	char szBuffer[256];
	Menu hMenu = new Menu(HitmarkerMenuH, MenuAction_End | MenuAction_Cancel | MenuAction_Select);
	hMenu.SetTitle(bRussian ? "Хитмаркер":"Hitmarker");
	FormatEx(szBuffer, 256, "%s: [%s]", bRussian ? "Звук":"Sound", (Hitmarker[iClient] & HITMARKER_SOUND) ? "✔":"×"); hMenu.AddItem("", szBuffer);
	FormatEx(szBuffer, 256, "%s: [%s]", bRussian ? "Зомби":"Zombie", (Hitmarker[iClient] & HITMARKER_ZOMBIE) ? "✔":"×"); hMenu.AddItem("", szBuffer);
	FormatEx(szBuffer, 256, "%s: [%s]", bRussian ? "Босс":"Boss", (Hitmarker[iClient] & HITMARKER_BOSS) ? "✔":"×"); hMenu.AddItem("", szBuffer);
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
			Hitmarker[iClient] ^= (1 << iItem);
			HitmarkerMenu(iClient);

			if(AreClientCookiesCached(iClient))
			{
				char szBuffer[16];
				IntToString(Hitmarker[iClient], szBuffer, 16);
				SetClientCookie(iClient, hCookie, szBuffer);
			}
		}
	}
}

public Action Command_Hitmarker(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient))
	{
		HitmarkerMenu(iClient);
	}
	
	return Plugin_Handled;
}

public void OnBossDamaged(CBoss Boss, CConfig Config, int client, float damage)
{
	Hitmark(client, HITMARKER_BOSS);
}

public void OnPlayerHurt(Event hEvent, const char[] event, bool bDontBroadcast)
{
	static int iAttacker;
	iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	
	if(iAttacker != GetClientOfUserId(hEvent.GetInt("userid")))
	{
		Hitmark(iAttacker, HITMARKER_ZOMBIE);
	}
}

void Hitmark(int iClient, int iEntityFlag)
{
	if(0 < iClient <= MaxClients && Hitmarker[iClient] & iEntityFlag)
	{
		if(!OverlayTime[iClient])
		{
			OverlayTime[iClient] = GetGameTime() + 0.2;
			DisplayClientOverlay(iClient, g_sFiles[0]);
		}
		
		if(Hitmarker[iClient] & HITMARKER_SOUND)
		{
			EmitSoundToClient(iClient, g_sFiles[2], SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS);
		}
	}
}

public void OnClientCookiesCached(int iClient)
{
	if(IsFakeClient(iClient))
	{
		Hitmarker[iClient] = 0;
		return;
	}

	char szBuffer[8];
	GetClientCookie(iClient, hCookie, szBuffer, 8);
	
	if(szBuffer[0])
	{
		Hitmarker[iClient] = StringToInt(szBuffer);
	}
}

public void OnClientDisconnect(int iClient)
{
	OverlayTime[iClient] = 0.0;
	Hitmarker[iClient] = HITMARKER_ALL;
}

stock void DisplayClientOverlay(int iClient, const char[] overlay = "")
{
	ClientCommand(iClient, "r_screenoverlay \"%s\"", overlay);
}