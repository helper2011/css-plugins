#include <sourcemod>
#include <sdkhooks>
#include <sdktools_functions>
#pragma newdecls required

int m_bConnected, PlayerManager, RussianLanguageId;
bool Hook, Invisible[MAXPLAYERS + 1];

char InsisName[40];

ConVar cvarInsisName;

UserMsg SayText2;

static const char Messages[][] = {"Игрок %N вступает в игру", "Игрок %N покидает игру (Disconnect by user.)"};

public Plugin myinfo = 
{
	name		= "SuperPlugin",
	version		= "1.0"
}

public void OnPluginStart()
{
	if((RussianLanguageId = GetLanguageByCode("ru")) == -1)
	{
		SetFailState("Cant find russian language (see languages.cfg)");
	}
	cvarInsisName = CreateConVar("admin_hide_name", "2I42q4iqJIORQr3q");
	cvarInsisName.GetString(InsisName, 40);
	cvarInsisName.AddChangeHook(OnConVarChange);
	AddCommandListener(Command_Hide, "sm_hide2");
	
	HookEvent("player_connect_client", OnPlayerConnect, EventHookMode_Pre);
	
	SayText2 = GetUserMessageId("SayText2");
	AutoExecConfig(true, "plugin.AdminHide");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
	
	
}

public void OnMapStart()
{
    if ((m_bConnected = FindSendPropInfo("CCSPlayerResource", "m_bConnected")) == -1)
    {
        SetFailState("CCSPlayerResource.m_bConnected offset is invalid");
    }

    if ((PlayerManager = FindEntityByClassname(-1, "cs_player_manager")) <= 0)
    {
        SetFailState("Entity cs_player_manager not founded.");
    }
}

public void OnMapEnd()
{
	ToggleHook(false);
}

public void OnThinkPost(int iEntity)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Invisible[i])
		{
			SetEntData(PlayerManager, m_bConnected + i * 4, false, 1, true);
		}
		
	}
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	cvar.GetString(InsisName, 40);
}

public Action Command_Hide(int iClient, const char[] command, int iArgs)
{
	if(iClient && !IsFakeClient(iClient) && GetUserFlagBits(iClient) & ADMFLAG_RCON)
	{
		ToggleInvisible(iClient);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

void CheckHook()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Invisible[i])
		{
			ToggleHook(true);
			return;
		}
	}
	
	ToggleHook(false);
}

void ToggleHook(bool bToggle)
{
	if(Hook == bToggle)
		return;
	
	Hook = bToggle;
	
	if(Hook)
	{
		SDKHook(PlayerManager, SDKHook_ThinkPost, OnThinkPost);
		AddCommandListener(Command_Jointeam, "jointeam");
		HookUserMessage(SayText2, UserMessage_SayText2, true);
		
	}
	else
	{
		SDKUnhook(PlayerManager, SDKHook_ThinkPost, OnThinkPost);
		RemoveCommandListener(Command_Jointeam, "jointeam");
		UnhookUserMessage(SayText2, UserMessage_SayText2, true);
		
	}
}

public Action Command_Jointeam(int iClient, const char[] command, int iArgs)
{
	if(Invisible[iClient])
	{
		if(iArgs > 0)
		{
			char szBuffer[4];
			GetCmdArg(1, szBuffer, 4);
			
			return StringToInt(szBuffer) != 1 ? Plugin_Handled:Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

public Action UserMessage_SayText2(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if(!reliable)
		return Plugin_Continue;

	int client;
	char sMessage[32];

	if(GetUserMessageType() == UM_Protobuf)
	{
		PbReadString(msg, "msg_name", sMessage, sizeof(sMessage));

		if(!(sMessage[0] == '#' && StrContains(sMessage, "Name_Change")))
			return Plugin_Continue;

		client = PbReadInt(msg, "ent_idx");
	}
	else
	{
		client = BfReadByte(msg);
		BfReadByte(msg);
		BfReadString(msg, sMessage, sizeof(sMessage));

		if(!(sMessage[0] == '#' && StrContains(sMessage, "Name_Change")))
			return Plugin_Continue;
	}

	if(Invisible[client])
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action OnPlayerConnect(Event hEvent, const char[] event, bool bDontBroadcast)
{
	char szBuffer[40];
	hEvent.GetString("name", szBuffer, 40);
	
	return strcmp(szBuffer, InsisName, true) ? Plugin_Continue:Plugin_Handled;
}

public void OnClientDisconnect(int iClient)
{
	if(Invisible[iClient])
	{
		if(Hook)
		{
			CheckHook();
		}
		Invisible[iClient] = false;
	}
}

public void OnClientPostAdminCheck(int iClient)
{
	if(IsFakeClient(iClient))
		return;
	
	if(GetClientTeam(iClient) < 2)
	{
		char szBuffer[40];
		GetClientName(iClient, szBuffer, 40);
		
		if(!strcmp(szBuffer, InsisName, false))
		{
			ToggleInvisible(iClient, false);
		}
	}
}

void ToggleInvisible(int iClient, bool bFireEvent = true)
{
	Invisible[iClient] = !Invisible[iClient];
	CheckHook();
	if(bFireEvent)
	{
		CreateEvent2(iClient);
	}
	
	if(GetClientTeam(iClient) != 1)
		ChangeClientTeam(iClient, 1);
	
	PrintToChat(iClient, "[SM] Режим невидимки %s", Invisible[iClient] ? "включён":"отключён");
}

void CreateEvent2(int iClient)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientLanguage(i) == RussianLanguageId)
		{
			PrintToChat(i, Messages[Invisible[iClient] ? 1:0], iClient);
		}
	}
	
}