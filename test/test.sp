#include <sourcemod>
#include <sdktools>

public void OnClientPostAdminCheck(int iClient)
{
    PrintToServer("%N %i", iClient, GetUserFlagBits(iClient));
    PrintToConsoleAll("%N %i", iClient, GetUserFlagBits(iClient));
}
