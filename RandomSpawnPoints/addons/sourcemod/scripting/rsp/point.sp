enum struct SpawnPointData
{
    int Id;
    float Position[3];
    float Angles[3];
    bool OnGround;
}

StringMap Points;

int NextPointID;

stock void Point_OnMapEnd()
{
    NextPointID = 0;
    Points.Clear();
}

stock void Point_DataInit()
{
    Points = new StringMap();
}

stock void Point_AddPoint(SpawnPointData point)
{
    DebugMessage2("Point_AddPoint")

    char szBuffer[16];
    point.Id = NextPointID;
    IntToString(Points.Size, szBuffer, 16);
    Points.SetArray(szBuffer, point, sizeof(point));
}

stock void Point_DelPoint(SpawnPointData point)
{
    DebugMessage("Point_DelPoint")

    char szBuffer[16];
    IntToString(point.Id, szBuffer, 16);
    Points.Remove(szBuffer);
}

stock void Point_LoadPoints()
{
    DebugMessage("Point_LoadPoints")
    
    char szBuffer[256];
    GetCurrentMap(szBuffer, 256);
    BuildPath(Path_SM, szBuffer, 256, "data/rsp/%s.txt", szBuffer);
    KeyValues hKeyValues = new KeyValues("SpawnPoints");
    if(!hKeyValues.ImportFromFile(szBuffer) || !hKeyValues.GotoFirstSubKey())
    {
        return;
    }
    int iId;
    int iCount;
    int iMaxID = -1;
    SpawnPointData point;
    do
    {
        hKeyValues.GetSectionName(szBuffer, 256);
        iId = StringToInt(szBuffer);

        hKeyValues.GetVector("Position", point.Position);
        hKeyValues.GetVector("Angles", point.Angles);
        IntToString(iCount++, szBuffer, 256);
        Points.SetArray(szBuffer, point, sizeof(point));
        DebugMessage(szBuffer)
        if(iMaxID == -1 || iId > iMaxID)
        {
            iMaxID = iId;
        }
    }
    while(hKeyValues.GotoNextKey());
    
    NextPointID = iMaxID + 1;
    delete hKeyValues;
}

stock void Point_TeleportClient(int iClient, SpawnPointData point)
{
    TeleportEntity(iClient, point.Position, point.Angles, NULL_VECTOR);
}

stock void Point_TeleportClientToRandomPoint(int iClient)
{
    static char szBuffer[16];
    if(GetConVarBool2(ENABLE) && Points.Size >= GetConVarInt2(MIN_POINTS))
    {
        IntToString(GetRandomInt(0, Points.Size - 1), szBuffer, 16);
        SpawnPointData point;
        if(Points.GetArray(szBuffer, point, 16))
        {
            Point_TeleportClient(iClient, point);
        }
    }
}