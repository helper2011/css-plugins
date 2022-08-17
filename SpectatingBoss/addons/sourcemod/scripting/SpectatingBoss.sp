#include <sourcemod>

const int MAX_BOSSES = 10;

Menu 
    BossMenu;
int
    ClientBossIndex[MAXPLAYERS + 1],
    Bosses,
    BossHammerID[MAX_BOSSES],
    BossParentRef[MAX_BOSSES],
    BossEntity[MAX_BOSSES];
bool 
    Toggle;
float
    BossPosFix[MAX_BOSSES][3];
char
    BossName[MAX_BOSSES][32];

public void OnPluginStart()
{
    BossMenu = new Menu(BossMenu_Handler, MenuAction_Select);
    BossMenu.SetTitle("Spec Boss");
    RegConsoleMenu("sm_specboss", Command_SpecBoss);
}

public void OnPluginEnd()
{
    ClientsStopSpecBoss();
    KillBossParents();
}

public void OnMapStart()
{
    char szBuffer[256];
    GetCurrentMap(szBuffer, 256);
    StringLowerCase(szBuffer);
    BuildPath(Path_SM, szBuffer, 256, "configs/specboss/%s.cfg", szBuffer);
    KeyValues hKeyValues = new KeyValues("Bosses");
    Enable = (hKeyValues.ImportFromFile(szBuffer) && hKeyValues.GotoFirstSubKey());
    if(Enable)
    {
        do
        {
            BossHammerID[Bosses] = hKeyValues.GetNum("hammerid");
            hKeyValues.GetString("name", BossName[Bosses], 32);
            hKeyValues.GetFloat("posfix", BossPosFix[Bosses]);
            Bosses++;
        }
        while(hKeyValues.GotoNextKey() && Bosses < MAX_BOSSES);
    }
    delete hKeyValues;
}

public void OnMapEnd()
{
    Bosses = 0;
    BossMenu.RemoveAllItems();
}

public void OnEntitySpawned(int entity, const char[] classname)
{
    if(Enable && IsValidEntity(entity))
    {
        int iHammerID = GetEntProp(entity, Prop_Data, "m_iHammerID");
        int iBossIndex = GetBossByHammerID(iHammerID);
        if(iBossIndex != -1)
        {
            BossEntity[iBossIndex] = entity;
            CreateBossParent(iBossIndex);
        }
    }
}

public void OnEntityDestroyed(int entity)
{
    if(Enable)
    {
        int iBossIndex = GetBossByEntity(entity);
        if(iBossIndex != -1)
        {
            
        }
    }
}

public void OnClientDisconnect(int iClient)
{

}

stock void ClientSpecBoss(int iClient, int iBossIndex)
{

}

stock void ClientStopSpecBoss(int iClient)
{

}

stock void ClientsStopSpecBoss()
{
    for(int i = 1; i <= MaxClients; i++)
    {
        ClientStopSpecBoss(i);
    }
}

stock int KillBossParent(int iBossIndex)
{

}

stock int KillBossParents()
{
    for(int i; i < Bosses; i++)
    {
        KillBossParent(i);
    }
}

stock int GetBossByName(const char[] name)
{
    for(int i; i < Bosses; i++)
    {

    }
}

stock int GetBossByHammerID(const int hammerid)
{
    for(int i; i < Bosses; i++)
    {

    }
}

stock int GetBossByEntity(const int hammerid)
{
    for(int i; i < Bosses; i++)
    {

    }
}



stock void StringLowerCase(char[] buffer)
{

}

