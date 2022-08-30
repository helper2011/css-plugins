#include <sourcemod>
#include <vip_core>
#include <sourcebanspp>

#pragma newdecls required

bool Loaded[MAXPLAYERS + 1];
ConVar cvarToggle, cvarVIPGroup, cvarBlockPostAdminCheck;

public void OnPluginStart()
{
	cvarToggle = CreateConVar("vip_free", "0");
	cvarVIPGroup = CreateConVar("vip_free_group", "vip_free");
	cvarBlockPostAdminCheck = CreateConVar("vip_free_auth_block", "1");
	AutoExecConfig(true, "plugin.FreeVIP", "vip");
}

public Action OnClientPreAdminCheck(int iClient)
{
	//PrintToConsoleAll("OnClientPreAdminCheck: %N (T = %b, B = %b, L %b)", iClient, cvarToggle.BoolValue, cvarBlockPostAdminCheck.BoolValue, Loaded[iClient]);
	return (cvarToggle.BoolValue && cvarBlockPostAdminCheck.BoolValue && !Loaded[iClient]) ? Plugin_Handled:Plugin_Continue;
}

public Action SBPP_OnCheckLoadAdmin(int iClient)
{
	//PrintToConsoleAll("SBPP_OnCheckLoadAdmin: %N (T = %b, B = %b, L %b)", iClient, cvarToggle.BoolValue, cvarBlockPostAdminCheck.BoolValue, Loaded[iClient]);
	return (cvarToggle.BoolValue && cvarBlockPostAdminCheck.BoolValue && !Loaded[iClient]) ? Plugin_Handled:Plugin_Continue;
}

public void VIP_OnClientLoaded_Pre(int iClient, bool bIsVIP)
{
	//PrintToConsoleAll("VIP_OnClientLoaded_Pre: %N (T = %b, B = %b, L %b, V %b)", iClient, cvarToggle.BoolValue, cvarBlockPostAdminCheck.BoolValue, Loaded[iClient], bIsVIP);
	if(cvarToggle.BoolValue && !IsFakeClient(iClient))
	{
		Loaded[iClient] = true;
		if(!bIsVIP)
		{

			char szBuffer[32];
			cvarVIPGroup.GetString(szBuffer, 32);
			VIP_GiveClientVIP(_, iClient, 0, szBuffer, false);

			/*if(cvarBlockPostAdminCheck.BoolValue)
			{
				RequestFrame(NotifyPostAdminCheck_Next, iClient);
			}*/
		}
	}
}

public void OnClientDisconnect(int iClient)
{
	Loaded[iClient] = false;
}

/*void NotifyPostAdminCheck_Next(int iClient)
{
	if(IsClientInGame(iClient))
	{
		NotifyPostAdminCheck(iClient);
	}
}*/