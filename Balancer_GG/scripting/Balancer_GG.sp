#include <sourcemod>

#pragma newdecls required

int Last;

static const char Messages[][] = 
{
	"Вы были перемещены за противоположную команду из-за дисбаланса", 
	"You were moved for the opposite team due to an disbalance"
};

public Plugin myinfo = 
{
    name = "Balancer GG",
    version = "1.0",
	description = "Balancer for GunGame mod",
    author = "hEl",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath, EventHookMode_PostNoCopy);
}

public void OnPlayerDeath(Event hEvent, const char[] name, bool bDontBroadcast)
{
	int iTime = GetTime();
	
	if(iTime - Last <= 10)
		return;
		
	Last = iTime;
	
	int Count[2];
	int[][] Players = new int[2][MaxClients + 1];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			int iTeam = GetClientTeam(i) - 2;
			if(iTeam > -1)
			{
				Players[iTeam][Count[iTeam]++] = i;
			}
		}
	}
	int iBiggerTeam, iSmallerTeam;
	
	if(Count[0] > Count[1] + 1)
	{
		iBiggerTeam = 0;
		iSmallerTeam = 1;
	}
	else if(Count[1] > Count[0] + 1)
	{
		iBiggerTeam = 1;
		iSmallerTeam = 0;
	}
	else
	{
		return;
	}
	while(Count[iBiggerTeam] > Count[iSmallerTeam] + 1)
	{
		int iIndex = GetRandomInt(0, --Count[iBiggerTeam]);
		ChangeClientTeam(Players[iBiggerTeam][iIndex], iSmallerTeam + 2);
		
		SendClientMessage(Players[iBiggerTeam][iIndex]);
		
		for(int i = iIndex; i < Count[iBiggerTeam]; i++)
		{
			Players[iBiggerTeam][i] = Players[iBiggerTeam][i + 1];
		}
		Count[iSmallerTeam]++;
	}
	
}

void SendClientMessage(int iClient)
{
	if(IsFakeClient(iClient))
		return;
		
	char szBuffer[8];
	GetLanguageInfo(GetClientLanguage(iClient), szBuffer, 8);
	int iId = !strcmp(szBuffer, "ru", false) ? 0:1;
	for(int i; i < 3; i++)
	{
		PrintToChat(iClient, "[SM] %s", Messages[iId]);
	}
}
