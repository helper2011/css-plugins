#pragma semicolon 1
#include <cstrike>
#include <sdktools>
#include <sourcemod>

public Plugin:myinfo = {
	name = "Reloaded_Sound",
	author = "Divix & SenatoR",
	description = "",
	version = "1.2",
	url = ""
};


new String:ReloadSound[] = "reloaded/reloaded3.wav";
new String:ReloadSound1[] = "reloaded/reloaded2.wav";
new String:ReloadSound2[] = "reloaded/reloaded1.wav";
new String:ReloadSound3[] = "reloaded/reloaded.wav";

public OnMapStart()
{
decl String:soundName[512];
Format(soundName,sizeof(soundName), "sound/%s", ReloadSound);
AddFileToDownloadsTable(soundName);
Format(soundName,sizeof(soundName), "sound/%s", ReloadSound1);
AddFileToDownloadsTable(soundName);
Format(soundName,sizeof(soundName), "sound/%s", ReloadSound2);
AddFileToDownloadsTable(soundName);
Format(soundName,sizeof(soundName), "sound/%s", ReloadSound3);
AddFileToDownloadsTable(soundName);

PrecacheSound(ReloadSound, true);
PrecacheSound(ReloadSound1, true);
PrecacheSound(ReloadSound2, true);
PrecacheSound(ReloadSound3, true);
}


new bool:restrict[MAXPLAYERS+1] = {false, ...};

public OnPluginStart()
{
HookEvent("weapon_reload", Event_reloaded, EventHookMode_Pre);
}

public Action:Event_reloaded(Handle:event, const String:name[], bool:dontBroadcast)
{
new client = GetClientOfUserId(GetEventInt(event, "userid"));
if(!restrict[client])
{
decl String:name1[MAX_NAME_LENGTH];
GetClientName(client, name1, sizeof(name1));
new random = GetRandomInt(0, 3);
if(random == 0)
EmitSoundToAll(ReloadSound, client);
else if(random == 1)
EmitSoundToAll(ReloadSound1, client);
else if(random == 2)
EmitSoundToAll(ReloadSound2, client);
else if(random == 3)
EmitSoundToAll(ReloadSound3, client);
restrict[client] = true;
CreateTimer(5.0, Timer_Reset, client);
}
}

public Action:Timer_Reset(Handle:timer,any:client)
{
restrict[client] = false;
}






