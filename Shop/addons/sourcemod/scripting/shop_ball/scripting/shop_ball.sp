#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <shop>

#define HELPER

#undef REQUIRE_PLUGIN
#tryinclude <HNS>
#define REQUIRE_PLUGIN

#pragma newdecls required

#define PLUGIN_VERSION	"2.0.3"

ConVar cvarModel, cvarMinPlayers, cvarMinTime, cvarSound;

float fBallPos[3];

int Credits[MAXPLAYERS], Cooldown;
bool HNS, Passed[MAXPLAYERS+1];

int CurrentPosition;
ArrayList SteamIDs;
char BallModel[256], PickSound[256];

GlobalForward
	GF_OnClientPickGift;

#if defined HELPER
const int MAX_HELPERS = 10;
int Helper[MAX_HELPERS], Helpers;
#endif


public Plugin myinfo = 
{
	name = "[Shop] Ball [Edited]",
	author = "FrozDark",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://www.hlmod.ru/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ShopBall_IsMapHaveGift", Native_IsMapHaveGift);
	RegPluginLibrary("shop_ball");
	return APLRes_Success;
}

public int Native_IsMapHaveGift(Handle plugin, int numParams)
{
	return view_as<int>(fBallPos[0] != 0.0);
}


public void OnPluginStart()
{
	GF_OnClientPickGift = new GlobalForward("ShopBall_OnPlayerGiftPicked", ET_Ignore, Param_Cell);
	SteamIDs = new ArrayList(ByteCountToCells(1));
	cvarModel = CreateConVar("sm_ball_model", "models/zombieden/xmas/giftbox.mdl", "Model file for the ball");
	cvarSound = CreateConVar("sm_ball_sound", "items/gift_drop.wav");
	cvarMinPlayers = CreateConVar("sm_ball_min_players", "4");
	cvarMinTime = CreateConVar("sm_ball_min_time", "180");
	
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	
	RegAdminCmd("sm_ball_reload", Command_Reload, ADMFLAG_ROOT, "Reloads configurations");
	RegAdminCmd("sm_ballset", Command_SetBallPosition, ADMFLAG_ROOT, "Sest ball position at aim");
	RegAdminCmd("sm_ballsetcredits", Command_SetPositionCredits, ADMFLAG_ROOT, "Sets credits on positions");
	LoadTranslations("shop_ball.phrases");
	HNS = LibraryExists("HNS");
	AutoExecConfig(true, "plugin.Ball", "shop");


	#if defined HELPER
	RegConsoleCmd("sm_ball_present", Command_Helper_BallPresent);
	LoadHelpers();
	#endif
}

#if defined HELPER

public Action Command_Helper_BallPresent(int iClient, int iArgs)
{
	if(!iClient || !ClientIsHelper(iClient))
	{
		return Plugin_Continue;
	}
	char szBuffer[64];
	float fPos[3];
	GetCurrentMap(szBuffer, 64);
	GetClientAbsOrigin(iClient, fPos);
	SetBallPosition(iClient);
	ServerCommand("sm_ball_reload");
	ServerCommand("sm_ballsetcredits 1 200");
	ServerCommand("sm_ballsetcredits 2 150");
	ServerCommand("sm_ballsetcredits 3 100");
	ServerCommand("sm_ballsetcredits 0 50");
	ServerCommand("sm_ball_reload");
	LogMessage("Helper %L set ball [Map: %s, Pos: %.1f %.1f %.1f", iClient, szBuffer, fPos[0], fPos[1], fPos[2]);
	return Plugin_Handled;
}

bool ClientIsHelper(int iClient)
{
	int iSteamID = GetSteamAccountID(iClient, true);

	for(int i; i < Helpers; i++)
	{
		if(Helper[i] == iSteamID)
		{
			return true;
		}
	}
	return false;
}
void LoadHelpers()
{
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, 256, "configs/shop/ball_helpers.txt");
	File hFile = OpenFile(szBuffer, "r");
	if(hFile)
	{
		
		while (!hFile.EndOfFile() && Helpers < MAX_HELPERS)
		{
			if (!hFile.ReadLine(szBuffer, 256))
				continue;
			
			if(TrimString(szBuffer) > 0)
			{
				Helper[Helpers++] = StringToInt(szBuffer);
			}
		}
	}
}
#endif
public void OnMapStart()
{
	cvarModel.GetString(BallModel, 256);
	if(BallModel[0])
	{
		cvarSound.GetString(PickSound, 256);
		if(PickSound[0])
		{
			PrecacheSound(PickSound);
		}
		PrecacheModel(BallModel);
		PrecacheModel("models/items/car_battery01.mdl");
		LoadCfg();
	}
	else
	{
		SetFailState("No ball model");
	}
}

public void OnMapEnd()
{
	Cooldown = 0;
	fBallPos[0] = 0.0;
	SteamIDs.Clear();
}

public void OnLibraryAdded(const char[] name)
{
	if(strcmp(name, "HNS", false) == 0)
	{
		HNS = true;
	}
}
public void OnLibraryRemoved(const char[] name)
{
	if(strcmp(name, "HNS", false) == 0)
	{
		HNS = false;
	}
}

public void OnClientPutInServer(int iClient)
{
	if(!IsFakeClient(iClient))
	{
		int iSteamID = GetSteamAccountID(iClient, true);
		Passed[iClient] = (iSteamID <= 0 || (SteamIDs.Length && SteamIDs.FindValue(iSteamID) != -1));
	}
}

void LoadCfg()
{
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, 256, "configs/shop/ball.txt");
	KeyValues hKeyValues = new KeyValues("Ball");
	
	if(!hKeyValues.ImportFromFile(szBuffer))
	{
		SetFailState("Config file \"%s\" does not exists", szBuffer);
	}
	
	GetCurrentMap(szBuffer, 256);
	if(!hKeyValues.JumpToKey(szBuffer))
	{
		delete hKeyValues;
		return;
	}
	
	hKeyValues.GetVector("pos", fBallPos);
	for (int i = 1; i < MAXPLAYERS; i++)
	{
		IntToString(i, szBuffer, 16);
		Credits[i] = hKeyValues.GetNum(szBuffer, -1);
		if ((Credits[i] = hKeyValues.GetNum(szBuffer, -1)) == -1)
		{
			Credits[i] = hKeyValues.GetNum("0", 25);
		}
	}
	delete hKeyValues;
}

public void OnRoundStart(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	if(fBallPos[0] != 0.0)
	{
		if(cvarMinPlayers.IntValue > GetClientCount2())
		{
			return;
		}
		int iTime = GetTime();
		if(Cooldown > iTime)
		{
			return;
		}
		int iMinTime = cvarMinTime.IntValue;
		if(iMinTime)
		{
			if(iMinTime == -1)
			{
				Cooldown = RoundToNearest((FindConVar("mp_roundtime")).FloatValue * 60.0) - 5;
			}
			else
			{
				Cooldown = iMinTime;
			}
			Cooldown += iTime;
		}
		CurrentPosition = 0;
		for(int i = 1; i <= MaxClients; i++)
		{
			Passed[i] = false;
		}
		SteamIDs.Clear();
		Stock_SpawnGift();
	}
	
}

public Action Command_SetBallPosition(int client, int argc)
{
	if (!client || !IsClientInGame(client))
	{
		ReplyToCommand(client, "ERROR: You can't use that command while not in game!");
		return Plugin_Handled;
	}
	SetBallPosition(client);
	return Plugin_Handled;
}

void SetBallPosition(int client)
{
	char szBuffer[256], szBuffer2[256];
	BuildPath(Path_SM, szBuffer, 256, "configs/shop/ball.txt");
	KeyValues hKeyValues = new KeyValues("Ball");
	float pos[3];
	if (hKeyValues.ImportFromFile(szBuffer))
	{
		GetCurrentMap(szBuffer2, 256);
		if(hKeyValues.JumpToKey(szBuffer2, true))
		{
			GetClientAbsOrigin(client, pos);
			pos[2] += 30.0;
			hKeyValues.SetVector("pos", pos);
			hKeyValues.Rewind();
			hKeyValues.ExportToFile(szBuffer);
			PrintToChat2(client, "%t", "SetPosSuccess", pos[0], pos[1], pos[2]);
		}
	}
	else
	{
		PrintToChat2(client, "%t", "SetPosFailed");
	}
	delete hKeyValues;
}

public Action Command_SetPositionCredits(int client, int argc)
{
	char sPos[12];
	char sCredits[24];
	if (argc < 2)
	{
		ReplyToCommand(client, "Usage: sm_ballsetcredits <player position> <credits>");
		return Plugin_Handled;
	}
	char szBuffer[256], szBuffer2[256];
	BuildPath(Path_SM, szBuffer, 256, "configs/shop/ball.txt");
	KeyValues hKeyValues = new KeyValues("Ball");
	if (hKeyValues.ImportFromFile(szBuffer))
	{
		GetCurrentMap(szBuffer2, 256);
		if(hKeyValues.JumpToKey(szBuffer2, true))
		{
			GetCmdArg(1, sPos, sizeof(sPos));
			GetCmdArg(2, sCredits, sizeof(sCredits));
			
			int pos = StringToInt(sPos);
			if (!(0 <= pos <= MAXPLAYERS))
			{
				if (!client)
				{
					ReplyToCommand(client, "ERROR: Set position from 0 to 64!");
				}
				else
				{
					PrintToChat2(client, "%t", "SetPosLimit");
				}
				return Plugin_Handled;
			}
			int credits = StringToInt(sCredits);
			hKeyValues.SetNum(sPos, credits);
			hKeyValues.Rewind();
			hKeyValues.ExportToFile(szBuffer);
			
			if (pos == 0)
			{
				if (!client)
				{
					ReplyToCommand(client, "%d credits for other positions has been set successfuly!", credits);
				}
				else
				{
					PrintToChat2(client, "%t", "CreditsSetForOtherSuccess", credits);
				}
			}
			else
			{
				if (!client)
				{
					ReplyToCommand(client, "Credits %d for the position %d set successfuly!", credits, pos);
				}
				else
				{
					PrintToChat2(client, "%t", "CreditsSetSuccess", credits, pos);
				}
			}

		}
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "ERROR: The ball position for the map is not configured!");
	return Plugin_Handled;
}

public Action Command_Reload(int client, int argc)
{
	LoadCfg();
	ReplyToCommand(client, "Configuration reloaded!");
	return Plugin_Handled;
}

void Stock_SpawnGift()
{
	int ent = CreateEntityByName("prop_dynamic_override");

	if (ent != -1)
	{
		char tmp[64];

		FormatEx(tmp, sizeof(tmp), "gift_%i", ent);
		DispatchKeyValue(ent, "model", BallModel);
		DispatchKeyValue(ent, "solid", "0");
		DispatchKeyValue(ent, "targetname", tmp);
		DispatchSpawn(ent);
		TeleportEntity(ent, fBallPos, NULL_VECTOR, NULL_VECTOR);
		
		int rot = CreateEntityByName("func_rotating");
		FormatEx(tmp, sizeof(tmp), "gift_rot_%i", rot);
		DispatchKeyValueVector(rot, "origin", fBallPos);
		DispatchKeyValue(rot, "targetname", tmp);
		DispatchKeyValue(rot, "maxspeed", "200");
		DispatchKeyValue(rot, "friction", "0");
		DispatchKeyValue(rot, "dmg", "0");
		DispatchKeyValue(rot, "solid", "0");
		DispatchKeyValue(rot, "spawnflags", "64");
		DispatchSpawn(rot);
		
		Format(tmp, sizeof(tmp), "%s,Kill,,0,-1", tmp);
		DispatchKeyValue(ent, "OnKilled", tmp);
		
		SetVariantString("!activator");
		AcceptEntityInput(ent, "SetParent", rot, rot);
		
		int trigger = CreateEntityByName("trigger_multiple");
		FormatEx(tmp, sizeof(tmp), "gift_trigger_%i", trigger);
		DispatchKeyValueVector(trigger, "origin", fBallPos);
		DispatchKeyValue(trigger, "targetname", tmp);
		DispatchKeyValue(trigger, "wait", "0");
		DispatchKeyValue(trigger, "spawnflags", "1");
		DispatchSpawn(trigger);
		
		Format(tmp, sizeof(tmp), "%s,Kill,,0,-1", tmp);
		DispatchKeyValue(rot, "OnKilled", tmp);
		
		ActivateEntity(trigger);
		SetEntProp(trigger, Prop_Data, "m_spawnflags", 1);
		SetEntityModel(trigger, "models/items/car_battery01.mdl");
		
		float fMins[3], fMaxs[3];
		GetEntPropVector(ent, Prop_Send, "m_vecMins", fMins);
		GetEntPropVector(ent, Prop_Send, "m_vecMaxs", fMaxs);
		
		SetEntPropVector(trigger, Prop_Send, "m_vecMins", fMins);
		SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", fMaxs);
		SetEntProp(trigger, Prop_Send, "m_nSolidType", 2);
		
		int iEffects = GetEntProp(trigger, Prop_Send, "m_fEffects");
		iEffects |= 32;
		SetEntProp(trigger, Prop_Send, "m_fEffects", iEffects);
		
		SetVariantString("!activator");
		AcceptEntityInput(trigger, "SetParent", rot, rot);
		AcceptEntityInput(rot, "Start");
		
		HookSingleEntityOutput(trigger, "OnStartTouch", OnStartTouch);
	}
}

/*void Stock_SpawnGift()
{
	int ent = CreateEntityByName("prop_physics_override");

	if (ent != -1)
	{
		char tmp[64];

		FormatEx(tmp, sizeof(tmp), "gift_%i", ent);
		DispatchKeyValue(ent, "model", BallModel);
		DispatchKeyValue(ent, "solid", "6");
		DispatchKeyValue(ent, "physicsmode", "2");
		DispatchKeyValue(ent, "massScale", "1.0");
		DispatchKeyValue(ent, "targetname", tmp);
		DispatchSpawn(ent);
		
		SetEntProp(ent, Prop_Send, "m_usSolidFlags", 8);
		SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
		TeleportEntity(ent, fBallPos, NULL_VECTOR, NULL_VECTOR);
		
		int rot = CreateEntityByName("func_rotating");
		FormatEx(tmp, sizeof(tmp), "gift_rot_%i", rot);
		DispatchKeyValueVector(rot, "origin", fBallPos);
		DispatchKeyValue(rot, "targetname", tmp);
		DispatchKeyValue(rot, "maxspeed", "200");
		DispatchKeyValue(rot, "friction", "0");
		DispatchKeyValue(rot, "dmg", "0");
		DispatchKeyValue(rot, "solid", "0");
		DispatchKeyValue(rot, "spawnflags", "64");
		DispatchSpawn(rot);
		
		Format(tmp, sizeof(tmp), "%s,Kill,,0,-1", tmp);
		DispatchKeyValue(ent, "OnKilled", tmp);
		
		SetVariantString("!activator");
		AcceptEntityInput(ent, "SetParent", rot, rot);
		
		int trigger = CreateEntityByName("trigger_multiple");
		FormatEx(tmp, sizeof(tmp), "gift_trigger_%i", trigger);
		DispatchKeyValueVector(trigger, "origin", fBallPos);
		DispatchKeyValue(trigger, "targetname", tmp);
		DispatchKeyValue(trigger, "wait", "0");
		DispatchKeyValue(trigger, "spawnflags", "1");
		DispatchSpawn(trigger);
		
		Format(tmp, sizeof(tmp), "%s,Kill,,0,-1", tmp);
		DispatchKeyValue(rot, "OnKilled", tmp);
		
		ActivateEntity(trigger);
		SetEntProp(trigger, Prop_Data, "m_spawnflags", 1);
		SetEntityModel(trigger, "models/items/car_battery01.mdl");
		
		float fMins[3], fMaxs[3];
		GetEntPropVector(ent, Prop_Send, "m_vecMins", fMins);
		GetEntPropVector(ent, Prop_Send, "m_vecMaxs", fMaxs);
		
		SetEntPropVector(trigger, Prop_Send, "m_vecMins", fMins);
		SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", fMaxs);
		SetEntProp(trigger, Prop_Send, "m_nSolidType", 2);
		
		int iEffects = GetEntProp(trigger, Prop_Send, "m_fEffects");
		iEffects |= 32;
		SetEntProp(trigger, Prop_Send, "m_fEffects", iEffects);
		
		SetVariantString("!activator");
		AcceptEntityInput(trigger, "SetParent", rot, rot);
		AcceptEntityInput(rot, "Start");
		
		HookSingleEntityOutput(trigger, "OnStartTouch", OnStartTouch);
	}
}*/

public void OnStartTouch(const char[] output, int caller, int activator, float delay)
{
	if (!(0 < activator <= MaxClients) || Passed[activator] || (HNS && HNS_GetClientData(activator, CLIENT_INFO) & CLIENT_INFO_FLY))
	{
		return;
	}
	
	int iSteamID = GetSteamAccountID(activator, true);
	if (iSteamID == 0)
	{
		return;
	}
	
	SteamIDs.Push(iSteamID);
	
	Passed[activator] = true;

	if (++CurrentPosition > MAXPLAYERS - 1)
	{
		CurrentPosition = MAXPLAYERS - 1;
	}
	
	if (Credits[CurrentPosition] < 1)
	{
		return;
	}
	
	Call_StartForward(GF_OnClientPickGift);
	Call_PushCell(activator);
	Call_Finish();
	
	int amount = Shop_GiveClientCredits(activator, Credits[CurrentPosition], CREDITS_BY_NATIVE);
	
	if(PickSound[0])
	{
		EmitSoundToAll(PickSound, activator);
	}
	
	PrintToChatAll2("%t", "PlayerFinished", activator, amount);
}

int GetClientCount2()
{
	int iCount;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1)
		{
			iCount++;
		}
	}
	
	return iCount;
}

void PrintToChat2(int iClient, const char[] message, any ...)
{
	int iLen = strlen(message) + 255;
	char[] szBuffer = new char[iLen];
	SetGlobalTransTarget(iClient);
	VFormat(szBuffer, iLen, message, 3);
	if(iClient == 0)
	{
		PrintToConsole(iClient, szBuffer);
	}
	else
	{
		SendMessage(iClient, szBuffer, iLen);
	}
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
	Format(szBuffer, iSize, "\x01%s", szBuffer);
	ReplaceString(szBuffer, iSize, "{C}", "\x07");

	
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