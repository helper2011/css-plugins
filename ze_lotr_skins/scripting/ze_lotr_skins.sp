#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

Handle TimerSetSkins;
int Frodo, Gandalf, AragornOwner, LegolasOwner, GimliOwner, FrodoOwner, GandalfOwner, OtherSkins, Damage[MAXPLAYERS + 1];
bool TopDefHook;

public Plugin myinfo = 
{
	name		= "[ZE] LOTR skins",
	version		= "1.0",
	description	= "",
	author		= "hEl"
}
	
public void OnPluginStart()
{
	CreateTimer(1.0, Timer_Auth);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	
	//RegAdminCmd("ttt", TestC, ADMFLAG_GENERIC);
}

public Action TestC(int iC, int iA)
{
	if(iC && !IsFakeClient(iC) && IsPlayerAlive(iC) && iA == 1)
	{
		char szBuffer[32];
		GetCmdArg(1, szBuffer, 32);
		EmitSoundToAll("sibgamers/lotr/gandalf/prepare.mp3", SOUND_FROM_PLAYER, _, StringToInt(szBuffer));
	}
}

public void OnMapStart()
{
	char szMap[256];
	GetCurrentMap(szMap, 256);
	
	if(StrContains(szMap, "_lotr_", false) == -1)
	{
		Suicide();
		return;
	}
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, 256, "configs/lotr_skins.cfg");
	KeyValues hKeyValues = new KeyValues("LOTR");
	
	if(!hKeyValues.ImportFromFile(szBuffer) || !hKeyValues.JumpToKey(szMap))
	{
		Suicide();
		return;
	}
	if((Frodo = hKeyValues.GetNum("Frodo")))
	{
		PrecacheModel("models/player/slow/amberlyn/lotr/frodo/slow.mdl", true);
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/frodo/slow_cape.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/frodo/slow_cape.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/frodo/slow_cape_bump.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/frodo/slow_clothes.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/frodo/slow_clothes.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/frodo/slow_clothes_bump.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/frodo/slow_eyes.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/frodo/slow_hair.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/frodo/slow_hair.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/frodo/slow_hair_2.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/frodo/slow_hair_bump.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/frodo/slow_skin.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/frodo/slow_skin.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/frodo/slow_skin_bump.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/frodo/slow_sword.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/frodo/slow_sword.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/frodo/slow_sword_bump.vtf");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/frodo/slow.dx80.vtx");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/frodo/slow.dx90.vtx");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/frodo/slow.mdl");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/frodo/slow.phy");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/frodo/slow.sw.vtx");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/frodo/slow.vvd");
	}
	if((Gandalf = hKeyValues.GetNum("Gandalf")))
	{
		PrecacheModel("models/player/slow/amberlyn/lotr/gandalf/slow.mdl", true);
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_cape.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_cape.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_cape_2.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_cape_bump.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_cape_translucent.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_clothes.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_clothes.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_clothes_bump.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_eyes.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_face.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_face.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_face_2.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_face_bump.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_hair.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_hair.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_hair_2.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_hair_bump.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_hands.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_hands.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_hands_bump.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_weapon.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_weapon.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_weapon_2.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gandalf/slow_weapon_bump.vtf");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/gandalf/slow.dx80.vtx");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/gandalf/slow.dx90.vtx");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/gandalf/slow.mdl");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/gandalf/slow.phy");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/gandalf/slow.sw.vtx");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/gandalf/slow.vvd");
		
		PrecacheSound("sibgamers/lotr/gandalf/prepare.mp3", true);
		AddFileToDownloadsTable("sound/sibgamers/lotr/gandalf/prepare.mp3");
		
	}
	if((OtherSkins |= (hKeyValues.GetNum("Aragorn") << 0)) & (1 << 0))
	{
		PrecacheModel("models/player/slow/amberlyn/lotr/aragorn/slow.mdl", true);
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/aragorn/slow_armor.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/aragorn/slow_armor.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/aragorn/slow_armor_bump.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/aragorn/slow_cape.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/aragorn/slow_cape.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/aragorn/slow_chain_skirt.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/aragorn/slow_clothes.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/aragorn/slow_clothes.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/aragorn/slow_clothes_bump.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/aragorn/slow_eyes.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/aragorn/slow_face.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/aragorn/slow_face.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/aragorn/slow_face_bump.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/aragorn/slow_hair.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/aragorn/slow_hair.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/aragorn/slow_hair_2.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/aragorn/slow_hair_bump.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/aragorn/slow_ring.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/aragorn/slow_weapon.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/aragorn/slow_weapon.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/aragorn/slow_weapon_bump.vtf");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/aragorn/slow.dx80.vtx");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/aragorn/slow.dx90.vtx");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/aragorn/slow.mdl");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/aragorn/slow.phy");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/aragorn/slow.sw.vtx");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/aragorn/slow.vvd");
	}
	if((OtherSkins |= (hKeyValues.GetNum("Legolas") << 1)) & (1 << 1))
	{
		PrecacheModel("models/player/slow/amberlyn/lotr/legolas/slow.mdl", true);
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/legolas/slow_armor.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/legolas/slow_armor.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/legolas/slow_armor_bump.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/legolas/slow_clothes.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/legolas/slow_clothes.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/legolas/slow_clothes_bump.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/legolas/slow_eyes.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/legolas/slow_face.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/legolas/slow_face.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/legolas/slow_face_bump.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/legolas/slow_hair.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/legolas/slow_hair.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/legolas/slow_hair_2.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/legolas/slow_hair_bump.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/legolas/slow_weapon.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/legolas/slow_weapon.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/legolas/slow_weapon_bump.vtf");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/legolas/slow.dx80.vtx");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/legolas/slow.dx90.vtx");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/legolas/slow.mdl");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/legolas/slow.phy");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/legolas/slow.sw.vtx");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/legolas/slow.vvd");
	}
	if((OtherSkins |= (hKeyValues.GetNum("Gimli") << 2)) & (1 << 2))
	{
		PrecacheModel("models/player/slow/amberlyn/lotr/gimli/slow.mdl", true);
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_armor.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_armor.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_armor_bump.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_body_gold.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_cape.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_crown_translucent.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_eyes.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_face.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_face.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_face_bump.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_hair.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_hair.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_hair_2.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_hair_bump.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_hair_gold.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_skirt.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_skirt.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_skirt_bump.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_skirt_gold.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_weapon.vmt");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_weapon.vtf");
		AddFileToDownloadsTable("materials/models/player/slow/amberlyn/lotr/gimli/slow_weapon_bump.vtf");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/gimli/slow.dx80.vtx");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/gimli/slow.dx90.vtx");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/gimli/slow.mdl");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/gimli/slow.phy");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/gimli/slow.sw.vtx");
		AddFileToDownloadsTable("models/player/slow/amberlyn/lotr/gimli/slow.vvd");
	}
	
	if(OtherSkins)
	{
		if(!TopDefHook)
		{
			TopDefHook = true;
			HookEvent("player_hurt", OnPlayerHurt);
		}
	}
	else
	{
		if(Gandalf <= 0 && Frodo <= 0)
		{
			Suicide();
			return;
		}
		if(TopDefHook)
		{
			TopDefHook = false;
			UnhookEvent("player_hurt", OnPlayerHurt);
			
		}
	}
	
	delete hKeyValues;
}


public Action Timer_Auth(Handle hTimer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnRoundStart(Event hEvent, const char[] name, bool dontbroadcast)
{
	AragornOwner = LegolasOwner = GimliOwner = FrodoOwner = GandalfOwner = 0;
	if(OtherSkins)
	{
		delete TimerSetSkins;
		TimerSetSkins = CreateTimer(3.0, Timer_SetSkins);
	}

}

public Action Timer_SetSkins(Handle hTimer)
{
	TimerSetSkins = null;
	int Skins[3], iCount, TopDefenders[3];
	
	for(int i; i < 3; i++)
	{
		if(OtherSkins & (1 << i))
		{
			Skins[iCount++] = i;
		}
	}
	
	for(int i; i < iCount; i++)
	{
		int iIndex = GetRandomInt(i, iCount - 1);
		
		if(iIndex != i)
		{
			int iTemp = Skins[iIndex];
			for(int j = iIndex; j > 0; j--)
			{
				
				Skins[j] = Skins[j - 1];
			}
			Skins[i] = iTemp;
		}
	}
	
	for(int i; i < 3; i++)
	{
		int iMax = -1;
		for(int j = 1; j <= MaxClients; j++)
		{
			if(IsClientInGame(j) && IsPlayerAlive(j) && GetClientTeam(j) == 3 && Damage[j] && (iMax == -1 || Damage[j] > Damage[iMax]) && !IsClientTopDefender(j, TopDefenders))
			{
				iMax = j;
			}
			
		}
		
		if(iMax != -1)
		{
			TopDefenders[i] = iMax;
		}
		
		
	}
	
	for(int i; i < iCount; i++)
	{
		if(TopDefenders[i])
		{
			switch(Skins[i])
			{
				case 0:
				{
					AragornOwner = TopDefenders[i];
					SetEntityModel(TopDefenders[i], "models/player/slow/amberlyn/lotr/aragorn/slow.mdl");
				}
				case 1:
				{
					GimliOwner = TopDefenders[i];
					SetEntityModel(TopDefenders[i], "models/player/slow/amberlyn/lotr/gimli/slow.mdl");
				}
				case 2:
				{
					LegolasOwner = TopDefenders[i];
					SetEntityModel(TopDefenders[i], "models/player/slow/amberlyn/lotr/legolas/slow.mdl");
				}
			}
		}
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		Damage[i] = 0;
	}
}

bool IsClientTopDefender(int iClient, int iTop[3])
{
	for(int i; i < 3; i++)
	{
		if(iTop[i] == iClient)
		{
			return true;
		}
	}
	
	return false;
}


public void OnPlayerHurt(Event hEvent, const char[] name, bool broadcast)
{
	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	
	if(0 < iAttacker <= MaxClients && GetClientTeam(iAttacker) == 3)
	{
		Damage[iAttacker] += hEvent.GetInt("dmg_health");
	}
}

public void OnClientPutInServer(int iClient)
{
	if(Gandalf > 0 || Frodo > 0)
	{
		SDKHook(iClient, SDKHook_WeaponEquipPost, OnWeaponEquip);
	}
}

public void OnClientDisconnect(int iClient)
{
	Damage[iClient] = 0;
}

void Suicide()
{
	char szBuffer[256];
	GetPluginFilename(GetMyHandle(), szBuffer, 256);
	ServerCommand("sm plugins unload %s", szBuffer);
}


public void OnWeaponEquip(int iClient, int iWeapon)
{
	if(IsValidEntity(iWeapon) && GetClientTeam(iClient) == 3 && AragornOwner != iClient && LegolasOwner != iClient && GimliOwner != iClient && GandalfOwner != iClient && FrodoOwner != iClient)
	{
		switch(GetWeaponId(iWeapon))
		{
			case 0:
			{
				FrodoOwner = iClient;
				SetEntityModel(iClient, "models/player/slow/amberlyn/lotr/frodo/slow.mdl");
			}
			case 1:
			{
				GandalfOwner = iClient;
				SetEntityModel(iClient, "models/player/slow/amberlyn/lotr/gandalf/slow.mdl");
				
				CreateTimer(1.0, Timer_PlayGandalf, iClient);
			}
		}
	}
}

public Action Timer_PlayGandalf(Handle hTimer, int iClient)
{
	if(IsClientInGame(iClient) && IsPlayerAlive(iClient) && GandalfOwner == iClient)
	{
		EmitSoundToAll("sibgamers/lotr/gandalf/prepare.mp3", iClient);
	}
}

int GetWeaponId(int iWeapon)
{
	int iHammerID = GetEntProp(iWeapon, Prop_Data, "m_iHammerID");
	
	if(iHammerID > 0)
	{
		if(iHammerID == Frodo)
		{
			return !FrodoOwner ? 0:-1;
		}
		if(iHammerID == Gandalf)
		{
			return !GandalfOwner ? 1:-1;
		}
	}
	return -1;
}