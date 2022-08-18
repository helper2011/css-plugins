#include <sourcemod>

#pragma newdecls required

KeyValues Config;

public void OnPluginStart()
{
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, 256, "configs/timeconfig.cfg");
	Config = new KeyValues("TimeConfig");
	if(!Config.ImportFromFile(szBuffer))
	{
		SetFailState("Config file \"%s\" not founded", szBuffer);
	}
	if(!Config.GotoFirstSubKey())
	{
		SetFailState("Config is empty");
	}
	
	HookEvent("round_start", OnRound, EventHookMode_PostNoCopy);
	HookEvent("round_end", OnRound, EventHookMode_PostNoCopy);
}

public void OnPluginEnd()
{
	ParseConfig(5);
}

public void OnConfigsExecuted()
{
	ParseConfig(6);
}

public void OnMapStart()
{
	ParseConfig(1);
	CreateTimer(30.0, Timer_Check, false, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapEnd()
{
	ParseConfig(2);
}

public void OnRound(Event hEvent,  const char[] szName, bool bDontBroadcast)
{
	ParseConfig(szName[6] == 's' ? 3:4);
}

public Action Timer_Check(Handle hTimer)
{
	ParseConfig();
	return Plugin_Continue;
}

void ParseConfig(int iEvent = 0)
{
	char szBuffer[256];
	FormatTime(szBuffer, 8, "%H%M");
	int CurTime = StringToInt(szBuffer);
	int iFinalCurTime;
	int MinTime;
	int MaxTime;
	int iSymbol;
	bool bInRange, bToggle;
	Config.Rewind();
	Config.GotoFirstSubKey();
	do
	{
		Config.GetSectionName(szBuffer, 16);
		bToggle = !!Config.GetNum("toggle");
		
		if((iSymbol = FindCharInString(szBuffer, '-')) == -1 || !Config.GotoFirstSubKey(false))
			continue;
		
		// thx for this mapchooser extended, edited by BotoX
		MaxTime = StringToInt(szBuffer[iSymbol + 1]); szBuffer[iSymbol] = 0;
		MinTime = StringToInt(szBuffer);
		iFinalCurTime = (CurTime <= MinTime) ? CurTime + 2400 : CurTime;
		MaxTime = (MaxTime <= MinTime) ? MaxTime + 2400 : MaxTime;
	
		bInRange = (MinTime <= iFinalCurTime <= MaxTime);
		
		if(!bInRange && !bToggle)
		{
			Config.GoBack();
			continue;
		}
		do
		{
			Config.GetSectionName(szBuffer, 256);
			if(!strcmp(szBuffer, "OnStart", false))
			{
				if(bInRange && !bToggle)
				{
					Config.GetString(NULL_STRING, szBuffer, 256);
					ServerCommand(szBuffer);
				}
			}
			else if(!strcmp(szBuffer, "OnEnd", false))
			{
				if(iEvent == 5 || (!bInRange && bToggle))
				{
					Config.GetString(NULL_STRING, szBuffer, 256);
					ServerCommand(szBuffer);
				}
			}
			else if(!strcmp(szBuffer, "OnMapStart", false))
			{
				if(bInRange && iEvent == 1)
				{
					Config.GetString(NULL_STRING, szBuffer, 256);
					ServerCommand(szBuffer);
				}
			}
			else if(!strcmp(szBuffer, "OnMapEnd", false))
			{
				if(bInRange && iEvent == 2)
				{
					Config.GetString(NULL_STRING, szBuffer, 256);
					ServerCommand(szBuffer);
				}
			}
			else if(!strcmp(szBuffer, "OnRoundStart", false))
			{
				if(bInRange && iEvent == 3)
				{
					Config.GetString(NULL_STRING, szBuffer, 256);
					ServerCommand(szBuffer);
				}
			}
			else if(!strcmp(szBuffer, "OnRoundEnd", false))
			{
				if(bInRange && iEvent == 4)
				{
					Config.GetString(NULL_STRING, szBuffer, 256);
					ServerCommand(szBuffer);
				}
			}
			else if(!strcmp(szBuffer, "OnConfigsExecuted", false))
			{
				if(bInRange && iEvent == 6)
				{
					Config.GetString(NULL_STRING, szBuffer, 256);
					ServerCommand(szBuffer);
				}
			}
			else if(strcmp(szBuffer, "toggle", false) && bInRange)
			{
				Config.GetString(NULL_STRING, szBuffer, 256);
				ServerCommand(szBuffer);
			}
		}
		while(Config.GotoNextKey(false));
		Config.GoBack();
		if(bInRange && !bToggle)
		{
			Config.SetNum("toggle", 1);
		}
		else if(!bInRange && bToggle)
		{
			Config.SetNum("toggle", 0);
		}
	}
	while(Config.GotoNextKey());
}

stock void ProcessCommand(char[] szBuffer, int iSize, int iEvent, bool bToggle, bool bInRange)
{
	Config.GetSectionName(szBuffer, iSize);
	if(!strcmp(szBuffer, "OnStart", false))
	{
		if(bInRange && !bToggle)
		{
			Config.GetString(NULL_STRING, szBuffer, 256);
			ServerCommand(szBuffer);
		}
	}
	else if(!strcmp(szBuffer, "OnEnd", false))
	{
		if(iEvent == 5 || (!bInRange && bToggle))
		{
			Config.GetString(NULL_STRING, szBuffer, 256);
			ServerCommand(szBuffer);
		}
	}
	else if(!strcmp(szBuffer, "OnMapStart", false))
	{
		if(bInRange && iEvent == 1)
		{
			Config.GetString(NULL_STRING, szBuffer, 256);
			ServerCommand(szBuffer);
		}
	}
	else if(!strcmp(szBuffer, "OnMapEnd", false))
	{
		if(bInRange && iEvent == 2)
		{
			Config.GetString(NULL_STRING, szBuffer, 256);
			ServerCommand(szBuffer);
		}
	}
	else if(!strcmp(szBuffer, "OnRoundStart", false))
	{
		if(bInRange && iEvent == 3)
		{
			Config.GetString(NULL_STRING, szBuffer, 256);
			ServerCommand(szBuffer);
		}
	}
	else if(!strcmp(szBuffer, "OnRoundEnd", false))
	{
		if(bInRange && iEvent == 4)
		{
			Config.GetString(NULL_STRING, szBuffer, 256);
			ServerCommand(szBuffer);
		}
	}
	else if(!strcmp(szBuffer, "OnConfigsExecuted", false))
	{
		if(bInRange && iEvent == 6)
		{
			Config.GetString(NULL_STRING, szBuffer, 256);
			ServerCommand(szBuffer);
		}
	}
	else if(strcmp(szBuffer, "toggle", false) && bInRange)
	{
		Config.GetString(NULL_STRING, szBuffer, 256);
		ServerCommand(szBuffer);
	}
}