#include <sourcemod>
#include <sdktools_sound>
#include <sdktools_functions>

#pragma newdecls required

enum
{
	CONVAR_TOGGLE,
	CONVAR_MINE_MODE,
	CONVAR_MINE_DELAY,
	CONVAR_MINE_MIN_ZOMBIES,
	CONVAR_MAX_EXPLODES_FOR_ROUND,
	CONVAR_MAX_CLIENT_EXPLODES_FOR_ROUND,
	CONVAR_ROUND_START_DELAY,
	CONVAR_EXPLODE_LAST_ZOMBIE,
	CONVAR_MINE_MAX_TOGETHER,
	CONVAR_EXPLODE_LAUNCH,

	CONVAR_TOTAL
}

ConVar ConVars[CONVAR_TOTAL];
int Settings[CONVAR_TOTAL], ClientExplodeTime[MAXPLAYERS + 1], ClientOwner[MAXPLAYERS + 1], ClientExplodes[MAXPLAYERS + 1], Explodes, Time;
bool ForceDeath[MAXPLAYERS + 1];

static const char BeepSound[] = "weapons/c4/c4_beep1.wav";
static const char PreBoomSound[] = "weapons/cguard/charging.wav";
static const char BoomSound[] = "weapons/explode3.wav";

public Plugin myinfo = 
{
	name		= "KnifeExplode",
	version		= "1.0",
	description	= "",
	author		= "hEl"
};

public void OnPluginStart()
{
	LoadTranslations("knife_explode.phrases");
	CreateConVar2(CONVAR_TOGGLE, "ke_toggle", "1");
	CreateConVar2(CONVAR_MINE_MODE, "ke_mine_mode", "0");
	CreateConVar2(CONVAR_MINE_DELAY, "ke_mine_delay", "50");
	CreateConVar2(CONVAR_MINE_MIN_ZOMBIES, "ke_mine_min_zombies", "3");
	CreateConVar2(CONVAR_MINE_MAX_TOGETHER, "ke_mine_max_together", "3");
	CreateConVar2(CONVAR_MAX_EXPLODES_FOR_ROUND, "ke_max_explodes_round", "3");
	CreateConVar2(CONVAR_MAX_CLIENT_EXPLODES_FOR_ROUND, "ke_max_client_explodes_round", "3");
	CreateConVar2(CONVAR_ROUND_START_DELAY, "ke_round_start_delay", "60");
	CreateConVar2(CONVAR_EXPLODE_LAST_ZOMBIE, "ke_expode_last_zombie", "0");
	CreateConVar2(CONVAR_EXPLODE_LAUNCH, "ke_expode_launch", "0");
	
	HookEvent("player_hurt", OnPlayerHurt);
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	
	AutoExecConfig(true, "plugin.KnifeExplode");
}

void CreateConVar2(int ConVarId, const char[] cvarName, const char[] cvarValue)
{
	ConVars[ConVarId] = CreateConVar(cvarName, cvarValue);
	ConVars[ConVarId].AddChangeHook(OnConVarChange);
	Settings[ConVarId] = ConVars[ConVarId].IntValue;
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	for(int i; i < CONVAR_TOTAL; i++)
	{
		if(ConVars[i] == cvar)
		{
			Settings[i] = cvar.IntValue;
			break;
			
		}
	}
}

public void OnMapStart()
{
	PrecacheSound(BeepSound, true);
	PrecacheSound(PreBoomSound, true);
	PrecacheSound(BoomSound, true);
}

public Action OnPlayerDeath(Event hEvent, const char[] name, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(ForceDeath[iClient])
	{
		ForceDeath[iClient] = false;
		return Plugin_Handled;
	}
	else
	{
		int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
		
		if(0 < iAttacker <= MaxClients && ClientOwner[iAttacker] && iAttacker != iClient && GetClientTeam(iAttacker) == 2)
		{
			if(IsClientInGame(ClientOwner[iAttacker]))
			{
				PrintToChat2(ClientOwner[iAttacker], "%t", "Zombie infected human and was rescued from the explosion", iAttacker, iClient);
			}
			if(!IsFakeClient(iAttacker))
			{
				PrintToChat2(iAttacker, "%t", "You were saved from the explosion");
			}
			ClientOwner[iAttacker] = 0;
			
		}
	}
	
	return Plugin_Continue;
}

public void OnRoundStart(Event hEvent, const char[] name, bool bDontBroadcast)
{
	Explodes = 0;
	Time = GetTime() + Settings[CONVAR_ROUND_START_DELAY];
}

public void OnRoundEnd(Event hEvent, const char[] name, bool bDontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		OnClientDisconnect(i);
	}
}



public void OnPlayerHurt(Event hEvent, const char[] name, bool bDontBroadcast)
{
	if(!Settings[CONVAR_TOGGLE])
		return;
		
	int iClient, iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	
	if(!(0 < iAttacker <= MaxClients) || GetClientTeam(iAttacker) != 3 || IsFakeClient(iAttacker) || (iClient = GetClientOfUserId(hEvent.GetInt("userid"))) == iAttacker)
	{
		return;
	}
	char szBuffer[4];
	hEvent.GetString("weapon", szBuffer, 4);
	
	if(szBuffer[0] != 'k')
	{
		return;
	}
	
	if(Settings[CONVAR_MAX_EXPLODES_FOR_ROUND] > 0 && Settings[CONVAR_MAX_EXPLODES_FOR_ROUND] <= Explodes)
	{
		PrintToChat2(iAttacker, "%t", "The limit of explosions per round is reached", Settings[CONVAR_MAX_EXPLODES_FOR_ROUND]);
		return;
	}
	if(Settings[CONVAR_MAX_CLIENT_EXPLODES_FOR_ROUND] > 0 && Settings[CONVAR_MAX_EXPLODES_FOR_ROUND] <= ClientExplodes[iAttacker])
	{
		PrintToChat2(iAttacker, "%t", "You have reached the limit of explosions per round", Settings[CONVAR_MAX_CLIENT_EXPLODES_FOR_ROUND]);
		return;
	}
	if(ClientOwner[iClient])
	{
		PrintToChat2(iAttacker, "%t", "This zombie is already mined", Settings[CONVAR_MAX_CLIENT_EXPLODES_FOR_ROUND]);
		return;
	}
	if(Settings[CONVAR_ROUND_START_DELAY] > 0)
	{
		int iTime = GetTime();
		if(Time > iTime)
		{
			PrintToChat2(iAttacker, "%t", "Not enough time has passed", Time - iTime);
			return;
		}
		
	}
	if(Settings[CONVAR_MINE_MAX_TOGETHER] > 0 && Settings[CONVAR_MINE_MAX_TOGETHER] <= GetClientMines(iClient))
	{
		PrintToChat2(iAttacker, "%t", "You have reached the limit of simultaneously mined zombies", Settings[CONVAR_MINE_MAX_TOGETHER]);
		return;
	}
	if(Settings[CONVAR_MINE_MIN_ZOMBIES] > 0 && Settings[CONVAR_MINE_MIN_ZOMBIES] > GetZombiesCount())
	{
		PrintToChat2(iAttacker, "%t", "Not enough zombies", Settings[CONVAR_MINE_MIN_ZOMBIES]);
		return;
	}
	
	if(!(0 < Settings[CONVAR_MINE_DELAY] < 300))
	{
		return;
	}
	ClientOwner[iClient] = iAttacker;
	ClientExplodeTime[iClient] = Settings[CONVAR_MINE_DELAY];
	CreateTimer(1.0, Timer_Explode, iClient, TIMER_REPEAT);
	
	PrintToChat2(iAttacker, "%t", "You have successfully mined", iClient, Settings[CONVAR_MINE_DELAY]);
	PrintToChat2(iClient, "%t", "You were laid", iAttacker, Settings[CONVAR_MINE_DELAY]);
}


public Action Timer_Explode(Handle hTimer, int iClient)
{
	if(	IsClientInGame(iClient) && 
		ClientExplodeTime[iClient] > 0 && 
		IsPlayerAlive(iClient) && 
		GetClientTeam(iClient) == 2 && 
		ClientOwner[iClient] != 0 && 
		IsClientInGame(ClientOwner[iClient]) && 
		IsPlayerAlive(ClientOwner[iClient]) && 
		GetClientTeam(ClientOwner[iClient]) == 3)
	{
		ClientExplodeTime[iClient]--;
	
		switch(ClientExplodeTime[iClient])
		{
			case 0:
			{
				if(Settings[CONVAR_EXPLODE_LAST_ZOMBIE] || GetZombiesCount(1) > 1)
				{
					if(Settings[CONVAR_MINE_MODE] < 2)
					{
						EmitSoundToAll(BoomSound, iClient);
					}
					ForceDeath[iClient] = true;
					ForcePlayerSuicide(iClient);
					Event hEvent = CreateEvent("player_death", true);
					if(hEvent)
					{
						hEvent.SetInt("userid", GetClientUserId(iClient));
						hEvent.SetInt("attacker", GetClientUserId(ClientOwner[iClient]));
						hEvent.SetString("weapon", "knife");
						hEvent.Fire();
					}
					SetEntProp(ClientOwner[iClient], Prop_Data, "m_iFrags", GetEntProp(ClientOwner[iClient], Prop_Data, "m_iFrags") + 1);
					Explodes++;
					ClientExplodes[ClientOwner[iClient]]++;
				}
				ClientOwner[iClient] = 0;
				ClientExplodeTime[iClient] = 0;
				return Plugin_Stop;
			}
			case 1:
			{
				if(Settings[CONVAR_MINE_MODE] < 2)
				{
					EmitSoundToAll(PreBoomSound, iClient);
				}
				if(Settings[CONVAR_EXPLODE_LAUNCH])
				{
					TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, 2000.0}));
				}
			}
			default:
			{
				if(!Settings[CONVAR_MINE_MODE])
				{
					EmitSoundToAll(BeepSound, iClient);
				}
			}
		}

		return Plugin_Continue;
	}
	ClientOwner[iClient] = 
	ClientExplodeTime[iClient] = 0;
	return Plugin_Stop;
	
}

int GetClientMines(int iClient)
{
	int iCount;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(ClientOwner[i] == iClient)
		{
			iCount++;
		}
	}
	
	return iCount;
}

int GetZombiesCount(int iAlive = -1)
{
	int iCount;
	bool bAlive = view_as<bool>(iAlive);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && (iAlive == -1 || bAlive == IsPlayerAlive(i)))
		{
			iCount++;
		}
	}
	
	return iCount;
}

public void OnClientDisconnect(int iClient)
{
	ClientOwner[iClient] = 0;
	ClientExplodes[iClient] = 0;
	ClientExplodeTime[iClient] = 0;
}

void PrintToChat2(int iClient, const char[] message, any ...)
{
	int iLen = strlen(message) + 255;
	char[] szBuffer = new char[iLen];
	SetGlobalTransTarget(iClient);
	VFormat(szBuffer, iLen, message, 3);
	SendMessage(iClient, szBuffer, iLen);
}


stock void PrintToChatAll2(const char[] message, any ...)
{
	int iLen = strlen(message) + 255;
	char[] szBuffer = new char[iLen];
	for(int i = 1;i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			SetGlobalTransTarget(i);
			VFormat(szBuffer, iLen, message, 2);
			SendMessage(i, szBuffer, iLen);
		}
	}
}


void SendMessage(int iClient, char[] szBuffer, int iSize)
{
	static int mode = -1;
	if(mode == -1)
	{
		mode = view_as<int>(GetUserMessageType() == UM_Protobuf);
	}
	SetGlobalTransTarget(iClient);
	Format(szBuffer, iSize, "\x04%t \x01%s", "Tag", szBuffer);
	ReplaceString(szBuffer, iSize, "{C}", "\x07");
	/*ReplaceString(szBuffer, iSize, "{MC}", MAIN_COLOR);
	ReplaceString(szBuffer, iSize, "{C1}", COLOR_FIRST);
	ReplaceString(szBuffer, iSize, "{C2}", COLOR_SECOND);*/

	
	Handle hMessage = StartMessageOne("SayText2", iClient, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	switch(mode)
	{
		case 0:
		{
			BfWrite bfWrite = UserMessageToBfWrite(hMessage);
			bfWrite.WriteByte(iClient);
			bfWrite.WriteByte(true);
			bfWrite.WriteString(szBuffer);
		}
		case 1:
		{
			Protobuf protoBuf = UserMessageToProtobuf(hMessage);
			protoBuf.SetInt("ent_idx", iClient);
			protoBuf.SetBool("chat", true);
			protoBuf.SetString("msg_name", szBuffer);
			for(int k;k < 4;k++)	
				protoBuf.AddString("params", "");
		}
	}
	EndMessage();
}