#include <sourcemod>
#include <shop>
#include <helco>

#pragma newdecls required

int KillT[2], KillCT[2], WinCT[2], WinT[2], MinRoundTime;

ConVar cvarPath, cvarRoundMinTime;

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