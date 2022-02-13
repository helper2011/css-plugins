#include <clientprefs>
#include <sdktools_sound>
#include <sdktools_stringtables>

#pragma newdecls required

Handle Ccookie;

bool Toggle[MAXPLAYERS + 1];
float Volume[MAXPLAYERS + 1];

ArrayList Sounds[5];

public Plugin myinfo = 
{
	name		= "Kill Sounds",
	version		= "2.0",
	description	= "",
	author		= "hEl"
}

public void OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	
	Ccookie = RegClientCookie("KillSoundsSets", "", CookieAccess_Private);
	
	RegConsoleCmd("ks", Command_KillSounds);
	RegConsoleCmd("killsounds", Command_KillSounds);

	LoadSounds();
}

public void OnMapStart()
{
	PrecacheSounds();
}

public Action Command_KillSounds(int iClient, int iArgs)
{
	KillSounds(iClient);
	return Plugin_Handled;
}

void KillSounds(int iClient)
{
	char szBuffer[256];
	Menu hMenu = new Menu(KillSoundsMenu, MenuAction_End | MenuAction_Cancel | MenuAction_Select);
	hMenu.SetTitle("Kill Sounds");
	FormatEx(szBuffer, 256, "Toggle: [%s]", Toggle[iClient] ? "✔":"×");				hMenu.AddItem("", szBuffer);
	FormatEx(szBuffer, 256, "Volume: [%i%%]", RoundToNearest(Volume[iClient] * 100.0));	hMenu.AddItem("", szBuffer);
	hMenu.Display(iClient, 0);
}

public int KillSoundsMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete hMenu;
		}
		case MenuAction_Cancel:
		{
			char szBuffer[64];
			if(!Toggle[iClient] || Volume[iClient] != 1.0)
			{
				FormatEx(szBuffer, 256, "%i;%i", Toggle[iClient] ? 1:0, RoundToNearest(Volume[iClient] * 100.0));
			}
			SetClientCookie(iClient, Ccookie, szBuffer);
		}
		case MenuAction_Select:
		{
			switch(iItem)
			{
				case 0:
				{
					Toggle[iClient] = !Toggle[iClient];
				}
				case 1:
				{
					if((Volume[iClient] += 0.01) > 1.0)
					{
						Volume[iClient] = 0.8;
					}
				}
				
			}
			KillSounds(iClient);
		}
	}

}

public void OnClientCookiesCached(int iClient)
{
	if(IsFakeClient(iClient))
	{
		Toggle[iClient] = false;
		return;
	}
	
	Toggle[iClient] = true;
	Volume[iClient] = 1.0;
	
	char szBuffer[64];
	GetClientCookie(iClient, Ccookie, szBuffer, 64);
	if(szBuffer[0])
	{
		int iSymbol = FindCharInString(szBuffer, ';');
		if(iSymbol != -1)
		{
			Volume[iClient] = float(StringToInt(szBuffer[iSymbol + 1])) / 100.0;
			szBuffer[iSymbol] = 0;
			Toggle[iClient] = !!(StringToInt(szBuffer));
		}
	}
}

public void OnClientPutInServer(int iClient)
{
	if(IsFakeClient(iClient))
	{
		Toggle[iClient] = false;
		return;
	}
	else if(!AreClientCookiesCached(iClient))
	{
		Toggle[iClient] = true;
		Volume[iClient] = 1.0;
	}
}

public void OnRoundStart(Event hEvent, const char[] event, bool bDontBroadcast)
{
	PlaySound(0);
}

public void OnPlayerDeath(Event hEvent, const char[] event, bool bDontBroadcast)
{
	static int iAttacker;
	static int iClient;
	static int iType;
	if(!(0 < (iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"))) <= MaxClients) || IsFakeClient(iAttacker) || GetClientTeam(iAttacker) != 3 || iAttacker == (iClient = GetClientOfUserId(hEvent.GetInt("userid"))) || GetClientTeam(iClient) != 2)
		return;

	iType = !!(hEvent.GetBool("headshot"));
	if(iType == 0 && (iType = GetEventWeapon(hEvent)) == -1)
		iType = 4;
	
	PlaySound(iType, iAttacker);
}

int GetEventWeapon(Event hEvent)
{
	char szBuffer[4];
	hEvent.GetString("weapon", szBuffer, 4);
	if(szBuffer[0] == 'k')								// knife
		return 2;
	else if(szBuffer[0] == 'h') 						// hegrenade
		return 3;
		
	return -1;
}

void LoadSounds()
{
	char szBuffer[256];
	char symbols[5] = "rhkgs";

	KeyValues hKeyValues = new KeyValues("KillSounds");
	BuildPath(Path_SM, szBuffer, 256, "configs/killsounds.cfg");
	if(!hKeyValues.ImportFromFile(szBuffer) || !hKeyValues.GotoFirstSubKey(false))
		SetFailState("[Killsounds] Config \"%s\" does exists...", szBuffer);
		
	for(int i; i < 5; i++)
	{
		delete Sounds[i];
		Sounds[i] = new ArrayList(ByteCountToCells(256));
	}
		
	do
	{
		hKeyValues.GetSectionName(szBuffer, 256);
		for(int i;i < 5; i++)
		{
			if(szBuffer[0] == symbols[i])
			{
				hKeyValues.GetString(NULL_STRING, szBuffer, 256);
				Sounds[i].PushString(szBuffer);
				break;
			}
				
		}
	}
	while(hKeyValues.GotoNextKey(false));
	
	delete hKeyValues;
}

void PrecacheSounds()
{
	int iLength;
	char szBuffer[256];
	for(int i; i < 5; i++)
	{
		iLength = Sounds[i].Length;
		for(int j; j < iLength; j++)
		{
			Sounds[i].GetString(j, szBuffer, 256);
			PrecacheSound(szBuffer, true);
			Format(szBuffer, 256, "sound/%s", szBuffer);
			AddFileToDownloadsTable(szBuffer);
		}
	}
}

void PlaySound(int iType, int iEntity = SOUND_FROM_PLAYER)
{
	static int iLength;
	static char szBuffer[256];
	iLength = Sounds[iType].Length;
	
	if(iLength)
	{
		Sounds[iType].GetString(GetRandomInt(0, iLength - 1), szBuffer, 256);
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && Toggle[i])
			{
				EmitSoundToClient(i, szBuffer, iEntity, _, SNDLEVEL_GUNFIRE, _, Volume[i]);
			}
		}
	}
}