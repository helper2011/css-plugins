StringMap SearchPoints;

int SearchGroundPoints;
int SearchNoGroundPoints;

Handle TimerSearch;

stock void Search_DataInit()
{
    SearchPoints = new StringMap();
}

stock void Search_TimerInit()
{
    DebugMessage("Search_TimerInit")
    delete TimerSearch;
    
    if(GetConVarBool2(SEARCH))
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
        return;
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
            hKeyValues.SetVector("Velocity", point.Velocity);
            hKeyValues.SetVector("Angles", point.Angles);
            hKeyValues.SetNum("OnGround", view_as<int>(point.OnGround));
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
    
    SpawnPointData point;
    static float fPosition[3];
    static float fAngles[3];
    static float fVelocity[3];
    static bool bOnGround;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i) || !IsPlayerAlive(i))
            continue;

        bOnGround = !!(GetEntityFlags(i) & FL_ONGROUND);

        if(!Search_IsPointGroundValid(bOnGround))
        {
            continue;
        }
        GetEntPropVector(i, Prop_Data, "m_vecOrigin", fPosition);
        if(!Search_IsPointPositionValid(fPosition))
        {
            continue;
        }

        point.Position = fPosition;
        point.Angles = fAngles;
        point.Velocity = fVelocity;
        point.OnGround = bOnGround;
        Point_AddPoint(point);
        Search_AddPoint(point);
    }
}

stock void Search_AddPoint(SpawnPointData point)
{
    char szBuffer[16];
    point.Id = NextPointID++;
    IntToString(SearchPoints.Size, szBuffer, 16);
    SearchPoints.SetArray(szBuffer, point, sizeof(point));
}

stock bool Search_IsPointPositionValid(float fPosition[3], bool bCall = true)
{
    char szBuffer[16];
    SpawnPointData point;
    //StringMapSnapshot snapshot;
    //snapshot = bCall ? (Points.Snapshot()):(SearchPoints.Snapshot());
    StringMap points = bCall ? Points:SearchPoints;
    float fDistance = GetConVarFloat2(bCall ? POINT_MIN_DIST:SEARCH_MIN_DIST);
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

    return bCall ? Search_IsPointPositionValid(fPosition, false):true;
}

stock bool Search_IsPointGroundValid(bool bOnGround)
{
    return (bOnGround || Search_GetGroundPointsRatio() < GetConVarFloat2(SEARCH_GROUND_RATIO));
}

stock float Search_GetGroundPointsRatio()
{
    return float(SearchGroundPoints) / float(SearchNoGroundPoints);
}