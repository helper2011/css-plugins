#include <sourcemod>
#include <clientprefs>
#include <vip_core>

#pragma newdecls required

Handle g_hCookie;
bool Input[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name		= "[VIP] Connect Message",
	version		= "1.0",
	author		= "hEl"
}

public void OnPluginStart()
{
	g_hCookie = RegClientCookie("VIP_ConnectMessage", "", CookieAccess_Private);
	
	RegConsoleCmd("sm_joinmsg", Command_JoinMsg);
}

public Action Command_JoinMsg(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient) && VIP_IsClientVIP(iClient))
	{
		Input[iClient] = true;
		
		PrintHintText(iClient, "[VIP] Connect Message\n%s", GetClientLanguage(iClient) == 22 ? "Теперь напиши в чат желаемое сообщение при входе (cancel = отмена)":"Type the desired message in chat (cancel to interrupt)");
	}
	
	return Plugin_Handled;
}

public Action OnClientSayCommand(int iClient, const char[] command, const char[] sArgs)
{
	if(Input[iClient])
	{
		if(strcmp(sArgs, "cancel", false))
		{
			SetClientCookie(iClient, g_hCookie, sArgs);
			PrintHintText(iClient, "[VIP] Connect Message\n%s", GetClientLanguage(iClient) == 22 ? "Вы успешно установили сообщение!":"You have successfully changed the message when connecting");
		}
		
		Input[iClient] = false;
		
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void VIP_OnVIPClientLoaded(int iClient)
{
	char szBuffer[256];
	GetClientCookie(iClient, g_hCookie, szBuffer, 256);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			PrintCenterText(i, "[VIP] %N %s %s", iClient, GetClientLanguage(i) == 22 ? "Подключился":"Connected", szBuffer);
		}
	}
}

public void OnClientDisconnect(int iClient)
{
	Input[iClient] = false;
}

