#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

static const int Color[][] = 
{
	{255, 255, 0, 255}, // yellow
	{255, 0, 0, 255}, // red
	{0, 0, 255, 255}, // blue
	{255, 192, 203, 255}, // pink
	{255, 215, 0, 255} // золотистый
}

/*static const char ColorName[][] = 
{
	"Синий",
	"Желтый",
	"Золотой",
	"Серебристый",
	"Белый"
}*/

const int Colors = sizeof(Color);
const int MAX_LIGHTS = 512;

int Lights, LightColor[MAX_LIGHTS], Ent[MAX_LIGHTS];
float Pos[MAX_LIGHTS][3];

float HyrlandFirstPos[MAXPLAYERS + 1][3];
bool Hide;

public Plugin myinfo = 
{
	name = "Christmasification [Edited]",
	author = "MPQC",
	description = "Adds some Christmas lights",
	version = "1.0.3",
	url = "www.steamgamers.com"
}

public void OnPluginStart()
{
	RegAdminCmd("sm_lights", Command_Lights, ADMFLAG_RCON); 
	HookEvent("round_start", RoundStart, EventHookMode_PostNoCopy);
}

public Action Command_Lights(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient))
	{
		Menu hMenu = new Menu(LightsMenuH, MenuAction_End | MenuAction_Cancel | MenuAction_Select);
		hMenu.SetTitle("Огоньки\n ");
		hMenu.AddItem("", "Зажечь огонек");
		hMenu.AddItem("", "Включить гирлянду");
		hMenu.AddItem("", "Перекрасить [последний]");
		hMenu.AddItem("", "Удалить [последний]");
		hMenu.AddItem("", "Удалить [все]");
		hMenu.AddItem("", "Удалить [все]");
		hMenu.Display(iClient, 0);
	}
	return Plugin_Handled;
}

public int LightsMenuH(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End:
		{
			if(iClient != MenuEnd_Selected)
			{
				delete hMenu;
			}
		}
		case MenuAction_Cancel:
		{
			HyrlandFirstPos[iClient][0] = 
			HyrlandFirstPos[iClient][1] = 
			HyrlandFirstPos[iClient][2] = 0.0;
		}
		case MenuAction_Select:
		{
			switch(iItem)
			{
				case 0:
				{
					if(Lights < MAX_LIGHTS)
					{
						float fPos[3], fAng[3]; 
						GetClientEyePosition(iClient, fPos);
						GetClientEyeAngles(iClient, fAng);
						TR_TraceRayFilter(fPos, fAng, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
						if(TR_DidHit(INVALID_HANDLE))
						{
							TR_GetEndPosition(Pos[Lights], INVALID_HANDLE);
							LightColor[Lights] = GetRandomInt(0, Colors - 1);
							CreateLight(Lights++);
						}
					}
					else
					{
						PrintToChat(iClient, "[Огоньки] Достигнут лимит огней (%i шт)", MAX_LIGHTS);
					}
				}
				case 1:
				{
					if(!HyrlandFirstPos[iClient][0] && !HyrlandFirstPos[iClient][1] && !HyrlandFirstPos[iClient][2])
					{
						PrintToConsoleAll("Hyrland");
						TraceEye(iClient, HyrlandFirstPos[iClient]);
					}
					else
					{
						PrintToConsoleAll("Hyrland 2");
						float fPos[3];
						TraceEye(iClient, fPos);
						DrawLights(HyrlandFirstPos[iClient], fPos);
						HyrlandFirstPos[iClient][0] = 
						HyrlandFirstPos[iClient][1] = 
						HyrlandFirstPos[iClient][2] = 0.0;
					}
				}
				case 2:
				{
					DeleteLight(Lights - 1);
					if(++LightColor[Lights - 1] >= Colors)
					{
						LightColor[Lights - 1] = 0;
					}
					CreateLight(Lights - 1);
				}
				case 3:
				{
					DeleteLight(--Lights);
				}
				case 4:
				{
					for(int i; i < Lights; i++)
						DeleteLight(i);
				
					Lights = 0;
				}
				case 5:
				{
					Hide = !Hide;
				}
			}
			hMenu.Display(iClient, 0);
		}
	}
	return 0;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return (entity > MaxClients || !entity);
}

public void OnMapStart()
{
	PrecacheModel("sprites/glow02.vmt");
	PrecacheModel("sprites/glow02.vtf");
	char szBuffer[256];
	Lights = 0;
	KeyValues hKeyValues = new KeyValues("ChristmasLights");
	BuildPath(Path_SM, szBuffer, 256, "configs/christmas_lights/");
	
	if (!DirExists(szBuffer))
	{
		CreateDirectory(szBuffer, 511);
	}
	GetCurrentMap(szBuffer, 256);
	BuildPath(Path_SM, szBuffer, 256, "configs/christmas_lights/%s.cfg", szBuffer);
	
	if(!FileExists(szBuffer))
	{
		File hFile = OpenFile(szBuffer, "w+");
		delete hFile;
	}
	if(!hKeyValues.ImportFromFile(szBuffer) || !hKeyValues.GotoFirstSubKey())
	{
		delete hKeyValues;
		return;
	}	
	

	
	do
	{
		int iColor[4];
		hKeyValues.GetVector("pos", Pos[Lights]);
		hKeyValues.GetColor4("color", iColor);
		hKeyValues.GetString("sprite", szBuffer, 256);
		LightColor[Lights] = GetColorId(iColor);
		
		
		Lights++;

	}
	while(hKeyValues.GotoNextKey() && Lights < MAX_LIGHTS);
	delete hKeyValues;
}

public void OnMapEnd()
{
	int iCount;
	char szBuffer[256];
	KeyValues hKeyValues = new KeyValues("ChristmasLights");
	do
	{
		IntToString(iCount, szBuffer, 256);
		if(hKeyValues.JumpToKey(szBuffer, true))
		{
			hKeyValues.SetVector("pos", Pos[iCount]);
			hKeyValues.SetColor4("color", Color[LightColor[iCount]]);
			hKeyValues.GoBack();
		}
		

		iCount++;
	
	}
	while(iCount < Lights);
	GetCurrentMap(szBuffer, 256);
	BuildPath(Path_SM, szBuffer, 256, "configs/christmas_lights/%s.cfg", szBuffer);
	hKeyValues.Rewind();
	hKeyValues.ExportToFile(szBuffer);
	delete hKeyValues;
}

public void RoundStart(Event hEvent, const char[] event, bool bDontBroadcast)
{
	for(int i; i < Lights; i++)
	{
		CreateLight(i);
	}
}

stock void CreateLight(int iLight)
{
	DeleteLight(iLight);	
	int iEntity = CreateEntityByName("env_sprite");
	if(iEntity != -1)
	{
		Ent[iLight] = EntIndexToEntRef(iEntity);
		char colors[32];
		Format(colors, sizeof(colors), "%i %i %i", Color[LightColor[iLight]][0], Color[LightColor[iLight]][1], Color[LightColor[iLight]][2]);
		DispatchKeyValue(iEntity, "spawnflags", "1");
		DispatchKeyValue(iEntity, "scale", "0.5");
		DispatchKeyValue(iEntity, "rendermode", "9");
		DispatchKeyValue(iEntity, "model", "sprites/glow02.vmt");
		DispatchKeyValue(iEntity, "rendercolor", colors);
		DispatchSpawn(iEntity);
		TeleportEntity(iEntity, Pos[iLight], NULL_VECTOR, NULL_VECTOR);
	}
}

void DeleteLight(int iLight)
{
	if(Ent[iLight])
	{
		if((Ent[iLight] = EntRefToEntIndex(Ent[iLight])) != INVALID_ENT_REFERENCE)
		{
			RemoveEntity(Ent[iLight]);
		}
		Ent[iLight] = 0;
	}
}


public bool TraceFilter(int ent, int mask)
{
	return true;
}

stock int GetColorId(const int color[4])
{
	for(int i; i < Colors; i++)
	{
		bool bBreak;
		for(int j; j < 4; j++)
		{
			if(Color[i][j] != color[j])
			{
				bBreak = true;
				break;
			}
		}
		if(!bBreak)
			return i;
	}
	return GetRandomInt(0, Colors - 1);
}

void TraceEye(int client, float pos[3])
{
	float vAngles[3], vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	TR_TraceRayFilter(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(INVALID_HANDLE)) TR_GetEndPosition(pos, INVALID_HANDLE);
}

stock void DrawLights(const float startpoint[3], const float endpoint[3])
{
	PrintToConsoleAll("DrawLights");
	float direction[3], starting[3];
	
	starting[0] = startpoint[0];
	starting[1] = startpoint[1];
	starting[2] = startpoint[2];
	
	SubtractVectors(endpoint, startpoint, direction);
	NormalizeVector(direction, direction);
	ScaleVector(direction, 75.0);
	
	while(Lights < MAX_LIGHTS)
	{
		Pos[Lights] = starting;
		LightColor[Lights] = GetRandomInt(0, Colors - 1);
		CreateLight(Lights++);
		
		if (GetVectorDistance(endpoint, starting) < 75.0)
		{
			break;
		}
		
		AddVectors(starting, direction, starting);
	}
}