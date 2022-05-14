#include <sourcemod>
#include <sdktools>
#include <Leader>

#undef REQUIRE_PLUGIN
#include <sourcecomms>
#define REQUIRE_PLUGIN


#pragma newdecls required

static const char Module[][] =
{
	"Marker",
	"Beacon",
	"Mute players"
}

const int MAX_STEAMID = 40;
const int Modules = sizeof(Module);

Handle
	g_hTimer[MAXPLAYERS + 1],
	g_hTimer2[MAXPLAYERS + 1],
	BeaconTimer[MAXPLAYERS + 1];

int
	SpriteBeam,
	SpriteHalo,
	SteamIDs,
	LastClientMute,
	Marker[MAXPLAYERS + 1];
char
	SteamID[MAX_STEAMID][40];

bool
	Mute,
	Toggle[Modules],
	Muted[MAXPLAYERS + 1],
	Leader[MAXPLAYERS + 1], 
	Access[MAXPLAYERS + 1],
	Beacon[MAXPLAYERS + 1],
	Admin[MAXPLAYERS + 1],
	
	SCIsLoaded;

ConVar
	cvarToggle[Modules];

GlobalForward
	OnClientActionLeader;
	
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Leader_IsClientLeader",			Native_IsClientLeader);
	CreateNative("Leader_IsClientPossibleLeader",	Native_IsClientPossibleLeader);
	CreateNative("Leader_GiveClientLeader",			Native_GiveClientLeader);

	RegPluginLibrary("Leader");
	return APLRes_Success;
}

public int Native_IsClientLeader(Handle hPlugin, int params)
{
	return view_as<int>(Leader[GetNativeCell(1)]);
}

public int Native_IsClientPossibleLeader(Handle hPlugin, int params)
{
	return view_as<int>(Access[GetNativeCell(1)]);
}

public int Native_GiveClientLeader(Handle hPlugin, int params)
{
	GiveClientLeader(GetNativeCell(1));
}

public Plugin myinfo = 
{
	name		= "Leader",
	version		= "1.0",
	description	= "Leadership with additional capabilities",
	author		= "hEl"
}

public void OnPluginStart()
{
	LoadLeaders();
	LoadTranslations("leader.phrases");
	
	OnClientActionLeader = new GlobalForward("Leader_OnClientActionLeader", ET_Ignore, Param_Cell, Param_Cell);
	
	RegConsoleCmd("sm_l", Command_Leader);
	RegConsoleCmd("sm_leader", Command_Leader);
	RegConsoleCmd("sm_leaders", Command_Leaders);
	RegServerCmd("sm_reloadleaders", Command_ReloadLeaders);
	
	cvarToggle[0] = CreateConVar2(0, "sm_leader_marker", "1");
	cvarToggle[1] = CreateConVar2(1, "sm_leader_beacon", "1");
	cvarToggle[2] = CreateConVar2(2, "sm_leader_mute_players", "1");

	HookEvent("player_team", OnPlayerTeam);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_disconnect", OnPlayerDisconnect);
	
	SCIsLoaded = LibraryExists("sourcecomms++");
	
	AuthClients();
}

public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "sourcecomms++", false))
	{
		SCIsLoaded = true;
	}
}
public void OnLibraryRemoved(const char[] name)
{
	if(!strcmp(name, "sourcecomms++", false))
	{
		SCIsLoaded = false;
	}
}



public void OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientDisconnect(i);
		}
	}
	
	ToggleMuteClients(0, false);
}

ConVar CreateConVar2(int iId, const char[] cvarName, const char[] cvarValue)
{
	ConVar cvar = CreateConVar(cvarName, cvarValue);
	Toggle[iId] = cvar.BoolValue;
	cvar.AddChangeHook(OnConVarChange);
	return cvar;
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	for(int i; i < 4; i++)
	{
		if(cvar == cvarToggle[i])
		{
			switch(i)
			{
				case 0:
				{
					
				}
				case 1:
				{
					Toggle[i] = cvar.BoolValue;
					
					if(Toggle[i])
						return;
					
					for(int j = 1; j <= MaxClients; j++)
					{
						if(IsClientInGame(j) && Beacon[j])
						{
							ToggleClientBeacon(j, false);
						}
					}
					
				}
				case 2:
				{
					Toggle[i] = cvar.BoolValue;
					if(!Toggle[i])
					{
						ToggleMuteClients(0, false);
					}
				}
				case 3:
				{
					Toggle[i] = cvar.BoolValue;
				}
				
			}
			break;
		}
	}
}

public void OnMapStart()
{
	PrecacheSound("sound/buttons/button9.wav");
	SpriteBeam = PrecacheModel("sprites/laser.vmt");
	SpriteHalo = PrecacheModel("sprites/halo01.vmt");
	
	Toggle[0] = cvarToggle[0].BoolValue;
	if(Toggle[0])
	{
		AddFileToDownloadsTable("materials/expert_zone/pingtool/circle_arrow.vtf");
		AddFileToDownloadsTable("materials/expert_zone/pingtool/circle_arrow.vmt");
		AddFileToDownloadsTable("materials/expert_zone/pingtool/circle_point.vtf");
		AddFileToDownloadsTable("materials/expert_zone/pingtool/circle_point.vmt");
		AddFileToDownloadsTable("materials/expert_zone/pingtool/grad.vtf");
		AddFileToDownloadsTable("materials/expert_zone/pingtool/grad.vmt");
		AddFileToDownloadsTable("models/expert_zone/pingtool/pingtool.dx80.vtx");
		AddFileToDownloadsTable("models/expert_zone/pingtool/pingtool.dx90.vtx");
		AddFileToDownloadsTable("models/expert_zone/pingtool/pingtool.mdl");
		AddFileToDownloadsTable("models/expert_zone/pingtool/pingtool.sw.vtx");
		AddFileToDownloadsTable("models/expert_zone/pingtool/pingtool.vvd");
		PrecacheModel("models/expert_zone/pingtool/pingtool.mdl");
	}
}

void LoadLeaders()
{
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, 256, "configs/leaders.cfg");
	File hFile = OpenFile(szBuffer, "r");

	if(hFile)
	{
		while (!hFile.EndOfFile() && SteamIDs < MAX_STEAMID)
		{
			if (!hFile.ReadLine(szBuffer, 256) || !TrimString(szBuffer))
				continue;
			
			strcopy(SteamID[SteamIDs++], 40, szBuffer);
		}
	}
	
	
	delete hFile;
}

public void OnPlayerTeam(Event hEvent, const char[] event, bool bDontBroadcast)
{
	if(hEvent.GetInt("team") != 3 && 0 < hEvent.GetInt("oldteam") < 3)
	{
		CheckLeaderActionLeave(GetClientOfUserId(hEvent.GetInt("userid")), "Leader has died");
	}
}


public void OnPlayerDisconnect(Event hEvent, const char[] event, bool bDontBroadcast)
{
	CheckLeaderActionLeave(GetClientOfUserId(hEvent.GetInt("userid")), "Leader has disconnected");
}

public void OnPlayerDeath(Event hEvent, const char[] event, bool bDontBroadcast)
{
	CheckLeaderActionLeave(GetClientOfUserId(hEvent.GetInt("userid")), "Leader has died");
}

public Action Command_ReloadLeaders(int iArgs)
{
	SteamIDs = 0;
	LoadLeaders();
	AuthClients();
	return Plugin_Handled;
}

public Action Command_Leader(int iClient, int iArgs)
{
	if(!CMD_IsValidClient(iClient))
		return Plugin_Handled;
	
	if(iArgs == 0)
	{
		if(Access[iClient] || Admin[iClient])
		{
			LeaderMenu(iClient);
		}
	}
	else if(Admin[iClient])
	{
		char szBuffer[32];
		GetCmdArg(1, szBuffer, 32);
		int iTarget = FindTarget(iClient, szBuffer, true, false);
		
		if(iTarget != -1)
		{
			if(!Access[iTarget])
			{
				GiveClientLeader(iTarget, iClient);
			}
			else
			{
				PrintToChat2(iClient, "%t", "This player already leader");
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Leaders(int iClient, int iArgs)
{
	if(!CMD_IsValidClient(iClient))
		return Plugin_Handled;
	
	int iCount[2];
	char szBuffer[2][256];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		if(Leader[i])
		{
			if(!iCount[0])
			{
				FormatEx(szBuffer[0], 256, "%N", i);
			}
			else
			{
				Format(szBuffer[0], 256, "%s, %N", szBuffer[0], i);
				
			}
			iCount[0]++;
		}
		if(Access[i])
		{
			if(!iCount[1])
			{
				FormatEx(szBuffer[1], 256, "%N", i);
			}
			else
			{
				Format(szBuffer[1], 256, "%s, %N", szBuffer[1], i);
				
			}
			iCount[1]++;
		}

	}
	
	if(iCount[0])
	{
		PrintToChat2(iClient, "%t", "Current leaders", szBuffer[0]);
	}
	if(iCount[1])
	{
		PrintToChat2(iClient, "%t", "Possible leaders", szBuffer[1]);
	}

	return Plugin_Handled;
}

bool CMD_IsValidClient(int iClient)
{
	return (iClient && !IsFakeClient(iClient));
}


public void OnClientPostAdminCheck(int iClient)
{
	if(IsFakeClient(iClient))
		return;
	
	int iFlags = GetUserFlagBits(iClient);
	Access[iClient] = (Admin[iClient] = (iFlags & ADMFLAG_GENERIC || iFlags & ADMFLAG_ROOT));
	
	if(Mute && !Admin[iClient])
	{
		Muted[iClient] = SourceComms_SetClientMute(iClient, Mute);
	}
	
	char szBuffer[40];
	GetClientAuthId(iClient, AuthId_Engine, szBuffer, 40, true);
	
	for(int i; i < SteamIDs; i++)
	{
		if(strcmp(szBuffer, SteamID[i], false) == 0)
		{
			Access[iClient] = true;
		}
	}
}

public void OnClientDisconnect(int iClient)
{
	LeaveLeader(iClient);
	Access[iClient] = false;
	Admin[iClient] = false;
}

void CheckLeaderActionLeave(int iClient, const char[] message)
{
	if(Leader[iClient])
	{
		LeaveLeader(iClient);
		PrintToChatAll2("%t", message, iClient);
	}
}

void LeaderMenu(int iClient, int iItem = 0)
{
	if(!Leader[iClient])
	{
		if(GetClientTeam(iClient) != 3 || !IsPlayerAlive(iClient))
		{
			return;
		}
		GF_OnClientActionLeader(iClient, true);
		
		ToggleClientBeacon(iClient, true);
		
		PrintToChatAll2("%t", "Client is new leader", iClient);
		Leader[iClient] = true;
	}
	Menu hMenu = new Menu(LeaderMenuH);
	hMenu.SetTitle("%T", "Leader menu title", iClient);
	AddMenuItem2(hMenu, Toggle[0] && Leader[iClient] ?					ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED, "", "%T", Module[0], iClient);
	//AddMenuItem2(hMenu, Toggle[1] && Leader[iClient] ?					ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED, "", "%T [%s]", Module[1], iClient, Beacon[iClient] ? "✔":"×");
	AddMenuItem2(hMenu, ITEMDRAW_DISABLED, "", "%T [%s]", Module[1], iClient, Beacon[iClient] ? "✔":"×");
	AddMenuItem2(hMenu, Toggle[2] && Leader[iClient] && SCIsLoaded ?	ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED, "", "%T [%s]", Module[2], iClient, Mute ? "✔":"×");

	AddMenuItem2(hMenu, Leader[iClient] ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED, "", "%T", "Leave lead", iClient);
	hMenu.DisplayAt(iClient, iItem, 0);
}

void AddMenuItem2(Menu hMenu, int style = ITEMDRAW_DEFAULT, const char[] buffer, const char[] format, any ...)
{
	int iLen = strlen(format) + 255;
	char[] szBuffer = new char[iLen];
	VFormat(szBuffer, iLen, format, 5);
	
	hMenu.AddItem(buffer, szBuffer, style);
}

public int LeaderMenuH(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			
			if(iItem == 3)
			{
				if(Leader[iClient])
				{
					LeaveLeader(iClient);
					PrintToChatAll2("%t", "Client is no longer a leader", iClient);
				}
			}
			else
			{
				if(Toggle[iItem])
				{
					OnItemClient(iClient, iItem);
				}

				LeaderMenu(iClient, hMenu.Selection);
			}
		}
		case MenuAction_End: delete hMenu;
	}
}

stock void ToggleClientBeacon(int iClient, bool bToggle)
{
	delete BeaconTimer[iClient];
	
	if(!(Beacon[iClient] = bToggle))
		return;
	
	BeaconTimer[iClient] = CreateTimer(0.75, Timer_Beacon, iClient, TIMER_REPEAT);
}

public Action Timer_Beacon(Handle hTimer, int iClient)
{
	float vec[3];
	GetClientAbsOrigin(iClient, vec);
	vec[2] += 10;

	TE_SetupBeamRingPoint(vec, 10.0, 375.0, SpriteBeam, SpriteHalo, 0, 15, 0.5, 5.0, 0.0, {128, 128, 128, 255}, 10, 0);
	TE_SendToAll();

	int rainbowColor[4];
	float i = GetGameTime();
	float Frequency = 2.5;
	rainbowColor[0] = RoundFloat(Sine(Frequency * i + 0.0) * 127.0 + 128.0);
	rainbowColor[1] = RoundFloat(Sine(Frequency * i + 2.0943951) * 127.0 + 128.0);
	rainbowColor[2] = RoundFloat(Sine(Frequency * i + 4.1887902) * 127.0 + 128.0);
	rainbowColor[3] = 255;

	TE_SetupBeamRingPoint(vec, 10.0, 375.0, SpriteBeam, SpriteHalo, 0, 10, 0.6, 10.0, 0.5, rainbowColor, 10, 0);

	TE_SendToAll();

	GetClientEyePosition(iClient, vec);

	return Plugin_Continue;
}

stock void ToggleMuteClients(int iLeader = 0, bool bMute)
{
	if(Mute == bMute || !SCIsLoaded)
		return;
	
	if(!(Mute = bMute))
		LastClientMute = iLeader;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !Admin[i] && !IsFakeClient(i))
		{
			if(Mute && !Muted[i])
			{
				Muted[i] = SourceComms_SetClientMute(i, Mute);
			}
			else if(!Mute && Muted[i])
			{
				Muted[i] = !SourceComms_SetClientMute(i, Mute);
				
			}
			
		}
	}
	
	if(bMute)
	{
		PrintToChatAll2("%t", "All players had their microphone turned off", iLeader);
	}
	else
	{
		PrintToChatAll2("%t", "All players had their microphone turned on", iLeader);
	}
}

public void BaseComm_OnClientMute(int client, bool muteState)
{
	Muted[client] = false;
}

void LeaveLeader(int iClient)
{
	if(Leader[iClient])
	{
		Leader[iClient] = false;
		
		GF_OnClientActionLeader(iClient, false);
	}
	KillMarker(iClient);
	delete g_hTimer[iClient];
	delete g_hTimer2[iClient];
	ToggleClientBeacon(iClient, false);
	
	if(LastClientMute == iClient)
		ToggleMuteClients(iClient, false);

}

void PrintToChat2(int iClient, const char[] message, any ...)
{
	if(!iClient)
		return;
	
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
	Format(szBuffer, iSize, "%s%t %s%s", MAIN_COLOR, "Tag", COLOR_FIRST, szBuffer);
	ReplaceString(szBuffer, iSize, "{C}", "\x07");
	ReplaceString(szBuffer, iSize, "{MC}", MAIN_COLOR);
	ReplaceString(szBuffer, iSize, "{C1}", COLOR_FIRST);
	ReplaceString(szBuffer, iSize, "{C2}", COLOR_SECOND);

	
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

int CreateMarker(int iClient, float fPos[3], float fAng[3])
{
	int iEntity = CreateEntityByName("prop_dynamic");

	if (iEntity == -1)
		return 0;
	
	KillMarker(iClient);
	
	DispatchKeyValue(iEntity, "model", "models/expert_zone/pingtool/pingtool.mdl");
	DispatchSpawn(iEntity);
	SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 2.5);
	TeleportEntity(iEntity, fPos, fAng, NULL_VECTOR);
	
	delete g_hTimer2[iClient];
	g_hTimer2[iClient] = CreateTimer(30.0, Timer_RemoveEntity, iClient, TIMER_FLAG_NO_MAPCHANGE);
	
	return iEntity;
}

public Action Timer_RemoveEntity(Handle hTimer, int iClient)
{
	g_hTimer2[iClient] = null;
	KillMarker(iClient);
}


public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}

void AuthClients()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
}

public void OnPlayerRunCmdPost(int iClient, int iButtons)
{
	static int iPrevButtons[MAXPLAYERS + 1], iPress[MAXPLAYERS + 1];
	
	if(!Leader[iClient] || !(iPrevButtons[iClient] & IN_ATTACK2))
	{
		iPress[iClient] = 0;
		iPrevButtons[iClient] = iButtons;
		return;
	}
	

	if(iButtons & IN_ATTACK2 && ++iPress[iClient] == 20)
	{
		EmitSoundToClient(iClient, "buttons/button9.wav");
		OnItemClient(iClient, 0);

	}
	else if(!(iButtons & IN_ATTACK2))
	{
		iPress[iClient] = 0;
	}
	iPrevButtons[iClient] = iButtons;
	
	return;
}

void OnItemClient(int iClient, int iModuleID)
{
	if(iModuleID == 0)
	{
		float ang[3], pos[3], vec[3], start[3];
		GetClientEyePosition(iClient, pos);
		GetClientEyeAngles(iClient, ang);
	
		TR_TraceRayFilter(pos, ang, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer); 
		if(TR_DidHit(null))
		{
			TR_GetEndPosition(start, null); 
			TR_GetPlaneNormal(null, vec); 
			GetVectorAngles(vec, vec); 
			vec[0] += 90.0; 
			Marker[iClient] = CreateMarker(iClient, start, vec);
		}
	}
	else if(iModuleID == 1)
	{
		ToggleClientBeacon(iClient, !Beacon[iClient]);
	}
	else
	{
		ToggleMuteClients(iClient, !Mute);
	}
}

void KillMarker(int iClient)
{
	if(Marker[iClient])
	{
		if(IsValidEntity(Marker[iClient]))
		{
			AcceptEntityInput(Marker[iClient], "kill");
		}
		Marker[iClient] = 0;
	}
}

void GiveClientLeader(int iClient, int iWho = 0)
{
	PrintToChatAll2("%t", "Client got the lead", iClient, iWho);
	Access[iClient] = true;
}

void GF_OnClientActionLeader(int iClient, bool bBecame)
{
	Call_StartForward(OnClientActionLeader);
	Call_PushCell(iClient);
	Call_PushCell(bBecame);
	Call_Finish();
}