#include <cstrike>

#pragma newdecls required

public Plugin myinfo = 
{
    name = "Balancer",
    version = "1.0",
    author = "hEl",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
}

public void OnRoundStart(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iCount[2];
	int[][] Players = new int[2][MaxClients + 1];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			int iTeam = GetClientTeam(i) - 2;
			if(iTeam >= 0)
			{
				Players[iTeam][iCount[iTeam]++] = i;
			}

		}
	}
	
	int iBiggerTeam = -1, iSmallerTeam = -1;
	
	if(iCount[0] > iCount[1] + 1)
	{
		iBiggerTeam = 0; iSmallerTeam = 1;
	}
	else if(iCount[1] > iCount[0] + 1)
	{
		iBiggerTeam = 1; iSmallerTeam = 0;
	}
	
	if(iBiggerTeam == -1 || iSmallerTeam == -1)
		return;
	
	
	while(iCount[iBiggerTeam] > iCount[iSmallerTeam] + 1)
	{
		int iIndex = GetRandomInt(0, --iCount[iBiggerTeam]);
		CS_SwitchTeam(Players[iBiggerTeam][iIndex], iSmallerTeam + 2);
		
		for(int i = iIndex; i < iCount[iBiggerTeam]; i++)
		{
			Players[iBiggerTeam][i] = Players[iBiggerTeam][i + 1];
		}
		iCount[iSmallerTeam]++;
	}
}