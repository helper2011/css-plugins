#include <sourcemod>

#pragma newdecls required

Database hDatabase;

public void OnPluginStart()
{
    Database.Connect(SQL_OnConnect, "sourcebans");
}

public void SQL_OnConnect(Database db, const char[] error, any data)
{
	if (db == null)
	{
		LogError("%s", error);
	}
	else
	{
		hDatabase = db;
	}

    LogMessage("Database = %x", hDatabase);

    if(hDatabase)
    {
        hDatabase.Query(SQL_CallBack, "SELECT `name`, `authid`, `reason` FROM sb_bans WHERE RemoveType IS NULL AND length = 0", 0);
    }
}

public void SQL_CallBack(Database db, DBResultSet hResults, const char[] error, any data)
{
    if(error[0])
    {
        return;
    }
    File hFile = OpenFile("addons/unban_clients.txt", "w");
    if(!hFile)
    {
        LogMessage("File error");
        return;
    }
    char szName[64];
    char szSteamId[64];
    char szReason[64];
    while(hResults.FetchRow())
    {
        hResults.FetchString(0, szName, 64);
        hResults.FetchString(1, szSteamId, 64);
        hResults.FetchString(2, szReason, 64);
        if(strlen(szReason) > 10 && IsReasonForUnban(szReason))
        {
            ServerCommand("sm_unban \"%s\" \"Прощён\"", szSteamId);
            WriteFileLine(hFile, "%s (%s) [%s]", szName, szSteamId, szReason);
        }
    }
    CloseHandle(hFile);
}

bool IsReasonForUnban(char[] reason)
{
    return (StrContains(reason, "Little Anti-Cheat", false) != -1 && StrContains(reason, "BhopHack", false) == -1);
}