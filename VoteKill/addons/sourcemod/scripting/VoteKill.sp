#include <sourcemod>
#include <sdktools_functions>


#pragma newdecls required

float DeathTime[MAXPLAYERS + 1];
bool Voted[MAXPLAYERS + 1][MAXPLAYERS + 1];

ConVar Log, Ratio, DeathCooldown;

public Plugin myinfo = 
{
    name = "Vote Kill",
    version = "1.0",
    author = "hEl"
};

public void OnPluginStart()
{
	Ratio = CreateConVar("votekill_ratio", "0.3");
	DeathCooldown = CreateConVar("votekill_death_cd", "40.0");
	Log = CreateConVar("votekill_log", "1");
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	RegConsoleCmd("votekill", Command_VoteKill);
}

public void OnRoundStart(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		DeathTime[i] = 0.0;
		ResetClientVotes(i);
	}
}

public void OnPlayerDeath(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	DeathTime[GetClientOfUserId(hEvent.GetInt("userid"))] = GetEngineTime() + DeathCooldown.FloatValue;
}

public Action Command_VoteKill(int iClient, int iArgs)
{
	if(iArgs == 0)
	{
		VoteKillMenu(iClient);
	}
	else
	{
		char szBuffer[64];
		GetCmdArg(1, szBuffer, 64);
		int iTarget = FindTarget(iClient, szBuffer, true, true);
		if(iTarget != -1 && iTarget != iClient && GetUserAdmin(iTarget) != INVALID_ADMIN_ID)
		{
			VoteKill(iClient, iTarget);
		}
	}
	
	return Plugin_Handled;
}

void VoteKillMenu(int iClient)
{
	int iCount;
	int iUserId;
	char szBuffer[32];
	Menu hMenu = new Menu(VoteKillMenuH, MenuAction_End | MenuAction_Select);
	hMenu.SetTitle("VoteKill menu");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || i == iClient || IsFakeClient(i) || GetUserAdmin(i) != INVALID_ADMIN_ID)
		{
			continue;
		}
		iCount++;
		IntToString((iUserId = GetClientUserId(i)), szBuffer, 32);
		AddMenuItem2(hMenu, Voted[i][iClient] ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT, szBuffer, "%N (#%i) [%i/%i]", i, iUserId, GetClientVoted(i), GetNeedVotes());
		
	}
	if(iCount == 0)
	{
		hMenu.AddItem("", "No Players", ITEMDRAW_DISABLED);
	}
	hMenu.Display(iClient, 0);
}

public int VoteKillMenuH(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End:
		{
			if(iItem != MenuEnd_Selected)
			{
				delete hMenu;
			}
		}
		case MenuAction_Select:
		{
			char szBuffer[32];
			hMenu.GetItem(iItem, szBuffer, 32);
			int iTarget = GetClientOfUserId(StringToInt(szBuffer));
			if(iTarget > 0 && IsClientInGame(iTarget))
			{
				VoteKill(iClient, iTarget);
			}
			else
			{
				PrintHintText(iClient, "[VoteKill]\nTarget is unavailbale");
			}

			
			hMenu.DisplayAt(iClient, hMenu.Selection, 0);
		}
	}

	return 0;
}

void VoteKill(int iClient, int iTarget)
{
	if(Voted[iTarget][iClient] || !IsPlayerAlive(iTarget))
		return;
		
	if(!IsPlayerAlive(iClient) && GetClientTeam(iClient) > 1 && DeathTime[iClient])
	{
		float fCD = DeathTime[iClient] - GetEngineTime();
		if(fCD <= 0.0)
		{
			Voted[iTarget][iClient] = true;
			if(!CheckClientVoted(iTarget))
			{
				PrintHintTextToAll("[VoteKill]\n%N -> %N (%i/%i)", iClient, iTarget, GetClientVoted(iTarget), GetNeedVotes());
			}
		}
		else
		{
			PrintHintText(iClient, "[VoteKill]\nWait %.2f sec", fCD);
		}
	}
	else
	{
		PrintHintText(iClient, "[VoteKill]\nOnly for the dead players");
	}
}

public void OnClientDisconnect(int iClient)
{
	ResetClientVotes(iClient);
	ResetClientVoted(iClient);
}

int GetClientVoted(int iClient)
{
	int iCount;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Voted[iClient][i])
		{
			if(!IsPlayerAlive(i))
			{
				iCount++;
			}
			else
			{
				Voted[iClient][i] = false;
			}
			
		}
	}
	
	return iCount;
}

bool CheckClientVoted(int iClient)
{
	if(GetClientVoted(iClient) >= GetNeedVotes())
	{
		if(Log.BoolValue)
		{
			char szBuffer[1024], szBuffer2[256];
			for(int i = 1; i <= MaxClients; i++)
			{
				if(Voted[iClient][i])
				{
					GetClientName(i, szBuffer2, 256);
					StrCat(szBuffer, 1024, szBuffer2);
					StrCat(szBuffer, 1024, ", ");
				}
			}
			int iLen = strlen(szBuffer);
			if(iLen > 0)
			{
				szBuffer[iLen - 2] = 0;
				LogMessage("%s voted for kill %N", szBuffer, iClient);
			}
		}
		ResetClientVoted(iClient);
		ForcePlayerSuicide(iClient);
		PrintHintTextToAll("[VoteKill]\nSuccessfull!");
		return true;
	}
	return false;
}

int GetNeedVotes()
{
	return RoundToNearest(float(GetClientCount2()) * Ratio.FloatValue)
}

int GetClientCount2()
{
	int iCount;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			iCount++;
		}
	}
	return iCount;
}

void ResetClientVotes(int iClient)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		Voted[i][iClient] = false;
	}
}

void ResetClientVoted(int iClient)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		Voted[iClient][i] = false;
	}
}


void AddMenuItem2(Menu hMenu, int style = ITEMDRAW_DEFAULT, const char[] buffer, const char[] format, any ...)
{
	int iLen = strlen(format) + 255;
	char[] szBuffer = new char[iLen];
	VFormat(szBuffer, iLen, format, 5);
	
	hMenu.AddItem(buffer, szBuffer, style);
}