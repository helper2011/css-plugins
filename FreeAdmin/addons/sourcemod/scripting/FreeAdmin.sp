#include <sourcemod>

#pragma newdecls required

public Plugin myinfo = 
{
	name		= "FreeAdmin",
	version		= "1.0",
	description	= "",
	author		= "hEl"
};

public void OnPluginStart()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
}

public void OnClientPostAdminCheck(int iClient)
{
	int iSteamID = GetSteamAccountID(iClient);
	
	if(iSteamID <= 0 || GetUserAdmin(iClient) != INVALID_ADMIN_ID)
	{
		return;
	}
	
	AdminId AID = CreateAdmin();
	SetAdminFlag(AID, Admin_Generic, true);
	SetAdminFlag(AID, Admin_Custom1, true);
	SetUserAdmin(iClient, AID, true);
	
	FakeClientCommand(iClient, "sm_admin");
}