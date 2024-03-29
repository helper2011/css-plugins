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
	HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);
}

public void OnMapStart()
{
	BuildLogFilePath();
}

public void OnMapEnd()
{
	delete LogFile;
}

void BuildLogFilePath()
{
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "logs/connects/");
	if(!DirExists(szBuffer) && !CreateDirectory(szBuffer, 511))
	{
		SetFailState("Cant create directory \"%s\"", szBuffer);
	}
	FormatTime(szBuffer, 367, "logs/connects/connects_%Y-%m-%d.log");
	BuildPath(Path_SM, szBuffer, 256, szBuffer);
	if((LogFile = OpenFile(szBuffer, "a+")) == null)
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