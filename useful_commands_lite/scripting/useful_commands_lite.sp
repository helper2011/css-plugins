#pragma newdecls required

const int MAX_COMMANDS = 25;

int		Commands;
char	Command[MAX_COMMANDS][64];

public Plugin myinfo = 
{
	name		= "Useful Commands",
	version		= "1.0",
	author		= "hEl"
}

public void OnPluginStart()
{
	LoadConfig();
	LoadTranslations("useful_commands.phrases");
	RegConsoleCmd("uc", Command_UsefulCommands);
}

public Action Command_UsefulCommands(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient))
	{
		UsefulCommandsMenu(iClient);
	}
	return Plugin_Handled;
}

void LoadConfig()
{
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, 256, "configs/useful_commands.txt");
	File hFile = OpenFile(szBuffer, "r");
	if(hFile)
	{
		while (!IsEndOfFile(hFile) && Commands < MAX_COMMANDS)
		{
			if (!ReadFileLine(hFile, szBuffer, 256))
				break;
			
			if(TrimString(szBuffer) > 0)
			{
				strcopy(Command[Commands++], 64, szBuffer);
			}
		}
	}
	else
	{
		SetFailState("Config file \"%s\" does exists...", szBuffer);
	}
	delete hFile;
}

void UsefulCommandsMenu(int iClient, int iItem = 0)
{
	char szBuffer[256];
	SetGlobalTransTarget(iClient);
	Menu hMenu = new Menu(UsefulCommandsMenu_Handler);
	hMenu.SetTitle("%t", "Useful commands menu title");
	
	for(int i; i < Commands; i++)
	{
		FormatEx(szBuffer, 256, "%t", Command[i]);
		hMenu.AddItem("", szBuffer);
	}
	
	hMenu.DisplayAt(iClient, iItem, 0);
}

public int UsefulCommandsMenu_Handler(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete hMenu;
		}
		case MenuAction_Select:
		{
			UsefulCommandsMenu(iClient, hMenu.Selection);
			FakeClientCommand(iClient, Command[iItem]);
		}
	}
	
	return -1;
}