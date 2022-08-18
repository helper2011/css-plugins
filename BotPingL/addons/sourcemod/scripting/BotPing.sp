#include <sdktools>

#define INTERVAL 3.0
#define MINPING 20
#define MAXPING 40

new g_iMaxClients = 0, String:g_szPlayerManager[20] = "", g_iPlayerManager = -1, g_iPing = -1;

public Plugin:myinfo ={name = "Bot Ping [L]",    author = "Danyas"};
public OnPluginStart()
{
    g_iPing    = FindSendPropInfo("CPlayerResource", "m_iPing");
    strcopy(g_szPlayerManager, sizeof(g_szPlayerManager), "cs_player_manager");
    CreateTimer(INTERVAL,SetPing,_,TIMER_REPEAT);
}

public OnMapStart()
{
    g_iPlayerManager    = FindEntityByClassname(MaxClients + 1, g_szPlayerManager);
}

public Action:SetPing(Handle:timer)
{
    for(new i = 1; i <= g_iMaxClients; i++)
    {
    if(!IsValidEdict(i) || !IsClientInGame(i) || !IsFakeClient(i)) continue;
    SetEntData(g_iPlayerManager, g_iPing + (i * 4), GetRandomInt(MINPING,MAXPING));}
}