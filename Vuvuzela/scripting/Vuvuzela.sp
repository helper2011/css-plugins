#include <sourcemod>
#include <sdktools>

#pragma newdecls required

enum
{
	VUVU_MAX_MODES,
	VUVU_DELAY_MIN,
	VUVU_DELAY_MAX,
	
	VUVU_DATA_TOTAL
	
}

enum
{
	INVERSION,
	LOW_GRAVITY,
	SPEED,
	FRICTION,
	
	MODE_TOTAL
}

enum
{
	MODE_TOGGLE,
	MODE_CHANCE,
	MODE_DURATION_MIN,
	MODE_DURATION_MAX,
	MODE_TIMER,
	
	MODE_DATA_TOTAL
}

enum
{
	SOUND_START_VUVU,
	SOUND_ENABLE_MODE,
	SOUND_DISABLE_MODE,
	
	SOUND_TOTAL
}

bool SoundIsValid[SOUND_TOTAL];
char Sound[SOUND_TOTAL][256];

static const char ModeNames[MODE_TOTAL][] = 
{
	"speed",
	"gravity",
	"friction",
	"inversion"
}

Handle g_hTimer;

ConVar cvarPath, sv_accelerate, sv_airaccelerate, sv_gravity, sv_friction;

int Mode[MODE_TOTAL], Modes, ModeData[MODE_TOTAL][MODE_DATA_TOTAL], VuvuData[VUVU_DATA_TOTAL];

public Plugin myinfo = 
{
    name = "Vuvuzela",
    version = "1.0",
    author = "hEl"
};

public void OnPluginStart()
{
	cvarPath = CreateConVar("vuvu_path", "configs/vuvu.cfg"); cvarPath.AddChangeHook(OnConVarChange);
	sv_accelerate = FindConVar("sv_accelerate");
	sv_airaccelerate = FindConVar("sv_airaccelerate");
	sv_gravity = FindConVar("sv_gravity");
	sv_friction = FindConVar("sv_friction");
	
	RegConsoleCmd("sm_vuvu", Command_Vuvu);
}

public Action Command_Vuvu(int iC, int iA)
{
	ToggleVuvu(!g_hTimer);
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(cvar == cvarPath)
	{
		LoadConfigVuvu();
	}
}

public void OnMapStart()
{
	LoadConfigVuvu();
}

void LoadConfigVuvu()
{
	char szBuffer[256];
	cvarPath.GetString(szBuffer, 256);
	BuildPath(Path_SM, szBuffer, 256, szBuffer);
	KeyValues hKeyValues = new KeyValues("Vuvu");
	
	if(!hKeyValues.ImportFromFile(szBuffer))
	{
		SetFailState("Config file \"%s\" was doesnt exists...", szBuffer);
	}
	
	VuvuData[VUVU_DELAY_MIN] = hKeyValues.GetNum("min_delay");
	VuvuData[VUVU_DELAY_MAX] = hKeyValues.GetNum("max_delay");
	VuvuData[VUVU_MAX_MODES] = hKeyValues.GetNum("max_modes");
	KV_GetSound(hKeyValues, "start_sound", SOUND_START_VUVU);
	KV_GetSound(hKeyValues, "enable_mode_sound", SOUND_ENABLE_MODE);
	KV_GetSound(hKeyValues, "disable_mode_sound", SOUND_DISABLE_MODE);



	
	for(int i; i < MODE_TOTAL; i++)
	{
		hKeyValues.Rewind();
		
		if(!hKeyValues.JumpToKey(ModeNames[i], true))
			continue;
		
		ModeData[i][MODE_TOGGLE] = hKeyValues.GetNum("toggle");
		ModeData[i][MODE_CHANCE] = hKeyValues.GetNum("chance");
		ModeData[i][MODE_DURATION_MIN] = hKeyValues.GetNum("min_duration");
		ModeData[i][MODE_DURATION_MAX] = hKeyValues.GetNum("max_duration");


	}
	
	delete hKeyValues;
}

void KV_GetSound(KeyValues hKeyValues, const char[] key, int iSound)
{
	SoundIsValid[iSound] = false;
	hKeyValues.GetString(key, Sound[iSound], 256);
	PrintToServer(Sound[iSound]);
	int iLen = strlen(Sound[iSound]);
	
	SoundIsValid[iSound] = (Sound[iSound][0] && iLen > 3 && (!strncmp(Sound[iSound][iLen - 4], ".mp3", 4, false) || !strncmp(Sound[iSound][iLen - 4], ".wav", 4, false)));
	
	if(SoundIsValid[iSound])
	{
		PrecacheSound(Sound[iSound][6], true);
		AddFileToDownloadsTable(Sound[iSound]);
	}
	
}

void ToggleVuvu(bool bToggle)
{
	delete g_hTimer;
	if(bToggle)
	{
		if(SoundIsValid[SOUND_START_VUVU])
		{
			EmitSoundToAll(Sound[SOUND_START_VUVU][6], SOUND_FROM_PLAYER);
		}
		PrintToChatAll("GetRandomInt(%i, %i) = %f", VuvuData[VUVU_DELAY_MIN], VuvuData[VUVU_DELAY_MAX], float(GetRandomInt(VuvuData[VUVU_DELAY_MIN], VuvuData[VUVU_DELAY_MAX])));
		g_hTimer = CreateTimer(float(GetRandomInt(VuvuData[VUVU_DELAY_MIN], VuvuData[VUVU_DELAY_MAX])), Timer_Vuvu);
	}
	else
	{
		StopSoundAll(Sound[SOUND_START_VUVU]);
		ToggleMode(-1, false);
	}
	
}

void StopSoundAll(const char[] sound)
{
	if(!sound[0])
		return;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		
		for(int j; j < 8; j++)
		{
			StopSound(i, j, sound[6]);
		}
	}

}

public Action Timer_Vuvu(Handle hTimer)
{
	int iMode[MODE_TOTAL], iModes;
	for(int i; i < MODE_TOTAL; i++)
	{
		for(int j; j < Modes; j++)
		{
			if(Mode[j] == i)
				break;
		}
		
		iMode[iModes++] = i;
	}

	ToggleMode(iMode[GetRandomInt(0, iModes - 1)], true);
	g_hTimer = CreateTimer(float(GetRandomInt(VuvuData[VUVU_DELAY_MIN], VuvuData[VUVU_DELAY_MAX])), Timer_Vuvu);
}

void ToggleMode(int iMode, bool bToggle)
{
	int iIndex = FindValue(Mode, Modes, iMode);
	if(bToggle)
	{
		if(iMode != -1)
		{
			if(SoundIsValid[SOUND_ENABLE_MODE])
			{
				EmitSoundToAll(Sound[SOUND_ENABLE_MODE][6], SOUND_FROM_PLAYER);
			}
			if(iIndex != -1)
			{
				StartModeTimer(iMode);
			}
			else
			{
				PushValue(Mode, Modes, iMode);
			}
		}

		
	}
	else
	{
		
		if(EraseValue(Mode, Modes, iMode) != -1)
		{
			if(SoundIsValid[SOUND_ENABLE_MODE])
			{
				EmitSoundToAll(Sound[SOUND_ENABLE_MODE][6], SOUND_FROM_PLAYER);
			}
		}
	}
	
	switch(iMode)
	{
		case LOW_GRAVITY:
		{
			if(bToggle)
			{
				sv_gravity.SetInt(200);
			}
			else
			{
				sv_gravity.SetInt(800);
				
			}
		}
		case INVERSION:
		{
			if(bToggle)
			{
				sv_accelerate.SetInt(-5);
				sv_airaccelerate.SetInt(-10);
			}
			else
			{
				sv_accelerate.SetInt(5);
				sv_airaccelerate.SetInt(10);
			}

		}
		case SPEED:
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i))
				{
					SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", bToggle ? 2.0:1.0);
				}
			}
		}
		case FRICTION:
		{
			if(bToggle)
			{
				sv_friction.SetInt(0);
			}
			else
			{
				sv_friction.SetInt(4);
				
			}
		}
		
		default:
		{
			for(int i; i < MODE_TOTAL; i++)
			{
				ToggleMode(i, false);
			}
		}
	}
}

void StartModeTimer(int iMode)
{
	DeleteModeTimer(iMode);
	ModeData[iMode][MODE_TIMER] = view_as<int>(CreateTimer(float(GetRandomInt(ModeData[iMode][MODE_DURATION_MIN], ModeData[iMode][MODE_DURATION_MAX])), Timer_Mode, iMode));
}

void DeleteModeTimer(int iMode)
{
	if(ModeData[iMode][MODE_TIMER])
	{
		ToggleMode(-1, false);
		KillTimer(view_as<Handle>(ModeData[iMode][MODE_TIMER]));
		ModeData[iMode][MODE_TIMER] = 0;
	}
}

public Action Timer_Mode(Handle hTimer, int iMode)
{
	ModeData[iMode][MODE_TIMER] = 0;
	ToggleMode(iMode, false);
}

stock int FindValue(int[] array, int size, int value)
{
	for(int i; i < size; i++)
	{
		if(array[i] == value)
			return i;
	}
	
	return -1;
}

stock int PushValue(int[] array, int& size, int value)
{
	array[size] = value;
	return size++;
}

stock int PushValueEx(int[] array, int& size, int value)
{
	return FindValue(array, size, value) == -1 ? PushValue(array, size, value):-1;
}

stock int EraseValueByIndex(int[] array, int& size, int index)
{
	size--;
	
	for(int i = index; i < size; i++)
	{
		array[i] = array[i + 1];
	}
	
	return size;
}

stock int EraseValue(int[] array, int& size, int value)
{
	int index = FindValue(array, size, value);
	return index != -1 ? EraseValueByIndex(array, size, index):-1;
}

