#include <sourcemod>
#include <sdktools_functions>

#pragma newdecls required

const int MAX_SKINS = 16;
int Skins[2];
char Skin[2][MAX_SKINS][256];
int Team[2][MAX_SKINS];

bool AdvertNick[MAXPLAYERS + 1];

ConVar cvarMode;

int Mode;

static const char AdvertWords[][] = 
{
	"for-css",
	"marcoplay",
	"gamer css",
	"marcoserv",
	"css-vip",
	"css-d",
	"[css-d",
	"csmega-92"
}

public Plugin myinfo =
{
	name		= "Start Skins",
	version		= "1.0",
	author		= "hEl"
};

public void OnPluginStart()
{
	cvarMode = CreateConVar("sm_start_skins_mode", "0", "0 - some teams, 1 - random");
	cvarMode.AddChangeHook(OnConVarChange);
	Mode = cvarMode.IntValue;
	AutoExecConfig(true, "plugin.StartSkins");
	
	LoadSkins(0);
	LoadSkins(1);
	
	if(!Skins[0] && !Skins[1])
	{
		SetFailState("No skins");
	}
	
	HookEvent("player_spawn", OnPlayerSpawn);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnMapStart()
{
	for(int j; j < 2; j++)
	{
		for(int i; i < Skins[j]; i++)
		{
			PrecacheModel(Skin[j][i], true);
		}
	}
}

void LoadSkins(int iType)
{
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, 256, "configs/%s.txt", iType ? "advert_skins":"start_skins");
	File hFile = OpenFile(szBuffer, "r");
	if(!hFile)
	{
		return;
	}
	
	int iSymbol = -1;
	while (!IsEndOfFile(hFile) && ReadFileLine(hFile, szBuffer, 256) && Skins[iType] < MAX_SKINS)
	{
		if(TrimString(szBuffer) > 0)
		{
			if((iSymbol = FindCharInString(szBuffer, '=')) == -1)
			{
				Team[iType][Skins[iType]] = -1;
			}
			else
			{
				Team[iType][Skins[iType]] = StringToInt(szBuffer[iSymbol + 1]);
				szBuffer[iSymbol] = 0;
			}
			Skin[iType][Skins[iType]++] = szBuffer;
		}
	}
	delete hFile;
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	Mode = cvar.IntValue;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientDisconnect(i);
			OnClientPutInServer(i);
		}
	}
}

public void OnPlayerSpawn(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	RequestFrame(OnPlayerSpawnNextTick, GetClientOfUserId(hEvent.GetInt("userid")));
}

void OnPlayerSpawnNextTick(int iClient)
{
	if(!IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return;
		
	int iType = AdvertNick[iClient] ? 1:0;
	
	if(!Skins[iType])
		return;
	
	int iTeam = Mode ? -1:GetClientTeam(iClient);
	
	if(iTeam == -1)
	{
		SetEntityModel(iClient, Skin[iType][GetRandomInt(0, Skins[iType] - 1)]);
	}
	else
	{
		int iSkinsCount;
		int[] iSkins = new int[Skins[iType]];
		for(int i; i < Skins[iType]; i++)
		{
			if(iTeam == Team[iType][i])
			{
				iSkins[iSkinsCount++] = i;
			}
		}
		
		if(iSkinsCount)
		{
			SetEntityModel(iClient, Skin[iType][iSkins[GetRandomInt(0, iSkinsCount - 1)]]);
		}
	}

	
}

public void OnClientPutInServer(int iClient)
{
	if(IsFakeClient(iClient))
		return;
	
	char szBuffer[32];
	if(GetClientName(iClient, szBuffer, 32))
	{
		for(int i; i < sizeof(AdvertWords); i++)
		{
			if(!strncmp(szBuffer, AdvertWords[i], strlen(AdvertWords[i]), false))
			{
				AdvertNick[iClient] = true;
				return;
			}
		}
	}
	
}

public void OnClientDisconnect(int iClient)
{
	AdvertNick[iClient] = false;
}