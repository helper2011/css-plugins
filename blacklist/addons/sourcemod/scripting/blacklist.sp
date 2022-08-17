const int MAX_BLACK_LIST_CLANS = 10;
const int MAX_BLACK_LIST_CLIENTS = 50;

int
	BL_Clans, 
	BL_SteamIDs, 
	BL_Clan[MAX_BLACK_LIST_CLANS], 
	BL_SteamID[MAX_BLACK_LIST_CLIENTS];
bool
	BL_Allow[MAXPLAYERS + 1];

stock void BL_Load()
{
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, 256, "configs/blacklist_clans.txt");
	File hFile = OpenFile(szBuffer, "r");
	if(hFile)
	{
		
		while (!hFile.EndOfFile() && BL_Clans < MAX_BLACK_LIST_CLANS)
		{
			if (!hFile.ReadLine(szBuffer, 256))
				continue;
			
			if(TrimString(szBuffer) > 0)
			{
				BL_Clan[BL_Clans++] = StringToInt(szBuffer);
			}
		}
	}
	delete hFile;
	BuildPath(Path_SM, szBuffer, 256, "configs/blacklist_clients.txt");
	hFile = OpenFile(szBuffer, "r");
	if(hFile)
	{
		
		while (!hFile.EndOfFile() && BL_SteamIDs < MAX_BLACK_LIST_CLIENTS)
		{
			if (!hFile.ReadLine(szBuffer, 256))
				break;
			
			if(TrimString(szBuffer) > 0)
			{
				BL_SteamID[BL_SteamIDs++] = StringToInt(szBuffer);
			}
		}
	}
	delete hFile;
}

stock void BL_OnClientPutInServer(int iClient)
{
	char szBuffer[32];
	GetClientInfo(iClient, "cl_clanid", szBuffer, 32);
	int iValue = StringToInt(szBuffer);
	
	for(int i; i < BL_Clans; i++)
	{
		if(iValue == BL_Clan[i])
		{
			return;
		}
	}
	
	if(!(iValue = GetSteamAccountID(iClient, true)))
		return;

	for(int i; i < BL_SteamIDs; i++)
	{
		if(iValue == BL_SteamID[i])
		{
			return;
		}
	}
	BL_Allow[iClient] = true;
}


stock void BL_OnClientDisconnect(int iClient)
{
	BL_Allow[iClient] = false;
}