#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

const int MAX_TELEPORTS = 10;

int Teleport[MAX_TELEPORTS], Teleports;

ConVar cvarMode;
int Mode;
bool Hook;

enum
{
	MODE_NONE,
	MODE_ALL,
	MODE_WHITELIST,
	MODE_BLACKLIST,
	MODE_AUTO
}

public Plugin myinfo =
{
	name	= "Teleport Velocity Reset",
	version	= "1.1",
	author	= "hEl"
};

public void OnPluginStart()
{
	cvarMode = CreateConVar("sm_tp_vel_reset", "4", "0 - disabled, 1 - all, 2 - whitelist, 3 - blacklist, 4 - auto", _, true, 0.0, true, 4.0);
	Mode = cvarMode.IntValue;
	cvarMode.AddChangeHook(OnConVarChange);
	AutoExecConfig(true, "plugin.TeleportVelocityReset");
}

public void OnConfigsExecuted()
{
	OnConVarChange(null, "", "");
}

public void OnMapStart()
{
	OnConfigsExecuted();
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	switch((Mode = cvarMode.IntValue))
	{
		case MODE_NONE:
		{
			ToggleHook(false);
		}
		case MODE_ALL:
		{
			ToggleHook(true);
			
		}
		case MODE_WHITELIST, MODE_BLACKLIST:
		{
			LoadTeleportList();
			ToggleHook(true);
		}
		case MODE_AUTO:
		{
			Mode = MODE_BLACKLIST;
			LoadTeleportList();
			if(!Teleports)
			{
				Mode = MODE_BLACKLIST;
				LoadTeleportList();
				if(!Teleports)
				{
					Mode = MODE_AUTO;
					ToggleHook(false);
					return;
				}
			}
			ToggleHook(true);
		}
	}
}

void LoadTeleportList()
{
	Teleports = 0;
	char szBuffer[256];
	GetCurrentMap(szBuffer, 256);
	BuildPath(Path_SM, szBuffer, 256, "configs/tp_vel_reset/%s_%s.txt", szBuffer, Mode == MODE_WHITELIST ? "w":"b");
	File hFile = OpenFile(szBuffer, "r");
	if(!hFile)
	{
		return;
	}
	while (!IsEndOfFile(hFile) && ReadFileLine(hFile, szBuffer, 256) && Teleports < MAX_TELEPORTS)
	{
		if(TrimString(szBuffer) > 0)
		{
			Teleport[Teleports++] = StringToInt(szBuffer);
		}
	}
	delete hFile;
}

void ToggleHook(bool bToggle)
{
	if(Hook == bToggle)
		return;
	
	switch(bToggle)
	{
		case false:
		{
			UnhookEntityOutput("trigger_teleport", "OnEndTouch", OnEndTouch);
		}
		
		case true:
		{
			HookEntityOutput("trigger_teleport", "OnEndTouch", OnEndTouch);
		}
	}
	
	Hook = bToggle;
}

public void OnEndTouch(const char[] sOutput, int iCaller, int iActivator, float fDelay)
{
	static bool bReset;
	bReset = false;
	if(1 <= iActivator <= MaxClients)
	{
		switch(Mode)
		{
			case MODE_ALL:
			{
				bReset = true;
			}
			default:
			{
				if(TeleportInList(iCaller))
				{
					if(Mode == MODE_BLACKLIST)
					{
						bReset = true;
					}
				}
				else if(Mode == MODE_WHITELIST)
				{
					bReset = true;
				}
			}
		}
		if(bReset)
		{
			TeleportEntity(iActivator, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
		}
	}
}

stock bool TeleportInList(int iEntity)
{
	static int iHammer;
	iHammer = GetEntProp(iEntity, Prop_Data, "m_iHammerID");
	for(int i; i < Teleports; i++)
	{
		if(Teleport[i] == iHammer)
			return true;
	}
	return false;
}