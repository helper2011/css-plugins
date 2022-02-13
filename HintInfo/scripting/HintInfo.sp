#include <sourcemod>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#include <entWatch_Sg>
#define REQUIRE_PLUGIN

#pragma newdecls required

enum
{
	RUSSIAN,
	ENGLISH,
	GERMAN,
	FRENCH,
	SPANISH,
	HUNGARY,

	LANGUAGES_TOTAL
}

const int MAX_COMMANDS = 10;
const int DEFAULT_LANGUAGE = ENGLISH;

static const char Languages[][] = {"ru", "en", "de", "fr", "es", "hu"};

int Commands, Language[MAXPLAYERS + 1];

char Title[LANGUAGES_TOTAL][128], CookieNotLoaded[LANGUAGES_TOTAL][128], Command[MAX_COMMANDS][16], Description[MAX_COMMANDS][LANGUAGES_TOTAL][64];

Handle Timer, g_hCookie;
bool Toggle, Disabled[MAXPLAYERS + 1], entWatch;

public Plugin myinfo = 
{
	name		= "Hint Info",
	version		= "1.0",
	description	= "",
	author		= "hEl"
};

public void OnPluginStart()
{
	LoadConfigFile();
	LoadTranslations("common.phrases");
	g_hCookie = RegClientCookie("ShowHintInfo", "", CookieAccess_Private);
	RegConsoleCmd("sm_info", Command_Info);
	SetCookieMenuItem(HintInfoMenuHandler, 0, "Hint info");
	
	entWatch = LibraryExists("entWatch_Sg");
	
	Toggle = (!entWatch || !entWatch_GetItems());
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
			
			if(AreClientCookiesCached(i))
			{
				OnClientCookiesCached(i);
			}
		}
	}
}

void LoadConfigFile()
{
	char szBuffer[256];
	KeyValues hKeyValues = new KeyValues("HintInfo");
	BuildPath(Path_SM, szBuffer, 256, "configs/HintInfo.cfg");
	
	if(!hKeyValues.ImportFromFile(szBuffer) || !hKeyValues.GotoFirstSubKey())
	{
		SetFailState("Config file \"%s\" not founded", szBuffer);
	}
	
	do
	{
		hKeyValues.GetSectionName(Command[Commands], 16);
		
		int iMode;
		
		if(!strcmp(Command[Commands], "Title", false))
		{
			iMode = 1;
		}
		else if(!strcmp(Command[Commands], "Cookie", false))
		{
			iMode = 2;
		}

		if(hKeyValues.GotoFirstSubKey(false))
		{
			do
			{
				
				hKeyValues.GetSectionName(szBuffer, 8);
				int iLanguage = GetLanguageId(szBuffer);
				
				switch(iMode)
				{
					case 0: hKeyValues.GetString(NULL_STRING, Description[Commands][iLanguage], 64);
					case 1: hKeyValues.GetString(NULL_STRING, Title[iLanguage], 128);
					case 2: hKeyValues.GetString(NULL_STRING, CookieNotLoaded[iLanguage], 128);
				}
				
			}
			while(hKeyValues.GotoNextKey(false));
			hKeyValues.GoBack();
			
			if(!iMode)
			{
				Commands++;
			}
			
		}
		
	}
	while(hKeyValues.GotoNextKey() && Commands < MAX_COMMANDS);
	
	delete hKeyValues;
}

public void entWatch_OnConfigLoaded()
{
	Toggle = false;
}

public void HintInfoMenuHandler(int iClient, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlen, "%s: %T", Title[Title[Language[iClient]][0] ? Language[iClient]:DEFAULT_LANGUAGE], Disabled[iClient] ? "Off":"On", iClient);
		}
		case CookieMenuAction_SelectOption:
		{
			SetClientCookieBool(iClient);
			ShowCookieMenu(iClient);
		}
	}
}

public Action Command_Info(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient))
	{
		if(AreClientCookiesCached(iClient))
		{
			SetClientCookieBool(iClient);
			PrintHintText(iClient, "%s: %T", Title[Title[Language[iClient]][0] ? Language[iClient]:DEFAULT_LANGUAGE], Disabled[iClient] ? "Off":"On", iClient);
		}
		else
		{
			PrintHintText(iClient, "%s", CookieNotLoaded[CookieNotLoaded[Language[iClient]][0] ? Language[iClient]:DEFAULT_LANGUAGE], iClient);
		}
	}
	
	return Plugin_Handled;
}

public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "entWatch_Sg", false))
	{
		entWatch = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if(!strcmp(name, "entWatch_Sg", false))
	{
		entWatch = false;
		Toggle = true;
	}
}

public void OnMapEnd()
{
	Toggle = true;
	ToggleTimer(false);
}

public void OnClientPutInServer(int iClient)
{
	if(!IsFakeClient(iClient))
	{
		char szBuffer[8];
		GetLanguageInfo(GetClientLanguage(iClient), szBuffer, 8);
		Language[iClient] = GetLanguageId(szBuffer);
	}
}

public void OnClientCookiesCached(int iClient)
{
	Disabled[iClient] = !IsFakeClient(iClient) ? GetClientCookieBool(iClient):true;
	
	if(!Disabled[iClient])
	{
		ToggleTimer(true);
	}
}

public void OnClientDisconnect(int iClient)
{
	Disabled[iClient] = false;
}

bool GetClientCookieBool(int iClient)
{
	char szBuffer[4];
	GetClientCookie(iClient, g_hCookie, szBuffer, 4);
	return szBuffer[0] ? view_as<bool>(StringToInt(szBuffer)):false;
}

void SetClientCookieBool(int iClient)
{
	Disabled[iClient] = !Disabled[iClient];
	SetClientCookie(iClient, g_hCookie, Disabled[iClient] ? "1":"0");
	
	if(!Disabled[iClient])
	{
		ToggleTimer(true);
	}
}

void ToggleTimer(bool bToggle)
{
	if(!Toggle)
	{
		return;
	}
	if(!bToggle)
	{
		delete Timer;
	}
	else if(!Timer)
	{
		Timer = CreateTimer(5.0, Timer_ShowHintInfo, _, TIMER_REPEAT);
	}
}

public Action Timer_ShowHintInfo(Handle hTimer)
{	
	if(!Toggle)
	{
		Timer = null;
		return Plugin_Stop;
	}
	int iCount;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !Disabled[i])
		{
			ShowClientHintInfo(i);
			iCount++;
		}
	}
	
	if(iCount == 0)
	{
		Timer = null;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

void ShowClientHintInfo(int iClient)
{
	int iCount;
	char szBuffer[1024];
	SetGlobalTransTarget(iClient);
	for(int i; i < Commands; i++)
	{
		if(Description[i][Language[iClient]][0])
		{
			if(!iCount)
			{
				FormatEx(szBuffer, 1024, "%s - %s", Command[i], Description[i][Description[i][Language[iClient]][0] ? Language[iClient]:DEFAULT_LANGUAGE]);
			}
			else
			{
				Format(szBuffer, 1024, "%s\n%s - %s", szBuffer, Command[i], Description[i][Description[i][Language[iClient]][0] ? Language[iClient]:DEFAULT_LANGUAGE]);
			}
			iCount++;
		}
		
	}
	
	if(iCount == 0)
	{
		return;
	}
	Handle hBuffer = StartMessageOne("KeyHintText", iClient);
	BfWriteByte(hBuffer, 1);
	BfWriteString(hBuffer, szBuffer);
	EndMessage();
}

int GetLanguageId(const char[] code)
{
	for(int i; i < LANGUAGES_TOTAL; i++)
	{
		if(!strcmp(code, Languages[i], false))
		{
			return i;
		}
	}
	
	return DEFAULT_LANGUAGE;
}