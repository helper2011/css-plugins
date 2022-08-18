#include <sourcemod>
#include <sdktools_functions>

#pragma newdecls required

const int MAX_COMMANDS = 8;
const int MAX_CHECKPOINTS = 20;

float	CheckPoint[MAX_CHECKPOINTS][3];
int		CheckPoints,
		Commands[MAX_CHECKPOINTS];
char	Title[MAX_CHECKPOINTS][32],
		Command[MAX_CHECKPOINTS][MAX_COMMANDS][32];
		
		
public Plugin myinfo = 
{
    name = "Check Points",
    version = "1.0",
	description = "",
    author = "hEl",
	url = ""
};
		

public void OnPluginStart()
{
	RegAdminCmd("sm_cp",				Command_CheckPoints, 	ADMFLAG_ROOT);
	RegAdminCmd("sm_checkpoints",		Command_CheckPoints, 	ADMFLAG_ROOT);
	RegAdminCmd("sm_savecp",			Command_SaveCheckPoint,	ADMFLAG_ROOT);

}

public Action Command_CheckPoints(int iClient, int iArgs)
{
	if(!iArgs && CheckPoints > 0)
	{
		CheckPointsMenu(iClient);
	}
	
	return Plugin_Handled;
}

void CheckPointsMenu(int iClient, int iItem = 0)
{
	char szBuffer[256];
	Menu hMenu = new Menu(CheckPointsMenuHandler);
	hMenu.SetTitle("CheckPoints");
	for(int i; i < CheckPoints; i++)
	{
		FormatEx(szBuffer, 256, "!%s", Command[i][0]);
		for(int j = 1; j < Commands[i]; j++)
		{
			Format(szBuffer, 256, "%s, !%s", szBuffer, Command[i][j]);
		}
		Format(szBuffer, 256, "%s\n· %s", Title[i], szBuffer);
		hMenu.AddItem("", szBuffer);
	}
	hMenu.DisplayAt(iClient, iItem, 0);
}

public int CheckPointsMenuHandler(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	if(action == MenuAction_End)
	{
		delete hMenu;
	}
	else if(action == MenuAction_Select)
	{
		CP_TeleportToPoint(iClient, iItem);
		CheckPointsMenu(iClient, hMenu.Selection);
	}
	return 0;
}

public Action Command_SaveCheckPoint(int iClient, int iArgs)
{
	if(iArgs == 1)
	{
		char szBuffer[2][256]; float fPos[3];
		GetClientAbsOrigin(iClient, fPos);
		KeyValues hKeyValues = view_as<KeyValues>(LoadARConfig(szBuffer[0], 256, true));
		GetCmdArg(1, szBuffer[1], 256);
		
		hKeyValues.SetVector(szBuffer[1], fPos);
		hKeyValues.Rewind();
		hKeyValues.ExportToFile(szBuffer[0]);
		delete hKeyValues;
		OnMapStart();
	}
	
	return Plugin_Handled;
}

public void OnMapStart()
{
	for(int i; i < CheckPoints; i++)
	{
		for(int j; j < Commands[i]; j++)
		{
			RemoveCommandListener(OnCPCommand, Command[i][j]);
		}
		Commands[i] = 0;
	}
	CheckPoints = 0;
	char szBuffer[256];
	KeyValues hKeyValues = view_as<KeyValues>(LoadARConfig(szBuffer, 256));
	if(hKeyValues && hKeyValues.GotoFirstSubKey(false))
	{
		do
		{
			Commands[CheckPoints] = 0;
			hKeyValues.GetSectionName(szBuffer, 256);
			hKeyValues.GetVector(NULL_STRING, CheckPoint[CheckPoints]);
			
			int iSymbol; bool bTitle;
			while((iSymbol = FindCharInString(szBuffer, ',', true)) != -1 || (bTitle = ((iSymbol = FindCharInString(szBuffer, ':')) != -1)))
			{
				if(Commands[CheckPoints] < MAX_COMMANDS && AddCommandListener(OnCPCommand, szBuffer[iSymbol + 1]))
				{
					strcopy(Command[CheckPoints][Commands[CheckPoints]++], 32, szBuffer[iSymbol + 1]);
				}
				szBuffer[iSymbol] = 0;
				
				if(bTitle)
					strcopy(Title[CheckPoints], 32, szBuffer);
			}
			
			CheckPoints++;
		}
		while(hKeyValues.GotoNextKey(false) && CheckPoints < MAX_CHECKPOINTS);
		delete hKeyValues;
	}
	
}

public Action OnCPCommand(int iClient, const char[] command, int iArgs)
{
	CheckCommand(iClient, command);
	return Plugin_Handled;
}

Handle LoadARConfig(char[] szBuffer, int iSize, bool bAutoCreate = false)
{
	char szMap[64];
	GetCurrentMap(szMap, 64);
	KeyValues hKeyValues = new KeyValues("CheckPoints");
	BuildPath(Path_SM, szBuffer, iSize, "configs/checkpoints.cfg");
	hKeyValues.ImportFromFile(szBuffer);
	if(!hKeyValues.JumpToKey(szMap, bAutoCreate))
	{
		delete hKeyValues;
		return null;
	}
	return hKeyValues;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	return (sArgs[0] == '/' && CheckCommand(client, sArgs[1])) ? Plugin_Handled:Plugin_Continue;
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if(sArgs[0] == '!')
	{
		CheckCommand(client, sArgs[1]);
	}
}

bool CheckCommand(int iClient, const char[] command)
{
	int iIndex = CP_FindCommand(command);
	if(iIndex != -1)
	{
		CP_TeleportToPoint(iClient, iIndex);
		return true;
	}
	
	return false;
}

int CP_FindCommand(const char[] command)
{
	for(int i; i < CheckPoints; i++)
	{
		for(int j; j < Commands[i]; j++)
		{
			if(strcmp(command, Command[i][j], false) == 0)
			{
				return i;
			}
		}
	}
	
	return -1;
}

void CP_TeleportToPoint(int iClient, int iId)
{
	TeleportEntity(iClient, CheckPoint[iId], NULL_VECTOR, NULL_VECTOR);
	PrintToChatAll("[CheckPoints] %N teleported to %s", iClient, Title[iId]);
}
