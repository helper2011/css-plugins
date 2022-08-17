public void OnPluginStart()
{
	RegConsoleCmd("sm_im", Command_Immortal);
}

public Action Command_Immortal(int client, int argc)
{
	int iValue;
	SetEntProp(client, Prop_Data, "m_takedamage", (iValue = (!GetEntProp(client, Prop_Data, "m_takedamage") ? 2:0)), 1);
	PrintToChat(client, "Immortal has %s", !iValue ? "enabled":"disabled");
	return Plugin_Handled;
}