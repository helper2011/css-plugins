#include <sourcemod>
#include <sdkhooks>
#include <sdktools_functions>
#include <sdktools_stringtables>

#pragma newdecls required

int POTC, Owner;
bool Timer[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name		= "[ZE] Pirates skins",
	version		= "1.0",
	description	= "",
	author		= "hEl"
}

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart, EventHookMode_Post);
	CreateTimer(1.0, Timer_Auth);
}

public void OnRoundStart(Event hEvent, const char[] name, bool bDontBroadcast)
{
	Owner = 0;
}

public Action Timer_Auth(Handle hTimer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
			if(!Timer[i])
			{
				Timer[i] = view_as<bool>(CreateTimer(0.5, Timer_SetClientSkin, i));
			}
		}
	}
}

public void OnMapStart()
{
	char szBuffer[256];
	GetCurrentMap(szBuffer, 256);
	
	if(!strcmp(szBuffer, "ze_potc_v3_4fix", false))
	{
		POTC = 0;
	}
	else if(!strcmp(szBuffer, "ze_potc_iv_v6_1", false))
	{
		POTC = 1;
	}
	else if(!strcmp(szBuffer, "ze_pirates_port_royal_v3_6", false))
	{
		POTC = 2;
	}
	else
	{
		GetPluginFilename(GetMyHandle(), szBuffer, 256);
		ServerCommand("sm plugins unload %s", szBuffer);
		return;
	}
	
	PrecacheModel("models/player/vad36jack_sparrow/jack.mdl", true);
	
	AddFileToDownloadsTable("models/player/vad36jack_sparrow/jack.sw.vtx");
	AddFileToDownloadsTable("models/player/vad36jack_sparrow/jack.vvd");
	AddFileToDownloadsTable("models/player/vad36jack_sparrow/jack.dx80.vtx");
	AddFileToDownloadsTable("models/player/vad36jack_sparrow/jack.dx90.vtx");
	AddFileToDownloadsTable("models/player/vad36jack_sparrow/jack.mdl");
	AddFileToDownloadsTable("models/player/vad36jack_sparrow/jack.phy");
	AddFileToDownloadsTable("materials/models/player/vad36jack_sparrow/material006.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36jack_sparrow/material006_n.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36jack_sparrow/material000.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36jack_sparrow/material000.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36jack_sparrow/material000_n.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36jack_sparrow/material001.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36jack_sparrow/material001.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36jack_sparrow/material001_n.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36jack_sparrow/material002.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36jack_sparrow/material002.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36jack_sparrow/material002_n.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36jack_sparrow/material003.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36jack_sparrow/material003.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36jack_sparrow/material003_n.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36jack_sparrow/material004.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36jack_sparrow/material004.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36jack_sparrow/material004_n.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36jack_sparrow/material005.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36jack_sparrow/material005.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36jack_sparrow/material005_n.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36jack_sparrow/material006.vmt");
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_WeaponEquipPost, OnWeaponHook);
}

public void OnClientDisconnect(int iClient)
{
	Timer[iClient] = false;
}

public void OnWeaponHook(int iClient, int iWeapon)
{
	if(!Owner && IsValidEntity(iWeapon) && !Timer[iClient] && GetClientTeam(iClient) == 3 && IsValidWeapon(iWeapon))
	{
		Timer[iClient] = view_as<bool>(CreateTimer(2.0, Timer_SetClientSkin, iClient));
	}
}

public Action Timer_SetClientSkin(Handle hTimer, int iClient)
{
	if(Timer[iClient])
	{
		Timer[iClient] = false;
		
		if(IsPlayerAlive(iClient) && GetClientTeam(iClient) == 3)
		{
			int iWeapon = GetPlayerWeaponSlot(iClient, 1);
			if(iWeapon != -1 && IsValidWeapon(iWeapon))
			{
				Owner = iClient;
				SetEntityModel(iClient, "models/player/vad36jack_sparrow/jack.mdl");
			}
		}
	}
}

bool IsValidWeapon(int iWeapon)
{
	int iHammerId = GetEntProp(iWeapon, Prop_Data, "m_iHammerID");
	return ((POTC == 0 && iHammerId == 432113) || (POTC == 1 && iHammerId == 187114) || (POTC == 2 && iHammerId == 2058306));
}