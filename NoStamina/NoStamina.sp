#include <sourcemod>
#include <sdktools_hooks>

#pragma newdecls required

int g_iVelocity, g_iStamina;

public void OnPluginStart()
{
	g_iVelocity = FindSendPropInfo("CCSPlayer", "m_flVelocityModifier");
	g_iStamina = FindSendPropInfo("CCSPlayer", "m_flStamina");
}

public void OnPlayerRunCmdPost(int iClient, int iButtons)
{
	if (!IsPlayerAlive(iClient) || GetEntityMoveType(iClient) & MOVETYPE_LADDER)
		return;
	
	if (GetEntDataFloat(iClient, g_iVelocity) < 1.0)
	{
		SetEntDataFloat(iClient, g_iVelocity, 1.0, true);
	}
	SetEntDataFloat(iClient, g_iStamina, 0.0);
}