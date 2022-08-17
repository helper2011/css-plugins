#include <sourcemod>
#include <clientprefs>
#include <sdktools_functions>
#include <sdktools_stringtables>

#pragma newdecls required

enum struct SkinData
{
	char Name[256];
	char Model[256];
	int Team;
	bool IsPrecached;
	bool SmartDownload;
}

Handle
	g_hCookie;
int
	SkinsCount,
	SkinID[MAXPLAYERS + 1][2],
	Flags[MAXPLAYERS + 1] = {-1, ...};

char
	SteamID[MAXPLAYERS + 1][32], 
	DefaultModel[MAXPLAYERS + 1][2][256];

StringMap
	Skins,
	Players;
StringMapSnapshot
	SkinsSnapshot;

ArrayList GroupList;

/*
	4.1	-	Fix players authorization
	4.2	-	Fix group error
	4.3 -	Fix root flags mistake
*/

public Plugin myinfo = 
{
    name = "Personal Skins",
    version = "4.3",
    author = "hEl"
};

	
public void OnPluginStart()
{
	Skins = new StringMap();
	Players = new StringMap();
	GroupList = new ArrayList(ByteCountToCells(1));
	LoadConfig();
	RegConsoleCmd("sm_skins", Skins_Menu);
	g_hCookie = RegClientCookie("PSkin", "", CookieAccess_Private);

	HookEvent("player_team", OnPlayerTeam);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_disconnect", OnPlayerDisconnect);
	
	CreateTimer(0.1, Timer_OnPluginStart);
}

public void OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientDisconnect(i);
		}
	}
}

public void OnMapStart()
{
	char szBuffer[256];
	int iLength;
	SkinData Skin;
	for(int i; i < SkinsCount; i++)
	{
		SkinsSnapshot.GetKey(i, szBuffer, 256);
		if(!Skins.GetArray(szBuffer, Skin, sizeof(Skin)))
		{
			continue;
		}
		Skin.IsPrecached = (IsModelPrecached(Skin.Model) || !Skin.SmartDownload);
		//PrintToConsoleRootAdmins("%s (%s) %b", Skin.Name, Skin.Model, Skin.IsPrecached);
		Skins.SetArray(szBuffer, Skin, sizeof(Skin));
	}
	int iCount;
	int[] iSkins = new int[SkinsCount];
	iLength = GroupList.Length;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(SteamID[i][0] && Players.GetArray(SteamID[i], iSkins, SkinsCount))
		{
			for(int j; j < SkinsCount; j++)
			{
				if(iSkins[j] == -1)
					break;
					
				SkinsSnapshot.GetKey(iSkins[j], szBuffer, 256);
				if(Skins.GetArray(szBuffer, Skin, sizeof(Skin)))
				{
					iCount++;
					Skin.IsPrecached = true;
					Skins.SetArray(szBuffer, Skin, sizeof(Skin));
					//PrintToConsoleRootAdmins("Skin \"%s\" is%sprecached", Skin.Name, Skin.IsPrecached ? " ":" not ");
				}
			}
		}
		if(Flags[i] > 0)
		{
			for(int j; j < iLength; j += 2)
			{
				if(Group_CheckClientFlags(i, j) == 1)
				{
					GroupList.GetArray(j + 1, iSkins, SkinsCount);
					//PrintSkinsArray(iSkins, "OnMapStart");
					for(int k; k < SkinsCount; k++)
					{
	
						if(iSkins[k] == -1)
							break;
							
						SkinsSnapshot.GetKey(iSkins[k], szBuffer, 256);
						if(Skins.GetArray(szBuffer, Skin, sizeof(Skin)) && !Skin.IsPrecached)
						{
							iCount++;
							Skin.IsPrecached = true;
							Skins.SetArray(szBuffer, Skin, sizeof(Skin));
							//PrintToConsoleRootAdmins("Skin \"%s\" is%sprecached", Skin.Name, Skin.IsPrecached ? " ":" not ");
						}
					}
				}
			}
		}

		
	}
	BuildPath(Path_SM, szBuffer, 256, "configs/personal_skins_downloads.cfg");
	File hFile = OpenFile(szBuffer, "r");
	if(hFile)
	{
		int iSkin = -1;
		while (!hFile.EndOfFile())
		{
			if (!hFile.ReadLine(szBuffer, 256))
				continue;
			
			TrimString(szBuffer);
			//PrintToConsoleRootAdmins("%s %i", szBuffer, iSkin);
			if(iSkin == -1)
			{
				//PrintToConsoleRootAdmins("%s %i %b %b", szBuffer, GetSkinID(szBuffer), Skins.GetArray(szBuffer, Skin, sizeof(Skin)), Skin.IsPrecached);
				if((iSkin = GetSkinID(szBuffer)) == -1 || !Skins.GetArray(szBuffer, Skin, sizeof(Skin)) || !Skin.IsPrecached)
				{
					iSkin = -2;
				}
			}
			else if(szBuffer[0] == '.')
			{
				iSkin = -1;
			}
			else if(iSkin != -2)
			{
				if ((iLength = TrimString(szBuffer)) && szBuffer[0] != '/')
				{
					ReplaceString(szBuffer, 256, "\\", "/", true);
					if (DirExists(szBuffer))
					{
						if (szBuffer[iLength - 1] == '/') 
						{ 
							szBuffer[iLength - 1] = 0; 
						}
						LoadFromDir(szBuffer);
					}
					else if (ExtAllowed(szBuffer, iLength)) 
					{
						AddFileToDownloadsTable(szBuffer);
						//PrintToConsoleRootAdmins(szBuffer);
					}
				}
				
			}
		}
	}
	else
		SetFailState("[Personal Skins] Download file \"%s\" doesnt exists...", szBuffer);
		
	delete hFile;
	
	for(int i; i < SkinsCount; i++)
	{
		SkinsSnapshot.GetKey(i, szBuffer, 256);
		if(!Skins.GetArray(szBuffer, Skin, sizeof(Skin)))
		{
			continue;
		}
		if(Skin.IsPrecached)
		{
			PrecacheModel(Skin.Model, true);
		}
		Skins.SetArray(szBuffer, Skin, sizeof(Skin), true)
	}
}

public Action Timer_OnPluginStart(Handle hTimer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
			
			if(AreClientCookiesCached(i))
			{
				OnClientCookiesCached(i);
			}
			OnClientPostAdminCheck(i);
		}
	}
}

public void OnPlayerTeam(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(Flags[iClient] > 0 || SteamID[iClient][0])
	{
		RequestFrame(SetClientSkinNextTick, iClient);
	}
}

public void OnPlayerSpawn(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	ResetClientDefaultModel(iClient);
	if(Flags[iClient] > 0 || SteamID[iClient][0])
	{
		RequestFrame(SetClientSkinNextTick, iClient);
	}
}

public void OnPlayerDeath(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!IsPlayerAlive(iClient))
	{
		ResetClientDefaultModel(iClient);
	}
}

void SetClientSkinNextTick(int iClient)
{
	if(IsClientInGame(iClient))
	{
		SetClientSkin(iClient, true);
	}
}

public void OnPlayerDisconnect(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	Flags[iClient] = -1;
	SteamID[iClient][0] = 0;
}

void LoadConfig()
{
	char szBuffer[256];
	KeyValues hKeyValues = new KeyValues("Skins");
	BuildPath(Path_SM, szBuffer, 256, "configs/personal_skins.cfg");
	if(!hKeyValues.ImportFromFile(szBuffer) || !CheckKeyValues(hKeyValues, "Models"))
	{
		SetFailState("[Personal Skins] Config file \"%s\" doesnt exists...", szBuffer);
	}
	SkinData Skin;
	do
	{
		hKeyValues.GetSectionName(szBuffer, 32);
		hKeyValues.GetString("name", Skin.Name, 256);
		hKeyValues.GetString("model", Skin.Model, 256);
		Skin.Team = hKeyValues.GetNum("team", 3) - 2;
		Skin.SmartDownload = !!(hKeyValues.GetNum("smart_download", 1));
		Skins.SetArray(szBuffer, Skin, sizeof(Skin), true);
	}
	while(hKeyValues.GotoNextKey());
	
	if(!Skins.Size)
	{
		SetFailState("No skins or clients");
		return;
	}
	SkinsSnapshot = Skins.Snapshot();
	SkinsCount = SkinsSnapshot.Length;
	int iCount;
	int[] iArray = new int[SkinsCount];
	if(CheckKeyValues(hKeyValues, "Players"))
	{
		do
		{
			if(!hKeyValues.GotoFirstSubKey(false))
				continue;
			
	
			do
			{
				hKeyValues.GetString(NULL_STRING, szBuffer, 32);
				iArray[iCount++] = GetSkinID(szBuffer);
			}
			while(hKeyValues.GotoNextKey(false));
			for(int i = iCount; i < SkinsCount; i++)
			{
				iArray[i] = -1;
			}
			iCount = 0;
			hKeyValues.GoBack();
			hKeyValues.GetSectionName(szBuffer, 256);
			Players.SetArray(szBuffer, iArray, SkinsCount, true);
		}
		while(hKeyValues.GotoNextKey());
	}
	
	if(CheckKeyValues(hKeyValues, "Groups"))
	{
		int iFlags;
		do
		{
			if(!hKeyValues.GotoFirstSubKey(false))
				continue;
		
			do
			{
				hKeyValues.GetSectionName(szBuffer, 256);
				if(strcmp(szBuffer, "flags", false))
				{
					hKeyValues.GetString(NULL_STRING, szBuffer, 32);
					iArray[iCount++] = GetSkinID(szBuffer);
				}

			}
			while(hKeyValues.GotoNextKey(false));
			hKeyValues.GoBack();
			hKeyValues.GetString("flags", szBuffer, 256);
			iFlags = ReadFlagString(szBuffer);
				
			if(iFlags)
			{
				for(int i = iCount; i < SkinsCount; i++)
				{
					iArray[i] = -1;
				}
				//PrintSkinsArray(iArray, "Load array for Group");
				GroupList.Push(iFlags);
				GroupList.PushArray(iArray, SkinsCount);
			}

			iCount = 0;
		}
		while(hKeyValues.GotoNextKey());
	}
	
	delete hKeyValues;
}

public Action Skins_Menu(int iClient, int iArgs)
{
	if(iClient && !IsFakeClient(iClient))
	{
		SkinsMenu(iClient);
	}
	
	return Plugin_Handled;
	
}


void SkinsMenu(int iClient, int iItem = 0)
{
	Menu hMenu = new Menu(SkinsMenuH);
	hMenu.SetTitle("Personal Skins");
	int iCount, iCount2;
	int[] iSkins = new int[SkinsCount];
	int[] iMenuSkins = new int[SkinsCount];
	SkinData Skin;
	char szBuffer[256], szBuffer2[32];
	if(SteamID[iClient][0] && Players.GetArray(SteamID[iClient], iSkins, SkinsCount))
	{
		for(int i; i < SkinsCount; i++)
		{
			if(iSkins[i] == -1)
				break;
			
			SkinsSnapshot.GetKey(iSkins[i], szBuffer, 256);
			if(!Skins.GetArray(szBuffer, Skin, sizeof(Skin)))
			{
				continue;
			}
			IntToString(iSkins[i], szBuffer2, 32);
			FormatEx(szBuffer, 256, "%s (%s)", Skin.Name, !Skin.Team ? "T":"CT");
			if(SkinID[iClient][Skin.Team] == iSkins[i])
			{
				Format(szBuffer, 256, "%s [✔]", szBuffer);
				
			}
			if(!Skin.IsPrecached)
			{
				Format(szBuffer, 256, "%s (На след. карте)", szBuffer);
			}
			hMenu.AddItem(szBuffer2, szBuffer);
			iMenuSkins[iCount++] = iSkins[i];
		}
	}
	if(Flags[iClient] > 0)
	{
		int iLength = GroupList.Length;
		for(int i; i < iLength; i += 2)
		{
			if(Group_CheckClientFlags(iClient, i))
			{
				GroupList.GetArray(i + 1, iSkins, SkinsCount);
				for(int j; j < SkinsCount; j++)
				{
					if(iSkins[j] == -1)
						break;
					if(Array_FindValue(iMenuSkins, iCount, iSkins[j]) != -1)
						continue;
						
					SkinsSnapshot.GetKey(iSkins[j], szBuffer, 256);
					if(!Skins.GetArray(szBuffer, Skin, sizeof(Skin)))
					{
						continue;
					}
					IntToString(iSkins[j], szBuffer2, 32);
					FormatEx(szBuffer, 256, "%s (%s)", Skin.Name, !Skin.Team ? "T":"CT");
					if(SkinID[iClient][Skin.Team] == iSkins[j])
					{
						Format(szBuffer, 256, "%s [✔]", szBuffer);
						
					}
					if(!Skin.IsPrecached)
					{
						Format(szBuffer, 256, "%s (На след. карте)", szBuffer);
					}
					hMenu.AddItem(szBuffer2, szBuffer);
					iCount2++;
				}
			}
		}
	}
	if(!iCount && !iCount2)
	{
		hMenu.AddItem("", "Нет доступных скинов", ITEMDRAW_DISABLED);
	}
	hMenu.DisplayAt(iClient, iItem, 0);
}

public int SkinsMenuH(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete hMenu;
		}
		case MenuAction_Select:
		{
			char szBuffer[32];
			hMenu.GetItem(iItem, szBuffer, 32);
			SetClientSkinID(iClient, StringToInt(szBuffer));
			SetClientSkin(iClient, false);
			SkinsMenu(iClient, hMenu.Selection);
			SaveClientSettings(iClient);
		}
	}
}

bool CheckKeyValues(KeyValues hKeyValues, const char[] key)
{
	hKeyValues.Rewind();
	return (hKeyValues.JumpToKey(key) && hKeyValues.GotoFirstSubKey());
}

public void OnClientCookiesCached(int iClient)
{
	if(IsFakeClient(iClient))
	{
		return;
	}
	
	char szBuffer[128];
	GetClientCookie(iClient, g_hCookie, szBuffer, 128);
	if(szBuffer[0])
	{
		int iSymbol = FindCharInString(szBuffer, ';');
		if(szBuffer[iSymbol + 1])
		{
			SkinID[iClient][1] = GetSkinID(szBuffer[iSymbol + 1]);
		}
		szBuffer[iSymbol] = 0;
		if(szBuffer[0])
		{
			SkinID[iClient][0] = GetSkinID(szBuffer);
		}
	}
	else
	{
		ClearClientValues(iClient);
	}
	
	if(IsClientInGame(iClient))
	{
		if(Flags[iClient] != -1)
		{
			CheckClientSkins(iClient);
		}
	}
}

public void OnClientPutInServer(int iClient)
{
	if(IsFakeClient(iClient))
	{
		ClearClientValues(iClient);
		return;
	}
	
	IntToString(GetSteamAccountID(iClient, true), SteamID[iClient], 32);
	int iArray[1];
	if(!Players.GetArray(SteamID[iClient], iArray, 1))
	{
		SteamID[iClient][0] = 0;
	}
	if(AreClientCookiesCached(iClient))
	{
		if(Flags[iClient] != -1)
		{
			CheckClientSkins(iClient);
		}
	}
	else
	{
		ClearClientValues(iClient);
	}
}

public void OnClientPostAdminCheck(int iClient)
{
	if(!IsFakeClient(iClient))
	{
		CreateTimer(1.0, Timer_Auth, iClient);
	}
}

public Action Timer_Auth(Handle hTimer, int iClient)
{
	if(IsClientInGame(iClient))
	{
		Flags[iClient] = GetUserFlagBits(iClient);
		
		int iLength = GroupList.Length;
		for(int i; i < iLength; i += 2)
		{
			if(Group_CheckClientFlags(iClient, i))
			{
				if(AreClientCookiesCached(iClient))
				{
					CheckClientSkins(iClient);
				}
				return;
			}
		}
		Flags[iClient] = 0;
		CheckClientSkins(iClient);
	}
}

public void OnClientDisconnect(int iClient)
{
	ClearClientValues(iClient);
}

void CheckClientSkins(int iClient)
{
	int iSkinsIDs[2] = {-1, -1};
	int[] iSkins = new int[SkinsCount];
	char szBuffer[256];
	SkinData Skin;
	bool bFind;
	if(SteamID[iClient][0] && Players.GetArray(SteamID[iClient], iSkins, SkinsCount))
	{
		for(int i; i < 2; i++)
		{
			if(SkinID[iClient][i] == -1)
			{
				continue;
			}
			for(int j; j < SkinsCount; j++)
			{
				if(iSkins[j] == -1)
					break;
			
				SkinsSnapshot.GetKey(iSkins[j], szBuffer, 256);
				if(SkinID[iClient][i] == GetSkinID(szBuffer) && Skins.GetArray(szBuffer, Skin, sizeof(Skin)) && Skin.Team == i)
				{
					bFind = true;
					break;
				}
			}

			iSkinsIDs[i] = bFind ? SkinID[iClient][i]:-1;
			bFind = false;
		}
	}
	if(Flags[iClient] > 0)
	{
		int iLength = GroupList.Length;
		for(int i; i < 2; i++)
		{
			if(iSkinsIDs[i] != -1 || SkinID[iClient][i] == -1)
				continue;
				
			for(int j; j < iLength; j += 2)
			{
				if(Group_CheckClientFlags(iClient, j))
				{
					GroupList.GetArray(j + 1, iSkins, SkinsCount);
					for(int k; k < SkinsCount; k++)
					{
						if(iSkins[k] == -1)
							break;
						
						SkinsSnapshot.GetKey(iSkins[k], szBuffer, 256);
						if(SkinID[iClient][i] == GetSkinID(szBuffer) && Skins.GetArray(szBuffer, Skin, sizeof(Skin)) && Skin.Team == i)
						{
							bFind = true;
							break;
						}
					}
					
					iSkinsIDs[i] = bFind ? SkinID[iClient][i]:-1;
					bFind = false;
					break;
				}
			}
		}
	}



	SkinID[iClient][0] = iSkinsIDs[0];
	SkinID[iClient][1] = iSkinsIDs[1];
}

void SaveClientSettings(int iClient)
{
	if(SkinID[iClient][0] != -1 || SkinID[iClient][1] != -1)
	{
		char szBuffer[256], szBuffer2[256];
		if(SkinID[iClient][0] != -1)
		{
			SkinsSnapshot.GetKey(SkinID[iClient][0], szBuffer, 256);
		}
		if(SkinID[iClient][1] != -1)
		{
			SkinsSnapshot.GetKey(SkinID[iClient][1], szBuffer2, 256);
		}
		
		Format(szBuffer, 256, "%s;%s", szBuffer, szBuffer2);
		SetClientCookie(iClient, g_hCookie, szBuffer);
	}
	else
	{
		SetClientCookie(iClient, g_hCookie, "");
	}
}

void ClearClientValues(int iClient)
{
	SkinID[iClient][0] =
	SkinID[iClient][1] = -1;
}

int GetSkinID(const char[] key)
{
	char szBuffer[256];
	for(int i; i < SkinsCount; i++)
	{
		SkinsSnapshot.GetKey(i, szBuffer, 256);
		if(!strcmp(key, szBuffer, false))
			return i;
	}
	return -1;
}

int SetClientSkinID(int iClient, int iSkinID)
{
	if(iSkinID == -1)
		return -1;
		
	char szBuffer[256];
	SkinsSnapshot.GetKey(iSkinID, szBuffer, 256);
	SkinData Skin;
	
	if(Skins.GetArray(szBuffer, Skin, sizeof(Skin)))
	{
		SkinID[iClient][Skin.Team] = (SkinID[iClient][Skin.Team] == iSkinID) ? -1:iSkinID;
		return SkinID[iClient][Skin.Team];
	}
	return -1;
}

void SetClientSkin(int iClient, bool bTimer = true, float fCooldown = 0.75)
{
	int iTeam = GetClientTeam(iClient) - 2;
	if(iTeam < 0 || !IsPlayerAlive(iClient))
		return;
	
	if(SkinID[iClient][iTeam] == -1)
	{
		if(DefaultModel[iClient][iTeam][0])
		{
			SetEntityModel(iClient, DefaultModel[iClient][iTeam]);
		}
	}
	else
	{
		char szBuffer[256];
		SkinData Skin;
		SkinsSnapshot.GetKey(SkinID[iClient][iTeam], szBuffer, 256);
		if(Skins.GetArray(szBuffer, Skin, sizeof(Skin)) && Skin.IsPrecached)
		{
			if(!DefaultModel[iClient][iTeam][0])
			{
				GetEntPropString(iClient, Prop_Data, "m_ModelName", DefaultModel[iClient][iTeam], 256);
			}
			if(bTimer)
			{
				CreateTimer(fCooldown, Timer_SetClientSkin, GetClientUserId(iClient));
				
			}
			else
			{
				SetEntityModel(iClient, Skin.Model);
			}
		}
	}

	
}

public Action Timer_SetClientSkin(Handle hTimer, int iClient)
{
	if((iClient = GetClientOfUserId(iClient)) && IsClientInGame(iClient))
	{
		SetClientSkin(iClient, false);
	}
}

void ResetClientDefaultModel(int iClient)
{
	DefaultModel[iClient][0][0] = 
	DefaultModel[iClient][1][0] = 0;
}

// wS: Add to Download

void LoadFromDir(const char[] sDir)
{
	//PrintToConsoleRootAdmins("Add directory \"%s\" to download", sDir);
	DirectoryListing dl = OpenDirectory(sDir);
	
	if(!dl)
	{
		return;
	}
	
	char szBuffer[256], szBuffer2[256]; FileType t;
	while (dl.GetNext(szBuffer, 256, t))
	{
		if (t == FileType_File && ExtAllowed(szBuffer, 256))
		{
			FormatEx(szBuffer2, 256, "%s/%s", sDir, szBuffer);
			AddFileToDownloadsTable(szBuffer2);
			//PrintToConsoleRootAdmins(szBuffer);
		}
		else if (t == FileType_Directory && strcmp(szBuffer, ".", true) && strcmp(szBuffer, "..", true))
		{
			FormatEx(szBuffer2, 256, "%s/%s", sDir, szBuffer);
			LoadFromDir(szBuffer2);
		}
	}
	delete dl;
}

bool ExtAllowed(const char[] s, int length)
{
	int i = length;
	while (--i > -1)
	{
		if (s[i] == '.') {
			return i > 0 && ((i+1) != length) && strcmp(s[i+1], "ztmp", false) && strcmp(s[i+1], "bz2", false);
		}
	}
	return false;
}

stock void PrintToConsoleRootAdmins(const char[] message, any ...)
{
	int iLen = strlen(message) + 255;
	char[] szBuffer = new char[iLen];
	VFormat(szBuffer, iLen, message, 2);
	LogMessage(szBuffer);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetUserFlagBits(i) & ADMFLAG_ROOT)
		{
			PrintToConsole(i, szBuffer);
		}
	}
}

stock int Array_FindValue(int[] iArray, int iSize, int iValue)
{
	for(int i; i < iSize; i++)
	{
		if(iArray[i] == iValue)
		{
			return i;
		}

	}
	
	return -1;
}

int Group_CheckClientFlags(int iClient, int iGroup)
{
	int iFlags = GroupList.Get(iGroup);
	if(Flags[iClient] & iFlags == iFlags)
	{
		return 1;
	}
	else if(Flags[iClient] & ADMFLAG_RCON || Flags[iClient] & ADMFLAG_ROOT)
	{
		return 2;
	}
	return 0;
}

stock void PrintSkinsArray(int[] iArray, const char[] message)
{
	PrintToConsoleRootAdmins("PrintSkinsArray: %s", message);
	for(int i;i < Skins.Size; i++)
	{
		if(iArray[i] == -1)
			break;
			
		PrintToConsoleRootAdmins("%i", iArray[i]);
	}
}