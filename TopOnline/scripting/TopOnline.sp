#include <sdktools_functions>
#include <toponline>

#pragma newdecls required

Menu			g_hMenu;
Database		g_hDatabase;
int				ID[MAXPLAYERS + 1],
				Online[MAXPLAYERS + 1],
				TempOnline[MAXPLAYERS + 1],
				Button[MAXPLAYERS + 1][100],
				SameAngles[MAXPLAYERS + 1],
				OnlineCount,
				LastAverage,
				MinAverage,
				MinPlayers,
				Buttons[MAXPLAYERS + 1];
float			LastPosition[MAXPLAYERS + 1][3],
				LastAngle[MAXPLAYERS + 1];
bool			ButtonsToggle,
				AFK[MAXPLAYERS + 1];
ConVar			cvarOnlineCount, cvarButtons, cvarButtonsMinAverage, cvarMinPlayers;

GlobalForward	g_hGFwd_OnClientOnlineCounted;

public Plugin myinfo = 
{
	name		= "Top Online",
	version		= "1.0",
	description	= "Counts players playing time",
	author		= "hEl"
}

public void OnPluginStart()
{
	RegServerCmd("sm_toponline_reload", Command_TopOnline_Reload);
	RegConsoleCmd("sm_toponline", Command_TopOnline);
	cvarOnlineCount			= CreateConVar("toponline_count", "100");				OnlineCount = cvarOnlineCount.IntValue;
	cvarButtons				= CreateConVar("toponline_buttons", "1");				ButtonsToggle = cvarButtons.BoolValue;
	cvarButtonsMinAverage	= CreateConVar("toponline_buttons_min_average", "5");	MinAverage = cvarButtonsMinAverage.IntValue;
	cvarMinPlayers			= CreateConVar("toponline_min_players", "3");			MinPlayers = cvarMinPlayers.IntValue;
	
	cvarOnlineCount.AddChangeHook(OnConVarChange);
	cvarButtons.AddChangeHook(OnConVarChange);
	cvarButtonsMinAverage.AddChangeHook(OnConVarChange);
	cvarMinPlayers.AddChangeHook(OnConVarChange);
	
	HookEvent("round_start",	OnRoundStart);
	HookEvent("round_end",		OnRoundEnd);

	g_hMenu = new Menu(MenuHandler);
	Database.Connect(ConnectCallBack, "toponline");
	CreateTimer(1.0, Timer_CheckPosition, _, TIMER_REPEAT);
	
	g_hGFwd_OnClientOnlineCounted = new GlobalForward("OnClientOnlineCounted", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

}

public Action Command_TopOnline_Reload(int iArgs)
{
	OnPluginEnd();
	OnMapStart();
	return Plugin_Handled;
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(cvar == cvarOnlineCount)
	{
		OnlineCount = cvar.IntValue;
		OnMapStart();
	}
	else if(cvar == cvarButtons)
	{
		ButtonsToggle = cvar.BoolValue;
		
		if(!ButtonsToggle)
		{
			ClearButtons();
		}
	}
	else if(cvar == cvarButtonsMinAverage)
	{
		MinAverage = cvar.IntValue;
	}
	else if(cvar == cvarMinPlayers)
	{
		MinPlayers = cvar.IntValue;
	}
}

void ClearButtons()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		Buttons[i] = 0;
	}
}

public void OnRoundStart(Event hEvent, const char[] event, bool bDontBroadcast)
{
	ClearButtons();
}

public void OnRoundEnd(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iCount;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && (!ButtonsToggle || Buttons[i]))
		{
			iCount++;
		}
	}
	
	if(MinPlayers > iCount)
		return;
	
	iCount = 0;
	
	int iButtons, Average;
	if(ButtonsToggle)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && Buttons[i])
			{
				iButtons += Buttons[i];
				iCount++;
			}
		}
		
		Average = iCount != 0 ? (iButtons / iCount):0;
		//LogMessage("RoundEnd: Players: %i, Button average: %i", iCount, Average);
		
		if(MinAverage > Average)
			return;
		
		LastAverage = Average;
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && TempOnline[i] && (!ButtonsToggle || Buttons[i] >= Average))
		{
			Online[i] += TempOnline[i];
			Call_StartForward(g_hGFwd_OnClientOnlineCounted);
			Call_PushCell(i);
			Call_PushCell(TempOnline[i]);
			Call_PushCell(Online[i]);
			Call_Finish();
			
			TempOnline[i] = 0;
		}
	}
	
	
}

int FindClientButton(int iClient, int iButtons)
{
	for(int i; i < Buttons[iClient]; i++)
	{
		if(Button[iClient][i] == iButtons)
		{
			return i;
		}
	}
	
	
	return -1;
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

public Action Command_TopOnline(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient) && g_hMenu.ItemCount)
	{
		g_hMenu.Display(iClient, 0);
	}
	
	return Plugin_Handled;
}

public void OnMapStart()
{
	LastAverage = 0;
	
	if(!g_hDatabase)
		return;
	
	if(g_hMenu.ItemCount)
	{
		g_hMenu.RemoveAllItems();
	}
	g_hMenu.SetTitle("TOP Online | TOP-%i", OnlineCount);
	
	char szBuffer[256];
	FormatEx(szBuffer, 256, "SELECT `name`, `online` FROM `toponline` ORDER BY `online` DESC LIMIT %i", OnlineCount);
	g_hDatabase.Query(SQL_GetTOP, szBuffer);
}


public int MenuHandler(Menu hMenu, MenuAction action, int iClient, int iItem)
{
}

public void SQL_GetTOP(Database hDatabase, DBResultSet hResults, const char[] sError, any data)
{ 
	if (sError[0]) 
	{ 
		LogError("GetTop100: %s", sError);
		return;
	}
	
	
	int iCount = hResults.RowCount;
	if (iCount > OnlineCount)
	{
		iCount = OnlineCount;
	}
	else if (!iCount)
	{
		return;
	}
	
	char szBuffer[256], szName[64];
	for(int i = 1; i <= iCount; i++)
	{
		hResults.FetchRow();
		hResults.FetchString(0, szName, 64);
		int iOnline = hResults.FetchInt(1);
		FormatTime2(iOnline, szBuffer, 256);
		Format(szBuffer, 256 , "%i. %s [%s]", i, szName, szBuffer);
		g_hMenu.AddItem("", szBuffer, ITEMDRAW_DISABLED);
	}
}

public Action Timer_CheckPosition(Handle hTimer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i) || IsFakeClient(i))
			continue;
		
		float fPos[3];
		GetClientAbsOrigin(i, fPos);
		
		if(LastPosition[i][0] != 0.0 && LastPosition[i][1] != 0.0 && LastPosition[i][2] != 0.0 && GetVectorDistance(fPos, LastPosition[i]) >= 10.0)
		{
			if(ButtonsToggle)
			{
				int iButtons = GetClientButtons(i);
				if(Buttons[i] < 100 && FindClientButton(i, iButtons) == -1)
				{
					Button[i][Buttons[i]++] = iButtons;
				}
			}
			float fAng[3];
			GetClientEyeAngles(i, fAng);
			if(LastAngle[i] == fAng[0])
			{
				if(++SameAngles[i] < 5)
				{
					TempOnline[i]++;
				}
			}
			else
			{
				SameAngles[i] = 0;
				TempOnline[i]++;
			}
			LastAngle[i] = fAng[0];
			
		}
		LastPosition[i] = fPos;
	}
}

public void ConnectCallBack(Database hDatabase, const char[] sError, any data) // Пришел результат соеденения
{
	if (hDatabase == null)	// Соединение  не удачное
	{
		SetFailState("Database failure: %s", sError); // Отключаем плагин
		return;
	}

	g_hDatabase = hDatabase; // Присваиваем глобальной переменной соеденения значение текущего соеденения
	
	
	SQL_LockDatabase(g_hDatabase); // Блокируем базу для других запросов

	g_hDatabase.Query(SQL_Callback_CheckError,	"CREATE TABLE IF NOT EXISTS `toponline` (\
															`id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,\
															`auth` VARCHAR(32) NOT NULL,\
															`name` VARCHAR(32) NOT NULL default 'unknown',\
															`last_connect` INTEGER UNSIGNED NOT NULL,\
															`online` INTEGER NOT NULL default '0');");
	SQL_UnlockDatabase(g_hDatabase); // Разблокируем базу
	
	g_hDatabase.SetCharset("utf8"); // Устанавливаем кодировку
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
	OnMapStart();
}

public void SQL_Callback_CheckError(Database hDatabase, DBResultSet results, const char[] szError, any data)
{
	if(szError[0])
	{
		LogError("SQL_Callback_CheckError: %s", szError);
	}
}

public void OnClientPostAdminCheck(int iClient)
{
	if(!IsFakeClient(iClient))
	{
		char szQuery[256], szAuth[32];
		GetClientAuthId(iClient, AuthId_Engine, szAuth, sizeof(szAuth), true);
		FormatEx(szQuery, sizeof(szQuery), "SELECT `id`, `online` FROM `toponline` WHERE `auth` = '%s';", szAuth);
		g_hDatabase.Query(SQL_Callback_SelectClient, szQuery, GetClientUserId(iClient));
	}
}

public void SQL_Callback_SelectClient(Database hDatabase, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQL_Callback_SelectClient: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}
	
	int iClient = GetClientOfUserId(iUserID);
	if(iClient)
	{
		char szQuery[256], szName[MAX_NAME_LENGTH*2+1];
		GetClientName(iClient, szQuery, MAX_NAME_LENGTH);
		g_hDatabase.Escape(szQuery, szName, sizeof(szName)); // Экранируем запрещенные символы в имени

		// Игрок всё еще на сервере
		if(hResults.FetchRow())	// Игрок есть в базе
		{
			// Получаем значения из результата
			ID[iClient] = hResults.FetchInt(0);	// id
			Online[iClient] = hResults.FetchInt(1);

			// Обновляем в базе ник и дату последнего входа
			FormatEx(szQuery, sizeof(szQuery), "UPDATE `toponline` SET `last_connect` = %i, `name` = '%s' WHERE `id` = %i;", GetTime(), szName, ID[iClient]);
			g_hDatabase.Query(SQL_Callback_CheckError, szQuery);
		}
		else
		{
			Online[iClient] = 0;

			char szAuth[32];
			GetClientAuthId(iClient, AuthId_Engine, szAuth, sizeof(szAuth));
			FormatEx(szQuery, sizeof(szQuery), "INSERT INTO `toponline` (`auth`, `name`, `last_connect`) VALUES ( '%s', '%s', %i);", szAuth, szName, GetTime());
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
	if(iClient)
	{
		ID[iClient] = results.InsertId; // Получаем ID только что добавленного игрока
	}
}

public void OnClientDisconnect(int iClient)
{
	if(!IsFakeClient(iClient))
	{
		LastAngle[iClient] =
		LastPosition[iClient][0] =
		LastPosition[iClient][1] =
		LastPosition[iClient][2] = 0.0;
		SameAngles[iClient] = 0;
		
		if(TempOnline[iClient])
		{
			if(!ButtonsToggle || (LastAverage && Buttons[iClient] >= LastAverage))
			{
				Online[iClient] += TempOnline[iClient];
			}
			TempOnline[iClient] = 0;
		}
		
		char szQuery[512];
		FormatEx(szQuery, sizeof(szQuery), "UPDATE `toponline` SET `online` = %i WHERE `id` = %i;", Online[iClient], ID[iClient]);
		g_hDatabase.Query(SQL_Callback_CheckError, szQuery);
	}
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
	
	
	FormatEx(buffer, iSize, "%i h, %i min, %i sec", iHours, iMinutes, iSeconds);
}