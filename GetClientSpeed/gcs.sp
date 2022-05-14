public void OnPluginStart()
{
	RegConsoleCmd("sm_gcs2", Command_GetClientSpeed);
}

public Action Command_GetClientSpeed(int client, int argc)
{
	if(argc < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_iammo <#userid|name>");
		return Plugin_Handled;
	}

	char sArgs[65];
	GetCmdArg(1, sArgs, sizeof(sArgs));

	char sTargetName[MAX_TARGET_LENGTH];

	int[] iTargets = new int[MaxClients];
	int iTargetCount;
	bool bIsML;
	if((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MaxClients, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_BOTS, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for(int i = 0; i < iTargetCount; i++)
	{
		PrintToChat(client, "%N = %f", iTargets[i], GetEntPropFloat(iTargets[i], Prop_Data, "m_flLaggedMovementValue"));
	}

	return Plugin_Handled;
}