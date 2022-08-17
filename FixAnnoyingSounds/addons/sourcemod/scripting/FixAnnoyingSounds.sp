#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
    name = "Fix Annoying Sounds",
    version = "1.0",
    author = "hEl"
};

public void OnPluginStart()
{
	AddNormalSoundHook(OnSound);
}

public Action OnSound(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if(entity >= 1 && entity <= MAXPLAYERS)
	{
		if(!strcmp(sample, "items/flashlight1.wav", false))
		{
			numClients = 1;
			clients[0] = entity;
			return Plugin_Changed;
		}
	}
	else 
	{
		if(	(sample[0] == 'w' && sample[8] == 'C' && sample[12] == 'E') ||	//	weapons/ClipEmpty_Rifle.wav
			(sample[0] == 'p' && sample[7] == 's' && sample[13] == 'r') )	//	player/sprayer.wav
		{
			numClients = 0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

stock void PrintToConsoleRootAdmins(const char[] message, any ...)
{
	int iLen = strlen(message) + 255;
	char[] szBuffer = new char[iLen];
	VFormat(szBuffer, iLen, message, 2);
	LogMessage(szBuffer);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetUserFlagBits(i) & ADMFLAG_ROOT)
		{
			PrintToConsole(i, szBuffer);
		}
	}
}