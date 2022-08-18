#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#pragma newdecls required

int iSnowFlakes[4], RussianLanguageId;
Handle hCookieDisabled;
bool Disabled[MAXPLAYERS + 1];

ConVar cvarHeight, cvarMinDist, cvarMaxDist;
float Height, MinDist, MaxDist;

public Plugin myinfo = 
{
	name = "SnowFall",
	author = "null138 & ZombieFeyk",
	description = "Makes snowfall on any map with custom snowflakes",
	version = "1.0",
	url = "https://steamcommunity.com/id/null138/"
}

public void OnPluginStart()
{
	if((RussianLanguageId = GetLanguageByCode("ru")) == -1)
	{
		SetFailState("Cant find russian language (see languages.cfg)");
	}
	RegConsoleCmd("sm_snow", cmdSnowFall);
	RegConsoleCmd("sm_snowfall", cmdSnowFall);
	cvarHeight = CreateConVar("sm_snowfall_height", "200.0");
	cvarHeight.AddChangeHook(OnConVarChange);
	cvarMinDist = CreateConVar("sm_snowfall_min_dist", "-1500.0");
	cvarMinDist.AddChangeHook(OnConVarChange);
	cvarMaxDist = CreateConVar("sm_snowfall_max_dist", "1500.0");
	cvarMaxDist.AddChangeHook(OnConVarChange);
	AutoExecConfig();
	hCookieDisabled = RegClientCookie("snowfall_disabled", "Snow Fall Disabled", CookieAccess_Protected);
	SetCookieMenuItem(HideSnowMenuHandler, 0, "Hide snowfall");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
	
}

public void OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == cvarHeight)
	{
		Height = cvarHeight.FloatValue;
	}
	else if(convar == cvarMinDist)
	{
		MinDist = cvarMinDist.FloatValue;
	}
	else if(convar == cvarMaxDist)
	{
		MaxDist = cvarMaxDist.FloatValue;
	}

}

public void OnConfigsExecuted()
{
	Height = cvarHeight.FloatValue;
	MinDist = cvarMinDist.FloatValue;
	MaxDist = cvarMaxDist.FloatValue;
}

public void OnMapStart()
{
	char buffer[64];
	for (int i = 0; i < 4; i++)
	{
		Format(buffer, 64, "materials/snowflake%i.vtf", i + 1);
		AddFileToDownloadsTable(buffer);
		Format(buffer, 64, "materials/snowflake%i.vmt", i + 1);
		AddFileToDownloadsTable(buffer);
		if((iSnowFlakes[i] = PrecacheModel(buffer)) == 0)
		{
			SetFailState("PrecacheModel() error (model #%i - %s)", i, buffer);
		}
	}
}

public void OnClientCookiesCached(int client)
{
	if(IsFakeClient(client))
		return;
		
	char buffer[4];
	GetClientCookie(client, hCookieDisabled, buffer, 4);
	Disabled[client] = (buffer[0] != 0);
}

public void OnClientDisconnect(int iClient)
{
	Disabled[iClient] = false;
}

public Action cmdSnowFall(int client, int args)
{
	ToggleClientSnowfall(client);
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(!IsFakeClient(client) && !Disabled[client])
	{
		float pos[3], vel[3];
		GetClientAbsOrigin(client, pos);
		pos[0] += GetRandomFloat(MinDist, MaxDist);
		pos[1] += GetRandomFloat(MinDist, MaxDist);
		pos[2] += Height;
		vel[0] = GetRandomFloat(-50.0, 50.0);
		vel[1] = GetRandomFloat(-50.0, 50.0);
		vel[2] = GetRandomFloat(-50.0, -100.0);
	
		TE_Start("Client Projectile");
	
		TE_WriteVector("m_vecOrigin", pos);
		TE_WriteVector("m_vecVelocity", vel);
		TE_WriteNum("m_nModelIndex", iSnowFlakes[GetRandomInt(0, 3)]);
		TE_WriteNum("m_hOwner", 0);
		TE_WriteNum("m_nLifeTime", 7);
		
		TE_SendToClient(client);
	}

	return Plugin_Continue;
}

public void HideSnowMenuHandler(int iClient, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlen, "%s: [%s]", GetClientLanguage(iClient) == RussianLanguageId ? "Снегопад":"Snow fall", Disabled[iClient] ? "×":"✔");
		}
		case CookieMenuAction_SelectOption:
		{
			ToggleClientSnowfall(iClient);
			ShowCookieMenu(iClient);
		}
	}
}

void ToggleClientSnowfall(int client)
{
	Disabled[client] = !Disabled[client];
	PrintHintText(client, "%s: [%s]", GetClientLanguage(client) == RussianLanguageId ? "Снегопад":"Snow fall", Disabled[client] ? "×":"✔");
	if(AreClientCookiesCached(client))
	{
		SetClientCookie(client, hCookieDisabled, Disabled[client] ? "1":"");
	}
}