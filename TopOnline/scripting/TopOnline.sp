#include <sourcemod>
#include <sdktools_functions>

#pragma newdecls required

enum
{
	TOP_ALL,
	TOP_WEEK,
	TOP_MONTH,

	TOP_TOTAL
}

enum 
{
	CLIENT_ID,
	CLIENT_INFO,
	CLIENT_ONLINE_TOTAL,
	CLIENT_ONLINE_CLEAN,
	CLIENT_ONLINE_DYNAMIC_TOTAL,
	CLIENT_ONLINE_DYNAMIC_CLEAN,
	CLIENT_ONLINE_DYNAMIC_SESSION_TIME,
	CLIENT_SAME_ANGLES_TICKS,
	CLIENT_DATA_TOTAL
}

enum /* Client info */
{
	CLIENT_INFO_AUTHORIZED 		= (1 << 0),
	CLIENT_INFO_SESSION_LOADED	= (1 << 1),
	CLIENT_INFO_LOADED			= (1 << 2)
}

static const char intervalNames[][] = 
{
	"all",
	"week",
	"month"
}

static const char intervalTitle[][] = 
{
	"All Time",
	"Week",
	"Month"
}



static const int intervalTimes[] = 
{
	0,
	604800,
	2628288
}

bool			DatabaseIsLoaded;
int				ClientData[MAXPLAYERS + 1][CLIENT_DATA_TOTAL];
float			ClientLastPos[MAXPLAYERS + 1][3],
				ClientLastAngle[MAXPLAYERS + 1];
Handle			TimerOnline;
ConVar			cvarTopTotalOnlineCount, cvarTopDynamicOnlineCount, cvarDynamicMinAllTime, cvarDynamicMaxSessionTime;
Database		g_hDatabase;
Panel			TopMenus[TOP_TOTAL];
int 			TopMenusCountCurrentQueries[TOP_TOTAL];

public Plugin myinfo = 
{
	name		= "Top Online",
	version		= "1.0",
	description	= "Counts players playing time",
	author		= "hEl"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_toponline", Command_TopOnline);
	RegConsoleCmd("sm_online", Command_Online);
	cvarTopTotalOnlineCount	= CreateConVar("sm_toponline_top_total_count", "20");
	cvarTopDynamicOnlineCount	= CreateConVar("sm_toponline_top_dynamic_count", "10");
	cvarDynamicMinAllTime	= CreateConVar("sm_toponline_dynamic_min_total_time", "36000");
	cvarDynamicMaxSessionTime	= CreateConVar("sm_toponline_dynamic_max_session_time", "604800");
	AutoExecConfig(true, "plugin.TopOnline");

	for(int i; i < TOP_TOTAL; i++)
	{
		TopMenus[i] = new Panel();
		TopMenus[i].SetKeys(1023);
	}

	Database.Connect(ConnectCallBack, "toponline");
}

public void OnMapStart()
{
	if(!DatabaseIsLoaded)
		return;
	
	int iTopTotalOnlineCount = cvarTopTotalOnlineCount.IntValue, iTopDynamicOnlineCount = cvarTopDynamicOnlineCount.IntValue, iTime = GetTime();
	char szBuffer[256];
	for(int i; i < TOP_TOTAL; i++)
	{
		switch(i)
		{
			case TOP_ALL:
			{
				FormatEx(szBuffer, 256, "SELECT `name`, `online_clean` FROM `total_online` ORDER BY `online_clean` DESC LIMIT %i", iTopTotalOnlineCount);
			}
			default:
			{
				FormatEx(szBuffer, 256, "SELECT `client_id`, SUM(`online_clean`) FROM `dynamic_online` WHERE %i - `start_time` <= %i GROUP BY `client_id` ORDER BY SUM(`online_clean`) DESC LIMIT %i", iTime, intervalTimes[i], iTopDynamicOnlineCount);
			}
		}
		if(!TopMenusCountCurrentQueries[i])
		{
			PrintToConsoleAll(szBuffer);
			g_hDatabase.Query(SQL_GetTOP, szBuffer, i);
		}
	}

	delete TimerOnline;
	TimerOnline = CreateTimer(1.0, Timer_CheckPosition, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

/*
int g_iCount;
stock void ImportDBFromFile()
{
	int iSymbol, iSymbol2, iAccount, iOnline;
	char szNick[64];
	char szFinalNick[MAX_NAME_LENGTH*2+1];
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, 256, "data/import_db.txt");
	File hFile = OpenFile(szBuffer, "r");
	if(hFile)
	{
		//int iCount;
		while(!hFile.EndOfFile())
		{
			if(!hFile.ReadLine(szBuffer, 256) || TrimString(szBuffer) <= 0 || (iSymbol = FindCharInString(szBuffer, ' ')) == -1 || (iSymbol2 = FindCharInString(szBuffer[iSymbol + 1], ' ')) == -1)
				continue;

			iSymbol2 += iSymbol + 1;
			strcopy(szNick, 64, szBuffer[iSymbol2 + 1]);
			szBuffer[iSymbol2] = 0;
			iOnline = StringToInt(szBuffer[iSymbol + 1]);
			szBuffer[iSymbol] = 0;
			iAccount = StringToInt(szBuffer);
			g_hDatabase.Escape(szNick, szFinalNick, sizeof(szFinalNick));
			FormatEx(szBuffer, 256, "INSERT INTO `total_online` (`id`, `name`, `online_total`, `online_clean`) VALUES ( %i, '%s', %i, %i);", iAccount, szFinalNick, iOnline, iOnline);
			g_hDatabase.Query(SQL_Callback_CheckError2, szBuffer);
			//LogMessage(szBuffer);
			//PrintToServer(szBuffer);
			PrintToServer("%i", ++g_iCount);
		}
	}
}

public void SQL_Callback_CheckError2(Database hDatabase, DBResultSet results, const char[] szError, any data)
{
	PrintToServer("%i", --g_iCount);
	if(szError[0])
	{
		LogError("SQL_Callback_CheckError: %s", szError);
	}
}
 */
public void OnMapEnd()
{
	TimerOnline = null;
}

public void SQL_GetTOP(Database hDatabase, DBResultSet hResults, const char[] sError, int iTopID)
{
	if(sError[0])
	{
		LogError("SQL_GetTOP: %s", sError);
		return;
	}
	if(!hResults || !hResults.RowCount)
	{
		return;
	}

	char szBuffer[256];
	int iCleanOnline, iPosition = 1;
	switch(iTopID)
	{
		case TOP_ALL:
		{
			char szTitle[2048];
			FormatEx(szTitle, 2048, "Top-%i Online | %s\n \n", cvarTopTotalOnlineCount.IntValue, intervalTitle[iTopID]);
			char szName[16];
			while(hResults.FetchRow())
			{
				hResults.FetchString(0, szName, 16);
				iCleanOnline = hResults.FetchInt(1);
				FormatTime2(iCleanOnline, szBuffer, 256);
				Format(szBuffer, 256 , "%i. %s (%s)", iPosition, szName, szBuffer);
				StrCat(szTitle, 2048, szBuffer);
				StrCat(szTitle, 2048, "\n");
				iPosition++;
			}
			TopMenus[iTopID].SetTitle(szTitle);
		}
		default:
		{
			int iId;
			DataPack hPack;
			DataPack hPack2 = new DataPack();
			PrintToConsoleAll("%i", hResults.RowCount);
			while(hResults.FetchRow())
			{
				iId = hResults.FetchInt(0);
				iCleanOnline = hResults.FetchInt(1);
				hPack = new DataPack();
				hPack.WriteCell(iTopID);
				hPack.WriteCell(iCleanOnline);
				hPack.WriteCell(view_as<int>(hPack2));
				FormatEx(szBuffer, 256, "SELECT `name` from `total_online` WHERE `id` = %i", iId);
				PrintToConsoleAll("r = %i\nq=%s", iId, szBuffer);
				g_hDatabase.Query(SQL_GetClientName, szBuffer, hPack);
				iPosition++;
				TopMenusCountCurrentQueries[iTopID]++;
			}
		}
	}
}

public void SQL_GetClientName(Database hDatabase, DBResultSet hResults, const char[] sError, DataPack hPack)
{
	hPack.Reset();
	int iTopID = hPack.ReadCell(), iCleanOnline = hPack.ReadCell();
	DataPack hPack2 = view_as<DataPack>(hPack.ReadCell());
	delete hPack;
	TopMenusCountCurrentQueries[iTopID]--;
	if(sError[0])
	{
		delete hPack2;
		LogError("SQL_GetClientName: %s", sError);
		return;
	}
	char szBuffer[256];
	if(hResults && hResults.FetchRow())
	{
		char szName[16];
		hResults.FetchString(0, szName, 16);
		FormatTime2(iCleanOnline, szBuffer, 256);
		Format(szBuffer, 256 , "%i. %s (%s)", view_as<int>(hPack2.Position) + 1, szName, szBuffer);
		hPack2.WriteString(szBuffer);
	}
	
	if(!TopMenusCountCurrentQueries[iTopID])
	{
		char szTitle[2048];
		FormatEx(szTitle, 2048, "Top-%i Online | %s\n \n", cvarTopDynamicOnlineCount.IntValue, intervalTitle[iTopID]);
		hPack2.Reset();
		while(hPack2.IsReadable(1))
		{
			hPack2.ReadString(szBuffer, 256);
			StrCat(szTitle, 2048, szBuffer);
			StrCat(szTitle, 2048, "\n");
		}
		TopMenus[iTopID].SetTitle(szTitle);
		delete hPack2;
	}
}

public void OnPluginEnd()
{
	if(!g_hDatabase)
		return;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientDisconnect(i);
		}
	}
}

public Action Command_Online(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient) && Bit_GetClientInfo(iClient, CLIENT_INFO_LOADED))
	{
		char szBuffer[256];
		FormatTime2(ClientData[iClient][CLIENT_ONLINE_CLEAN], szBuffer, 256);
		PrintToChat(iClient, szBuffer);

	}
	
	return Plugin_Handled;
}

public Action Command_TopOnline(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient))
	{
		char szBuffer[256];
		switch(iArgs)
		{
			case 0:
			{
				for(int i; i < sizeof(intervalNames); i++)
				{
					StrCat(szBuffer, 256, intervalNames[i]);
					StrCat(szBuffer, 256, "|");
				}
				szBuffer[strlen(szBuffer) - 1] = 0;
				ReplyToCommand(iClient, "Usage: sm_toponline <%s>", szBuffer);

				TopMenus[TOP_ALL].Send(iClient, TopMenusH, 0);
			}
			case 1:
			{
				GetCmdArg(1, szBuffer, 256);
				int iIndex = GetIntervalIdByName(szBuffer);
				if(iIndex != -1)
				{
					TopMenus[iIndex].Send(iClient, TopMenusH, 0);
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public int TopMenusH(Menu hMenu, MenuAction action, int iClient, int iItem)
{
}

public Action Timer_CheckPosition(Handle hTimer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i) || !Bit_GetClientInfo(i, CLIENT_INFO_LOADED))
			continue;
		

		ClientData[i][CLIENT_ONLINE_TOTAL]++;
		ClientData[i][CLIENT_ONLINE_DYNAMIC_TOTAL]++;

		float fPos[3];
		GetClientAbsOrigin(i, fPos);
		
		if(ClientLastPos[i][0] != 0.0 && ClientLastPos[i][1] != 0.0 && ClientLastPos[i][2] != 0.0 && GetVectorDistance(fPos, ClientLastPos[i]) >= 10.0)
		{
			float fAng[3];
			GetClientEyeAngles(i, fAng);
			if(ClientLastAngle[i] == fAng[0])
			{
				if(++ClientData[i][CLIENT_SAME_ANGLES_TICKS] < 5)
				{
					ClientData[i][CLIENT_ONLINE_CLEAN]++;
					ClientData[i][CLIENT_ONLINE_DYNAMIC_CLEAN]++;
				}
			}
			else
			{
				ClientData[i][CLIENT_SAME_ANGLES_TICKS] = 0;
				ClientData[i][CLIENT_ONLINE_CLEAN]++;
				ClientData[i][CLIENT_ONLINE_DYNAMIC_CLEAN]++;
			}
			ClientLastAngle[i] = fAng[0];
			
		}
		ClientLastPos[i] = fPos;
	}
}

public void ConnectCallBack(Database hDatabase, const char[] sError, any data) // Пришел результат соеденения
{
	if (hDatabase == null)
	{
		SetFailState("Database failure: %s", sError);
	}

	g_hDatabase = hDatabase; 
	Transaction hTxn = new Transaction();

	hTxn.AddQuery("CREATE TABLE IF NOT EXISTS `total_online` (\
															`id` INTEGER NOT NULL PRIMARY KEY,\
															`name` VARCHAR(32) NOT NULL default 'unknown',\
															`online_clean` INTEGER NOT NULL default '0',\
															`online_total` INTEGER NOT NULL default '0');");
	hTxn.AddQuery("CREATE TABLE IF NOT EXISTS `dynamic_online` (\
															`client_id` INTEGER NOT NULL PRIMARY KEY,\
															`start_time` INTEGER NOT NULL default '0',\
															`online_clean` INTEGER NOT NULL default '0',\
															`online_total` INTEGER NOT NULL default '0');");

	g_hDatabase.Execute(hTxn, SQL_Callback_TxnSuccess, SQL_Callback_TxnFailure);


}

public void SQL_Callback_TxnFailure(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	SetFailState("Cant create table (%i): %s", failIndex, error);
}

public void SQL_Callback_TxnSuccess(Database hDatabase, int iData, int iNumQueries, DBResultSet[] results, any[] QueryData)
{
	DatabaseIsLoaded = true;

	g_hDatabase.SetCharset("utf8");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
	OnMapStart();
	//ImportDBFromFile();
}

public void SQL_Callback_CheckError(Database hDatabase, DBResultSet results, const char[] szError, any data)
{
	if(szError[0])
	{
		LogError("SQL_Callback_CheckError: %s", szError);
	}
}

public void OnClientPutInServer(int iClient)
{
	ResetClientData(iClient);

	if(!DatabaseIsLoaded || IsFakeClient(iClient))
	{
		return;
	}

	ClientData[iClient][CLIENT_ID] = GetSteamAccountID(iClient, true);

	if(ClientData[iClient][CLIENT_ID])
	{
		char szQuery[256];
		FormatEx(szQuery, sizeof(szQuery), "SELECT `online_clean`, `online_total` FROM `total_online` WHERE `id` = %i LIMIT 1;", ClientData[iClient][CLIENT_ID]);
		g_hDatabase.Query(SQL_Callback_SelectClient, szQuery, GetClientUserId(iClient));

	}
}

public void SQL_Callback_SelectClient(Database hDatabase, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0])
	{
		LogError("SQL_Callback_SelectClient: %s", sError);
		return;
	}
	int iClient = GetClientOfUserId(iUserID);
	if(iClient && IsClientInGame(iClient))
	{
		char szQuery[256], szName[MAX_NAME_LENGTH*2+1];
		GetClientName(iClient, szQuery, MAX_NAME_LENGTH);
		g_hDatabase.Escape(szQuery, szName, sizeof(szName));

		if(hResults.FetchRow())
		{
			Bit_SetClientInfo(iClient, CLIENT_INFO_AUTHORIZED, true);
			CheckClientLoading(iClient);
			ClientData[iClient][CLIENT_ONLINE_CLEAN] = hResults.FetchInt(0);
			ClientData[iClient][CLIENT_ONLINE_TOTAL] = hResults.FetchInt(1);

			FormatEx(szQuery, sizeof(szQuery), "UPDATE `total_online` SET `name` = '%s' WHERE `id` = %i;", szName, ClientData[iClient][CLIENT_ID]);
			g_hDatabase.Query(SQL_Callback_CheckError, szQuery);

			GetClientSession(iClient);
		}
		else
		{
			FormatEx(szQuery, sizeof(szQuery), "INSERT INTO `total_online` (`id`, `name`, `online_total`, `online_clean`) VALUES (%i, '%s', 0, 0);", ClientData[iClient][CLIENT_ID], szName);
			g_hDatabase.Query(SQL_Callback_CreateClient, szQuery, GetClientUserId(iClient));
		}
	}
}

public void SQL_Callback_CreateClient(Database hDatabase, DBResultSet results, const char[] szError, any iUserID)
{
	if(szError[0])
	{
		LogError("SQL_Callback_CreateClient: %s", szError);
		return;
	}
	
	int iClient = GetClientOfUserId(iUserID);
	if(iClient && IsClientInGame(iClient))
	{
		Bit_SetClientInfo(iClient, CLIENT_INFO_AUTHORIZED, true);
		CreateClientSession(iClient);
	}
}

stock void GetClientSession(int iClient)
{
	if(ClientData[iClient][CLIENT_ONLINE_CLEAN] >= cvarDynamicMinAllTime.IntValue)
	{
		char szQuery[512];
		FormatEx(szQuery, sizeof(szQuery), "SELECT `start_time`, `online_clean`, `online_total` FROM `dynamic_online` WHERE `client_id` = %i ORDER BY `start_time` DESC LIMIT 1;", ClientData[iClient][CLIENT_ID]);
		g_hDatabase.Query(SQL_Callback_GetClientSession, szQuery, GetClientUserId(iClient));
	}
	else
	{
		Bit_SetClientInfo(iClient, CLIENT_INFO_SESSION_LOADED, true);
		CheckClientLoading(iClient);
	}
}

public void SQL_Callback_GetClientSession(Database hDatabase, DBResultSet hResults, const char[] sError, int iClient)
{
	if(sError[0])
	{
		LogError("SQL_Callback_GetClientSession: %s", sError);
		return;
	}
	
	if(!hResults || (iClient = GetClientOfUserId(iClient)) == 0 || !IsClientInGame(iClient))
	{
		return;
	}

	if(hResults.FetchRow())
	{
		int iStartSessionTime = hResults.FetchInt(0);

		if(GetTime() - iStartSessionTime <= cvarDynamicMaxSessionTime.IntValue)
		{
			ClientData[iClient][CLIENT_ONLINE_DYNAMIC_SESSION_TIME] = iStartSessionTime;
			ClientData[iClient][CLIENT_ONLINE_DYNAMIC_CLEAN] = hResults.FetchInt(1);
			ClientData[iClient][CLIENT_ONLINE_DYNAMIC_TOTAL] = hResults.FetchInt(2);

			Bit_SetClientInfo(iClient, CLIENT_INFO_SESSION_LOADED, true);
			CheckClientLoading(iClient);
			return;
		}
	}
	CreateClientSession(iClient);
}

stock void CreateClientSession(int iClient)
{
	if(ClientData[iClient][CLIENT_ONLINE_CLEAN] >= cvarDynamicMinAllTime.IntValue)
	{
		ClientData[iClient][CLIENT_ONLINE_DYNAMIC_SESSION_TIME] = GetTime();
		char szQuery[512];
		FormatEx(szQuery, sizeof(szQuery), "INSERT INTO `dynamic_online` (`client_id`, `start_time`, `online_clean`, `online_total`) VALUES (%i, %i, 0, 0);", ClientData[iClient][CLIENT_ID], ClientData[iClient][CLIENT_ONLINE_DYNAMIC_SESSION_TIME]);
		g_hDatabase.Query(SQL_Callback_CreateClientSession, szQuery, GetClientUserId(iClient));
	}
}

public void SQL_Callback_CreateClientSession(Database hDatabase, DBResultSet hResults, const char[] sError, int iClient)
{
	if(sError[0])
	{
		LogError("SQL_Callback_CreateClientSession: %s", sError);
		return;
	}
	
	if((iClient = GetClientOfUserId(iClient)) == 0 || !IsClientInGame(iClient))
	{
		return;
	}

	Bit_SetClientInfo(iClient, CLIENT_INFO_SESSION_LOADED, true);
	CheckClientLoading(iClient);
}

public void OnClientDisconnect(int iClient)
{
	char szQuery[512];
	if(Bit_GetClientInfo(iClient, CLIENT_INFO_AUTHORIZED))
	{
		FormatEx(szQuery, sizeof(szQuery), "UPDATE `total_online` SET `online_clean` = %i, `online_total` = %i WHERE `id` = %i;", ClientData[iClient][CLIENT_ONLINE_CLEAN], ClientData[iClient][CLIENT_ONLINE_TOTAL], ClientData[iClient][CLIENT_ID]);
		g_hDatabase.Query(SQL_Callback_CheckError, szQuery);
	}
	if(Bit_GetClientInfo(iClient, CLIENT_INFO_SESSION_LOADED) && ClientData[iClient][CLIENT_ONLINE_DYNAMIC_SESSION_TIME])
	{
		FormatEx(szQuery, sizeof(szQuery), "UPDATE `dynamic_online` SET `online_clean` = %i, `online_total` = %i WHERE `client_id` = %i and `start_time` = %i;", ClientData[iClient][CLIENT_ONLINE_DYNAMIC_CLEAN], ClientData[iClient][CLIENT_ONLINE_DYNAMIC_TOTAL], ClientData[iClient][CLIENT_ID], ClientData[iClient][CLIENT_ONLINE_DYNAMIC_SESSION_TIME]);
		g_hDatabase.Query(SQL_Callback_CheckError, szQuery);
	}

	ResetClientData(iClient);
}

void ResetClientData(int iClient)
{
	for(int i; i < CLIENT_DATA_TOTAL; i++)
	{
		ClientData[iClient][i] = 0;
	}

	ClientLastAngle[iClient] = 0.0;
	ClientLastPos[iClient][0] = 0.0;
	ClientLastPos[iClient][1] = 0.0;
	ClientLastPos[iClient][2] = 0.0;
}

void FormatTime2(int iSeconds, char[] buffer, int iSize)
{
	int iMinutes, iHours;
	
	while(iSeconds >= 60)
	{
		iMinutes++;
		iSeconds -= 60;
	}
	
	while(iMinutes >= 60)
	{
		iHours++;
		iMinutes -= 60;
	}
	
	
	FormatEx(buffer, iSize, "%i h", iHours);
}

stock int GetIntervalIdByName(const char[] name)
{
	for(int i; i < sizeof(intervalNames); i++)
	{
		if(!strcmp(name, intervalNames[i], false))
		{
			return i;
		}
	}

	return -1;
}

stock bool Bit_GetClientInfo(int iClient, int iInfo)
{
	return !!(ClientData[iClient][CLIENT_INFO] & iInfo);
}

stock bool Bit_SetClientOppInfo(int iClient, int iInfo)
{
	return !!((ClientData[iClient][CLIENT_INFO] ^= iInfo) & iInfo);
}

void Bit_SetClientInfo(int iClient, int iInfo, bool bToggle)
{
	if(bToggle)
	{
		ClientData[iClient][CLIENT_INFO] |= iInfo;
	}
	else
	{
		ClientData[iClient][CLIENT_INFO] &= ~iInfo;
		
	}
}


void CheckClientLoading(int iClient)
{
	if(Bit_GetClientInfo(iClient, CLIENT_INFO_LOADED))
	{
		return;
	}

	if(Bit_GetClientInfo(iClient, CLIENT_INFO_AUTHORIZED) && Bit_GetClientInfo(iClient, CLIENT_INFO_SESSION_LOADED))
	{
		Bit_SetClientInfo(iClient, CLIENT_INFO_LOADED, true);
		OnClientLoaded(iClient);
	}
}

stock void OnClientLoaded(int iClient)
{
	if(iClient)
	{

	}
}