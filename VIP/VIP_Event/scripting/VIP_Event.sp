#include <vip_core>
ConVar cvars[3];

char Group[64];
bool Enable, MapIsEnd;
int Winner[MAXPLAYERS + 1], Winners, Admin, Time, MinRoundTime, Vips;

static const int	iTimes[] = {	86400,		259200,		604800,		2629743,	7889232,	15778463,		31556926};
static const char	szTimes[][] = {	"1 День",	"3 Дня",	"1 Неделя",	"1 Месяц",	"3 месяца",	"6 месяцев",	"1 Год"};

public Plugin myinfo = 
{
	name		= "[VIP] Event",
	version		= "1.0",
	description = "Giving a VIP status for winning Event (Zombie escape)",
	author		= "hEl"
}

public void OnPluginStart()
{
	(cvars[0] = CreateConVar("event_vip", "0")).AddChangeHook(OnConVarChange);						Enable = cvars[0].BoolValue;
	(cvars[1] = CreateConVar("event_vip_group", "vip_event")).AddChangeHook(OnConVarChange2);	cvars[1].GetString(Group, 64);
	(cvars[2] = CreateConVar("event_vip_minroundtime", "150")).AddChangeHook(OnConVarChange3);		MinRoundTime = cvars[2].IntValue;
	
	HookEvent("round_end", OnRoundEnd);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	
	if(Enable)
	{
		Time = GetTime() + MinRoundTime;
	}
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if((Enable = view_as<bool>(StringToInt(newValue))))
	{
		Admin = 0;
		Winners = 0;
		Time = GetTime() + MinRoundTime;
	}
}

public void OnConVarChange2(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	strcopy(Group, 64, newValue);
}

public void OnConVarChange3(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	MinRoundTime = StringToInt(newValue);
}


public void OnMapStart()
{
	if(Enable)
	{
		cvars[0].SetInt(0);
		Admin = 0;
		Winners = 0;
	}
	MapIsEnd = false;
}

public void OnMapEnd()
{
	if(Vips > 0)
	{
		char szBuffer[64];
		GetCurrentMap(szBuffer, 64);
		LogMessage("[VIP Event] Issued: %i VIP statuses per %s", Vips, szBuffer);
		Vips = 0;
	}
	if(Enable)
	{
		Admin = 0;
		Winners = 0;
	}
	MapIsEnd = true;
}

public void OnRoundStart(Event hEvent, const char[] event, bool bDontBroadcast)
{
	if(Enable)
	{
		Time = GetTime() + MinRoundTime;
	}
}


public void OnRoundEnd(Event hEvent, const char[] event, bool bDontBroadcast)
{
	if(Enable && hEvent.GetInt("winner") == 3 && GetTime() >= Time)
	{
		Winners = 0;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 3)
			{
				Winner[Winners++] = i;
			}
		}
		EventAdminMenu();
	}
}

public void OnClientDisconnect(int iClient)
{
	if(Enable)
	{
		if(Admin == iClient)
		{
			LogMessage("[VIP Event] %N disconnected from server and closed VIP Event menu", iClient);
			EventAdminMenu();
		}
		for(int i; i < Winners; i++)
		{
			if(Winner[i] == iClient)
			{
				RemoveWinnerFromList(i);
				break;
			}
		}
	}
}

void EventAdminMenu(int iSkipClient = 0)
{
	Admin = 0;
	
	if(MapIsEnd || !Winners)
		return;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && iSkipClient != i && !IsFakeClient(i) && GetUserFlagBits(i) & ADMFLAG_ROOT)
		{
			Menu hMenu = new Menu(AdminMenu);
			hMenu.SetTitle("[VIP Event]\nВы одобряете данный вин?");
			hMenu.AddItem("", "Да");
			hMenu.AddItem("", "Нет");
			hMenu.Display(i, 0);
		}
	}
	
}


public int AdminMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	if(action == MenuAction_End)
	{
		delete hMenu;
	}
	else if(action == MenuAction_Select)
	{
		if(Winners > 0)
		{
			if(Admin != 0)
			{
				PrintToChat(iClient, "[VIP Event] %N ответил раньше вас.", Admin);
			}
			else if(iItem == 0)
			{
				Admin = iClient;
				EventAdminMenu_Days(Admin);
				LogMessage("[VIP Event] %N opened VIP Event menu.", iClient);
			}
		}
		else
		{
			PrintToChat(iClient, "[VIP Event] Победители недоступны или вышли из игры");
			LogMessage("[VIP Event] %N couldn't open VIP Event menu cause winners is %i", iClient, Winners);
		}
	}
}

void EventAdminMenu_Days(int iClient)
{
	Menu hMenu = new Menu(AdminMenuDays);
	hMenu.SetTitle("[VIP Event]\nГруппа: %s\nУкажите длительность: ", Group);
	for(int i; i < 7; i++)
	{
		hMenu.AddItem("", szTimes[i]);
	}
	hMenu.Display(iClient, 0);
}


public int AdminMenuDays(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	if(action == MenuAction_End)
	{
		delete hMenu;
	}
	else if(action == MenuAction_Cancel)
	{
		if(Admin == iClient)
		{
			EventAdminMenu(iClient);
			LogMessage("[VIP Event] %N closed VIP Event menu", iClient);
		}
	}
	else if(action == MenuAction_Select)
	{
		if(Winners > 0)
		{
			EventAdminMenu_Players(iClient, iItem);
		}
		else
		{
			PrintToChat(iClient, "[VIP Event] Победители недоступны или вышли из игры");
		}
	}
}


void EventAdminMenu_Players(int iClient, int iTime, int iItem = 0)
{
	char szBuffer[256], szBuffer2[64];
	Menu hMenu = new Menu(AdminMenuPlayers);
	hMenu.SetTitle("[VIP Event]\nГруппа: %s\nДлительность: %s\nСписок победителей:", Group, szTimes[iTime]);
	FormatEx(szBuffer2, 64, "0_%i", iTime);
	hMenu.AddItem(szBuffer2, "[Выдать всем]");
	for(int i; i < Winners; i++)
	{
		FormatEx(szBuffer2, 64, "%i_%i", Winner[i], iTime);
		FormatEx(szBuffer, 256, "%N%s", Winner[i], VIP_IsClientVIP(Winner[i]) ? " (VIP)":" ");
		hMenu.AddItem(szBuffer2, szBuffer);
	}
	hMenu.ExitBackButton = true;
	hMenu.DisplayAt(iClient, iItem, 0);
	
}


public int AdminMenuPlayers(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	if(action == MenuAction_End)
	{
		delete hMenu;
	}
	else if(action == MenuAction_Cancel && Admin == iClient)
	{
		if(iItem == MenuCancel_ExitBack)
		{
			EventAdminMenu_Days(iClient);
		}
		else
		{
			EventAdminMenu(iClient);
			LogMessage("[VIP Event] %N closed VIP Event menu", iClient);
		}
	}
	else if(action == MenuAction_Select)
	{
		if(Winners <= 0)
		{
			PrintToChat(iClient, "[VIP Event] Победители недоступны или вышли из игры");
			return -1;
		}
		char szBuffer[64];
		hMenu.GetItem(iItem, szBuffer, 64);
		int iSymbol = FindCharInString(szBuffer, '_');
		if(iSymbol == -1)
		{
			PrintToChat(iClient, "[VIP Event] Упс! Что-то пошло не так...");
			return -1;
		}
		int iTime = StringToInt(szBuffer[iSymbol + 1]);
		if(iItem == 0)
		{
			for(int i; i < Winners; i++)
			{
				VIPEvent_AddVIP(Winner[i], iTime);
			}
			Winners = 0;
			LogMessage("[VIP Event] %N issued VIP to all players", iClient);
		}
		else
		{
			szBuffer[iSymbol] = 0;
			int iEventWinner = StringToInt(szBuffer);
			if(FindInArray(iEventWinner) != iItem - 1)
			{
				PrintToChat(iClient, "[VIP Event] Данный игрок недоступен.");
				LogMessage("[VIP Event] %N couldn't issued VIP to %N (unavailbale)", iClient, iEventWinner);
			}
			else
			{
				VIPEvent_AddVIP(iEventWinner, iTime);
				RemoveWinnerFromList(iItem);
				LogMessage("[VIP Event] %N issued VIP to %N", iClient, iEventWinner);
				
				if(Winners > 0)
				{
					EventAdminMenu_Players(iClient, iTime, hMenu.Selection);
				}
				
			}
		}
	}
	
	return -1;
}

int FindInArray(int iClient)
{
	for(int i; i < Winners; i++)
	{
		if(Winner[i] == iClient)
			return i;
	}
	
	return -1;
}

void RemoveWinnerFromList(int iIndex)
{
	Winners--;
	
	for(int i = iIndex; i < Winners; i++)
	{
		Winner[i] = Winner[i + 1];
	}
}


void VIPEvent_AddVIP(int iClient, int iTime)
{
	if(VIP_IsClientVIP(iClient))
	{
		int iVipTime = VIP_GetClientAccessTime(iClient);
		if(iVipTime == -1)
		{
			PrintToChat(Admin, "[VIP Event] %N не удалось выдать VIP-Статус (не удалось определить время окончания его VIP-Прав", iClient);
		}
		else if(iVipTime > 0)
		{
			Vips++;
			VIP_SetClientAccessTime(iClient, iVipTime + iTimes[iTime]);
			PrintToChat(Admin, "[VIP Event] %N продлен VIP-Статус", iClient);
			
		}
	}
	else
	{
		Vips++;
		VIP_GiveClientVIP(_, iClient, iTimes[iTime], Group);
		PrintToChat(Admin, "[VIP Event] %N получил VIP-Статус", iClient);
	}
}