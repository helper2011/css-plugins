#include <sourcemod>
#include <clientprefs>
#include <vip_core>

#pragma newdecls required

Handle g_hCookie;
int RussianLanguageId;

public Plugin myinfo = 
{
	name		= "[VIP] Connect Message",
	version		= "1.0",
	author		= "hEl"
}

public void OnPluginStart()
{
	if((RussianLanguageId = GetLanguageByCode("ru")) == -1)
	{
		SetFailState("Cant find russian language (see languages.cfg)");
	}
	g_hCookie = RegClientCookie("VIP_ConnectMessage", "", CookieAccess_Private);
	
	RegConsoleCmd("sm_joinmsg", Command_JoinMsg);
}

public Action Command_JoinMsg(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient) && VIP_IsClientVIP(iClient))
	{
		char szBuffer[256];
		if(iArgs < 1)
		{
			ReplyToCommand(iClient, "%s: !joinmsg <%s> [clear - %s]", GetClientLanguage(iClient) == RussianLanguageId ? "Использование":"Usage", GetClientLanguage(iClient) == RussianLanguageId ? "сообщение":"message", GetClientLanguage(iClient) == RussianLanguageId ? "сброс":"reset");
			GetClientCookie(iClient, g_hCookie, szBuffer, 256);
			if(szBuffer[0])
			{
				ReplyToCommand(iClient, "%s: %s", GetClientLanguage(iClient) == RussianLanguageId ? "Твое текущее сообщение":"Your current message", szBuffer);
			}
		}
		else
		{
			GetCmdArgString(szBuffer, 256);
			if(strcmp(szBuffer, "clear", false) == 0)
			{
				SetClientCookie(iClient, g_hCookie, "");
				ReplyToCommand(iClient, "%s", GetClientLanguage(iClient) == RussianLanguageId ? "Сообщение сброшено!":"Message cleared!");

			}
			else
			{
				SetClientCookie(iClient, g_hCookie, szBuffer);
				ReplyToCommand(iClient, "%s: %s", GetClientLanguage(iClient) == RussianLanguageId ? "Твое новое сообщение":"Your new message", szBuffer);
			}
		}
	}
	
	return Plugin_Handled;
}

public void OnClientCookiesCached(int iClient)
{
	if(!IsClientInGame(iClient) || IsFakeClient(iClient) || !VIP_IsClientVIP(iClient))
	{
		return;
	}
	PrintClientMessage(iClient);
}

public void VIP_OnVIPClientLoaded(int iClient)
{
	if(!AreClientCookiesCached(iClient))
	{
		return;
	}
	PrintClientMessage(iClient);
}

void PrintClientMessage(int iClient)
{
	char szBuffer[256];
	GetClientCookie(iClient, g_hCookie, szBuffer, 256);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			PrintCenterText(i, "[VIP] %N %s %s", iClient, GetClientLanguage(i) == RussianLanguageId ? "Подключился":"Connected", szBuffer);
		}
	}

}