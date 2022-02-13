enum
{
	ACTION_DRUG,
	ACTION_BURN,
	ACTION_FREEZE,
	ACTION_BEACON,
	ACTION_SLAP,
	
	
	ACTION_TOTAL
}

static const char Commands[][] = 
{
	"sm_drug",
	"sm_burn",
	"sm_freeze",
	"sm_beacon",
	"sm_slap"
};

StringMap Data;
int ClientActions[MAXPLAYERS + 1][ACTION_TOTAL];

ConVar CVars[ACTION_TOTAL];

void FreeAdmin_OnPluginStart()
{
	Data = new StringMap();
	
	char szBuffer[256];
	for(int i; i < ACTION_TOTAL; i++)
	{
		FormatEx(szBuffer, 256, "%s_cd", Commands[i]);
		CVars[i] = CreateConVar(szBuffer, "60");
	}
}

void FreeAdmin_OnMapStart()
{
	CreateTimer(120.0, Timer_CheckData, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void FreeAdmin_OnMapEnd()
{
	Data.Clear();
}

void FreeAdmin_OnClientPutInServer(int iClient)
{
	int iSteamID = GetSteamAccountID(iClient);
	
	for(int i; i < ACTION_TOTAL; i++)
	{
		ClientActions[iClient][i] = iSteamID <= 0 ? -1:0;
	}
	
	if(iSteamID <= 0)
	{
		return;
	}

	char szBuffer[40];
	IntToString(iSteamID, szBuffer, 40);
	
	if(Data.GetArray(szBuffer, ClientActions[iClient], ACTION_TOTAL))
	{
		Data.Remove(szBuffer);
	}
	else if(GetClientIP(iClient, szBuffer, 16) && Data.GetArray(szBuffer, ClientActions[iClient], ACTION_TOTAL))
	{
		Data.Remove(szBuffer);
	}
		
}

public void FreeAdmin_OnClientDisconnect(int iClient)
{
	int iSteamID = GetSteamAccountID(iClient);
	
	if(iSteamID <= 0 || !NeedSaveActions(ClientActions[iClient]))
	{
		return;
	}
	
	char szBuffer[40];
	IntToString(iSteamID, szBuffer, 40);
	Data.SetArray(szBuffer, ClientActions[iClient], ACTION_TOTAL, true);
	
	if(GetClientIP(iClient, szBuffer, 16))
	{
		Data.SetArray(szBuffer, ClientActions[iClient], ACTION_TOTAL, true);
	}
}

bool NeedSaveActions(const int iArray[ACTION_TOTAL])
{
	int iTime = GetTime();
	
	for(int i; i < ACTION_TOTAL; i++)
	{
		if(iArray[i] > iTime)
		{
			return true;
		}
	}
	return false;
}

public Action Timer_CheckData(Handle hTimer)
{
	char szBuffer[40];
	StringMapSnapshot Shot = Data.Snapshot();
	int iLength = Shot.Length;
	int iArray[ACTION_TOTAL];
	for(int i; i < iLength; i++)
	{
		Shot.GetKey(i, szBuffer, 40);
		if(Data.GetArray(szBuffer, iArray, ACTION_TOTAL) && !NeedSaveActions(iArray))
		{
			Data.Remove(szBuffer);
		}
		
	}
	delete Shot;
}

bool CheckClientAction(int iClient, int iAction)
{
	if(GetUserFlagBits(iClient) & ADMFLAG_ROOT)
	{
		return true;
	}
	static int iTime;
	iTime = GetTime();
	
	if(ClientActions[iClient][iAction] == -1)
	{
		PrintHintText(iClient, "Ваши данные не были загружены!\nПерезайдите срочно на сервер!");
		return false;
	}
	
	if(ClientActions[iClient][iAction] > iTime)
	{
		PrintHintText(iClient, "Уважаемый Администратор!\nОтдохните %i сек", ClientActions[iClient][iAction] - iTime);
		return false;
	}
	
	ClientActions[iClient][iAction] = iTime + CVars[iAction].IntValue;
	return true;
}