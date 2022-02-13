#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

int HeadEntity[MAXPLAYERS+1];
int Hits[MAXPLAYERS+1];
int NeedHits;
char Sound[256];
ConVar cvarSound, cvarHits, cvarClearTime;

Handle Timer;

StringMap Models;

public Plugin myinfo =
{
	name = "SM Decapitation [Edited]",
	author = "Franc1sco Steam: franug",
	description = "Decapite",
	version = "v1.0",
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_hurt", OnPlayerHurt);
	HookEvent("player_spawn", OnPlayerSpawn);
	cvarSound = CreateConVar("sm_decapitation_sound", "decapitation/scream.wav", "Decapitation sound");
	cvarHits = CreateConVar("sm_decapitation_hits", "5", "headshots for decapitation");
	cvarClearTime = CreateConVar("sm_decapitation_cleartime", "60.0");
	
	NeedHits = cvarHits.IntValue;
	cvarHits.AddChangeHook(OnConVarChange);
	Models = new StringMap();
}

public void OnPluginEnd()
{
	Timer_DeleteEntities(null);
}

public void OnMapStart()
{
	cvarSound.GetString(Sound, 256);
	if(Sound[0])
	{
		char szBuffer[256];
		Format(szBuffer, 256, "sound/%s", Sound);
		AddFileToDownloadsTable(szBuffer);	
		PrecacheSound(Sound, true);	
	}
}

public void OnMapEnd()
{
	Models.Clear();
	Timer = null;
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	NeedHits = StringToInt(newValue);
}

public void OnPlayerSpawn(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	Hits[iClient] = 0;
	DeleteHeadEntity(iClient);
}

public void OnPlayerHurt(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	static int iClient;
	if(0 < GetClientOfUserId(hEvent.GetInt("attacker")) <= MaxClients && hEvent.GetInt("hitgroup") == 1 && !HeadEntity[(iClient = GetClientOfUserId(hEvent.GetInt("userid")))] && ++Hits[iClient] == NeedHits)
	{
		Decapitate(iClient);
	}
}

public void OnRoundStart(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		HeadEntity[i] = 0;
	}
		
		
	delete Timer;
	float fDelay = cvarClearTime.FloatValue;
	
	if(fDelay > 0.0)
	{
		Timer = CreateTimer(fDelay, Timer_DeleteEntities, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}
}

public Action Timer_DeleteEntities(Handle hTimer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		DeleteHeadEntity(i);
	}
}

void Decapitate(int iClient)
{
	static int iValue;
	static char szBuffer[256];
	static char szBuffer2[256];
	static float fPos[3];
	if(Sound[0])
	{
		GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", fPos);
		EmitSoundToAll(Sound, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, fPos);
	}

	GetClientModel(iClient, szBuffer, 256);
	szBuffer2 = szBuffer;
	ReplaceString(szBuffer, 256, ".mdl", "_hs.mdl");
	ReplaceString(szBuffer2, 256, ".mdl", "_head.mdl");

	if(!Models.GetValue(szBuffer, iValue))
	{
		iValue = (FileExists(szBuffer) && FileExists(szBuffer2)) ? 1:0;
		Models.SetValue(szBuffer, iValue, true);
		
		if(iValue)
		{
			if(!IsModelPrecached(szBuffer))
			{
				PrecacheModel(szBuffer);	
			}
			if(!IsModelPrecached(szBuffer2))
			{
				PrecacheModel(szBuffer2);	
			}
		}

	}
	if(!iValue)
	{
		return;
	}
	
	SetEntityModel(iClient, szBuffer);
	
	GetClientAbsOrigin(iClient, fPos);
	fPos[2] += GetRandomFloat(20.0, 30.0);
	
	if((HeadEntity[iClient] = CreateEntityByName("prop_physics_override")) != -1)
	{
		SetEntityModel(HeadEntity[iClient], szBuffer2);
		TeleportEntity(HeadEntity[iClient], fPos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(HeadEntity[iClient]);
		SetEntProp(HeadEntity[iClient], Prop_Data, "m_CollisionGroup", 2); 
		HeadEntity[iClient] = EntIndexToEntRef(HeadEntity[iClient]);
	}
	else
	{
		HeadEntity[iClient] = 0;
	}
}


void DeleteHeadEntity(int iClient)
{
	if(HeadEntity[iClient])
	{
		if((HeadEntity[iClient] = EntRefToEntIndex(HeadEntity[iClient])) != INVALID_ENT_REFERENCE && IsValidEntity(HeadEntity[iClient]))
		{
			RemoveEntity(HeadEntity[iClient]);
		}
		
		HeadEntity[iClient] = 0;
	}
}