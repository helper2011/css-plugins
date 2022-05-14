#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#pragma newdecls required

int g_iDuration;
int g_iColor[2][4];

Handle hCookie;
bool Toggle[MAXPLAYERS + 1] = {true, ...};

public Plugin myinfo =
{
	name = "Kill Screen Effect",
	version = "1.0.0"
};

public void OnPluginStart()
{
	ConVar hCvar = CreateConVar("sm_kill_screen_duration", "0.2");
	hCvar.AddChangeHook(OnDurationChange);
	g_iDuration = RoundToCeil(hCvar.FloatValue*1000.0);
	
	hCvar = CreateConVar("sm_kill_screen_color_t", "255 0 0 50");
	hCvar.AddChangeHook(OnColorChangeT);
	GetConVarColor(hCvar, g_iColor[0]);

	hCvar = CreateConVar("sm_kill_screen_color_ct", "0 0 255 50");
	hCvar.AddChangeHook(OnColorChangeCT);
	GetConVarColor(hCvar, g_iColor[1]);

	AutoExecConfig(true, "plugin.KillScreen");

	HookEvent("player_death", OnPlayerDeath);
	RegConsoleCmd("sm_killscreen", Command_KillScreen);
	hCookie = RegClientCookie("KillScreen", "", CookieAccess_Private);
	SetCookieMenuItem(CookieMenuH, 0, "Kill Screen Effect");

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
			continue;

		if(AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
}

public Action Command_KillScreen(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient))
	{
		ToggleClientKillScreenEffect(iClient);
	}

	return Plugin_Handled;
}

public void CookieMenuH(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlen, "Kill Screen Effect: [%s]", Toggle[client] ? "✔":"×");
		}
		case CookieMenuAction_SelectOption:
		{
			ToggleClientKillScreenEffect(client);
			ShowCookieMenu(client);
		}
	}
}

void ToggleClientKillScreenEffect(int iClient)
{
	Toggle[iClient] = !Toggle[iClient];
	PrintHintText(iClient, "Kill Screen Effect: [%s]", Toggle[iClient] ? "✔":"×");

	if(AreClientCookiesCached(iClient))
	{
		SetClientCookie(iClient, hCookie, Toggle[iClient] ? "":"0");
	}
}

public void OnClientCookiesCached(int iClient)
{
	if(IsFakeClient(iClient))
	{
		return;
	}
	char szBuffer[4];
	GetClientCookie(iClient, hCookie, szBuffer, 4);
	Toggle[iClient] = (szBuffer[0] == 0)
}

public void OnClientDisconnect(int iClient)
{
	Toggle[iClient] = true;
}

public void OnDurationChange(ConVar cvar, const char[] oldValue, const char[] newValue)		
{
	g_iDuration = RoundToCeil(cvar.FloatValue*1000.0);
}

public void OnColorChangeT(ConVar cvar, const char[] oldValue, const char[] newValue)	
{	
	GetConVarColor(cvar, g_iColor[0]);
}
public void OnColorChangeCT(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	GetConVarColor(cvar, g_iColor[1]);
}		

void GetConVarColor(ConVar cvar, int color[4])
{
	char sBuffer[16];
	char sParts[4][4];
	cvar.GetString(sBuffer, 16);
	ExplodeString(sBuffer, " ", sParts, sizeof(sParts), sizeof(sParts[]));
	for(int i = 0; i < 4; ++i)
	{
		StringToIntEx(sParts[i], color[i]);
	}
}

public void OnPlayerDeath(Event hEvent, const char[] name, bool bDontBroadcast)  
{
	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker")), iTeam;
	if(0 < iAttacker <= MaxClients && Toggle[iAttacker] && IsPlayerAlive(iAttacker) && 0 <= (iTeam = GetClientTeam(iAttacker) - 2) <= 1)
	{
		int iClients[1];
		Handle hMessage;
		iClients[0] = iAttacker;
		hMessage = StartMessage("Fade", iClients, 1); 
		if(GetUserMessageType() == UM_Protobuf) 
		{
			PbSetInt(hMessage, "duration", g_iDuration);
			PbSetInt(hMessage, "hold_time", 0);
			PbSetInt(hMessage, "flags", 0x0001);
			PbSetColor(hMessage, "clr", g_iColor[iTeam]);
		}
		else
		{
			BfWriteShort(hMessage, g_iDuration);
			BfWriteShort(hMessage, 0);
			BfWriteShort(hMessage, (0x0001));
			BfWriteByte(hMessage, g_iColor[iTeam][0]);
			BfWriteByte(hMessage, g_iColor[iTeam][1]);
			BfWriteByte(hMessage, g_iColor[iTeam][2]);
			BfWriteByte(hMessage, g_iColor[iTeam][3]);
		}
		EndMessage(); 
	}
}