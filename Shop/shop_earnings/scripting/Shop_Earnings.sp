#include <sourcemod>
#include <shop>
#include <helco>

#pragma newdecls required

int KillT[2], KillCT[2], WinCT[2], WinT[2], MinRoundTime;

ConVar cvarPath, cvarRoundMinTime;

enum
{
	ONLINE_30_MINUTES,
	ONLINE_60_MINUTES,
	ONLINE_90_MINUTES,
	ONLINE_120_MINUTES,
	ONLINE_150_MINUTES,
	ONLINE_180_MINUTES,
	ONLINE_210_MINUTES,
	ONLINE_240_MINUTES,
	ONLINE_270_MINUTES,
	ONLINE_300_MINUTES,
	ONLINE_330_MINUTES,
	ONLINE_360_MINUTES
	
}

static const int Minutes[][] = {30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330, 360, 390, 420, 450, 480, 510, 540, 570, 600};

int	
	ClientOnlineId[MAXPLAYERS + 1],
	ClientOnline[MAXPLAYERS + 1],
	RewardOnline[sizeof(Minutes)];
	
public Plugin myinfo =
{
	name		= "[Shop] Earnings",
	version		= "1.0",
	author		= "hEl"
};

public void OnPluginStart()
{
	cvarPath = CreateConVar("shop_earning_path", "configs/shop/earnings.cfg");
	cvarPath.AddChangeHook(OnConVarChange);
	cvarRoundMinTime = CreateConVar("shop_earning_min_round_time", "180");
	AutoExecConfig(true, "plugin.Earnings", "shop");
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	MinRoundTime = GetTime() + cvarRoundMinTime.IntValue;
	LoadConfig();
	LoadTranslations("shop_earnings.phrases");
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(KillT[0] || KillT[1] || KillCT[0] || KillCT[1])
	{
		UnhookEvent("player_death", OnPlayerDeath);
		KillT[0] = 0;
		KillT[1] = 0;
		KillCT[0] = 0;
		KillCT[1] = 0;

	}
	if(WinT[0] || WinT[1] || WinCT[0] || WinCT[1])
	{
		UnhookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
		WinT[0] = 0;
		WinT[1] = 0;
		WinCT[0] = 0;
		WinCT[1] = 0;
	}
	LoadConfig();
}

public void OnMapStart()
{
	if(Online[0][0])
	{
		CreateTimer(60.0, Timer_CheckOnline, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_CheckOnline(Handle hTimer)
{

}

void LoadConfig()
{
	char szBuffer[256];
	cvarPath.GetString(szBuffer, 256);
	BuildPath(Path_SM, szBuffer, 256, szBuffer);
	KeyValues hKeyValues = new KeyValues("Earnings");
	if(!hKeyValues.ImportFromFile(szBuffer))
	{
		LogError("Config file \"%s\" does not exists...", szBuffer);
		return;
	}
	if(hKeyValues.JumpToKey("events"))
	{
		KillT[0] = hKeyValues.GetNum("kill_t");
		KillT[1] = hKeyValues.GetNum("death_t");
		KillCT[0] = hKeyValues.GetNum("kill_ct");
		KillCT[1] = hKeyValues.GetNum("death_ct");

		WinT[0] = hKeyValues.GetNum("win_t");
		WinT[1] = hKeyValues.GetNum("lose_t");

		WinCT[0] = hKeyValues.GetNum("win_ct");
		WinCT[1] = hKeyValues.GetNum("lose_ct");

		if(KillT[0] || KillT[1] || KillCT[0] || KillCT[1])
		{
			HookEvent("player_death", OnPlayerDeath);
		}
		if(WinT[0] || WinT[1] || WinCT[0] || WinCT[1])
		{
			HookEvent("round_end", OnRoundEnd);
		}
	}
	hKeyValues.Rewind();
	if(hKeyValues.JumpToKey("online") && hKeyValues.GotoFirstSubKey(false))
	{
		int iCount;
		do
		{
			hKeyValues.GetSectionName(szBuffer, 256);
			Online[0][iCount] = StringToInt(szBuffer);
			hKeyValues.GetString(NULL_STRING, szBuffer, 256);
			Online[1][iCount] = StringToInt(szBuffer);
			iCount++;
		}
		while(hKeyValues.GotoNextKey(false) && iCount < 10);
		
		if(iCount)
		{
			PrintOnlineArray();
			int iIndex, iTemp[2];
			for(int i; i < iCount; i++)
			{
				iIndex = -1;
				for(int j = i; j < iCount; j++)
				{
					if(iIndex == -1 || Online[0][j] > Online[0][iIndex])
					{
						iIndex = j;
					}
				}
				if(iIndex != -1 && iIndex != i)
				{
					iTemp[0] = Online[0][i];
					iTemp[1] = Online[1][i];
					Online[0][i] = Online[0][iIndex];
					Online[1][i] = Online[1][iIndex];
					Online[0][iIndex] = iTemp[0];
					Online[1][iIndex] = iTemp[1];
				}
			}
		
			PrintOnlineArray();
		}
	}
	delete hKeyValues;
}

public void OnRoundStart(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	MinRoundTime = GetTime() + cvarRoundMinTime.IntValue;
}
public void OnRoundEnd(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	if(GetTime() < MinRoundTime)
		return;
	
	int iWinner = hEvent.GetInt("winner");
	if(iWinner > 1)
	{
		int iLoser = iWinner == 2 ? 3:2, iCredits, iTeam;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i) || IsFakeClient(i) || (iTeam = GetClientTeam(i)) < 2)
				continue;
			
			switch(iWinner)
			{
				case 2:
				{
					if(WinT[0] && iTeam == iWinner && IsPlayerAlive(i) && (iCredits = Shop_GiveClientCredits(i, WinT[0])) != -1)
					{
						PrintToChat2(i, "%t", "Earn", iCredits, "Win");
					}
					if(WinCT[1] && iTeam == iLoser && (iCredits = Shop_TakeClientCredits(i, WinCT[1])) != -1)
					{
						PrintToChat2(i, "%t", "Lost", iCredits, "Lose");
					}
				}
				case 3:
				{
					if(WinCT[0] && iTeam == iWinner && IsPlayerAlive(i) && (iCredits = Shop_GiveClientCredits(i, WinCT[0])) != -1)
					{
						PrintToChat2(i, "%t", "Earn", iCredits, "Win");
					}
					if(WinT[1] && iTeam == iLoser && (iCredits = Shop_TakeClientCredits(i, WinT[1])) != -1)
					{
						PrintToChat2(i, "%t", "Lost", iCredits, "Lose");
					}
				}
			}
		}
	}
}


public void OnPlayerDeath(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker")), iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(0 < iAttacker <= MaxClients && iAttacker != iClient)
	{
		int iCredits;
		switch(GetClientTeam(iAttacker))
		{
			case 2:
			{
				if(KillT[0])
				{
					if(!IsFakeClient(iAttacker) && (iCredits = Shop_GiveClientCredits(iAttacker, KillT[0])) != -1)
					{
						PrintToChat2(iAttacker, "%t", "Earn", iCredits, "Kill");
					}
				}
				if(KillCT[1])
				{
					if(!IsFakeClient(iClient) && (iCredits = Shop_TakeClientCredits(iClient, KillCT[1])) != -1)
					{
						PrintToChat2(iClient, "%t", "Lost", iCredits, "Death");
					}
				}
			}
			case 3:
			{
				if(KillCT[0])
				{
					if(!IsFakeClient(iAttacker) && (iCredits = Shop_GiveClientCredits(iAttacker, KillCT[0])) != -1)
					{
						PrintToChat2(iAttacker, "%t", "Earn", iCredits, "Kill");
					}
				}
				if(KillT[1])
				{
					if(!IsFakeClient(iClient) && (iCredits = Shop_TakeClientCredits(iClient, KillT[1])) != -1)
					{
						PrintToChat2(iClient, "%t", "Lost", iCredits, "Death");
					}
				}
			}
		}
	}
}



stock void PrintOnlineArray()
{
	PrintToServer("PrintOnlineArray");
	for(int i; i < 10; i++)
	{
		if(Online[0][i] == 0)
			break;
		
		PrintToServer("%i sec = %i cred", Online[0][i], Online[1][i]);
	}
}

