#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

public Plugin myinfo =
{
	name = "Advanced Targeting [Lite]",
	author = "BotoX + Obus",
	description = "Adds extra targeting methods",
	version = "1.3"
}

public void OnPluginStart()
{
	AddMultiTargetFilter("@admins", Filter_Admin, "Admins", false);
	AddMultiTargetFilter("@random", Filter_Random, "a Random Player", false);
	AddMultiTargetFilter("@randomct", Filter_RandomCT, "a Random CT", false);
	AddMultiTargetFilter("@randomt", Filter_RandomT, "a Random T", false);
	AddMultiTargetFilter("@alivect", Filter_AliveCT, "Alive Humans", false);
	AddMultiTargetFilter("@alivet", Filter_AliveT, "Alive Zombies", false);

	RegConsoleCmd("sm_admins", Command_Admins, "Currently online admins.");

}

public void OnPluginEnd()
{
	RemoveMultiTargetFilter("@admins", Filter_Admin);
	RemoveMultiTargetFilter("@random", Filter_Random);
	RemoveMultiTargetFilter("@randomct", Filter_RandomCT);
	RemoveMultiTargetFilter("@randomt", Filter_RandomT);
	RemoveMultiTargetFilter("@alivect", Filter_AliveCT);
	RemoveMultiTargetFilter("@alivet", Filter_AliveT);
}


public Action Command_Admins(int client, int args)
{
	char aBuf[1024];
	char aBuf2[MAX_NAME_LENGTH];
	int iFlags;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && ((iFlags = GetUserFlagBits(i)) & ADMFLAG_GENERIC || iFlags & ADMFLAG_ROOT))
		{
			GetClientName(i, aBuf2, sizeof(aBuf2));
			StrCat(aBuf, sizeof(aBuf), aBuf2);
			StrCat(aBuf, sizeof(aBuf), ", ");
		}
	}

	if(strlen(aBuf))
	{
		aBuf[strlen(aBuf) - 2] = 0;
		ReplyToCommand(client, "[SM] Admins currently online: %s", aBuf);
	}
	else
		ReplyToCommand(client, "[SM] Admins currently online: none");

	return Plugin_Handled;
}


public bool Filter_Admin(const char[] sPattern, ArrayList hClients)
{
	int iFlags;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && ((iFlags = GetUserFlagBits(i)) & ADMFLAG_GENERIC || iFlags & ADMFLAG_ROOT))
		{
			hClients.Push(i);
		}
	}

	return true;
}

public bool Filter_AliveCT(const char[] sPattern, ArrayList hClients)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
		{
			hClients.Push(i);
		}
	}

	return true;
}

public bool Filter_AliveT(const char[] sPattern, ArrayList hClients)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			hClients.Push(i);
		}
	}

	return true;
}

public bool Filter_Random(const char[] sPattern, ArrayList hClients)
{
	int iClient = GetRandomAliveClient();
	
	if(iClient != -1)
	{
		hClients.Push(iClient);
		return true;
	}
	
	return false;
}

public bool Filter_RandomCT(const char[] sPattern, ArrayList hClients)
{
	int iClient = GetRandomAliveClient(3);
	
	if(iClient != -1)
	{
		hClients.Push(iClient);
		return true;
	}
	
	return false;
}

public bool Filter_RandomT(const char[] sPattern, ArrayList hClients)
{
	int iClient = GetRandomAliveClient(2);
	
	if(iClient != -1)
	{
		hClients.Push(iClient);
		return true;
	}
	
	return false;
}

int GetRandomAliveClient(int iTeam = -1)
{
	int iCount = -1;
	int[] Clients = new int[MaxClients];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && (iTeam == -1 || GetClientTeam(i) == iTeam))
		{
			Clients[++iCount] = i;
		}
	}
	
	return iCount != -1 ? Clients[GetRandomInt(0, iCount)]:-1;
}