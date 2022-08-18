#include <vip_core>

#pragma newdecls required

const int MAX_COMMANDS = 25;

int Commands;
char Title[MAX_COMMANDS][64], Command[MAX_COMMANDS][64];


public Plugin myinfo = 
{
	name		= "[VIP] Commands",
	version		= "1.0",
	author		= "hEl"
}

public void OnPluginStart()
{
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, 256, "data/vip/modules/commands.cfg");
	KeyValues hKeyValues = new KeyValues("Commands");
	if(hKeyValues.ImportFromFile(szBuffer) && hKeyValues.GotoFirstSubKey(false))
	{
		do
		{
			hKeyValues.GetSectionName(Title[Commands], 64);
			hKeyValues.GetString(NULL_STRING, Command[Commands], 64);
			if(Title[Commands][0] && Command[Commands][0])
			{
				Commands++;
			}
		}
		while(hKeyValues.GotoNextKey(false) && Commands < MAX_COMMANDS);
		
	}
	else
	{
		SetFailState("Config file \"%s\" doesnt exists...", szBuffer);
	}
	delete hKeyValues;
	
	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public void OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		for(int i; i < Commands; i++)
		{
			VIP_UnregisterFeature(Title[i]);
		}
		
	}
}

public void VIP_OnVIPLoaded() 
{
	for(int i; i < Commands; i++)
	{
		VIP_RegisterFeature(Title[i], VIP_NULL, SELECTABLE, ItemSelect);
	}
	
}

public Action ItemSelect(int iClient, const char[] szFeature, VIP_ToggleState eOldStatus, VIP_ToggleState &eNewStatus)
{
	for(int i; i < Commands; i++)
	{
		if(!strcmp(szFeature, Title[i], false))
		{
			ClientCommand(iClient, Command[i]);
			break;
		}
	}
	return Plugin_Continue;
}