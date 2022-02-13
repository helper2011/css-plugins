#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <halflife>

#pragma newdecls required


bool g_bInfAmmoHooked = false;
bool g_bInfAmmo[MAXPLAYERS + 1] = {false, ...};

ConVar g_CVar_sv_pausable;

static char g_sServerCanExecuteCmds[][] = {	"cl_soundscape_flush", "r_screenoverlay", "playgamesound",
						"slot0", "slot1", "slot2", "slot3", "slot4", "slot5", "slot6",
						"slot7", "slot8", "slot9", "slot10", "cl_spec_mode", "cancelselect",
						"invnext", "play", "invprev", "sndplaydelay", "lastinv", "dsp_player",
						"name", "redirect", "retry", "r_cleardecals", "echo", "soundfade"};

public Plugin myinfo =
{
	name 		= "Advanced Commands",
	author 		= "BotoX + Obus",
	description	= "Adds extra commands for admins.",
	version 	= "2.1.4",
	url 		= "https://github.com/CSSZombieEscape/sm-plugins/tree/master/ExtraCommands/"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegAdminCmd("sm_hp", Command_Health, ADMFLAG_GENERIC, "sm_hp <#userid|name> <value>");
	RegAdminCmd("sm_health", Command_Health, ADMFLAG_GENERIC, "sm_health <#userid|name> <value>");
	RegAdminCmd("sm_armor", Command_Armor, ADMFLAG_GENERIC, "sm_armor <#userid|name> <value>");
	RegAdminCmd("sm_weapon", Command_Weapon, ADMFLAG_GENERIC, "sm_weapon <#userid|name> <name> [clip] [ammo]");
	RegAdminCmd("sm_give", Command_Weapon, ADMFLAG_GENERIC, "sm_give <#userid|name> <name> [clip] [ammo]");
	RegAdminCmd("sm_strip", Command_Strip, ADMFLAG_GENERIC, "sm_strip <#userid|name>");
	RegAdminCmd("sm_iammo", Command_InfAmmo, ADMFLAG_GENERIC, "sm_iammo <#userid|name> <0|1>");
	RegAdminCmd("sm_speed", Command_Speed, ADMFLAG_GENERIC, "sm_speed <#userid|name> <value>");
	RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_GENERIC, "sm_respawn <#userid|name>");
	RegAdminCmd("sm_team", Command_Team, ADMFLAG_GENERIC, "sm_team <#userid|name> <team> [alive]");
	RegAdminCmd("sm_cash", Command_Cash, ADMFLAG_GENERIC, "sm_cash <#userid|name> <value>");
	RegAdminCmd("sm_modelscale", Command_ModelScale, ADMFLAG_GENERIC, "sm_modelscale <#userid|name> <scale>");
	RegAdminCmd("sm_resize", Command_ModelScale, ADMFLAG_GENERIC, "sm_resize <#userid|name> <scale>");
	RegAdminCmd("sm_setmodel", Command_SetModel, ADMFLAG_GENERIC, "sm_setmodel <#userid|name> <modelpath>");
	RegAdminCmd("sm_setscore", Command_SetScore, ADMFLAG_GENERIC, "sm_setscore <#userid|name> <(optional +/-) value>");
	RegAdminCmd("sm_setdeaths", Command_SetDeaths, ADMFLAG_GENERIC, "sm_setdeaths <#userid|name> <value>");
	RegAdminCmd("sm_setmvp", Command_SetMvp, ADMFLAG_GENERIC, "sm_setmvp <#userid|name> <value>");
	RegAdminCmd("sm_setteamscore", Command_SetTeamScore, ADMFLAG_GENERIC, "sm_setteamscore <team> <value>");
	RegAdminCmd("sm_restartround", Command_RestartRound, ADMFLAG_GENERIC, "sm_restartround <delay>");
	RegAdminCmd("sm_fcvar", Command_ForceCVar, ADMFLAG_CHEATS, "sm_fcvar <#userid|name> <cvar> <value>");
	RegAdminCmd("sm_setclantag", Command_SetClanTag, ADMFLAG_CHEATS, "sm_setclantag <#userid|name> [text]");
	RegAdminCmd("sm_fakecommand", Command_FakeCommand, ADMFLAG_CHEATS, "sm_fakecommand <#userid|name> [command] [args]");
	RegAdminCmd("sm_querycvar", Command_QueryCVar, ADMFLAG_GENERIC, "sm_querycvar <#userid|name> [cvar]");
	RegAdminCmd("sm_precachesound", Command_PrecacheSound, ADMFLAG_CHEATS, "sm_precachesound <soundpath>");


	g_CVar_sv_pausable = FindConVar("sv_pausable");

	if(g_CVar_sv_pausable)
	{
		AddCommandListener(Listener_Pause, "pause");
		AddCommandListener(Listener_Pause, "setpause"); //doesn't work on win32 srcds?
		AddCommandListener(Listener_Pause, "unpause"); //doesn't work on win32 srcds?
	}
}

public void OnMapStart()
{
	ToggleInfAmmoHook(false);
}

public Action Listener_Pause(int client, const char[] command, int argc)
{
	static bool bPaused;

	if(!g_CVar_sv_pausable.BoolValue)
	{
		ReplyToCommand(client, "[SM] \"sv_pausable\" is set to 0!");
		return Plugin_Handled;
	}

	if(client == 0)
	{
		PrintToServer("[SM] Cannot use command from server console.");
		return Plugin_Handled;
	}

	if(!IsClientAuthorized(client) || !GetAdminFlag(GetUserAdmin(client), Admin_Generic))
	{
		ReplyToCommand(client, "[SM] You do not have permission to pause/unpause the game.");
		return Plugin_Handled;
	}

	if(strcmp(command, "setpause") == 0)
		bPaused = true;
	else if(strcmp(command, "unpause") == 0)
		bPaused = false;
	else
		bPaused = !bPaused;

	ShowActivity2(client, "\x01[SM] \x04", "%s\x01 the game.", bPaused ? "Paused" : "Unpaused");
	LogAction(client, -1, "\"%L\" %s the game.", client, bPaused ? "Paused" : "Unpaused");

	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	g_bInfAmmo[client] = false;
}


public void Event_WeaponFire(Handle hEvent, char[] name, bool dontBroadcast)
{
	static int client;
	static int weapon;
	static int toAdd;
	static char weaponClassname[32];
	if(!g_bInfAmmo[(client = GetClientOfUserId(GetEventInt(hEvent, "userid")))] || !IsValidEntity((weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", 0))))
		return;
		
	if(weapon != GetPlayerWeaponSlot(client, 0) && weapon != GetPlayerWeaponSlot(client, 1))
		return;

	if(GetEntProp(weapon, Prop_Send, "m_iState", 4, 0) == 2 && GetEntProp(weapon, Prop_Send, "m_iClip1", 4, 0))
	{
		toAdd = 1;
		GetEntityClassname(weapon, weaponClassname, sizeof(weaponClassname));

		if(strcmp(weaponClassname[7], "glock", true) == 0 || strcmp(weaponClassname[7], "famas", true) == 0)
		{
			if(GetEntProp(weapon, Prop_Send, "m_bBurstMode"))
			{
				switch (GetEntProp(weapon, Prop_Send, "m_iClip1"))
				{
					case 1:
					{
						toAdd = 1;
					}
					case 2:
					{
						toAdd = 2;
					}
					default:
					{
						toAdd = 3;
					}
				}
			}
		}

		SetEntProp(weapon, Prop_Send, "m_iClip1", GetEntProp(weapon, Prop_Send, "m_iClip1", 4, 0) + toAdd, 4, 0);
	}
}

public Action Command_Health(int client, int argc)
{
	if(argc < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_hp <#userid|name> <value>");
		return Plugin_Handled;
	}

	char sArgs[65];
	char sArgs2[20];
	char sTargetName[MAX_TARGET_LENGTH];
	int iTargets[MAXPLAYERS];
	int iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArgs, sizeof(sArgs));
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	int amount = clamp(StringToInt(sArgs2), 1, 0x7FFFFFFF);

	if((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_ALIVE, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for(int i = 0; i < iTargetCount; i++)
	{
		SetEntProp(iTargets[i], Prop_Send, "m_iHealth", amount, 1);
	}

	ShowActivity2(client, "\x01[SM] \x04", "\x01Set health to \x04%d\x01 on target \x04%s", amount, sTargetName);

	if(iTargetCount > 1)
		LogAction(client, -1, "\"%L\" set health to \"%d\" on target \"%s\"", client, amount, sTargetName);
	else
		LogAction(client, iTargets[0], "\"%L\" set health to \"%d\" on target \"%L\"", client, amount, iTargets[0]);

	return Plugin_Handled;
}

public Action Command_Armor(int client, int argc)
{
	if(argc < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_armor <#userid|name> <value>");
		return Plugin_Handled;
	}

	char sArgs[65];
	char sArgs2[20];
	char sTargetName[MAX_TARGET_LENGTH];
	int iTargets[MAXPLAYERS];
	int iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArgs, sizeof(sArgs));
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	int amount = clamp(StringToInt(sArgs2), 0, 0xFF);

	if((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_ALIVE, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for(int i = 0; i < iTargetCount; i++)
	{
		SetEntProp(iTargets[i], Prop_Send, "m_ArmorValue", amount, 1);
	}

	ShowActivity2(client, "\x01[SM] \x04", "\x01Set kevlar to \x04%d\x01 on target \x04%s", amount, sTargetName);

	if(iTargetCount > 1)
		LogAction(client, -1, "\"%L\" set kevlar to \"%d\" on target \"%s\"", client, amount, sTargetName);
	else
		LogAction(client, iTargets[0], "\"%L\" set kevlar to \"%d\" on target \"%L\"", client, amount, iTargets[0]);

	return Plugin_Handled;
}

public Action Command_Weapon(int client, int argc)
{
	if(argc < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_weapon <#userid|name> <weapon> [clip] [ammo]");
		return Plugin_Handled;
	}

	int ammo = 2500;
	int clip = -1;

	char sArgs[65];
	GetCmdArg(1, sArgs, sizeof(sArgs));

	char sArgs2[65];
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	char sWeapon[65];

	if(strncmp(sArgs2, "weapon_", 7) != 0 && strncmp(sArgs2, "item_", 5) != 0 && !StrEqual(sArgs2, "nvg", false))
		Format(sWeapon, sizeof(sWeapon), "weapon_%s", sArgs2);
	else
		strcopy(sWeapon, sizeof(sWeapon), sArgs2);

	if(StrContains(sWeapon, "grenade", false) != -1 || StrContains(sWeapon, "flashbang", false) != -1 || strncmp(sArgs2, "item_", 5) == 0) //decoy healthshot molotov diversion
		ammo = -1;

	if(client >= 1)
	{
		if(!GetAdminFlag(GetUserAdmin(client), Admin_RCON))
		{
			if(StrEqual(sWeapon, "weapon_c4", false) || StrEqual(sWeapon, "weapon_smokegrenade", false) || StrEqual(sWeapon, "item_defuser", false))
			{
				ReplyToCommand(client, "[SM] This weapon is restricted!");
				return Plugin_Handled;
			}
		}
	}

	if(argc >= 3)
	{
		char sArgs3[20];
		GetCmdArg(3, sArgs3, sizeof(sArgs3));

		if(StringToIntEx(sArgs3, clip) == 0)
		{
			ReplyToCommand(client, "[SM] Invalid Clip Value");
			return Plugin_Handled;
		}
	}

	if(argc >= 4)
	{
		char sArgs4[20];
		GetCmdArg(4, sArgs4, sizeof(sArgs4));

		if(StringToIntEx(sArgs4, ammo) == 0)
		{
			ReplyToCommand(client, "[SM] Invalid Ammo Value");
			return Plugin_Handled;
		}
	}

	if(StrContains(sWeapon, "grenade", false) != -1 || StrContains(sWeapon, "flashbang", false) != -1)
	{
		int tmp = ammo;
		ammo = clip;
		clip = tmp;
	}

	char sTargetName[MAX_TARGET_LENGTH];
	int iTargets[MAXPLAYERS];
	int iTargetCount;
	bool bIsML;

	if((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_ALIVE, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	if(StrEqual(sWeapon, "nvg", false))
	{
		for(int i = 0; i < iTargetCount; i++)
			SetEntProp(iTargets[i], Prop_Send, "m_bHasNightVision", 1, 1);
	}
	else if(StrEqual(sWeapon, "item_defuser", false))
	{
		for(int i = 0; i < iTargetCount; i++)
			SetEntProp(iTargets[i], Prop_Send, "m_bHasDefuser", 1);
	}
	else
	{
		for(int i = 0; i < iTargetCount; i++)
		{
			int ent = GivePlayerItemFixed(iTargets[i], sWeapon);

			if(ent == -1) {
				ReplyToCommand(client, "[SM] Invalid Weapon");
				return Plugin_Handled;
			}

			if(clip != -1)
				SetEntProp(ent, Prop_Send, "m_iClip1", clip);

			if(ammo != -1)
			{
				int PrimaryAmmoType = GetEntProp(ent, Prop_Data, "m_iPrimaryAmmoType");

				if(PrimaryAmmoType != -1)
					SetEntProp(iTargets[i], Prop_Send, "m_iAmmo", ammo, _, PrimaryAmmoType);
			}

			if(strncmp(sArgs2, "item_", 5) != 0 && !StrEqual(sWeapon, "weapon_hegrenade", false))
				EquipPlayerWeapon(iTargets[i], ent);

			if(ammo != -1)
			{
				int PrimaryAmmoType = GetEntProp(ent, Prop_Data, "m_iPrimaryAmmoType");

				if(PrimaryAmmoType != -1)
					SetEntProp(iTargets[i], Prop_Send, "m_iAmmo", ammo, _, PrimaryAmmoType);
			}
		}
	}

	ShowActivity2(client, "\x01[SM] \x04", "\x01Gave \x04%s\x01 to target \x04%s", sWeapon, sTargetName);

	if(iTargetCount > 1)
		LogAction(client, -1, "\"%L\" gave \"%s\" to target \"%s\"", client, sWeapon, sTargetName);
	else
		LogAction(client, iTargets[0], "\"%L\" gave \"%s\" to target \"%L\"", client, sWeapon, iTargets[0]);

	return Plugin_Handled;
}

public Action Command_Strip(int client, int argc)
{
	if(argc < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_strip <#userid|name>");
		return Plugin_Handled;
	}

	char sArgs[65];
	GetCmdArg(1, sArgs, sizeof(sArgs));

	char sTargetName[MAX_TARGET_LENGTH];
	int iTargets[MAXPLAYERS];
	int iTargetCount;
	bool bIsML;

	if((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_ALIVE, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for(int i = 0; i < iTargetCount; i++)
	{
		for(int j = 0; j < 5; j++)
		{
			int w = -1;

			while ((w = GetPlayerWeaponSlot(iTargets[i], j)) != -1)
			{
				if(IsValidEntity(w) && IsValidEdict(w))
				{
					RemovePlayerItem(iTargets[i], w);
					AcceptEntityInput(w, "Kill");
				}
			}
		}
	}

	ShowActivity2(client, "\x01[SM] \x04", "\x01Stripped all weapons from target \x04%s", sTargetName);

	if(iTargetCount > 1)
		LogAction(client, -1, "\"%L\" stripped all weapons from target \"%s\"", client, sTargetName);
	else
		LogAction(client, iTargets[0], "\"%L\" stripped all weapons from target \"%L\"", client, iTargets[0]);

	return Plugin_Handled;
}

void CheckInfAmmoHook()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(g_bInfAmmo[i])
		{
			ToggleInfAmmoHook(true);
			return;
		}
	}
	ToggleInfAmmoHook(false);
}

void ToggleInfAmmoHook(bool bToggle)
{
	if(bToggle == g_bInfAmmoHooked)
		return;
	
	if(!g_bInfAmmoHooked)
	{
		HookEvent("weapon_fire", Event_WeaponFire);
	}
	else
	{
		UnhookEvent("weapon_fire", Event_WeaponFire);
	}
	g_bInfAmmoHooked = !g_bInfAmmoHooked;
}

public Action Command_InfAmmo(int client, int argc)
{
	if(argc < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_iammo <#userid|name> <0|1>");
		return Plugin_Handled;
	}

	char sArgs[65];
	GetCmdArg(1, sArgs, sizeof(sArgs));

	int value = -1;
	char sArgs2[20];
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	if(StringToIntEx(sArgs2, value) == 0)
	{
		ReplyToCommand(client, "[SM] Invalid Value");
		return Plugin_Handled;
	}
	
	char sTargetName[MAX_TARGET_LENGTH];

	int[] iTargets = new int[MaxClients];
	int iTargetCount;
	bool bIsML;
	bool bToggle = value ? true : false;
	if((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MaxClients, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_BOTS, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for(int i = 0; i < iTargetCount; i++)
	{
		g_bInfAmmo[iTargets[i]] = bToggle;
	}

	ShowActivity2(client, "\x01[SM] \x04", "%s\x01 infinite ammo on target \x04%s", (value ? "Enabled" : "Disabled"), sTargetName);
	LogAction(client, -1, "\"%L\" %s infinite ammo on target \"%s\"", client, (value ? "enabled" : "disabled"), sTargetName);
	CheckInfAmmoHook();
	return Plugin_Handled;
}

public Action Command_Speed(int client, int argc)
{
	if(argc < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_speed <#userid|name> <value>");
		return Plugin_Handled;
	}

	char sArgs[65];
	char sArgs2[20];
	char sTargetName[MAX_TARGET_LENGTH];
	int iTargets[MAXPLAYERS];
	int iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArgs, sizeof(sArgs));
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	float speed = clamp(StringToFloat(sArgs2), 0.0, 100.0);

	if((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_ALIVE, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for(int i = 0; i < iTargetCount; i++)
	{
		SetEntPropFloat(iTargets[i], Prop_Data, "m_flLaggedMovementValue", speed);
	}

	ShowActivity2(client, "\x01[SM] \x04", "\x01Set speed to \x04%.2f\x01 on target \x04%s", speed, sTargetName);

	if(iTargetCount > 1)
		LogAction(client, -1, "\"%L\" set speed to \"%.2f\" on target \"%s\"", client, speed, sTargetName);
	else
		LogAction(client, iTargets[0], "\"%L\" set speed to \"%.2f\" on target \"%L\"", client, speed, iTargets[0]);

	return Plugin_Handled;
}

public Action Command_Respawn(int client, int argc)
{
	if(argc < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_respawn <#userid|name>");
		return Plugin_Handled;
	}

	char sArgs[64];
	char sTargetName[MAX_TARGET_LENGTH];
	int iTargets[MAXPLAYERS];
	int iTargetCount;
	bool bIsML;
	bool bDidRespawn;

	GetCmdArg(1, sArgs, sizeof(sArgs));

	if((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_DEAD, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for(int i = 0; i < iTargetCount; i++)
	{
		if(GetClientTeam(iTargets[i]) == CS_TEAM_SPECTATOR || GetClientTeam(iTargets[i]) == CS_TEAM_NONE)
			continue;

		bDidRespawn = true;
		CS_RespawnPlayer(iTargets[i]);
	}

	if(bDidRespawn)
	{
		ShowActivity2(client, "\x01[SM] \x04", "\x01Respawned \x04%s", sTargetName);
		LogAction(client, -1, "\"%L\" respawned \"%s\"", client, sTargetName);
	}

	return Plugin_Handled;
}

public Action Command_Team(int client, int argc)
{
	if(argc < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_team <#userid|name> <team>");
		return Plugin_Handled;
	}

	char sArgs[65];
	GetCmdArg(1, sArgs, sizeof(sArgs));

	int iTeam = CS_TEAM_NONE;
	char sArgs2[8];
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	bool bAlive = false;
	if(argc >= 3)
	{
		char sArgs3[8];
		GetCmdArg(3, sArgs3, sizeof(sArgs3));
		if(StringToInt(sArgs3))
			bAlive = true;
	}

	if(StringToIntEx(sArgs2, iTeam) == 0 || iTeam < CS_TEAM_NONE || iTeam > CS_TEAM_CT)
	{
		ReplyToCommand(client, "[SM] Invalid Value");
		return Plugin_Handled;
	}

	char sTargetName[MAX_TARGET_LENGTH];
	int iTargets[MAXPLAYERS];
	int iTargetCount;
	bool bIsML;

	if((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, 0, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for(int i = 0; i < iTargetCount; i++)
	{
		if(bAlive)
			CS_SwitchTeam(iTargets[i], iTeam);
		else
			ChangeClientTeam(iTargets[i], iTeam);
	}

	ShowActivity2(client, "\x01[SM] \x04", "\x01Changed \x04%s\x01 to team \x04%d", sTargetName, iTeam);
	LogAction(client, -1, "\"%L\" changed team%s to %d on target \"%s\"", client, bAlive ? " ALIVE" : "", iTeam, sTargetName);

	return Plugin_Handled;
}

public Action Command_Cash(int client, int argc)
{
	if(argc < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_cash <#userid|name> <value>");
		return Plugin_Handled;
	}

	char sArgs[64];
	char sArgs2[32];
	char sTargetName[MAX_TARGET_LENGTH];
	int iTargets[MAXPLAYERS];
	int iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArgs, sizeof(sArgs));
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	int iCash = clamp(StringToInt(sArgs2), 0, 0xFFFF);

	if((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_ALIVE, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for(int i = 0; i < iTargetCount; i++)
	{
		SetEntProp(iTargets[i], Prop_Send, "m_iAccount", iCash);
	}

	ShowActivity2(client, "\x01[SM] \x04", "\x01Set cash to \x04%d\x01 on target \x04%s", iCash, sTargetName);

	if(iTargetCount > 1)
		LogAction(client, -1, "\"%L\" set cash to \"%d\" on target \"%s\"", client, iCash, sTargetName);
	else
		LogAction(client, iTargets[0], "\"%L\" set cash to \"%d\" on target \"%L\"", client, iCash, iTargets[0]);

	return Plugin_Handled;
}

public Action Command_ModelScale(int client, int argc)
{
	if(argc < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_resize/sm_modelscale <#userid|name> <scale>");
		return Plugin_Handled;
	}

	char sArgs[64];
	char sArgs2[32];
	char sTargetName[MAX_TARGET_LENGTH];
	int iTargets[MAXPLAYERS];
	int iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArgs, sizeof(sArgs));
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	float fScale = clamp(StringToFloat(sArgs2), 0.1, 100.0);

	if((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_ALIVE, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for(int i = 0; i < iTargetCount; i++)
	{
		SetEntPropFloat(iTargets[i], Prop_Send, "m_flModelScale", fScale);
	}

	ShowActivity2(client, "\x01[SM] \x04", "\x01Set model scale to \x04%.2f\x01 on target \x04%s", fScale, sTargetName);

	if(iTargetCount > 1)
		LogAction(client, -1, "\"%L\" set model scale to \"%.2f\" on target \"%s\"", client, fScale, sTargetName);
	else
		LogAction(client, iTargets[0], "\"%L\" set model scale to \"%.2f\" on target \"%L\"", client, fScale, iTargets[0]);

	return Plugin_Handled;
}

public Action Command_SetModel(int client, int argc)
{
	if(argc < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setmodel <#userid|name> <modelpath>");
		return Plugin_Handled;
	}

	char sArgs[32];
	char sArgs2[PLATFORM_MAX_PATH];
	char sTargetName[MAX_TARGET_LENGTH];
	int iTargets[MAXPLAYERS];
	int iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArgs, sizeof(sArgs));
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	if((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_ALIVE, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	if(!FileExists(sArgs2, true))
	{
		ReplyToCommand(client, "[SM] File \"%s\" does not exist.", sArgs2);
		return Plugin_Handled;
	}

	if(!IsModelPrecached(sArgs2))
	{
		ReplyToCommand(client, "[SM] File \"%s\" is not precached, attempting to precache now.", sArgs2);

		PrecacheModel(sArgs2);
	}

	for(int i = 0; i < iTargetCount; i++)
	{
		SetEntityModel(iTargets[i], sArgs2);
	}

	ShowActivity2(client, "\x01[SM] \x04", "\x01Set model to \x04%s\x01 on target \x04%s", sArgs2, sTargetName);

	if(iTargetCount > 1)
		LogAction(client, -1, "\"%L\" set model to \"%s\" on target \"%s\"", client, sArgs2, sTargetName);
	else
		LogAction(client, iTargets[0], "\"%L\" set model to \"%s\" on target \"%L\"", client, sArgs2, iTargets[0]);

	return Plugin_Handled;
}

public Action Command_SetScore(int client, int argc)
{
	if(argc < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setscore <#userid|name> <(optional +/-) value>");
		return Plugin_Handled;
	}

	char sArgs[32];
	char sArgs2[32];
	char sTargetName[MAX_TARGET_LENGTH];
	int iTargets[MAXPLAYERS];
	int iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArgs, sizeof(sArgs));
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	if((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, 0, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	int iMode = 0;
	int iVal;

	if(StrContains(sArgs2, "+", true) != -1)
	{
		iMode = 1;
		iVal = StringToInt(sArgs2[1]);
	}
	else if(StrContains(sArgs2, "-", true) != -1)
	{
		iMode = 2;
		iVal = StringToInt(sArgs2[1]);
	}
	else
	{
		iVal = StringToInt(sArgs2);
	}

	for(int i = 0; i < iTargetCount; i++)
	{
		if(iMode == 1)
		{
			SetEntProp(iTargets[i], Prop_Data, "m_iFrags", GetEntProp(iTargets[i], Prop_Data, "m_iFrags") + iVal);
			ShowActivity2(client, "\x01[SM] \x04", "\x01Increased score by \x04%d\x01 on target \x04%s", iVal, sTargetName);
		}
		else if(iMode == 2)
		{
			SetEntProp(iTargets[i], Prop_Data, "m_iFrags", GetEntProp(iTargets[i], Prop_Data, "m_iFrags") - iVal);
			ShowActivity2(client, "\x01[SM] \x04", "\x01Decreased score by \x04%d\x01 on target \x04%s", iVal, sTargetName);
		}
		else
		{
			SetEntProp(iTargets[i], Prop_Data, "m_iFrags", iVal);
			ShowActivity2(client, "\x01[SM] \x04", "\x01Set score to \x04%d\x01 on target \x04%s", iVal, sTargetName);
		}
	}

	if(iTargetCount > 1)
		LogAction(client, -1, "\"%L\" set score \"%s\" on target \"%s\"", client, sArgs2, sTargetName);
	else
		LogAction(client, iTargets[0], "\"%L\" set score \"%s\" on target \"%L\"", client, sArgs2, iTargets[0]);

	return Plugin_Handled;
}

public Action Command_SetDeaths(int client, int argc)
{
	if(argc < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setdeaths <#userid|name> <value>");
		return Plugin_Handled;
	}

	char sArgs[32];
	char sArgs2[32];
	char sTargetName[MAX_TARGET_LENGTH];
	int iTargets[MAXPLAYERS];
	int iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArgs, sizeof(sArgs));
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	int iVal = StringToInt(sArgs2);

	if((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, 0, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for(int i = 0; i < iTargetCount; i++)
	{
		SetEntProp(iTargets[i], Prop_Data, "m_iDeaths", iVal);
	}

	if(iTargetCount > 1)
	{
		ShowActivity2(client, "\x01[SM] \x04", "\x01Set deaths to \x04%d\x01 on target \x04%s", iVal, sTargetName);
		LogAction(client, -1, "\"%L\" set deaths to \"%d\" on target \"%s\"", client, iVal, sTargetName);
	}
	else
	{
		ShowActivity2(client, "\x01[SM] \x04", "\x01Set deaths to \x04%d\x01 on target \x04%s", iVal, sTargetName);
		LogAction(client, iTargets[0], "\"%L\" set deaths to \"%d\" on target \"%L\"", client, iVal, iTargets[0]);
	}

	return Plugin_Handled;
}

public Action Command_SetMvp(int client, int argc)
{
	if(argc < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setmvp <#userid|name> <value>");
		return Plugin_Handled;
	}

	char sArgs[32];
	char sArgs2[32];
	char sTargetName[MAX_TARGET_LENGTH];
	int iTargets[MAXPLAYERS];
	int iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArgs, sizeof(sArgs));
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	int iVal = StringToInt(sArgs2);

	if((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, 0, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for(int i = 0; i < iTargetCount; i++)
	{
		CS_SetMVPCount(iTargets[i], iVal);
	}

	if(iTargetCount > 1)
	{
		ShowActivity2(client, "\x01[SM] \x04", "\x01Set MVP to \x04%d\x01 on target \x04%s", iVal, sTargetName);
		LogAction(client, -1, "\"%L\" set MVP to \"%d\" on target \"%s\"", client, iVal, sTargetName);
	}
	else
	{
		ShowActivity2(client, "\x01[SM] \x04", "\x01Set MVP to \x04%d\x01 on target \x04%s", iVal, sTargetName);
		LogAction(client, iTargets[0], "\"%L\" set MVP to \"%d\" on target \"%L\"", client, iVal, iTargets[0]);
	}

	return Plugin_Handled;
}

public Action Command_SetTeamScore(int client, int argc)
{
	if(argc < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setteamscore <team> <value>");
		return Plugin_Handled;
	}

	char sArgs[32];
	char sArgs2[32];

	GetCmdArg(1, sArgs, sizeof(sArgs));
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	int iVal = StringToInt(sArgs2);

	if(strcmp(sArgs, "@ct", false) == 0 || strcmp(sArgs, "@cts", false) == 0)
	{
		SetTeamScore(CS_TEAM_CT, iVal);
		CS_SetTeamScore(CS_TEAM_CT, iVal);

		ShowActivity2(client, "\x01[SM] \x04", "\x01Set team-score to \x04%d\x01 on team \x04Counter-Terrorists", iVal);
		LogAction(client, -1, "\"%L\" set team-score to \"%d\" on team \"Counter-Terrorists\"", client, iVal);
	}
	else if(strcmp(sArgs, "@t", false) == 0 || strcmp(sArgs, "@ts", false) == 0)
	{
		SetTeamScore(CS_TEAM_T, iVal);
		CS_SetTeamScore(CS_TEAM_T, iVal);

		ShowActivity2(client, "\x01[SM] \x04", "\x01Set team-score to \x04%d\x01 on team \x04Terrorists", iVal);
		LogAction(client, -1, "\"%L\" set team-score to \"%d\" on team \"Terrorists\"", client, iVal);
	}
	else
	{
		ReplyToCommand(client, "[SM] Invalid team.");
	}

	return Plugin_Handled;
}

public Action Command_RestartRound(int client, int argc)
{
	if(argc < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_restartround <delay>");
		return Plugin_Handled;
	}

	char sArgs[32];
	GetCmdArg(1, sArgs, sizeof(sArgs));

	float fDelay = StringToFloat(sArgs);

	CS_TerminateRound(fDelay, CSRoundEnd_Draw, true);

	ShowActivity2(client, "\x01[SM] \x04", "\x01Restarted the round (%f seconds)", fDelay);
	LogAction(client, -1, "\"%L\" restarted the round (%f seconds)", client, fDelay);

	return Plugin_Handled;
}

stock bool TraceEntityFilter_FilterCaller(int entity, int contentsMask, int client)
{
	return entity != client;
}

public Action Command_ForceCVar(int client, int argc)
{
	if(argc < 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fcvar <#userid|name> <cvar> <value>");
		return Plugin_Handled;
	}

	char sArg[65];
	char sArg2[65];
	char sArg3[65];
	char sTargetName[MAX_TARGET_LENGTH];
	int iTargets[MAXPLAYERS];
	int iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArg, sizeof(sArg));
	GetCmdArg(2, sArg2, sizeof(sArg2));
	GetCmdArg(3, sArg3, sizeof(sArg3));

	ConVar cvar = FindConVar(sArg2);

	if(cvar == null)
	{
		ReplyToCommand(client, "[SM] No such cvar.");
		return Plugin_Handled;
	}

	if((iTargetCount = ProcessTargetString(sArg, client, iTargets, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for(int i = 0; i < iTargetCount; i++)
	{
		cvar.ReplicateToClient(iTargets[i], sArg3);
	}

	return Plugin_Handled;
}

public Action Command_SetClanTag(int client, int argc)
{
	if(argc < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setclantag <#userid|name> [text]");
		return Plugin_Handled;
	}

	char sArg[64];
	char sArg2[64];
	char sTargetName[MAX_TARGET_LENGTH];
	int iTargets[MAXPLAYERS];
	int iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArg, sizeof(sArg));
	GetCmdArg(2, sArg2, sizeof(sArg2));

	if((iTargetCount = ProcessTargetString(sArg, client, iTargets, MAXPLAYERS, 0, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for(int i = 0; i < iTargetCount; i++)
	{
		CS_SetClientClanTag(iTargets[i], sArg2);
	}

	return Plugin_Handled;
}

public Action Command_FakeCommand(int client, int argc)
{
	if(argc < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fakecommand <#userid|name> [command] [args]");
		return Plugin_Handled;
	}

	char sArg[64];
	char sArg2[64];
	char sArg3[64];
	char sTargetName[MAX_TARGET_LENGTH];
	int iTargets[MAXPLAYERS];
	int iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArg, sizeof(sArg));
	GetCmdArg(2, sArg2, sizeof(sArg2));
	GetCmdArg(3, sArg3, sizeof(sArg3));

	if((iTargetCount = ProcessTargetString(sArg, client, iTargets, MAXPLAYERS, COMMAND_FILTER_CONNECTED, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	bool bCanServerExecute = false;

	for(int i = 0; i < sizeof(g_sServerCanExecuteCmds); i++)
	{
		if(strcmp(g_sServerCanExecuteCmds[i], sArg2) == 0)
		{
			bCanServerExecute = true;
			break;
		}
	}

	for(int i = 0; i < iTargetCount; i++)
	{
		if(bCanServerExecute)
			ClientCommand(iTargets[i], "%s %s", sArg2, sArg3);
		else
			FakeClientCommand(iTargets[i], "%s %s", sArg2, sArg3);
	}

	return Plugin_Handled;
}

public Action Command_QueryCVar(int client, int argc)
{
	if(argc < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_querycvar <#userid|name> [cvar]");
		return Plugin_Handled;
	}

	char sArg[64];
	char sArg2[64];
	int iTarget;

	GetCmdArg(1, sArg, sizeof(sArg));
	GetCmdArg(2, sArg2, sizeof(sArg2));

	if((iTarget = FindTarget(client, sArg, true)) <= 0)
		return Plugin_Handled;

	if(QueryClientConVar(iTarget, sArg2, ConVarQueryFinished_QueryCVar, client) == QUERYCOOKIE_FAILED)
		ReplyToCommand(client, "[SM] Failed to query cvar \"%s\"", sArg2);

	return Plugin_Handled;
}

public Action Command_PrecacheSound(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_precachesound <soundpath>");
		return Plugin_Handled;
	}

	char sArgs[PLATFORM_MAX_PATH];
	char sArgs2[PLATFORM_MAX_PATH];
	GetCmdArg(1, sArgs, sizeof(sArgs));
	Format(sArgs2, sizeof(sArgs2), "sound/%s", sArgs);

	if(!FileExists(sArgs2, true))
	{
		ReplyToCommand(client, "[SM] File \"%s\" does not exist.", sArgs2);
		return Plugin_Handled;
	}

	/*if(IsSoundPrecached(sArgs2))
	{
		ReplyToCommand(client, "[SM] File \"%s\" is already precached.", sArgs2);
		return Plugin_Handled;
	}*/

	bool bPrechache = PrecacheSound(sArgs, false);

	if(bPrechache)
		ReplyToCommand(client, "[SM] File \"%s\" successfully precached.", sArgs2);
	else
		ReplyToCommand(client, "[SM] File \"%s\" cannot be precached.", sArgs2);

	return Plugin_Handled;
}

public void ConVarQueryFinished_QueryCVar(QueryCookie hCookie, int client, ConVarQueryResult res, const char[] sCVarName, const char[] sCVarValue, int admin)
{
	switch(res)
	{
		case ConVarQuery_NotFound:
		{
			ReplyToCommand(admin, "[SM] No such cvar.");
			return;
		}
		case ConVarQuery_NotValid:
		{
			ReplyToCommand(admin, "[SM] Commands can not be queried.");
			return;
		}
		case ConVarQuery_Protected:
		{
			ReplyToCommand(admin, "[SM] That cvar is protected and can not be queried.");
			return;
		}
	}

	ReplyToCommand(admin, "[SM] Value for cvar \"%s\" on client \"%N\" is \"%s\".", sCVarName, client, sCVarValue);
}

stock any clamp(any input, any min, any max)
{
	any retval = input < min ? min : input;

	return retval > max ? max : retval;
}

stock int GivePlayerItemFixed(int client, const char[] item)
{
	static bool bEngineVersionIsCSGO;

	// These weapons 'exist' on csgo, but attempting to give them causes a crash.
	if (bEngineVersionIsCSGO || GetEngineVersion() == Engine_CSGO)
	{
		bEngineVersionIsCSGO = true;

		if (StrEqual(item, "weapon_galil", false) ||
			StrEqual(item, "weapon_m3", false) ||
			StrEqual(item, "weapon_mp5navy", false) ||
			StrEqual(item, "weapon_p228", false) ||
			StrEqual(item, "weapon_scout", false) ||
			StrEqual(item, "weapon_sg550", false) ||
			StrEqual(item, "weapon_sg552", false) ||
			StrEqual(item, "weapon_tmp", false) ||
			StrEqual(item, "weapon_usp", false))
		{
			LogError("Prevented giving ent: %s", item);
			return -1;
		}
	}

	return GivePlayerItem(client, item);
}
