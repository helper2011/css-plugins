//  SteamWorks Game Description Override (C) 2014-2016 Sarabveer Singh <me@sarabveer.me>
//  
//  SteamWorks Game Description Override is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, per version 3 of the License.
//  
//  SteamWorks Game Description Override is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  
//  You should have received a copy of the GNU General Public License
//  along with SteamWorks Game Description Override. If not, see <http://www.gnu.org/licenses/>.
//
//  This file is based off work(s) covered by the following copyright(s):   
//
//   SteamTools Game Description Override
//   Copyright (C) 2011-2012 Dr. McKay
//   Licensed under GNU GPL version 3
//   Page: <https://forums.alliedmods.net/showthread.php?p=1583349>
//

#pragma semicolon 1

#include <sourcemod>
#include <SteamWorks>
#define PLUGIN_VERSION "1.1"

new Handle:descriptionCvar = INVALID_HANDLE;

public Plugin:myinfo = {
	name        = "SteamWorks Game Description Override",
	author      = "Dr. McKay, Sarabveer(VEER�)",
	description = "Overrides the default game description (i.e. \"Team Fortress\") in the server browser using SteamWorks",
	version     = PLUGIN_VERSION,
	url         = "http://www.doctormckay.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) { 
	MarkNativeAsOptional("Updater_AddPlugin"); 
	return APLRes_Success;
} 

public OnPluginStart() {
	descriptionCvar = CreateConVar("sw_gamedesc_override", "", "What to override your game description to");
	decl String:description[128];
	GetConVarString(descriptionCvar, description, sizeof(description));
	HookConVarChange(descriptionCvar, CvarChanged);
	SteamWorks_SetGameDescription(description);
}

public CvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	decl String:description[128];
	GetConVarString(descriptionCvar, description, sizeof(description));
	SteamWorks_SetGameDescription(description);
}
