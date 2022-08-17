#define LOG

#include <sourcemod>

#pragma newdecls required

#if defined LOG

File LogFile;
#define BuildLogFile() _BuildLogFile()




public void OnPluginStart()
{
    AddCommandListener(Command_JoinClass, "joinclass");
}

public Action Command_JoinClass(int iClient, const char[] command, int iArgs)
{
    
}