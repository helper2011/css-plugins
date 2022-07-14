#include <sourcemod>

int IgnoreFlags;
char DownloadURL[256];
char FakeDownloadURL[256];
ConVar sv_downloadurl;

public void OnPluginStart()
{
    char szBuffer[256];
    sv_downloadurl = FindConVar("sv_downloadurl");
    if(sv_downloadurl == null)
    {
        SetFailState("Cant find \"sv_downloadurl\"");
    }
    sv_downloadurl.AddChangeHook(OnConVarURLChanged);
    sv_downloadurl.GetString(szBuffer, 256);
    strcopy(DownloadURL, 256, szBuffer);
    ConVar cvar = CreateConVar("sv_fakedownloadurl", "https://bit.ly/3PuLQnP"); // rick roll xD
    cvar.AddChangeHook(OnConVarFakeURLChanged);
    cvar.GetString(szBuffer, 256);
    strcopy(FakeDownloadURL, 256, szBuffer);
    cvar = CreateConVar("sv_fakedownloadurl_ignore_flags", "z");
    cvar.AddChangeHook(OnConVarIgnoreFlagsChanged);
    cvar.GetString(szBuffer, 256);
    IgnoreFlags = ReadFlagString(szBuffer);
    AutoExecConfig(true, "plugin.FakeDownloadURL");
}

public void OnConVarURLChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    strcopy(DownloadURL, 256, newValue);
}

public void OnConVarFakeURLChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    strcopy(FakeDownloadURL, 256, newValue);
}

public void OnConVarIgnoreFlagsChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    IgnoreFlags = ReadFlagString(newValue);
}

public void OnClientPutInServer(int iClient)
{
    if(!IsFakeClient(iClient))
    {
        ProcessClient(iClient);
    }
}

public void OnClientPostAdminCheck(int iClient)
{
    if(!IsFakeClient(iClient) && GetUserFlagBits(iClient) & IgnoreFlags)
    {
        ProcessClient(iClient, false);
    }
}

stock void ProcessClient(int iClient, bool bSetFake = true)
{
    sv_downloadurl.ReplicateToClient(iClient, bSetFake ? FakeDownloadURL:DownloadURL);
}