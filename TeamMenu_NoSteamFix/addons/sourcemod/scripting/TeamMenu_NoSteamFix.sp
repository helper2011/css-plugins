#include <sourcemod>

#pragma newdecls required

public Plugin myinfo =
{
	name		= "TeamMenu NoSteam Fix",
	version		= "1.0",
	description = "Fix changing team for css.turbo-boost nosteam client",
	author		= "hEl"
};

public void OnPluginStart()
{
	AddCommandListener(OnCommand, "teammenu");
}

public Action OnCommand(int iClient, const char[] command, int iArgs)
{
	if(iClient && !IsFakeClient(iClient))
	{
		int iTeam;
		switch(GetClientTeam(iClient))
		{
			case 0, 1:
			{
				iTeam = GetRandomInt(0, 1) == 0 ? 2:3;
			}
			case 2:
			{
				iTeam = 3;
			}
			case 3:
			{
				iTeam = 2;
			}

		}
		ClientCommand(iClient, "jointeam %i", iTeam);
	}

	return Plugin_Continue;
}