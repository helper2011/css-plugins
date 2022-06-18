enum 
{
    CVAR_INT,
    CVAR_FLOAT
}

enum /* int */
{
    MAX_TOTAL_POINTS,
    MAX_CURRENT_POINTS,
    POINT_NO_GROUND,
    CENTR_ANGLES,
    SEARCH,
    SEARCH_NO_GROUND,

    CONVARS_INT_TOTAL
}

enum /* float */
{
    POINT_MIN_DIST,
    POINT_MIN_VEL,
    POINT_MAX_VEL,
    POINT_MIN_Z_VEL,
    POINT_MAX_Z_VEL,
    POINT_GROUND_RATIO,
    SEARCH_DELAY,
    SEARCH_MIN_VEL,
    SEARCH_MAX_VEL,
    SEARCH_MIN_Z_VEL,
    SEARCH_MAX_Z_VEL,
    SEARCH_MIN_DIST,
    SEARCH_GROUND_RATIO,
    CONVARS_FLOAT_TOTAL
}

ConVar CVarsInt[CONVARS_INT_TOTAL];
ConVar CVarsFloat[CONVARS_FLOAT_TOTAL];

int CVarsCacheInt[CONVARS_INT_TOTAL];
float CVarsCacheFloat[CONVARS_FLOAT_TOTAL];

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
    CreateConVar2(CVAR_INT,     MAX_TOTAL_POINTS,         "max_total_points",     "1000");
    CreateConVar2(CVAR_INT,     MAX_CURRENT_POINTS,       "max_current_points",   "250");
    CreateConVar2(CVAR_INT,     POINT_NO_GROUND,          "point_no_ground",      "1");
    CreateConVar2(CVAR_FLOAT,   POINT_MIN_DIST,            "point_min_dist",        "500");
    CreateConVar2(CVAR_FLOAT,   POINT_MIN_VEL,            "point_min_vel",        "800");
    CreateConVar2(CVAR_FLOAT,   POINT_MAX_VEL,            "point_max_vel",        "2000");
    CreateConVar2(CVAR_FLOAT,   POINT_MIN_Z_VEL,          "point_min_z_vel",      "200");
    CreateConVar2(CVAR_FLOAT,   POINT_MAX_Z_VEL,          "point_max_z_vel",      "600");
    CreateConVar2(CVAR_INT,     CENTR_ANGLES,             "centr_angles",         "1");
    CreateConVar2(CVAR_INT,     SEARCH,                   "search",               "1");
    CreateConVar2(CVAR_FLOAT,   SEARCH_DELAY,             "search_delay",         "5");
    CreateConVar2(CVAR_FLOAT,   SEARCH_MIN_VEL,           "search_min_vel",       "800");
    CreateConVar2(CVAR_FLOAT,   SEARCH_MAX_VEL,           "search_max_vel",       "2000");
    CreateConVar2(CVAR_FLOAT,   SEARCH_MIN_Z_VEL,         "search_min_z_vel",     "200");
    CreateConVar2(CVAR_FLOAT,   SEARCH_MAX_Z_VEL,         "search_max_z_vel",     "600");
    CreateConVar2(CVAR_INT,     SEARCH_NO_GROUND,         "search_no_ground",     "1");
    CreateConVar2(CVAR_FLOAT,   SEARCH_MIN_DIST,          "search_min_dist",      "500");
    CreateConVar2(CVAR_FLOAT,   SEARCH_GROUND_RATIO,      "search_ground_ratio",  "1.75");
    CreateConVar2(CVAR_FLOAT,   POINT_GROUND_RATIO,       "point_ground_ratio",   "1.75");
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
    int iCvarId = GetConVarIndex_Int(cvar);
    CVarsCacheInt[iCvarId] = CVarsInt[iCvarId].IntValue;
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

