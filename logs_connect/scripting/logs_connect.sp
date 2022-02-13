#include <sourcemod>

#pragma newdecls required

File LogFile;

public Plugin myinfo =
{
	name = "Connect/Disconnect Logging",
	author = "Maxim EPacker2 Kharin [Edited]",
	version = "1.1",
};

public void OnPluginStart()
{
	BuildLogFilePath();
	
	HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);
}

void BuildLogFilePath()
{
	char szBuffer[256];
	FormatTime(szBuffer, 367, "logs/connects_%Y-%m-%d.log");
	BuildPath(Path_SM, szBuffer, 256, szBuffer);
	if((LogFile = OpenFile(szBuffer, "w+")) == null)
	{
		SetFailState("Cant create/open \"%s\"", szBuffer);
	}
}

public void OnClientAuthorized(int iClient)
{
	if (iClient > 0 && !IsFakeClient(iClient))
	{
		char szIp[16];
		GetClientIP(iClient, szIp, 16);
		LogToOpenFile(LogFile, "Connect: %L, %s", iClient, szIp);
	}
}

public void OnPlayerDisconnect(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
	if (iClient > 0 && !IsFakeClient(iClient))
	{
		char szReason[256], szIp[16];
		GetClientIP(iClient, szIp, 16);
		hEvent.GetString("reason", szReason, 256);
		LogToOpenFile(LogFile, "Disconnect: %L, %s (%s)", iClient, szIp, szReason);
	}
}