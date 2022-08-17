#include <sourcemod>
#include <geoip>
#include <vip_core>

#pragma newdecls required

int Status[MAXPLAYERS + 1];

static const char ConnectWords[][] = 
{
	"подключился",
	"connected"
}

public Plugin myinfo = 
{
    name = "Connect Info",
    version = "1.0",
	description = "",
    author = "hEl",
	url = ""
};

public void OnClientPostAdminCheck(int iClient)
{
	CheckStatus(iClient, (1 << 0));
}

public void VIP_OnClientLoaded(int iClient, bool bIsVip)
{
	CheckStatus(iClient, (1 << 1));
}

void CheckStatus(int iClient, int iInfo, bool bTimer = true)
{
	Status[iClient] += iInfo;
	if(!(Status[iClient] & (1 << 0) && Status[iClient] & (1 << 1)))
		return;
		
	if(!IsClientInGame(iClient) || IsFakeClient(iClient))
	{
		OnClientDisconnect(iClient);
		return;
	}
	if(bTimer)
	{
		CreateTimer(1.0, Timer_Info, iClient);
		return;
	}
	
	char szIp[16], szCountry[2][128], szBuffer[64], szType[128];
	int iFlags = GetUserFlagBits(iClient), iLangId;
	
	if(GetClientIP(iClient, szIp, 16) && GeoipCountry(szIp, szBuffer, 64))
	{
		FormatEx(szCountry[0], 128, " из \x07FFB980%s", szBuffer);
		FormatEx(szCountry[1], 128, " from \x07FFB980%s", szBuffer);
	}
	GetClientAuthId(iClient, AuthId_Steam3, szBuffer, 64);
	if(iFlags & ADMFLAG_ROOT)
	{
		szType = "[Root Admin] ";
	}
	else if(iFlags & ADMFLAG_UNBAN)
	{
		szType = "[Superior admin] ";
	}
	else if(iFlags & ADMFLAG_GENERIC)
	{
		szType = "[Admin] ";
	}
	else if(iFlags & ADMFLAG_CUSTOM2)
	{
		szType = "[VIP] ";
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			iFlags = GetUserFlagBits(i);
			iLangId = !GetClientLanguage(i) ? 1:0;
			if(iFlags & ADMFLAG_ROOT || iFlags & ADMFLAG_UNBAN)
			{
				PrintToChat(i, "\x07D280FF%s\x0780FFFF%N %s%s\x07FFB980\nSteamID: %s, IP: %s", szType, iClient, ConnectWords[iLangId], szCountry[iLangId], szBuffer, szIp);
			}
			else if(iFlags & ADMFLAG_GENERIC)
			{
				PrintToChat(i, "\x07D280FF%s\x0780FFFF%N %s%s\x07FFB980\nSteamID: %s", szType, iClient, ConnectWords[iLangId], szCountry[iLangId], szBuffer);
			}
			else
			{
				PrintToChat(i, "\x07D280FF%s\x0780FFFF%N %s%s", szType, iClient, ConnectWords[iLangId], szCountry[iLangId]);
			}
		}
	}
}

public Action Timer_Info(Handle hTimer, int iClient)
{
	CheckStatus(iClient, 0, false);
}

public void OnClientDisconnect(int iClient)
{
	Status[iClient] = 0;
}