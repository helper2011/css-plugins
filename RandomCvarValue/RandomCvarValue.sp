#include <sourcemod>

int count;
DataPack pack;

public void OnPluginStart()
{
    RegServerCmd("sm_rcv", Command_RCV);
}

public Action Command_RCV(int iArgs)
{
    if(iArgs != 1)
        return Plugin_Handled;

    char szBuffer[256];
    GetCmdArg(1, szBuffer, 256);
    if(pack == null)
    {
        pack = new DataPack();
        pack.WriteString(szBuffer);
        return Plugin_Handled;
    }
    else if(!strcmp(szBuffer, "exec", false))
    {
        if(count)
        {
            pack.Reset();
            pack.ReadString(szBuffer, 256);
            ConVar cvar = FindConVar(szBuffer);

            if(cvar)
            {
                pack.Position = view_as<DataPackPos>(GetRandomInt(1, count));
                pack.ReadString(szBuffer, 256);
                cvar.SetString(szBuffer);
            }
        }
        count = 0;
        delete pack;
    }
    else
    {
        pack.WriteString(szBuffer);
        count++;
    }
    
    return Plugin_Handled;
}