StringMap SearchPoints;

Handle TimerSearch;

stock void Search_DataInit()
{
    SearchPoints = new StringMap();
}

stock void Search_TimerInit()
{
    DebugMessage("Search_TimerInit")
    delete TimerSearch;
    
    if(GetConVarBool2(ENABLE) && GetConVarBool2(SEARCH))
    {
        float fDelay = GetConVarFloat2(SEARCH_DELAY);
        if(fDelay > 0.0)
        {
            TimerSearch = CreateTimer(fDelay, Timer_Search, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

stock void Search_OnMapStart()
{
    Search_TimerInit();
}

stock void Search_OnMapEnd()
{
    TimerSearch = null;

    Search_SavePoints();
    SearchPoints.Clear();
}

stock void Search_SavePoints()
{
    DebugMessage("Search_SavePoints")
    int iSize = SearchPoints.Size;
    if(iSize == 0)
        return;

    char szBuffer[256];
    char szDataFile[256];
    GetCurrentMap(szBuffer, 256);
    BuildPath(Path_SM, szDataFile, 256, "data/rsp/%s.txt", szBuffer);
    KeyValues hKeyValues = new KeyValues("SpawnPoints");
    if(!hKeyValues.ImportFromFile(szDataFile))
    {
        BuildPath(Path_SM, szDataFile, 256, "data/rsp/template.txt");
        hKeyValues = new KeyValues("SpawnPoints");
        if(hKeyValues.ImportFromFile(szDataFile))
        {
            BuildPath(Path_SM, szDataFile, 256, "data/rsp/%s.txt", szBuffer);
        }
        else
        {
            return;
        }
    }
    int iSavedPoints;
    SpawnPointData point;
    DebugMessage("Search points = %i", iSize)
    for(int i; i < iSize; i++)
    {
        IntToString(i, szBuffer, 16);
        if(!SearchPoints.GetArray(szBuffer, point, sizeof(point)))
        {
            DebugMessage("Search_SavePoints: Cant get point data")
            continue;
        }

        IntToString(point.Id, szBuffer, 256);
        if(hKeyValues.JumpToKey(szBuffer))
        {
            LogMessage("JumpToKey Error! Point ID = %i", point.Id);
            continue;
        }

        if(hKeyValues.JumpToKey(szBuffer, true))
        {
            hKeyValues.SetVector("Position", point.Position);
            hKeyValues.SetVector("Angles", point.Angles);
            hKeyValues.GoBack();
            iSavedPoints++;
        }
    }

    DebugMessage("Saved points = %i", iSavedPoints)

    if(iSavedPoints)
    {
        hKeyValues.Rewind();
        hKeyValues.ExportToFile(szDataFile);
    }

    delete hKeyValues;
}

public Action Timer_Search(Handle hTimer)
{
    DebugMessage("Timer_Search")
    
    if(!GetConVarBool2(SEARCH))
    {
        return Plugin_Stop;
    }
    if(Points.Size + SearchPoints.Size > GetConVarInt2(MAX_POINTS))
    {
        return Plugin_Stop;
    }
    
    FF_Update();
    SpawnPointData point;
    static float fPosition[3];
    static float fAngles[3];
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i) || !IsPlayerAlive(i) || !(GetEntityFlags(i) & FL_ONGROUND) || GetEntPropEnt(i, Prop_Send, "m_hGroundEntity") > 0)
            continue;

        GetEntPropVector(i, Prop_Data, "m_vecOrigin", fPosition);
        if(!Search_IsPointPositionValid(fPosition))
        {
            continue;
        }

        point.Position = fPosition;
        point.Angles = fAngles;
        Point_AddPoint(point);
        Search_AddPoint(point);
    }

    return Plugin_Continue;
}

stock void Search_AddPoint(SpawnPointData point)
{
    char szBuffer[16];
    point.Id = NextPointID++;
    IntToString(SearchPoints.Size, szBuffer, 16);
    SearchPoints.SetArray(szBuffer, point, sizeof(point));
}

stock bool Search_IsPointPositionValid(float fPosition[3], StringMap points = null)
{
    if(points == null)
    {
        return (Search_IsPointPositionValid(fPosition, Points) && Search_IsPointPositionValid(fPosition, SearchPoints));
    }

    char szBuffer[16];
    SpawnPointData point;
    float fDistance = GetConVarFloat2(POINT_MIN_DIST);
    int iLength = points.Size;
    for(int i; i < iLength; i++)
    {
        IntToString(i, szBuffer, 16);
        if(!points.GetArray(szBuffer, point, sizeof(point)))
        {
            DebugMessage("Search_IsPointPositionValid: cant get point data")
            continue;
        }

        if(GetVectorDistance(fPosition, point.Position) <= fDistance)
            return false;
    }

    return true;
}