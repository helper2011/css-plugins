#include <sourcemod>

#pragma newdecls required

const int MAX_FILE_LINES = 20;

char ConsoleMessage[MAX_FILE_LINES][1024];

public Plugin myinfo = 
{
	name = "Console Welcome Message",
	author = "hEl",
	version = "1.0"
}

public void OnPluginStart()
{
	LoadWelcomeMessage();
}

void LoadWelcomeMessage()
{
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, 256, "configs/console_welcome_message.cfg");
	
	File hFile = OpenFile(szBuffer, "rt");
	if (!hFile)
	{
		SetFailState("Config file \"%s\" not founded", szBuffer);
		return;
	}
	
	int iCount;
	while (!hFile.EndOfFile() && hFile.ReadLine(szBuffer, 256) && iCount < MAX_FILE_LINES)
	{
		ConsoleMessage[iCount++] = szBuffer;
	}
	
	delete hFile;
}

public void OnClientPutInServer(int iClient)
{
	if(IsFakeClient(iClient))
	{
		return;
	}
	
	int i;
	while(i < MAX_FILE_LINES && ConsoleMessage[i][0])
	{
		PrintToConsole(iClient, ConsoleMessage[i++]);
	}
}
