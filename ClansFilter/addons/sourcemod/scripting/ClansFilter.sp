#include <sourcemod>

#pragma newdecls required

const int MAX_CLANS = 32;

int Clans, Id[MAX_CLANS], ClientId[MAXPLAYERS + 1];
char Pattern[MAX_CLANS][16];

public Plugin myinfo = 
{
    name = "Clans Filter",
    version = "1.0",
	description = "",
    author = "hEl",
	url = ""
};


public void OnPluginStart()
{
	RegAdminCmd("sm_getclientclan", Command_GetClientClan, ADMFLAG_BAN);
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, 256, "configs/clansfilter.cfg");
	KeyValues hKeyValues = new KeyValues("ClansFilter");
	
	if(!hKeyValues.ImportFromFile(szBuffer) || !hKeyValues.GotoFirstSubKey(false))
	{
		SetFailState("Config file \"%s\" doesnt exist...", szBuffer);
	}
	
	do
	{
		char szClan[64];
		hKeyValues.GetSectionName(szClan, 64);
		hKeyValues.GetString(NULL_STRING, szBuffer, 256);
		
		int Symbol = FindCharInString(szBuffer, ':');
		
		if(Symbol != -1)
		{
			Id[Clans] = StringToInt(szBuffer[Symbol + 1]);
			szBuffer[Symbol] = 0;
			strcopy(Pattern[Clans], 16, szBuffer);
			AddMultiTargetFilter(Pattern[Clans], OnClanFilter, szClan, false);
			Clans++;
		}
		
	}
	while (hKeyValues.GotoNextKey(false) && Clans < MAX_CLANS);
	delete hKeyValues;
	
	if(Clans)
	{
		HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
		
		GetClientsClanId();
	}
}

public void OnPluginEnd()
{
	for(int i; i < Clans; i++)
	{
		RemoveMultiTargetFilter(Pattern[i], OnClanFilter);
	}
}

public bool OnClanFilter(const char[] pattern, ArrayList clients)
{
	for(int i; i < Clans; i++)
	{
		if(!strcmp(pattern, Pattern[i], false))
		{
			for(int j = 1; j <= MaxClients; j++)
			{
				if(Id[i] == ClientId[j])
				{
					clients.Push(j);
				}
			}
			return true;
		}
	}
	return false;
}


public Action Command_GetClientClan(int iClient, int iArgs)
{
	if(iArgs)
	{
		if(iClient)
		{
			char szBuffer[32];
			GetCmdArg(1, szBuffer, 32);
			
			int iTarget = FindTarget(iClient, szBuffer, false, false);
			
			if(iTarget != -1)
			{
				PrintToChat(iClient, "[SM] Clan id %N = %i", iTarget, GetClientClanId(iTarget));
			}
		}
	}
	else
	{
		PrintToChat(iClient, "[SM] Usage: sm_getclientclan <name|userid>");
	}
	
	return Plugin_Handled;
}

public void OnRoundStart(Event hEvent, const char[] event, bool bDontBroadcast)
{
	GetClientsClanId()
}

void GetClientsClanId()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		ClientId[i] = GetClientClanId(i);
	}
}

int GetClientClanId(int iClient)
{
	if(!IsClientInGame(iClient) || IsFakeClient(iClient))
		return 0;
		
	char sClanID[32];
	GetClientInfo(iClient, "cl_clanid", sClanID, 32);
	return StringToInt(sClanID);
}

public void OnClientDisconnect(int iClient)
{
	ClientId[iClient] = 0;
}