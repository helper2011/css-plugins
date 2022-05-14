#include <sourcemod>

#pragma newdecls required

Menu g_hMenu;

public Plugin myinfo = 
{
	name		= "Help",
	version		= "1.0",
	author		= "hEl"
}

public void OnPluginStart()
{
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, 256, "configs/sm_help.txt");
	File hFile = OpenFile(szBuffer, "r");
	if(hFile)
	{
		g_hMenu = new Menu(MenuH, MenuAction_Display | MenuAction_DisplayItem | MenuAction_Select);
		while (!hFile.EndOfFile())
		{
			if (!ReadFileLine(hFile, szBuffer, 256))
				break;
			
			if(TrimString(szBuffer) > 0)
			{
				g_hMenu.AddItem(szBuffer, "");
			}
		}
		delete hFile;
	}
	else
	{
		SetFailState("Config file \"%s\" does exists...", szBuffer);
	}
	
	LoadTranslations("sm_help.phrases");
	RegConsoleCmd("sm_help", Command_Help);
}

public Action Command_Help(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient))
	{
		g_hMenu.Display(iClient, 0);
	}
	return Plugin_Handled;
}

public int MenuH(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	char szBuffer[256];
	switch(action)
	{
		case MenuAction_Display:
		{
			FormatEx(szBuffer, 256, "%T", "Title", iClient);
			(view_as<Panel>(iItem)).SetTitle(szBuffer);
		}
		case MenuAction_DisplayItem:
		{
			char szItem[32];
			hMenu.GetItem(iItem, szItem, 32);
			FormatEx(szBuffer, 256, "%T", szItem, iClient);
			return RedrawMenuItem(szBuffer);
		}
		case MenuAction_Select:
		{
			g_hMenu.GetItem(iItem, szBuffer, 256);
			g_hMenu.DisplayAt(iClient, hMenu.Selection, 0);
			FakeClientCommand(iClient, szBuffer);
		}
	}
	return -1;
}