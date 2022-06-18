#if DEBUG 1
#define DebugMessage(%0) DebugMsg(%0)

#if DEBUG_ADV 1
#define DebugMessage2(%0) DebugMsg(%0)
#else
#define DebugMessage2(%0)
#endif
#define Debug_FileInit() Debug_FileInit2()

File LogFile;

stock void Debug_FileInit2()
{
    delete LogFile;

    char szBuffer[256];
    FormatTime(szBuffer, 256, "logs/rsp_%Y-%m-%d.log");
    BuildPath(Path_SM, szBuffer, 256, szBuffer);
    if((LogFile = OpenFile(szBuffer, "w+")) == null)
    {
    	SetFailState("Cant create/open \"%s\"", szBuffer);
    }
}

stock void DebugMsg(const char[] format, any ...)
{
    int iLen = strlen(format) + 256 + 1;
    char[] szBuffer = new char[iLen];
    VFormat(szBuffer, iLen, format, 2);
    LogToOpenFile(LogFile, szBuffer);
    Debug_PrintToRconAdmins(szBuffer);
}

stock void Debug_PrintToRconAdmins(const char[] message)
{
    char szBuffer[256];
    FormatEx(szBuffer, 256, "\x07FF0000RSP Debug: \x07FFFFFF%s", message);
    
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && GetUserFlagBits(i) & (ADMFLAG_RCON | ADMFLAG_ROOT))
        {
            PrintToChat(i, szBuffer);
        }
    }
}

#else
#define DebugMessage(%0)
#define Debug_FileInit(%0)
#endif