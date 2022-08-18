#pragma newdecls required

bool g_bThirdPerson[MAXPLAYERS + 1];

public void OnPluginStart()
{
	HookEvent("player_spawn", 		OnPlayerSpawn);
	RegConsoleCmd("sm_tp", 			Command_ThirdPerson);
	RegConsoleCmd("sm_third", 		Command_ThirdPerson);
	RegConsoleCmd("sm_thirdperson", Command_ThirdPerson);
}

public void OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && g_bThirdPerson[i])
			SetThirdPersonView(i, false);
	}
}

public void OnClientPutInServer(int iClient)
{
	g_bThirdPerson[iClient] = false;
}

public Action Command_ThirdPerson(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient))
	{
		if(IsPlayerAlive(iClient))
		{
			SetThirdPersonView(iClient, !g_bThirdPerson[iClient]);
			
		}
		else
		{
			g_bThirdPerson[iClient] = !g_bThirdPerson[iClient];
		}
		
		PrintHintText(iClient, "[ThirdPerson: %s]", g_bThirdPerson[iClient] ? "enabled":"disabled");
	}
		
	return Plugin_Handled;
}

public void OnPlayerSpawn(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(g_bThirdPerson[iClient])
	{
		CreateTimer(0.1, Timer_SetThirdPerson, iClient);
	}
}

public Action Timer_SetThirdPerson(Handle hTimer, int iClient)
{
	if(g_bThirdPerson[iClient] && IsClientInGame(iClient) && IsPlayerAlive(iClient))
	{
		SetThirdPersonView(iClient, true);
	}
	return Plugin_Continue;
}
	
void SetThirdPersonView(int iClient, bool bThird)
{
	g_bThirdPerson[iClient] = bThird;
	SetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget", 	g_bThirdPerson[iClient] ? 0:-1); 
	SetEntProp(iClient, Prop_Send, "m_iObserverMode",		g_bThirdPerson[iClient] ? 1:0);
	SetEntProp(iClient, Prop_Send, "m_bDrawViewmodel", 		g_bThirdPerson[iClient] ? 0:1);
	SetEntProp(iClient, Prop_Send, "m_iFOV",				g_bThirdPerson[iClient] ? 120:0);
}