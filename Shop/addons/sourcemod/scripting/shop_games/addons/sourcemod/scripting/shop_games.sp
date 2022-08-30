#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <shop>

#define GPREFIX	"\x04[Games]\x01"
#define GTITLE	"Игры на двоих"

ConVar	cv_Commission;
ConVar	cv_ConfirmTime;
ConVar	cv_StartTime;
ConVar	cv_GameTime;

char GameName[][] =
{
	"Камень-Ножницы-Бумага",
	"Покер на Костях"
};

#define GAMES sizeof(GameName)

ConVar	cv_OnGame[GAMES];
Menu	Rules[GAMES];

int		OnGame[GAMES];
int		Commission;
int		ConfirmTime;
int		StartTime;
int		GameTime;

Handle	CookieResultMenu;
Handle	CookieGames[GAMES];

bool	ClientCookie[MAXPLAYERS+1][GAMES];
bool	ClientCookieResult[MAXPLAYERS+1];

enum Bet
{
	Amount,
	Name
}

int		BetsCount;
char	Bets[35][Bet][64];

enum GameOptions
{
	Game,
	bet,
	Target,
	Started
}

int Options[MAXPLAYERS+1][GameOptions];
int Time[MAXPLAYERS+1];

#include "games/KNB.sp"
#include "games/Poker.sp"

public Plugin myinfo =
{
	name = "[Shop] Games",
	author = "Monroe",
	version = "1.2.1"
};

public void OnPluginStart()
{
	cv_OnGame[0] =		CreateConVar("sm_shop_games_knb",			"1",	"Игра Камень-ножницы-бумага.", 0, true, 0.0, true, 1.0);
	cv_OnGame[1] =		CreateConVar("sm_shop_games_poker",			"1",	"Игра Покер на костях.", 0, true, 0.0, true, 1.0);
	cv_Commission =		CreateConVar("sm_shop_games_commission",	"10",	"Комиссия в %.", 0, true, 1.0, true, 50.0);
	cv_ConfirmTime =	CreateConVar("sm_shop_games_confirmtime",	"20",	"Через сколько секунд предложение об игре будет отменено.", 0, true, 10.0, true, 60.0);
	cv_StartTime =		CreateConVar("sm_shop_games_starttime",		"3",	"Через сколько секунд начнется игра после подтверждения.", 0, true, 2.0, true, 10.0);
	cv_GameTime =		CreateConVar("sm_shop_games_gametime",		"20",	"Через сколько секунд игра завершится, если игрок не совершит действие.", 0, true, 10.0, true, 30.0);

	for (new i = 0; i < GAMES; i++)
	{
		cv_OnGame[i].	AddChangeHook(OnConVarChanged);
	}
	cv_Commission.	AddChangeHook(OnConVarChanged);
	cv_ConfirmTime.	AddChangeHook(OnConVarChanged);
	cv_StartTime.	AddChangeHook(OnConVarChanged);
	cv_GameTime.	AddChangeHook(OnConVarChanged);

	AutoExecConfig(true, "shop_games", "shop");

	RegConsoleCmd("sm_games", Command_Games, "Show main menu");

	LoadRules();
	LoadBets();

	if (Shop_IsStarted())
	{
		Shop_Started();
	}
}

void RefreshConVarCache()
{
	for (new i = 0; i < GAMES; i++)
	{
		OnGame[i] =	cv_OnGame[i].IntValue;
	}

	Commission =	cv_Commission.IntValue;
	ConfirmTime =	cv_ConfirmTime.IntValue;
	StartTime =		cv_StartTime.IntValue;
	GameTime =		cv_GameTime.IntValue;
}

public void OnConfigsExecuted()
{
	char buffer[16];
	for (new i = 0; i < GAMES; i++)
	{
		FormatEx(buffer, sizeof(buffer), "shop_game_%i", i);
		CookieGames[i] = RegClientCookie(buffer, "Ignoring the offer to play", CookieAccess_Private);
	}

	CookieResultMenu = RegClientCookie("shop_game_result", "Off result menu", CookieAccess_Private);

	CheckAllClientsCookie();
	RefreshConVarCache();
}

public void OnConVarChanged(ConVar convar, char[] oldValue, char[] newValue)
{
	RefreshConVarCache();
}

public void OnClientPutInServer(client)
{
	CheckClientCookie(client);
}

public void OnClientDisconnect(client)
{
	Options[client][Started] = false;
}

public void OnPluginEnd()
{
	Shop_UnregisterMe();
}

void LoadRules()
{
	char path[PLATFORM_MAX_PATH];
	Shop_GetCfgFile(path, sizeof(path), "games_rules.txt");

	KeyValues kv = new KeyValues("Games");

	char buffer[256];
	for (int i = 0; i < GAMES; i++)
	{
		kv.ImportFromFile(path);
		Rules[i] = new Menu(Rules_Handler);
		Rules[i].SetTitle("%s \nПравила: %s\n \n", GTITLE, GameName[i]);
		IntToString(i, buffer, sizeof(buffer));

		if (kv.JumpToKey(buffer, false) && kv.GotoFirstSubKey(false))
		{
			do
			{
				if (kv.GetString(NULL_STRING, buffer, sizeof(buffer)))
				{
					Rules[i].AddItem("", buffer, ITEMDRAW_DISABLED);
				}
			}
			while (kv.GotoNextKey(false));
		}

		Rules[i].ExitBackButton = true;
	}

	delete kv;
}

public int Rules_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		ShowMenu_Rules(client);
	}
	return 0;
}

void LoadBets()
{
	char path[PLATFORM_MAX_PATH];
	Shop_GetCfgFile(path, sizeof(path), "games.txt");

	KeyValues kv = new KeyValues("Games");
	kv.ImportFromFile(path);

	if (kv.JumpToKey("Bets", false) && kv.GotoFirstSubKey(false))
	{
		char amount[16], name[64];
		do
		{
			if (kv.GetSectionName(amount, sizeof(amount)))
			{
				kv.GetString(NULL_STRING, name, sizeof(name));
				if (amount[0])
				{
					strcopy(Bets[BetsCount][Amount], sizeof(Bets[][]), amount);
					strcopy(Bets[BetsCount][Name], sizeof(Bets[][]), name);

					BetsCount++;
				}
			}
		}
		while (kv.GotoNextKey(false));
	}
	delete kv;
}

void CheckAllClientsCookie()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		CheckClientCookie(i);
	}
}

void CheckClientCookie(int client)
{
	if (IsValidClient(client))
	{
		char buffer[10];

		for (int i = 0; i < GAMES; i++)
		{
			ClientCookie[client][i] = false;
			GetClientCookie(client, CookieGames[i], buffer, sizeof(buffer));

			if(StrEqual(buffer, "1"))
			{
				ClientCookie[client][i] = true;
			}
		}

		GetClientCookie(client, CookieResultMenu, buffer, sizeof(buffer));

		if(StrEqual(buffer, "1"))
		{
			ClientCookieResult[client] = true;
		}
	}
}

public Shop_Started()
{
	Shop_AddToFunctionsMenu(FunctionDisplay, FunctionSelect);
}

public FunctionDisplay(client, String:buffer[], maxlength)
{
	char title[64];
	FormatEx(title, sizeof(title), "%s [Комиссия: %i%%]", GTITLE, Commission);

	strcopy(buffer, maxlength, title);
}

public bool FunctionSelect(client)
{
	ShowMenu_Main(client);

	return true;
}

bool IsValidClient(int client, int credits = 0)
{
	return client > 0 ? IsClientInGame(client) && !IsFakeClient(client) ? Shop_GetClientCredits(client) >= credits ? true : false : false : false;
}

public Action Command_Games(int client, int args)
{
	if (IsValidClient(client))
	{
		ShowMenu_Main(client);
	}

	return Plugin_Handled;
}

void SetMenuTitleEx(Menu menu, int client)
{
	menu.SetTitle("%s \nКредитов: %i \n \n", GTITLE, Shop_GetClientCredits(client));
}

void ShowMenu_Main(int client)
{
	Menu menu = new Menu(Main_MenuHandler);
	SetMenuTitleEx(menu, client);

	menu.AddItem("", "Играть", Options[client][Started] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.AddItem("", "", ITEMDRAW_SPACER);
	menu.AddItem("", "Правила");
	menu.AddItem("", "Настройки");

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Main_MenuHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		Shop_ShowFunctionsMenu(client);
	}
	else if (action == MenuAction_Select)
	{
		switch (param)
		{
			case 0: ShowMenu_Games(client);
			case 2: ShowMenu_Rules(client);
			case 3: ShowMenu_Settings(client);
		}
	}
	return 0;
}

void ShowMenu_Games(int client)
{
	Menu menu = new Menu(Games_MenuHandler);
	SetMenuTitleEx(menu, client);

	for (int i = 0; i < GAMES; i++)
	{
		if(OnGame[i])
		{
			menu.AddItem("", GameName[i]);
		}
	}

	if (!menu.ItemCount)
	{
		menu.AddItem("", "Нет доступных игр", ITEMDRAW_DISABLED);
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Games_MenuHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		ShowMenu_Main(client);
	}
	else if (action == MenuAction_Select)
	{
		Options[client][Game] = param;
		ShowMenu_Bets(client);
	}
	return 0;
}

void ShowMenu_Bets(int client)
{
	Menu menu = new Menu(Bets_MenuHandler);
	SetMenuTitleEx(menu, client);

	for (int i = 0; i < BetsCount; i++)
	{
		AddMenuItem(menu, Bets[i][Amount], Bets[i][Name], Shop_GetClientCredits(client) < StringToInt(Bets[i][Amount]) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Bets_MenuHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		ShowMenu_Games(client);
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));
		Options[client][bet] = StringToInt(info);

		if (!IsValidClient(client, Options[client][bet]))
		{
			PrintToChat(client, "%s Недостаточно кредитов.", GPREFIX);
			ShowMenu_Bets(client);
		}
		else
		{
			ShowMenu_Target(client);
		}
	}
	return 0;
}

void ShowMenu_Target(int client)
{
	Menu menu = new Menu(Target_MenuHandler);
	menu.SetTitle("%s \nВыберите игрока:\n \n", GTITLE);

	char userid[10], name[64];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i, Options[client][bet]) && client != i && !ClientCookie[i][Options[client][Game]])
		{
			IntToString(GetClientUserId(i), userid, sizeof(userid));
			GetClientName(i, name, sizeof(name));
			Format(name, sizeof(name), "%s (%i)", name, Shop_GetClientCredits(i));

			menu.AddItem(userid, name, Options[client][Started] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		}
	}

	if (!menu.ItemCount)
	{
		menu.AddItem("", "Нет подходящих игроков", ITEMDRAW_DISABLED);
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Target_MenuHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		ShowMenu_Bets(client);
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));

		Options[client][Target] = GetClientOfUserId(StringToInt(info));

		ShowMenu_Confirm(client);
	}
	return 0;
}

void ShowMenu_Confirm(int client)
{
	Menu menu = new Menu(Confirm_MenuHandler);
	menu.SetTitle("%s \nПодтверждение игры:\n \n", GTITLE);

	char buffer[128];

	FormatEx(buffer, sizeof(buffer), "Игра: %s", GameName[Options[client][Game]]); menu.AddItem("", buffer, ITEMDRAW_DISABLED);
	FormatEx(buffer, sizeof(buffer), "Игрок: %N", Options[client][Target]); menu.AddItem("", buffer, ITEMDRAW_DISABLED);
	FormatEx(buffer, sizeof(buffer), "Ставка: %i (Комиссия %i%%)\n \n", Options[client][bet], Commission); menu.AddItem("", buffer, ITEMDRAW_DISABLED);

	menu.AddItem("", "Играть");

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Confirm_MenuHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		ShowMenu_Target(client);
	}
	else if (action == MenuAction_Select)
	{
		if (param == 3)
		{
			new target = Options[client][Target];

			if (IsValidClient(target, Options[client][bet]) && !Options[target][Started] && !ClientCookie[target][Options[client][Game]])
			{
				PrintToChat(client, "%s Предложение отправлено.", GPREFIX);
				ShowMenu_OfferToPlay(target, client);
			}
			else
			{
				PrintToChat(client, "%s Игрок недоступен.", GPREFIX);
			}
		}
	}
	return 0;
}

void ShowMenu_OfferToPlay(int client, int caller)
{
	Options[client][Game] =		Options[caller][Game];
	Options[client][bet] =		Options[caller][bet];
	Options[client][Target] =	caller;
	Options[client][Started] =	true;
	Options[caller][Started] =	true;

	Menu menu = new Menu(OfferToPlay_MenuHandler);
	menu.SetTitle("%s \nПоступило предложение:\n \n", GTITLE);

	char buffer[128];

	FormatEx(buffer, sizeof(buffer), "От: %N", caller); menu.AddItem("", buffer, ITEMDRAW_DISABLED);
	FormatEx(buffer, sizeof(buffer), "Игра: %s", GameName[Options[caller][Game]]); menu.AddItem("", buffer, ITEMDRAW_DISABLED);
	FormatEx(buffer, sizeof(buffer), "Ставка: %i (Комиссия %i%%)\n \n", Options[caller][bet], Commission); menu.AddItem("", buffer, ITEMDRAW_DISABLED);

	menu.AddItem("", "Принять");
	menu.AddItem("", "Отказаться");

	menu.ExitBackButton = false;
	menu.Display(client, ConfirmTime);
}

public int OfferToPlay_MenuHandler(Menu menu, MenuAction action, int client, int param)
{
	int caller;
	if (client > 0)
	{
		caller = Options[client][Target];
	}

	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		ResetGame(client, caller);
		PrintToChat(caller, "%s Игрок \x04%N\x01 не принял предложение.", GPREFIX, client);
	}
	else if (action == MenuAction_Select)
	{
		if (param == 3)
		{
			PrintToChat(caller, "%s Игрок \x04%N\x01 принял предложение. Игра начнется через \x04%i\x01 секунд(ы).", GPREFIX, client, StartTime);
			CreateTimer(view_as<float>(StartTime), StartGame, client);
		}
		else
		{
			ResetGame(client, caller);
			PrintToChat(client, "%s Вы отказались от игры.", GPREFIX);
			PrintToChat(caller, "%s Игрок \x04%N\x01 отказался от игры.", GPREFIX, client);
		}
	}
	return 0;
}

void ResetGame(int client1, int client2 = 0)
{
	Options[client1][Started] = false;
	Options[client2][Started] = false;
}

void ShowMenu_Rules(int client)
{
	Menu menu = new Menu(Rules_MenuHandler);
	menu.SetTitle("%s \nПравила:\n \n", GTITLE);

	for (int i = 0; i < GAMES; i++)
	{
		if(OnGame[i])
		{
			menu.AddItem("", GameName[i]);
		}
	}

	if (!menu.ItemCount)
	{
		menu.AddItem("", "Нет доступных игр", ITEMDRAW_DISABLED);
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Rules_MenuHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		ShowMenu_Main(client);
	}
	else if (action == MenuAction_Select)
	{
		Rules[param].Display(client, MENU_TIME_FOREVER);
	}
	return 0;
}

void ShowMenu_Settings(int client)
{
	Menu menu = new Menu(Settings_MenuHandler);
	menu.SetTitle("%s \nНастройки:\n \n", GTITLE);

	char buffer[256];
	FormatEx(buffer, sizeof(buffer), "[%s] Отключить меню результатов в конце игры\n \n", ClientCookieResult[client] ? "✓" : "   ");
	menu.AddItem("", buffer);

	for (int i = 0; i < GAMES; i++)
	{
		if(OnGame[i])
		{
			FormatEx(buffer, sizeof(buffer), "[%s] Игнорировать предложения %s", ClientCookie[client][i] ? "✓" : "   ", GameName[i]);
			menu.AddItem("", buffer);
		}
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Settings_MenuHandler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		ShowMenu_Main(client);
	}
	else if (action == MenuAction_Select)
	{
		char charBool[][] = {"0", "1"};

		if (!param)
		{
			ClientCookieResult[client] ^= true;

			SetClientCookie(client, CookieResultMenu, charBool[view_as<int>(ClientCookieResult[client])]);
		}
		else
		{
			param -= 1;
			ClientCookie[client][param] ^= true;

			SetClientCookie(client, CookieGames[param], charBool[view_as<int>(ClientCookieResult[client])]);
		}

		ShowMenu_Settings(client);
	}
	return 0;
}

public Action StartGame(Handle timer, any client)
{
	switch (Options[client][Game])
	{
		case 0: StartGame_KNB(client);
		case 1: StartGame_Poker(client);
	}
	return Plugin_Continue;
}

int GetWinCredits(int iBet)
{
	return RoundToNearest(float(iBet) / 100 * (100 - Commission * 2));
}

void ResultGame(int client, char[] game_name, char[] buffer1, char[] buffer2, bool win = false)
{
	int iBet = Options[client][bet];
	int credits = GetWinCredits(iBet);

	if (win)
	{
		Shop_GiveClientCredits(client, credits);
	}
	else
	{
		Shop_TakeClientCredits(client, iBet);
	}

	char buffer3[128];
	FormatEx(buffer3, sizeof(buffer3), "Вы %s %i кредитов", win ? "выиграли" : "проиграли", win ? iBet + credits : iBet);

	if(!ClientCookieResult[client])
	{
		Menu menu = new Menu(Result_MenuHandler);
		menu.SetTitle("%s:\n \n%s\n%s\n \n%s\n \n", game_name, buffer1, buffer2, buffer3);

		menu.AddItem("", "Закрыть");

		menu.ExitBackButton = false;
		menu.Display(client, MENU_TIME_FOREVER);
	}

	PrintToChat(client, "%s %s.", GPREFIX, buffer3);
	ResetGame(client);
}

public int Result_MenuHandler(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

int IsClientPlay(client)
{
	return Options[client][Started];
}

int GetClientEnemy(client)
{
	return Options[client][Target];
}
