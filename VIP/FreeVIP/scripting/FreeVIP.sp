#include <sourcemod>
#include <vip_core>

#pragma newdecls required

public void VIP_OnClientLoaded(int iClient, bool bIsVIP)
{
	if(!IsFakeClient(iClient))
	{
		if(!bIsVIP)
		{
			VIP_GiveClientVIP(_, iClient, 0, "vip", false);
		}
		
	}
}
