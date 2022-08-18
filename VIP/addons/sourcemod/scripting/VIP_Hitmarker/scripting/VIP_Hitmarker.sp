#include <sourcemod>
#include <sdktools_entoutput>
#include <sdktools_stringtables>

#include <vip_core>

#pragma newdecls required

bool Hitmarker[MAXPLAYERS + 1], Overlay[MAXPLAYERS + 1];

static const char g_sFeature[] = "Hitmarker";

static const char g_sFiles[][] = 
{
	"sibgamers/hitmarker.vmt",
	"sibgamers/hitmarker.vtf",
	"sibgamers/other/hit.mp3"
};

public Plugin myinfo = 
{
	name		= "[VIP] Hitmarker",
	version		= "1.0",
	author		= "hEl"
}

public void OnPluginStart()
{
	HookEvent("player_hurt", OnPlayerHurt);
	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && VIP_IsClientVIP(i))
		{
			VIP_OnClientLoaded(i, true);
		}
	}
}

public void OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
}

public void VIP_OnVIPLoaded() 
{
	VIP_RegisterFeature(g_sFeature, BOOL, TOGGLABLE, ItemSelect);
}

public void VIP_OnClientLoaded(int iClient, bool bIsVIP)
{
	Hitmarker[iClient] = (bIsVIP && VIP_GetClientFeatureStatus(iClient, g_sFeature) <= ENABLED && VIP_IsClientFeatureUse(iClient, g_sFeature));
}

public Action ItemSelect(int iClient, const char[] szFeature, VIP_ToggleState eOldStatus, VIP_ToggleState &eNewStatus)
{
	Hitmarker[iClient] = (eNewStatus == ENABLED);
	return Plugin_Continue;
}


public void OnClientDisconnect(int iClient)
{
	Hitmarker[iClient] = false;
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

public void OnPlayerHurt(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	
	if(iAttacker != GetClientOfUserId(hEvent.GetInt("userid")))
	{
		Hitmark(iAttacker);
	}
}

void Hitmark(int iClient)
{
	if(0 < iClient <= MaxClients && Hitmarker[iClient])
	{
		if(!Overlay[iClient])
		{
			ClientCommand(iClient, "r_screenoverlay %s", g_sFiles[0]);
			Overlay[iClient] = view_as<bool>(CreateTimer(0.2, Timer_RemoveHitMarker, iClient));
		}
		ClientCommand(iClient, "playgamesound %s", g_sFiles[2]);
	}
}

public Action Timer_RemoveHitMarker(Handle hTimer, int iClient)
{
	Overlay[iClient] = false;
	if(IsClientInGame(iClient)) 
		ClientCommand(iClient, "r_screenoverlay off");

	return Plugin_Continue;
}