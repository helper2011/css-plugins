/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>
// #include <sendproxy>


#define GAMEDESC "Hide N Seek: Source"
#define SERVERTAG "hnsource"
#define PLUGIN_VERSION "1.0"
#define SEMICLIP_RADIUS 75.0

#define FFADE_IN			0x0001		// Just here so we don't pass 0 into the function
#define FFADE_OUT			0x0002		// Fade out (not in)
#define FFADE_MODULATE		0x0004		// Modulate (don't blend)
#define FFADE_STAYOUT		0x0008		// ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE			0x0010		// Purges all other fades, replacing them with this one

new g_iAdvertCount = 0;
new g_iROUNDSLOST = 0;
new bool:convar_semiclip;
new Handle:countdownTimer = INVALID_HANDLE;
new Handle:gameTimer = INVALID_HANDLE;
new Handle:announceTimer = INVALID_HANDLE;
new bool:roundStarted;
new bool:shouldCollide[MAXPLAYERS] = { true , ... };
new Handle:freezeTimers[MAXPLAYERS];

// offsets
new offs_ammo;

// convars
new Handle:hns_forceswap;
new Handle:hns_t_flashbang;
new Handle:hns_t_hegrenade;
new Handle:hns_t_smokegrenade;
new Handle:hns_countdown_length;
new Handle:hns_spawn_invulnerable;
new Handle:hns_realflashnumber;
new Handle:hns_blockslash;
new Handle:hns_freeze_radius;
new Handle:hns_freeze_invulnerable;
new Handle:hns_freeze_turning;
new Handle:hns_freeze_enable;
new Handle:hns_freeze_duration;
new Handle:hns_freeze_slowdown;
new Handle:hns_t_noflash;
new Handle:mp_roundtime;

public Plugin:myinfo = 
{
	name = "HnSource",
	author = "Absolute",
	description = "Hide and Seek Source",
	version = PLUGIN_VERSION,
	url = "<- URL ->"
}

public OnPluginStart()
{
	CreateConVar("hns_version", PLUGIN_VERSION, "Version of the Plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("round_start", Event_RoundStart);
	// HookEvent("round_freeze_end", Event_RoundStartFreeze);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_spawn", Event_PlayerSpawn);
	// HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("player_blind", Event_PlayerBlind);
	AutoExecConfig();
	// HookConVarChange(CreateConVar("hns_semiclip", "0", "Disable blocking of teammates"), Convar_SemiClipChanged);
	hns_blockslash = CreateConVar("hns_blockslash", "0", "If enabled this blocks the left mouse button of cts");
	hns_t_flashbang = CreateConVar("hns_t_flashbang", "2", "How many flashbangs Terrorists get at spawn");
	hns_t_hegrenade = CreateConVar("hns_t_hegrenade", "1", "How many grenades Terrorists get at spawn");
	hns_t_smokegrenade = CreateConVar("hns_t_smokegrenade", "1", "How many grenades Terrorists get at spawn");
	hns_t_noflash = CreateConVar("hns_t_noflash", "1", "If Terrorists shouldnt get flashed");
	hns_freeze_enable = CreateConVar("hns_freeze_enable", "1", "Enables freeze grenade for Terrorists");
	hns_freeze_radius = CreateConVar("hns_freeze_radius", "1000", "The radius of a freezegrenade");
	hns_freeze_invulnerable = CreateConVar("hns_freeze_invulnerable", "1", "Makes frozen CTs invulnerable");
	hns_freeze_duration = CreateConVar("hns_freeze_duration", "5", "Duration of the freeze");
	hns_freeze_slowdown = CreateConVar("hns_freeze_slowdown", "2", "Time the player is slowed down after being frozen");
	hns_freeze_turning = CreateConVar("hns_freeze_turning", "0", "Allow players to move the camera when frozen");
	hns_forceswap = CreateConVar("hns_forceswap", "5", "After how many rounds without teamswaps teams should be swapped");
	hns_spawn_invulnerable = CreateConVar("hns_spawn_invulnerable", "1", "If enabled CTs will get invulnerability while they are at spawn");
	hns_countdown_length = CreateConVar("hns_countdown_length", "10", "How long the CTs will be frozen at spawn (== mp_freezetime)");
	// hns_realflashnumber = CreateConVar("hns_realflashnumber", "1", "If enabled, Terrorists will drop all grenades they carry");
	SetConVarInt(FindConVar("mp_freezetime"), 0);
	mp_roundtime = FindConVar("mp_roundtime");
	offs_ammo = FindSendPropInfo("CCSPlayer", "m_iAmmo");

}


// public OnGameFrame()
// {
	// if (!convar_semiclip)
		// return;
	// decl client, otherclient;
	// decl clientteam;
	// decl Float:clientorigin[3], Float:otherclientorigin[3];
	// new bool:checkstatus[MaxClients+1];
	// for (client=1;client <= MaxClients; client++)
	// {
		// if(isValidClient(client) && IsPlayerAlive(client))
		// {
			// checkstatus[client] = true;
		// }
	// }
	// for (client=1;client <= MaxClients; client++)
	// {
		// if(!checkstatus[client]) continue;
		// GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientorigin);
		// clientteam = GetClientTeam(client);
		// for (otherclient=1;otherclient <= MaxClients; otherclient++)
		// {
			// if((client == otherclient) || !checkstatus[otherclient]) continue;
			
			// GetEntPropVector(otherclient, Prop_Send, "m_vecOrigin", otherclientorigin);
			
			// if(GetVectorDistance(otherclientorigin, clientorigin) <= SEMICLIP_RADIUS)
			// {
				// if (clientteam == GetClientTeam(otherclient))
				// {
					// shouldCollide[client] = false;
					// break;
				// }
				// else
				// {
					// shouldCollide[client] = true;
					// break;
				// }
			// }
			
		// }
	// }
// }
public OnMapStart()
{
	roundStarted = false;
	decl String:downloadLink[64];
	AddFileToDownloadsTable("sound/frostnade/impalehit.wav");
	AddFileToDownloadsTable("sound/frostnade/impalelaunch1.wav");
	AddFileToDownloadsTable("materials/overlays/hns/icetexture.vmt");
	AddFileToDownloadsTable("materials/overlays/hns/icetexture.vtf");
	PrecacheSound("sound/frostnade/impalehit.wav");
	PrecacheSound("sound/frostnade/impalelaunch1.wav");

	
	for (new x=1;x <= 10; x++)
	{
		Format(downloadLink, sizeof(downloadLink), "sound/hns_timer/%isec.mp3", x);
		AddFileToDownloadsTable(downloadLink);
		Format(downloadLink, sizeof(downloadLink), "hns_timer/%isec.mp3", x);
		PrecacheSound(downloadLink);
	}
	
	decl String:szClass[65];
	for (new i = MaxClients; i <= GetMaxEntities(); i++)
	{
	  if(IsValidEdict(i) && IsValidEntity(i))
	  {
		GetEdictClassname(i, szClass, sizeof(szClass));
		if(StrEqual("func_buyzone", szClass) || 
		StrEqual("func_bomb_target", szClass))
		{
			RemoveEdict(i);
		}
	  }
	}

}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponCanUse, canUse);
	SDKHook(client, SDKHook_WeaponSwitchPost, weaponSwitch);
	// SDKHook(client, SDKHook_ShouldCollide, ShouldCollide);
	// if (GetExtensionFileStatus("sendproxy.ext") == 1)
	// {
		// SendProxy_Hook(client, "m_CollisionGroup", Prop_Int, ProxyCallback);
	// }
}

// public Action:ProxyCallback(entity, const String:propname[], &iValue, element)
// {
	
    // Set iValue to whatever you want to send to clients
	// if (convar_semiclip && !shouldCollide[entity])
	// {
		// iValue = 2;
		// return Plugin_Changed;
	// }
	// return Plugin_Continue;
// }  




// public Convar_SemiClipChanged(Handle:convar, String:oldval[], String:newval[])
// {
	// new bool:newvalue = bool:StringToInt(newval);
	// if (GetExtensionFileStatus("sendproxy.ext") != 1 && newvalue == true)
	// {
		// SetConVarBool(convar, false);
	// }
	
	// convar_semiclip = newvalue;
// }

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// CreateTimer(0.05, delayFreezetime);
	decl Float:roundtime;
	roundtime = GetConVarFloat(mp_roundtime) * 60;
	decl String:formattime[6];
	FormatTime(formattime,sizeof(formattime),"%M:%S", RoundToFloor(roundtime))
	roundStarted = false;
	
	new ent = CreateEntityByName("game_player_equip");
	DispatchKeyValue(ent, "weapon_knife", "1");
	DispatchSpawn(ent);	

	for (new client=1; client<=MaxClients;client++)
	{
		if (!isValidClient(client)) continue;
		switch (GetClientTeam(client)) {
		case CS_TEAM_T:
			printPrefix(client, "You are now a \x01Hider\x04, stay alive for %s min!!!", formattime);
		
		case CS_TEAM_CT:
			printPrefix(client, "You are now a \x01Seeker\x04, you have %s min to kill all Hiders!!!", formattime);
				
		}

	}
	decl String:szClass[65];
	for (new i = MaxClients; i <= GetMaxEntities(); i++)
	{
	  if(IsValidEdict(i) && IsValidEntity(i))
	  {
		GetEdictClassname(i, szClass, sizeof(szClass));
		if(StrEqual("func_buyzone", szClass) || 
		StrEqual("hostage_entity", szClass) || 
		StrEqual("func_bomb_target", szClass) ||
		StrEqual("weapon_c4", szClass) ||
		StrEqual("weapon_usp", szClass)
		)
		{
			RemoveEdict(i);
		}
	  }
	}

	g_iAdvertCount++;
	switch (g_iAdvertCount)
	{
		case 4:
			printPrefixAll("Join the Group \x01HnSource \x04if you like HnS.");
		case 8:
		{
			printPrefixAll("Script written by \x01Absolute\x04.");
			g_iAdvertCount = 0;
		}
	}

	if (countdownTimer != INVALID_HANDLE) KillTimer(countdownTimer);
	CountdownTimer(INVALID_HANDLE, GetConVarInt(hns_countdown_length));


	if (gameTimer != INVALID_HANDLE)
		KillTimer(gameTimer);
	gameTimer = CreateTimer(roundtime, endRound);
	if (announceTimer != INVALID_HANDLE)
		KillTimer(announceTimer);
	announceTimer = CreateTimer(roundtime-10, announceEnd);
}

public Action:Event_RoundStartFreeze(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundStarted = true;
	new bool:invuln = GetConVarBool(hns_spawn_invulnerable);
	for (new client=1; client<=MaxClients;client++)
	{
		if (!isValidClient(client)) continue;

		PrintHintText(client, " ");
		if (GetClientTeam(client) == CS_TEAM_CT) 
		{
			printPrefix(client, "GoGoGo!!!");
			Client_ScreenFade(client, 3000, FFADE_IN + FFADE_PURGE, 0);
			SetEntityFlags(client, FL_ONGROUND);
			if (invuln)
				makeInvulnerable(client, false);
			// SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
		}
		else
		{
			printPrefix(client, "Seeking started!!!");
		}
		
	}

	
}
public Action:announceEnd(Handle:Timer)
{
	printPrefixAll("\x01Seekers\x04 have 10 seconds left!");
	announceTimer = INVALID_HANDLE;
}


public Action:endRound(Handle:Timer)
{
	gameTimer = INVALID_HANDLE;
	for (new client=1; client<=MaxClients;client++)
	{
		if (!isValidClient(client)) continue;
		if (IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT)
		{
			ForcePlayerSuicide(client);
		}
	}
}

public Action:delayFreezetime(Handle:Timer, any:number)
{
	GameRules_SetProp("m_bFreezePeriod", 0,1); // disable freezing
}
public Action:CountdownTimer(Handle:Timer, any:number)
{
	countdownTimer = INVALID_HANDLE;
	if (number == 0)
	{
		Event_RoundStartFreeze(INVALID_HANDLE, "", false);
		// GameRules_SetProp("m_bFreezePeriod", 1,1);
		roundStarted = true;
	}
	else if (number > 0)
	{
		PrintHintTextToAll("Start in %i seconds.", number);
		if (number <= 10)
		{
			decl String:soundString[32];
			Format(soundString, sizeof(soundString), "hns_timer/%isec.mp3", number);
			EmitSoundToAll(soundString);
		}
		countdownTimer = CreateTimer(1.0, CountdownTimer, number-1);
		
	}

}


public Action:Event_PlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetConVarBool(hns_t_noflash))
	{
		if (GetClientTeam(client) == CS_TEAM_T)
		{
			SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.0);
		}
	}
}


public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsPlayerAlive(client)) return;
	new team = GetClientTeam(client);
	StripPlayer(client);
	if (team == CS_TEAM_T)
	{
		GivePlayerItem(client, "weapon_knife");
		decl amount;
		amount = GetConVarInt(hns_t_flashbang);
		if (amount > 0)
		{
			GivePlayerItem(client, "weapon_flashbang");
			SetEntData(client, offs_ammo+48, amount);
			// SetEntProp(client, Prop_Send, "m_iAmmo.012", amount);
		}
		amount = GetConVarInt(hns_t_hegrenade);
		if (amount > 0)
		{
			GivePlayerItem(client, "weapon_hegrenade");
			SetEntData(client, offs_ammo+44, amount);

			// SetEntProp(client, Prop_Send, "m_iAmmo.011", amount);
		}
		amount = GetConVarInt(hns_t_smokegrenade);
		if (amount > 0)
		{
			GivePlayerItem(client, "weapon_smokegrenade");
			SetEntData(client, offs_ammo+52, amount);

			// SetEntProp(client, Prop_Send, "m_iAmmo.013", amount);
		}
		
		
	}
	else if (team == CS_TEAM_CT)
	{
		GivePlayerItem(client, "weapon_knife");
		if (!roundStarted ) 
		{	
			// if they spawn late
			Client_ScreenFade(client, 0, FFADE_STAYOUT, 10);
			SetEntityFlags(client, FL_FROZEN);
			if (GetConVarBool(hns_spawn_invulnerable))
				makeInvulnerable(client, true);
			// SetEntityMoveType(client, MOVETYPE_NONE);
		}
	}
	
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(hns_realflashnumber))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		// PrintToChatAll("flashamount %i", GetEntData(client, offs_ammo+48));
	}
}

public weaponSwitch(client,weapon)
{
	if (!isValidClient(client)) return;
	decl String:classname[32];
	GetEntityClassname(weapon, classname, sizeof(classname));
	if (StrEqual(classname, "weapon_knife", false))
	{
		if (GetClientTeam(client) == CS_TEAM_CT)
		{
			if(GetConVarBool(hns_blockslash))
				SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 99999999999.9);
		}
		else
		{
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 99999999999.9);
			SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", 99999999999.9);
		}
		
	}
}

public bool:ShouldCollide(entity, collisiongroup, contentsmask, bool:originalResult)
{
	if (convar_semiclip && (entity <= MaxClients))
	{
		if (contentsmask == 33636363)
		{
			originalResult = shouldCollide[entity];
			return shouldCollide[entity];
		}
		
	}
	return true;
}


public Action:canUse(client,weapon)
{
	if (GetClientTeam(client) == CS_TEAM_CT)
	{
		decl String:classname[32];
		GetEntityClassname(weapon, classname, sizeof(classname));
		if (StrEqual(classname, "weapon_usp", false))
			RemoveEdict(weapon);
		if (!StrEqual(classname, "weapon_knife", false))
			return Plugin_Handled;
	}
	return Plugin_Continue;
	//PrintToChatAll("client canuse, %i,%i", client,weapon);
}


public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundStarted = false;
	new winner = GetEventInt(event, "winner");
	new forceswap = GetConVarInt(hns_forceswap);
	if (winner == CS_TEAM_T)
	{
		g_iROUNDSLOST += 1;
		if (forceswap != 0 && g_iROUNDSLOST == forceswap)
		{
			printPrefixAll("Teams have been swapped because Hiders won \x01%i \x04rounds in a row.", forceswap);
			swapTeams();
			g_iROUNDSLOST = 0;
		}
	}
	else if (winner == CS_TEAM_CT)
	{
		swapTeams();
		g_iROUNDSLOST = 0;
	}
}


public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(hns_freeze_enable)) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damage = GetEventInt(event, "dmg_health");
	decl String:classname[32];
	GetEventString(event, "weapon", classname, sizeof(classname));
	if (StrEqual(classname, "hegrenade"))
	{
		SetEntProp(client, Prop_Data, "m_iHealth", GetEntProp(client, Prop_Data, "m_iHealth") + damage);
		if (GetClientTeam(client) != GetClientTeam(attacker))
		{
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 0.0);
			SetEntityRenderColor(client, 0, 150, 255);
			ClientCommand(client, "r_screenoverlay  \"overlays/hns/icetexture\"");
			if (GetConVarBool(hns_freeze_invulnerable))
				makeInvulnerable(client, true);
				
			if (!GetConVarBool(hns_freeze_turning))
				SetEntityFlags(client, FL_FROZEN);
				
			if (freezeTimers[client] != INVALID_HANDLE)
			{
				KillTimer(freezeTimers[client]);
			}
			decl Float:origin[3];
			GetClientAbsOrigin(client, origin);
			EmitAmbientSound("frostnade/impalehit.wav", origin);
		
			freezeTimers[client] = CreateTimer(GetConVarFloat(hns_freeze_duration), unFreeze, client);
		}
	}
}
public Action:unFreeze(Handle:Timer, any:client)
{
	if (!isValidClient(client))
	{
		freezeTimers[client] = INVALID_HANDLE;
		return;
	}
	if (GetConVarBool(hns_freeze_invulnerable))
		makeInvulnerable(client, false);
			
	if (!GetConVarBool(hns_freeze_turning))
		SetEntityFlags(client, FL_ONGROUND);
		
	ClientCommand(client, "r_screenoverlay  0");
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 0.6);
	decl Float:origin[3];
	GetClientAbsOrigin(client, origin);
	EmitAmbientSound("frostnade/impalelaunch1.wav", origin);
	freezeTimers[client] = CreateTimer(GetConVarFloat(hns_freeze_slowdown), removeSlow, client);
}

public Action:removeSlow(Handle:Timer, any:client)
{
	freezeTimers[client] = INVALID_HANDLE;
	if (!isValidClient(client))
	{
		return;
	}
	SetEntityRenderColor(client, 255,255,255,255);
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
	

}


/*public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "hegrenade_projectile"))
	{
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
	}
}*/

public OnEntitySpawned(entity, const String:classname[])
{
	
	if (StrEqual(classname, "hegrenade_projectile"))
	{
		if (GetConVarBool(hns_freeze_enable))
		{
			// PrintToChatAll("ent spawned");
			SetEntPropFloat(entity, Prop_Send, "m_flDamage", 2.0);
			SetEntPropFloat(entity, Prop_Send, "m_DmgRadius", GetConVarFloat(hns_freeze_radius));
		}
	}
}

public Action:OnGetGameDescription(String:gameDesc[64])
{
	strcopy(gameDesc, sizeof(gameDesc), GAMEDESC);
	return Plugin_Changed;

}

public swapTeams()
{
	decl team;
	for (new client=1; client<=MaxClients;client++)
	{
		if (!isValidClient(client)) continue;
		team = GetClientTeam(client);
		if (team == CS_TEAM_SPECTATOR) continue;
		CS_SwitchTeam(client, 5-team);
	}
}

public StripPlayer(client)
{
	new ent = CreateEntityByName("player_weaponstrip");
	DispatchSpawn(ent);
	AcceptEntityInput(ent, "Strip", client, client);
	RemoveEdict(ent);
}

public bool:isValidClient(client)
{
	return (IsClientInGame(client) && IsClientConnected(client));
}

public printPrefix(client, String:text[], any:...)
{
	decl String:formatted[255];
	VFormat(formatted, sizeof(formatted), text, 3);
	
	PrintToChat(client, "\x03[HnSource] \x04%s", formatted);
}

public printPrefixAll(String:text[], any:...)
{
	decl String:formatted[255];
	VFormat(formatted, sizeof(formatted), text, 2);
	
	for (new client=1; client<=MaxClients;client++)
	{
		if (!isValidClient(client)) continue;

		printPrefix(client, formatted);
	}
}
public makeInvulnerable(client, bool:status)
{
	if (status)
		SetEntProp(client, Prop_Send, "m_lifeState", 0);
	else
		SetEntProp(client, Prop_Send, "m_lifeState", 512);
}

stock bool:Client_ScreenFade(client, duration, mode, holdtime=-1, r=0, g=0, b=0, a=255, bool:reliable=true)
{
	new Handle:userMessage = StartMessageOne("Fade", client, (reliable?USERMSG_RELIABLE:0));

	if (userMessage == INVALID_HANDLE) {
		return false;
	}

	BfWriteShort(userMessage,	duration);	// Fade duration
	BfWriteShort(userMessage,	holdtime);	// Fade hold time
	BfWriteShort(userMessage,	mode);		// What to do
	BfWriteByte(userMessage,	r);			// Color R
	BfWriteByte(userMessage,	g);			// Color G
	BfWriteByte(userMessage,	b);			// Color B
	BfWriteByte(userMessage,	a);			// Color Alpha
	EndMessage();

	return true;
}
