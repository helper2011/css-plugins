#include <sourcemod>
#include <sdktools_sound>
#include <sdktools_stringtables>

#pragma newdecls required

ConVar Delay;
Handle Timer;
Menu AdminOverlayMenu;

int Filter[MAXPLAYERS + 1] = {-1, ...};

static const char Filters[][] = 
{
	"@all",
	"@alivect",
	"@alivet",
	"@random",
	"@ct",
	"@t",
	"@spec"
}

public Plugin myinfo = 
{
	name		= "Admin Overlay",
	version		= "1.0",
	description	= "The ability to output an overlay to players",
	author		= "hEl",
	url			= ""
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	char szBuffer[256];
	KeyValues hKeyValues = new KeyValues("Overlays");
	BuildPath(Path_SM, szBuffer, 256, "configs/overlays.cfg");
	if(!hKeyValues.ImportFromFile(szBuffer) || !hKeyValues.GotoFirstSubKey(false))
	{
		SetFailState("Config file  \"%s\" does not exists", szBuffer);
	}
	AdminOverlayMenu = new Menu(MenuHandler, MenuAction_Select | MenuAction_DisplayItem);
	AdminOverlayMenu.SetTitle("Admin Overlay");
	AdminOverlayMenu.AddItem("#", "Filter");
	int iCount;
	char szBuffer2[256];
	do
	{
		hKeyValues.GetSectionName(szBuffer, 256);
		hKeyValues.GetString(NULL_STRING, szBuffer2, 256);
		AdminOverlayMenu.AddItem(szBuffer2, szBuffer);
		
		if(++iCount > 5 && iCount % 6 == 0)
		{
			AdminOverlayMenu.AddItem("#", "Filter");
		}
	}
	while(hKeyValues.GotoNextKey(false));
	delete hKeyValues;
	Delay = CreateConVar("admin_overlay_delay", "5.0");
	RegAdminCmd("sm_overlay", Command_Overlay, ADMFLAG_BAN);
	AutoExecConfig(true, "plugin.AdminOverlay");
}


public void OnMapStart()
{
	char szBuffer[256];
	int iCount = AdminOverlayMenu.ItemCount, iLen;
	
	for(int i; i < iCount; i++)
	{
		AdminOverlayMenu.GetItem(i, szBuffer, 256);
		
		if(szBuffer[0] == '#' || (iLen = strlen(szBuffer)) < 5 || strcmp(szBuffer[iLen - 4], ".vmt", false))
		{
			continue;
		}
		Format(szBuffer, 256, "materials/%s", szBuffer);
		AddFileToDownloadsTable(szBuffer);
		PrecacheModel(szBuffer);
		ReplaceString(szBuffer, 256, ".vmt", ".vtf");
		AddFileToDownloadsTable(szBuffer);
	}
}

public void OnClientDisconnect(int iClient)
{
	Filter[iClient] = -1;
}

public Action Command_Overlay(int iClient, int iArgs)
{
	if(iArgs == 0)
	{
		if(Filter[iClient] == -1)
		{
			Filter[iClient] = 0;
			ReplyToCommand(iClient, "Syntax: sm_overlay <#name|#userid> <overlay name> [delay]");
		}
		AdminOverlayMenu.Display(iClient, 0);
	}
	else if(iArgs < 2)
	{
		ReplyToCommand(iClient, "Syntax: sm_overlay <#name|#userid> <overlay name> [delay]");
	}
	else
	{
		char szFilter[64], szBuffer[64], szBuffer2[64];
		GetCmdArg(1, szFilter, 64);
		GetCmdArg(2, szBuffer, 64);
		
		int iCount = AdminOverlayMenu.ItemCount;
		for(int i; i < iCount; i++)
		{
			AdminOverlayMenu.GetItem(i, "", 0, _, szBuffer2, 64);
			
			if(strncmp(szBuffer, szBuffer2, strlen(szBuffer), false) == 0)
			{
				float fDelay = 0.0;
				if(iArgs > 2)
				{
					GetCmdArg(3, szBuffer, 64);
					fDelay = StringToFloat(szBuffer);
				}
				Overlay(iClient, i, szFilter, fDelay);
				break;
			}
		}
	}
	return Plugin_Handled;
}

public int MenuHandler(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	char szBuffer[256];
	hMenu.GetItem(iItem, szBuffer, 256);
	bool bFilter = (szBuffer[0] == '#');
	switch(action)
	{
		case MenuAction_Select:
		{
			if(bFilter)
			{
				if(++Filter[iClient] >= sizeof(Filters))
				{
					Filter[iClient] = 0;
				}
			}
			else
			{
				Overlay(iClient, iItem, Filters[Filter[iClient]]);
			}
			
			AdminOverlayMenu.DisplayAt(iClient, hMenu.Selection, 0);
		}
		case MenuAction_DisplayItem:
		{
			if(bFilter)
			{
				FormatEx(szBuffer, 256, "[%s]\n ", Filters[Filter[iClient]]);
				return RedrawMenuItem(szBuffer);
			}
		}
	}
	
	return 0;
}

void Overlay(int iClient, int iItem, const char[] szFilter, float fDelay = 0.0)
{
	char sTargetName[256], szOverlay[256], szPath[256];
	int[] iTargets = new int[MaxClients];
	int iTargetCount;
	bool bIsML;

	if((iTargetCount = ProcessTargetString(szFilter, iClient, iTargets, MaxClients, COMMAND_FILTER_NO_BOTS, sTargetName, 256, bIsML)) <= 0)
	{
		ReplyToTargetError(iClient, iTargetCount);
		return;
	}
	AdminOverlayMenu.GetItem(iItem, szPath, 256, _, szOverlay, 256);

	for(int i; i < iTargetCount; i++)
	{
		ClientCommand(iTargets[i], "r_screenoverlay %s", szPath);
	}

	ShowActivity2(iClient, "\x01[SM] \x04", "\x01Show overlay \x04%s\x01 on target \x04%s", szOverlay, sTargetName);
	
	if(!(0.0 < fDelay < 30.0) && (fDelay = Delay.FloatValue) <= 0.0)
	{
		fDelay = 5.0;
	}
	delete Timer;
	Timer = CreateTimer(fDelay, Timer_OffOverlay);
}

public Action Timer_OffOverlay(Handle hTimer)
{
	Timer = null;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			ClientCommand(i, "r_screenoverlay off");
		}
	}
}
