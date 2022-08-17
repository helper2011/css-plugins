#include <sourcemod>
#include <cstrike>
#include <vip_core>


ConVar Group;
bool VIP[MAXPLAYERS + 1], SupportVIP[MAXPLAYERS + 1];

static const int ClanId = 11892945;

public Plugin myinfo =
{
	name			= "[VIP] VIP for Clantag",
	author			= "hEl"
};

public void OnPluginStart()
{
	Group = CreateConVar("sm_vip_clantag_group", "member");
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			VIP[i] = VIP_IsClientVIP(i);
		}
	}
	OnRoundStart(null, "", true);
}

public void OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && SupportVIP[i])
		{
			VIP_RemoveClientVIP2(0, i, false, true);
		}
	}
}

public void VIP_OnClientLoaded(int iClient, bool bIsVIP)
{
	if(bIsVIP)
	{
		if(!SupportVIP[iClient])
		{
			VIP[iClient] = true;
		}
	}
	else if(GetClientClanId(iClient) == ClanId)
	{
		char szBuffer[64];
		Group.GetString(szBuffer, 64);
		SupportVIP[iClient] = true;
		VIP_GiveClientVIP(-1, iClient, 0, szBuffer, false);
	}
}

public void VIP_OnVIPClientAdded(int iClient, int iAdmin)
{
	VIP_OnClientLoaded(iClient, true);
}

public void VIP_OnVIPClientRemoved(int iClient, const char[] szReason, int iAdmin)
{
	OnClientDisconnect(iClient);
}

public void OnRoundStart(Event hEvent, const char[] name, bool bDontBroadcast)
{
	char szBuffer[64];
	Group.GetString(szBuffer, 64);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && !VIP[i])
		{
			
			if(GetClientClanId(i) == ClanId)
			{
				if(!SupportVIP[i])
				{
					SupportVIP[i] = true;
					VIP_GiveClientVIP(-1, i, 0, szBuffer, false);
				}
			}
			else if(SupportVIP[i])
			{
				VIP_RemoveClientVIP2(0, i, false, true);
			}
		}
	}
}

int GetClientClanId(int iClient)
{
	char szBuffer[32];
	GetClientInfo(iClient, "cl_clanid", szBuffer, 32);
	return StringToInt(szBuffer);
}

public void OnClientDisconnect(int iClient)
{
	VIP[iClient] = false;
	SupportVIP[iClient] = false;
}