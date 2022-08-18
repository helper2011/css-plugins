Handle g_hTimer;
int Time;
bool Announce;

public Plugin myinfo = 
{
	name		= "AutoRestart",
	version		= "1.0",
	author		= "hEl"
}

public void OnPluginStart()
{
	ConVar cvar = CreateConVar("autorestart_time", "0300"); // UTC +3
	//ConVar cvar = CreateConVar("autorestart_time", "1900"); // UTC -5
	cvar.AddChangeHook(OnConVarChange);
	StartTimer(cvar);
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	delete g_hTimer;
	StartTimer(cvar);
}

void StartTimer(ConVar cvar)
{
	char szBuffer[64];
	cvar.GetString(szBuffer, 64);
	int iTime[2][2];
	GetIntDate(iTime[0], szBuffer);
	if(iTime[0][0] != -1 && iTime[0][1] != -1)
	{
		FormatTime(szBuffer, 64, "%H%M");
		GetIntDate(iTime[1], szBuffer);
		
		if(iTime[1][1] > iTime[0][1])
		{
			iTime[0][0]--;
			iTime[0][1] += 60;
		}
		
		int iMinutes = iTime[0][1] - iTime[1][1];
		
		if(iTime[1][0] > iTime[0][0])
		{
			iTime[0][0] += 24;
		}
		
		
		int iHours = iTime[0][0] - iTime[1][0];
		
		Time = GetTime() + (iHours * 3600) + (iMinutes * 60);
		
		if(!iHours && !iMinutes)
			Time += 86400;
		
		g_hTimer = CreateTimer(300.0, Timer_CheckTime, _, TIMER_REPEAT);
	}
}

void GetIntDate(int Date[2], char[] szBuffer)
{
	ResetDate(Date);
	if(szBuffer[0] && strlen(szBuffer) == 4)
	{
		Date[1] = StringToInt(szBuffer[2]);
		szBuffer[2] = 0;
		Date[0] = StringToInt(szBuffer);
		
		if(!(0 <= Date[0] < 24 && 0 <= Date[1] < 60))
			ResetDate(Date);
	}
}

void ResetDate(int Date[2])
{
	Date[0] = Date[1] = -1;
	
}

public Action Timer_CheckTime(Handle hTimer)
{
	if(!Announce && GetTime() >= Time)
	{
		Announce = view_as<bool>(CreateTimer(0.0, Timer_Announce, 60)); 
	}
	return Plugin_Continue;
}

public Action Timer_Announce(Handle hTimer, int iCoolDown)
{
	if(iCoolDown > 0)
	{
		PrintHintTextToAll("The server will restart in %i seconds", iCoolDown);
		CreateTimer(1.0, Timer_Announce, --iCoolDown); 
		
	}
	else
	{
		Announce = false;
		LogMessage("Restarting...");
		ServerCommand("_restart");
	}
	return Plugin_Continue;
}