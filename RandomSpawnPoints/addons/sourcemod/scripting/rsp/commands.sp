stock void RegCommands()
{
    RegAdminCmd("sm_rsp", Command_RSP, ADMFLAG_RCON);
}

public Action Command_RSP(int iClient, int iArgs)
{
    RSP_Menu(iClient);
    return Plugin_Handled;
}

stock void RSP_Menu(int iClient)
{
    Menu hMenu = new Menu(RSPMenuH, MenuAction_End | MenuAction_Select);
    hMenu.SetTitle("RSPMenu\n ");
    hMenu.AddItem("points", "Points\n ");
    hMenu.AddItem("searchpoints", "Search Points\n ");
    hMenu.AddItem("reload", "Reload");
    hMenu.AddItem("save", "Save");
    hMenu.Display(iClient, 0);
}

public int RSPMenuH(Menu hMenu, MenuAction action, int iClient, int iItem)
{
    switch(action)
    {
        case MenuAction_End: delete hMenu;

        case MenuAction_Select:
        {
            char szBuffer[16];
            hMenu.GetItem(iItem, szBuffer, 16);
            if(strcmp(szBuffer, "points", false) == 0)
            {
                RSP_PointsMenu(iClient);
            }
            if(strcmp(szBuffer, "searchpoints", false) == 0)
            {
                RSP_PointsMenu(iClient, "Search ");
            }
            else if(strcmp(szBuffer, "reload", false) == 0)
            {
                
            }
            else if(strcmp(szBuffer, "save", false) == 0)
            {

            }
        }
    }

    return 0;
}

stock void RSP_PointsMenu(int iClient, const char[] prefix = "")
{
    char szId[64];
    char szBuffer[256];
    Menu hMenu = new Menu(RSP_PointsMenuH, MenuAction_End | MenuAction_Cancel | MenuAction_Select);
    FormatEx(szBuffer, 256, "%sPoints", prefix);
    hMenu.SetTitle("%sPoints", prefix);
    StringMap points = prefix[0] ? SearchPoints:Points;
    StringMapSnapshot snapshot = points.Snapshot();
    int iLength = snapshot.Length;

    if(iLength == 0)
    {
        delete hMenu;
        delete snapshot;
        RSP_Menu(iClient);
        PrintToChat(iClient, "RSP: No points");
    }
    SpawnPointData point;
    for(int i; i < iLength; i++)
    {
        if(!snapshot.GetKey(i, szBuffer, 256) || !points.GetArray(szBuffer, point, sizeof(point)))
        {
            DebugMessage("RSP_PointsMenu: cant get point data")
            continue;
        }

        FormatEx(szId, 64, "%i;%i", point.Id, view_as<int>(points));
        FormatEx(szBuffer, 256,  "#%i\nP: %.0f %.0f %.0f, V: %.0f %.0f %.0f, G: %c", point.Id, point.Position[0],  point.Position[1],  point.Position[2], point.Velocity[0], point.Velocity[1], point.Velocity[2], point.OnGround ? '+':'-');

        hMenu.AddItem(szId, szBuffer);
    }

    hMenu.Display(iClient, 0);
}

public int RSP_PointsMenuH(Menu hMenu, MenuAction action, int iClient, int iItem)
{
    switch(action)
    {
        case MenuAction_End:
        {
            if(iItem != MenuEnd_Selected)
            {
                delete hMenu;
            }
        }
        case MenuAction_Cancel:
        {
            if(iItem == MenuCancel_ExitBack)
            {
                RSP_Menu(iClient);
            }
        }
        case MenuAction_Select:
        {
            char szBuffer[64];
            char szBuffers[2][32];
            hMenu.GetItem(iItem, szBuffer, 64);

            if(ExplodeString(szBuffer, ";", szBuffers, 2, 32) == 2)
            {
                StringMap points = view_as<StringMap>(StringToInt(szBuffers[1]));

                if(points != Points && points != SearchPoints)
                {
                    DebugMessage("RSP_PointsMenuH - StringMap ref not valid!")
                    return 0;
                }

                SpawnPointData point;
                if(!points.GetArray(szBuffers[0], point, sizeof(point)))
                {
                    DebugMessage("RSP_PointsMenuH - cant get point data (pId = %i)", StringToInt(szBuffers[0]))
                    return 0;
                }

                Point_TeleportClient(iClient, point);
                hMenu.DisplayAt(iClient, hMenu.Selection, 0);
            }
            else
            {
                DebugMessage("RSP_PointsMenuH - ExplodeString Error")
            }
        }

    }

    return 0;
}