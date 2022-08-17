#include <sourcemod>

#pragma newdecls required

const int MAX_STEAMIDS = 50;

bool Hook;

int SteamIDs, SteamID[MAX_STEAMIDS], ID[MAXPLAYERS + 1] = {-1, ...};

char Buffer[2048], Path[256];

public Plugin myinfo = 
{
    name = "Cmd Listener",
    version = "1.0",
	description = "Log commands that use some players in list",
    author = "hEl",
	url = ""
};

public void OnPluginStart()
{
	char szBuffer[256];
	BuildPath(Path_SM, Path, 256, "logs/command_listener.log");
	BuildPath(Path_SM, szBuffer, 256, "configs/command_listener.txt");
	File hFile = OpenFile(szBuffer, "r");
	if(hFile)
	{
		
		while (!IsEndOfFile(hFile) && SteamIDs < MAX_STEAMIDS)
		{
			if (!ReadFileLine(hFile, szBuffer, 256))
				break;
			
			if(TrimString(szBuffer) > 0)
			{
				SteamID[SteamIDs++] = StringToInt(szBuffer);
			}
		}
	}
	else
	{
		SetFailState("Config file \"%s\" not founded.", szBuffer);
	}
	
	delete hFile;
	
	if(SteamIDs == 0)
	{
		SetFailState("No one player listen.", szBuffer);
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnPluginEnd()
{
	LogCommands();
}

public void OnMapEnd()
{
	LogCommands();
}

public void OnClientPutInServer(int iClient)
{
	if(!IsFakeClient(iClient))
	{
		int iSteamID = GetSteamAccountID(iClient, true);
		
		for(int i; i < SteamIDs; i++)
		{
			if(iSteamID == SteamID[i])
			{
				LogToFile(Path, "%N (Steam = %i, id = %i) connected.", iClient, SteamID[i], i);
				ID[iClient] = i;
				ToggleHook(true);
				return;
			}
		}
	}
}

public void OnClientDisconnect(int iClient)
{
	if(ID[iClient] != -1)
	{
		ID[iClient] = -1;
		
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(ID[i] != -1)
			{
				return;
			}
		}
		
		ToggleHook(false);
		
	}
}

bool ToggleHook(bool bToggle)
{
	if(Hook != bToggle)
	{
		if(bToggle)
		{
			AddCommandListener(OnListenCommand, "");
		}
		else
		{

			LogCommands();
			RemoveCommandListener(OnListenCommand, "");
		}
		
		Hook = bToggle;
	}

}

public Action OnListenCommand(int client, const char[] command, int argc)
{
	if(ID[client] != -1)
	{
		if(strlen(Buffer) + strlen(command) + 80 >= 1024)
		{
			LogToFile(Path, Buffer);
			Buffer[0] = 0;
		}
		else if(!Buffer[0])
		{
			FormatEx(Buffer, 1024, "%N (%i): %s", client, ID[client], command);
		}
		else
		{
			Format(Buffer, 1024, "%s\n%N (%i): %s", Buffer, client, ID[client], command);
			
		}
	}
}

void LogCommands()
{
	if(Buffer[0])
	{
		LogToFile(Path, Buffer);
		Buffer[0] = 0;
	}
}