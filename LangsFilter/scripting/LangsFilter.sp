#include <sourcemod>

#pragma newdecls required

const int MAX_LANGUAGES = 32;

int Langages, ClientLanguage[MAXPLAYERS + 1] = {-1, ...};
char Code[MAX_LANGUAGES][16], Pattern[MAX_LANGUAGES][16];

public Plugin myinfo = 
{
	name		= "Langs Filter",
	version		= "1.0",
	description	= "",
	author		= "hEl"
}

public void OnPluginStart()
{
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, 256, "configs/langsfilter.cfg");
	KeyValues hKeyValues = new KeyValues("LangsFilter");
	
	if(!hKeyValues.ImportFromFile(szBuffer) || !hKeyValues.GotoFirstSubKey(false))
	{
		SetFailState("Config file \"%s\" doesnt exist...", szBuffer);
	}
	
	do
	{
		hKeyValues.GetString(NULL_STRING, szBuffer, 256);
		
		int Symbol = FindCharInString(szBuffer, ':');
		
		if(Symbol != -1)
		{
			char szName[64];
			hKeyValues.GetSectionName(szName, 64);
			strcopy(Code[Langages], 16, szBuffer[Symbol + 1]);	szBuffer[Symbol] = 0;
			strcopy(Pattern[Langages], 16, szBuffer);
			AddMultiTargetFilter(Pattern[Langages], OnLangFilter, szName, false);
			Langages++;
		}
		
	}
	while (hKeyValues.GotoNextKey(false) && Langages < MAX_LANGUAGES);
	delete hKeyValues;
	
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
	for(int i; i < Langages; i++)
	{
		RemoveMultiTargetFilter(Pattern[i], OnLangFilter);
	}
}

public bool OnLangFilter(const char[] pattern, ArrayList clients)
{
	for(int i; i < Langages; i++)
	{
		if(!strcmp(pattern, Pattern[i], false))
		{
			for(int j = 1; j <= MaxClients; j++)
			{
				if(ClientLanguage[j] == i)
				{
					clients.Push(j);
				}
			}
			return true;
		}
	}
	return false;
}

public void OnClientPutInServer(int iClient)
{
	if(Langages && !IsFakeClient(iClient))
	{
		char code[16];
		GetLanguageInfo(GetClientLanguage(iClient), code, 16);
		
		ClientLanguage[iClient] = GetLanguageId(code);
	}
}

public void OnClientDisconnect(int iClient)
{
	ClientLanguage[iClient] = -1;
}

int GetLanguageId(const char[] code)
{
	for(int i; i < Langages; i++)
	{
		if(!strcmp(code, Code[i], false))
		{
			return i;
		}
	}
	
	return -1;
}