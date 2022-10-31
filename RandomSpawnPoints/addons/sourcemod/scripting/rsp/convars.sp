enum 
{
    CVAR_INT,
    CVAR_FLOAT
}

enum /* int */
{
    ENABLE,
    MIN_POINTS,
    MAX_POINTS,
    CENTR_ANGLES,
    SEARCH,
    FRIENDLY_FIRE,

    CONVARS_INT_TOTAL
}

enum /* float */
{
    POINT_MIN_DIST,
    SEARCH_DELAY,
    CONVARS_FLOAT_TOTAL
}

ConVar CVarsInt[CONVARS_INT_TOTAL];
ConVar CVarsFloat[CONVARS_FLOAT_TOTAL];

int CVarsCacheInt[CONVARS_INT_TOTAL];
float CVarsCacheFloat[CONVARS_FLOAT_TOTAL];

ConVar mp_friendlyfire;

stock int GetConVarInt2(int iCvarId)
{
    return CVarsCacheInt[iCvarId];
}

stock bool GetConVarBool2(int iCvarId)
{
    return !!CVarsCacheInt[iCvarId];
}

stock float GetConVarFloat2(int iCvarId)
{
    return CVarsCacheFloat[iCvarId];
}

stock void CreateConVars()
{
    mp_friendlyfire = FindConVar("mp_friendlyfire");
    CreateConVar2(CVAR_INT,     ENABLE,                   "enable",               "1");
    CreateConVar2(CVAR_INT,     MIN_POINTS,               "min_points",           "100");
    CreateConVar2(CVAR_INT,     MAX_POINTS,               "max_points",           "250");
    CreateConVar2(CVAR_FLOAT,   POINT_MIN_DIST,           "point_min_dist",       "1000");
    CreateConVar2(CVAR_INT,     CENTR_ANGLES,             "centr_angles",         "1");
    CreateConVar2(CVAR_INT,     SEARCH,                   "search",               "1");
    CreateConVar2(CVAR_INT,     FRIENDLY_FIRE,            "friendly_fire",        "1");
    CreateConVar2(CVAR_FLOAT,   SEARCH_DELAY,             "search_delay",         "5");
}

stock void CreateConVar2(int iCvarType, int iCvarId, const char[] cvarName, const char[] cvarValue)
{
    char szBuffer[128];
    FormatEx(szBuffer, 128, "sm_rsp_%s", cvarName);

    switch(iCvarType)
    {
        case CVAR_INT:
        {
            CVarsInt[iCvarId] = CreateConVar(szBuffer, cvarValue);
            CVarsInt[iCvarId].AddChangeHook(OnConVarChanged_Int);
            CVarsCacheInt[iCvarId] = CVarsInt[iCvarId].IntValue;
        }
        case CVAR_FLOAT:
        {
            CVarsFloat[iCvarId] = CreateConVar(szBuffer, cvarValue);
            CVarsFloat[iCvarId].AddChangeHook(OnConVarChanged_Float);
            CVarsCacheFloat[iCvarId] = CVarsFloat[iCvarId].FloatValue;
        }
    }
}

public void OnConVarChanged_Int(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    //int iOldValue = StringToInt(oldValue);
    //int iNewValue = StringToInt(newValue);
    int iCvarId = GetConVarIndex_Int(cvar);
    CVarsCacheInt[iCvarId] = CVarsInt[iCvarId].IntValue;

    switch(iCvarId)
    {
        case FRIENDLY_FIRE:
        {
            FF_Update();
        }
    }
}

public void OnConVarChanged_Float(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    int iCvarId = GetConVarIndex_Float(cvar);
    CVarsCacheFloat[iCvarId] = CVarsFloat[iCvarId].FloatValue;
}


stock int GetConVarIndex_Int(ConVar cvar)
{
    for(int i; i < CONVARS_INT_TOTAL; i++)
    {
        if(CVarsInt[i] == cvar)
        {
            return i;
        }
    }

    return -1;
}

stock int GetConVarIndex_Float(ConVar cvar)
{
    for(int i; i < CONVARS_FLOAT_TOTAL; i++)
    {
        if(CVarsFloat[i] == cvar)
        {
            return i;
        }
    }

    return -1;
}

