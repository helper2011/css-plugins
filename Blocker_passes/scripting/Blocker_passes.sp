#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <adminmenu>

#define ADMIN_LEVEL		ADMFLAG_UNBAN

#pragma newdecls required

#define PLUGIN_VERSION 	"1.2.5"

Menu	MainMenu,
		PropsMenu,
		RotateMenu,
		ShiftMenu,
		ScaleMenu,
		ColorMenu;
		
Handle	BPAdminMenu;
	
KeyValues PropMapData;
ArrayList EntityList;

char Props[64][256];

public Plugin myinfo = 
{
	name = "Blocker passes [Edited]",
	author = ">>Satan<<",
	description = "Blocker passes on maps",
	version = PLUGIN_VERSION,
};

public void OnPluginStart() 
{
	MainMenu = new Menu(MenuPropMenuHandler);
	MainMenu.SetTitle("| Управление предметами |");
	MainMenu.ExitBackButton = true;
	
	MainMenu.AddItem("PropsMenu", 	"Меню предметов");
	MainMenu.AddItem("ColorMenu", 	"Меню покраски");
	MainMenu.AddItem("SaveProps", 	"Сохранить предметы");
	MainMenu.AddItem("", 		"", ITEMDRAW_SPACER);
	
	RotateMenu = new Menu(PropRoteMenuHandle);
	RotateMenu.SetTitle("| Повернуть предмет |");
	RotateMenu.ExitBackButton = true;
	
	RotateMenu.AddItem("RotateX+1", "Повернуть на +1° по оси X");
	RotateMenu.AddItem("RotateX-1", "Повернуть на -1° по оси X");
	RotateMenu.AddItem("RotateY+1", "Повернуть на +1° по оси Y");
	RotateMenu.AddItem("RotateY-1", "Повернуть на -1° по оси Y");
	RotateMenu.AddItem("RotateZ+1", "Повернуть на +1° по оси Z");
	RotateMenu.AddItem("RotateZ-1", "Повернуть на -1° по оси Z");
	
	ShiftMenu = new Menu(PropShiftMenuHandle);
	ShiftMenu.SetTitle("| Сдвинуть предмет |");
	ShiftMenu.ExitBackButton = true;
	
	ShiftMenu.AddItem("ShiftX+1", "Сдвинуть на +1° по оси X");
	ShiftMenu.AddItem("ShiftX-1", "Сдвинуть на -1° по оси X");
	ShiftMenu.AddItem("ShiftY+1", "Сдвинуть на +1° по оси Y");
	ShiftMenu.AddItem("ShiftY-1", "Сдвинуть на -1° по оси Y");
	ShiftMenu.AddItem("ShiftZ+1", "Сдвинуть на +1° по оси Z");
	ShiftMenu.AddItem("ShiftZ-1", "Сдвинуть на -1° по оси Z");
	
	ScaleMenu = new Menu(MenuPropScaleHandler);
	ScaleMenu.SetTitle("| Изменить размер предмета |");
	ScaleMenu.AddItem("", "25%");
	ScaleMenu.AddItem("", "50%");
	ScaleMenu.AddItem("", "75%");
	ScaleMenu.AddItem("", "100%");
	ScaleMenu.AddItem("", "125%");
	ScaleMenu.AddItem("", "150%");
	ScaleMenu.AddItem("", "175%");
	ScaleMenu.ExitBackButton = true;	
	
	ColorMenu = new Menu(MenuPropColorHandler);
	ColorMenu.SetTitle("| Окрасить предмет |");
	ColorMenu.ExitBackButton = true;	
	
	ColorMenu.AddItem("color1", "Красный");
	ColorMenu.AddItem("color2", "Зеленый");
	ColorMenu.AddItem("color3", "Синий");
	ColorMenu.AddItem("color4", "Желтый");
	ColorMenu.AddItem("color7", "Прозрачный (10%)");
	ColorMenu.AddItem("color8", "Прозрачный (25%)");
	ColorMenu.AddItem("color9", "Прозрачный (100%)");

	EntityList = new ArrayList(ByteCountToCells(32));
	
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	
	RegAdminCmd("sm_minecraft", CommandAdminPasses, ADMIN_LEVEL);
	
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	LoadPropsMenu();
}

public void OnMapStart() 
{
	int i;
	
	while (i < 64 && Props[i][0])
	{
		PrecacheModel(Props[i++], true);
	}
	LoadMapData();
}

public void OnMapEnd()
{
	delete PropMapData;
}

void LoadMapData()
{
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "data/blocker_passes/");
	
	if (!DirExists(szBuffer))
	{
		CreateDirectory(szBuffer, 511);
	}
	GetCurrentMap(szBuffer, sizeof(szBuffer));
	
	BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "data/blocker_passes/%s.txt", szBuffer);
	PropMapData = new KeyValues("blocker_passes");
	if(PropMapData.ImportFromFile(szBuffer) && PropMapData.GotoFirstSubKey())
	{
		do
		{
			PropMapData.GetString("model", szBuffer, 256);
			if(!IsModelPrecached(szBuffer))
			{
				PropMapData.DeleteThis();
			}
		}
		while (PropMapData.GotoNextKey());
		
		PropMapData.Rewind();
	}
	
	
}

public Action CommandAdminPasses(int client, int args)
{
	DisplayTopMenu(BPAdminMenu, client, TopMenuPosition_LastCategory);
	return Plugin_Handled;
}

public void OnRoundStart(Event hEvent, const char[] name, bool bDontBroadcast) 
{
	EntityList.Clear();
	
	if(PropMapData)
	{
		SpawnBlocks();
	}
}

public void OnAdminMenuReady(Handle topmenu)
{
	if (BPAdminMenu == topmenu){
		return;
	}
	
	BPAdminMenu = topmenu;
	
	TopMenuObject blocker_passes = FindTopMenuCategory(BPAdminMenu, "blocker_passes");
		
	if (blocker_passes == INVALID_TOPMENUOBJECT)
	{
		blocker_passes = AddToTopMenu(BPAdminMenu, "blocker_passes", TopMenuObject_Category, Handle_Category, INVALID_TOPMENUOBJECT, "sm_blocker_passes", ADMIN_LEVEL);
	}
			
	AddToTopMenu(BPAdminMenu, "sm_bp_save", TopMenuObject_Item, blocker_passes_Save, blocker_passes, "sm_bp_save", ADMIN_LEVEL);
	AddToTopMenu(BPAdminMenu,"sm_bp_props", TopMenuObject_Item, blocker_passes_Props, blocker_passes, "sm_bp_props", ADMIN_LEVEL);
	
	return;
}

public void Handle_Category(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayTitle, TopMenuAction_DisplayOption:
		{
			Format(buffer, maxlength, "Управление Minecraft");
		}
	}
}

public void blocker_passes_Props(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption :
		{
			Format(buffer, maxlength, "[Управление предметами]");
		}
		case TopMenuAction_SelectOption :
		{
			DisplayMenu(MainMenu, param, MENU_TIME_FOREVER);
		}
	}
}

public void blocker_passes_Save(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption :
		{
			Format(buffer, maxlength, "Сохранить предметы");
		}
		case TopMenuAction_SelectOption :
		{
			SaveAllProps(param);
		}
	}
}

public int MenuPropMenuHandler(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel :
		{
			if (param2 == MenuCancel_ExitBack)
			{
				if (BPAdminMenu != INVALID_HANDLE)
					DisplayTopMenu(BPAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_Select :
		{
		
			char s_Type[32];
			GetMenuItem(menu, param2, s_Type, sizeof(s_Type));
			
			if (StrEqual(s_Type, "PropsMenu", false))
			{
				DisplayMenu(PropsMenu, param1, MENU_TIME_FOREVER);
			}
			else if (StrEqual(s_Type, "ColorMenu", false))
			{
				DisplayMenu(ColorMenu, param1, MENU_TIME_FOREVER);
			}
			else if (StrEqual(s_Type, "SaveProps", false))
			{
				SaveAllProps(param1);
			}
			
		}
	}
	
	return 0;
}

public int PropMenuHandler(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel :
		{
			if (param2 == MenuCancel_ExitBack)
			{
				DisplayMenu(MainMenu, param1, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_Select :
		{
		
			char info[64];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			int ent = -1, index = -1, index2 = StringToInt(info);
			
			float g_fOrigin[3], g_fAngles[3];
			
			GetClientEyePosition(param1, g_fOrigin);
			GetClientEyeAngles(param1, g_fAngles);
			TR_TraceRayFilter(g_fOrigin, g_fAngles, MASK_SOLID, RayType_Infinite, Trace_FilterPlayers, param1);
			
			if(TR_DidHit(INVALID_HANDLE))
			{
			
				TR_GetEndPosition(g_fOrigin, INVALID_HANDLE);
				TR_GetPlaneNormal(INVALID_HANDLE, g_fAngles);
				GetVectorAngles(g_fAngles, g_fAngles);
				g_fAngles[0] += 90.0;
				
				if (!strcmp(info, "rote"))
				{
					DisplayMenu(RotateMenu, param1, MENU_TIME_FOREVER);
					return 0;
				}
				else if(!strcmp(info, "shift"))
				{
					DisplayMenu(ShiftMenu, param1, MENU_TIME_FOREVER);
					return 0;
				
				}
				else if (!strcmp(info, "remove"))
				{
					if ((ent = GetClientAimTarget(param1, false)) > MaxClients)
					{
						if ((index = FindValueInArray(EntityList, EntIndexToEntRef(ent))) != -1)
						{
							RemoveFromArray(EntityList, index);
							DeleteProp(ent);
							PrintHintText(param1, "Предмет успешно удалён!");
						}
					}
					else
					{
						PrintToChat(param1, "\x05[Minecraft]\x01 Неверный предмет!");
					}
				}
				else if(!strcmp(info, "scale"))
				{
					DisplayMenu(ScaleMenu, param1, MENU_TIME_FOREVER);
					return 0;
				}
				else
				{
					CreateEntity(g_fOrigin, g_fAngles, Props[index2]);
					PrintHintText(param1, "Блокирующая перегородка успешно\nустановлена!");
				}
				DisplayMenuAtItem(menu, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
			}
		}
	}
	
	return 0;
}

public int PropRoteMenuHandle(Handle menu, MenuAction action, int client, int param2)
{
	switch (action){
		case MenuAction_Cancel :
		{
			if (param2 == MenuCancel_ExitBack)
			{
				DisplayMenu(PropsMenu, client, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_Select :
		{
		
			char info[64];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			float RotateVec[3];
			int entity = GetClientAimTarget2(client, false);
			
			if (entity > MaxClients)
			{
			
				GetEntPropVector(entity, Prop_Send, "m_angRotation", RotateVec);
				
				if (StrEqual(info, "RotateX+1")){
					RotateVec[0] = RotateVec[0] + 1.0;
				}else if (StrEqual(info, "RotateX-1")){
					RotateVec[0] = RotateVec[0] - 1.0;
				}else if (StrEqual(info, "RotateY+1")){
					RotateVec[1] = RotateVec[1] + 1.0;
				}else if (StrEqual(info, "RotateY-1")){
					RotateVec[1] = RotateVec[1] - 1.0;
				}else if (StrEqual(info, "RotateZ+1")){
					RotateVec[2] = RotateVec[2] + 1.0;
				}else if (StrEqual(info, "RotateZ-1")){
					RotateVec[2] = RotateVec[2] - 1.0;
				}
				
				TeleportEntity(entity, NULL_VECTOR, RotateVec, NULL_VECTOR);	
			}
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		}
	}
	
	return 0;
}

public int PropShiftMenuHandle(Handle menu, MenuAction action, int client, int param2)
{
	switch (action){
		case MenuAction_Cancel :
		{
			if (param2 == MenuCancel_ExitBack)
			{
				DisplayMenu(PropsMenu, client, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_Select :
		{
		
			char info[64];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			float ShiftVec[3];
			int entity = GetClientAimTarget2(client, false);
			
			if (entity > MaxClients)
			{
			
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", ShiftVec);
				
				if (StrEqual(info, "ShiftX+1"))
				{
					ShiftVec[0] = ShiftVec[0] + 1.0;
				}
				else if (StrEqual(info, "ShiftX-1"))
				{
					ShiftVec[0] = ShiftVec[0] - 1.0;
				}
				else if (StrEqual(info, "ShiftY+1"))
				{
					ShiftVec[1] = ShiftVec[1] + 1.0;
				}
				else if (StrEqual(info, "ShiftY-1"))
				{
					ShiftVec[1] = ShiftVec[1] - 1.0;
				}
				else if (StrEqual(info, "ShiftZ+1"))
				{
					ShiftVec[2] = ShiftVec[2] + 1.0;
				}
				else if (StrEqual(info, "ShiftZ-1"))
				{
					ShiftVec[2] = ShiftVec[2] - 1.0;
				}
				
				TeleportEntity(entity, ShiftVec, NULL_VECTOR, NULL_VECTOR);	
			}
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		}
	}
	
	return 0;
}




public int MenuPropColorHandler(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel :
		{
			if (param2 == MenuCancel_ExitBack)
			{
				if (BPAdminMenu != INVALID_HANDLE)
				{
					DisplayMenu(MainMenu, param1, MENU_TIME_FOREVER);
				}
			}
		}
		case MenuAction_Select :
		{
		
			char s_Type[10];
			GetMenuItem(menu, param2, s_Type, sizeof(s_Type));
			
			int ent = -1;
			
			if ((ent = GetClientAimTarget(param1, false)) > MaxClients)
			{
				if (!strcmp(s_Type, "color1"))
				{
					SetEntityColor(ent, {255, 0, 0, 255});
				}
				else if (!strcmp(s_Type, "color2"))
				{
					SetEntityColor(ent, {0, 255, 0, 255});
				}
				else if (!strcmp(s_Type, "color3"))
				{
					SetEntityColor(ent, {0, 0, 255, 255});
				}
				else if (!strcmp(s_Type, "color4"))
				{
					SetEntityColor(ent, {255, 255, 0, 255});
				}
				else if (!strcmp(s_Type, "color7"))
				{
					SetEntityColor(ent, {255, 255, 255, 228});
				}
				else if (!strcmp(s_Type, "color8"))
				{
					SetEntityColor(ent, {255, 255, 255, 128});
				}
				else if (!strcmp(s_Type, "color9"))
				{
					SetEntityColor(ent, {255, 255, 255, 0});
				}
				
				
			}
			
			DisplayMenuAtItem(menu, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		}
	}
	
	return 0;
}

public int MenuPropScaleHandler(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel :
		{
			if (param2 == MenuCancel_ExitBack)
			{
				if (BPAdminMenu != INVALID_HANDLE)
				{
					DisplayMenu(MainMenu, param1, MENU_TIME_FOREVER);
				}
			}
		}
		case MenuAction_Select :
		{
			int ent = -1;
			
			if ((ent = GetClientAimTarget(param1, false)) > MaxClients)
			{
				SetEntPropFloat(ent, Prop_Send, "m_flModelScale", float(param2 + 1) * 0.25);
			}
			
			DisplayMenuAtItem(menu, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		}
	}
	
	return 0;
}

void SpawnBlocks()
{
	float pos[3], ang[3]; int entity, scale, color[4];
	char buffer[16], Models[256], s_text[256];
	
	if (PropMapData.GotoFirstSubKey())
	{
		do
		{
			PropMapData.GetVector("Position", pos);
			PropMapData.GetVector("Angles", ang);
			PropMapData.GetString("Model", Models, sizeof(Models));
			PropMapData.GetString("Text", s_text, sizeof(s_text));
			PropMapData.GetString("Colors", buffer, sizeof(buffer));
			scale = PropMapData.GetNum("Scale", 100);
			
			StringToColor(buffer, color);
			
			if ((entity = CreateEntity(pos, ang, Models, scale)) != -1)
			{
				SetEntityColor(entity, color);
			}
		}
		while (PropMapData.GotoNextKey());
	}
	
	PropMapData.Rewind();
}

int CreateEntity(const float pos[3], const float ang[3], const char[] model, int scale = 100)
{
	int entity = CreateEntityByName("prop_dynamic_override");
	
	if (entity == -1)
	{
		return -1;
	}
	
	if(!IsModelPrecached(model))
	{
		return -1;
	}
	
	char buffer[32];
	Format(buffer, sizeof(buffer), "BpModelId%d", entity);
	
	SetEntityModel(entity, model);
	DispatchKeyValue(entity, "targetname", buffer);
	DispatchKeyValue(entity, "Solid", "6");
	DispatchSpawn(entity);
	
	TeleportEntity(entity, pos, ang, NULL_VECTOR);
	SetEntPropFloat(entity, Prop_Send, "m_flModelScale", float(scale) / 100.0);
	
	PushArrayCell(EntityList, EntIndexToEntRef(entity));
	
	return entity;
}

public bool Trace_FilterPlayers(int entity, int contentsMask, int data)
{
	if(entity != data && entity > MaxClients)
	{
		return true;
	}
	return false;
}

public bool TRFilter_AimTarget(int entity, int mask, int client)
{
    return (entity != client);
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask, int client)
{
	return ((entity > MaxClients) || !entity);
}


void ClearPropMapData(KeyValues hKeyValues)
{
	hKeyValues.Rewind();
	
	if (hKeyValues.GotoFirstSubKey())
	{
		do
		{
			hKeyValues.DeleteThis();
		}
		while (hKeyValues.GotoNextKey());
	}
	hKeyValues.Rewind();
	
	return;
}

void SaveAllProps(int client)
{
	ClearPropMapData(PropMapData);
	
	int index = 1;
	char buffer_modelsname[PLATFORM_MAX_PATH], buffer_2[64], colors[16]; int ent, scale, color[4]; float pos[3], ang[3];
			
	char path[PLATFORM_MAX_PATH];
	GetCurrentMap(path, sizeof(path));
	BuildPath(Path_SM, path, sizeof(path), "data/blocker_passes/%s.txt", path);
	
	for (int i; i < GetArraySize(EntityList); i++)
	{
		
		ent = EntRefToEntIndex(GetArrayCell(EntityList, i));
		
		if (ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
		{
			
			scale = RoundToNearest(GetEntPropFloat(ent, Prop_Send, "m_flModelScale") * 100.0);
			GetEntPropString(ent, Prop_Data, "m_ModelName", buffer_modelsname, sizeof(buffer_modelsname));
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
			GetEntPropVector(ent, Prop_Send, "m_angRotation", ang);
			GetEntityRenderColor2(ent, color);
			ColorToString(color, colors, sizeof(colors));
			
			IntToString(index, buffer_2, sizeof(buffer_2));
			if(PropMapData.JumpToKey(buffer_2, true))
			{
			
				PropMapData.SetVector("Position", pos);
				PropMapData.SetVector("Angles", ang);
				PropMapData.SetString("Model", buffer_modelsname);
				PropMapData.SetString("colors", colors);
				PropMapData.SetNum("Scale", scale);
				PropMapData.SetString("Text", "");
				
				char buffer[32], outBuffer[2][8];
				GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
				ExplodeString(buffer, "_", outBuffer, 2, 16, false);
	
				PropMapData.Rewind();
				
				index++;
			}
		}
	}
	
	PropMapData.ExportToFile(path);
	PropMapData.Rewind();
	
	if (client == 0)
	{
		return;
	}
	
	PrintHintText(client, "Координаты\nуспешно сохранены.\nВсего %d предмета!", index - 1);
	DisplayTopMenu(BPAdminMenu, client, TopMenuPosition_LastCategory);
	
	return;
}
void DeleteProp(int entity)
{
	char dname[16];
	Format(dname, sizeof(dname), "dis_%d", entity);
	DispatchKeyValue(entity, "targetname", dname);
	int diss = CreateEntityByName("env_entity_dissolver");
	DispatchKeyValue(diss, "dissolvetype", "3");
	DispatchKeyValue(diss, "target", dname);
	AcceptEntityInput(diss, "Dissolve");
	AcceptEntityInput(diss, "kill");
	
	return;
}

void LoadPropsMenu()
{
	PropsMenu = new Menu(PropMenuHandler);
	PropsMenu.SetTitle("| Меню предметов |");
	SetMenuExitButton(PropsMenu, true);
	PropsMenu.ExitBackButton = true;
	
	char file[255];
	KeyValues hKeyValues = new KeyValues("Props");
	BuildPath(Path_SM, file, sizeof(file), "data/blocker_passes/props_menu.txt");
	hKeyValues.ImportFromFile(file);
	int menu_items = 0;
	int reqmenuitems = 2;
	
	if (hKeyValues.GotoFirstSubKey())
	{
		int index = 0;
		char buffer[255];
		char bufferindex[5];
		do
		{
			hKeyValues.GetString("model", Props[index], 256);
			
			hKeyValues.GetSectionName(buffer, sizeof(buffer));
			IntToString(index, bufferindex, sizeof(bufferindex));
			PropsMenu.AddItem(bufferindex, buffer);
			index++;
			menu_items++;
			if (menu_items == reqmenuitems)
			{
				menu_items = 0;
				PropsMenu.AddItem("", 	"", ITEMDRAW_SPACER);
				PropsMenu.AddItem("shift", 	"[Сдвинуть]");
				PropsMenu.AddItem("rote", 	"[Повернуть]");
				PropsMenu.AddItem("scale", 	"[Изменить размер]");
				PropsMenu.AddItem("remove", 	"[Удалить]");
			}
		}
		while (hKeyValues.GotoNextKey());
	}
	delete hKeyValues;
	
	return;
}

stock bool GetPlayerEye(int client, float pos[3])
{
	float vAngles[3], vOrigin[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer, client);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return true;
	}
	CloseHandle(trace);
	return false;
}

stock void RotateYaw(float angles[3], float degree)
{
    float direction[3], Float:normal[3];
    GetAngleVectors( angles, direction, NULL_VECTOR, normal );
    
    new Float:sin = Sine( degree * 0.01745328 );
    new Float:cos = Cosine( degree * 0.01745328 );
    new Float:a = normal[0] * sin;
    new Float:b = normal[1] * sin;
    new Float:c = normal[2] * sin;
    new Float:x = direction[2] * b + direction[0] * cos - direction[1] * c;
    new Float:y = direction[0] * c + direction[1] * cos - direction[2] * a;
    new Float:z = direction[1] * a + direction[2] * cos - direction[0] * b;
    direction[0] = x;
    direction[1] = y;
    direction[2] = z;
    
    GetVectorAngles( direction, angles );

    float up[3];
    GetVectorVectors( direction, NULL_VECTOR, up );

    float roll = GetAngleBetweenVectors( up, normal, direction );
    angles[2] += roll;
}

int GetClientAimTarget2(int client, bool only_clients = true)
{
    float eyeloc[3], ang[3];
    GetClientEyePosition(client, eyeloc);
    GetClientEyeAngles(client, ang);
    TR_TraceRayFilter(eyeloc, ang, MASK_SOLID, RayType_Infinite, TRFilter_AimTarget, client);
	
    int entity = TR_GetEntityIndex();

    if (only_clients)
	{
        if (entity >= 1 && entity <= MaxClients)
		{
            return entity;
		}
    }
	else
	{
        if (entity > 0)
		{
            return entity;
		}
    }
    return -1;
}

stock float GetAngleBetweenVectors( const float vector1[3], const float vector2[3], const float direction[3] )
{
    float vector1_n[3], vector2_n[3], direction_n[3], cross[3];
    NormalizeVector( direction, direction_n );
    NormalizeVector( vector1, vector1_n );
    NormalizeVector( vector2, vector2_n );
    float degree = ArcCosine( GetVectorDotProduct( vector1_n, vector2_n ) ) * 57.29577951;
    GetVectorCrossProduct( vector1_n, vector2_n, cross );
    
    if ( GetVectorDotProduct( cross, direction_n ) < 0.0 )
	{
        degree *= -1.0;
    }

    return degree;
}

stock void GetEntityRenderColor2(int entity, int color[4])
{
	int offset = GetEntSendPropOffs(entity, "m_clrRender");
	
	if (offset <= 0){
		ThrowError("GetEntityColor not supported by this mod");
	}
	
	color[0] = GetEntData(entity, offset, 1);
	color[1] = GetEntData(entity, offset + 1, 1);
	color[2] = GetEntData(entity, offset + 2, 1);
	color[3] = GetEntData(entity, offset + 3, 1);
}

int SetEntityColor(int entity, int color[4] = {-1, ...})
{
	int dummy_color[4]; 
	
	GetEntityRenderColor2(entity, dummy_color);
	
	for (int i = 0; i <= 3; i++)
	{
		if (color[i] != -1)
		{
			dummy_color[i] = color[i];
		}
	}
	
	SetEntityRenderColor(entity, dummy_color[0], dummy_color[1], dummy_color[2], dummy_color[3]);
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
}

bool StringToColor(const char[] str, int color[4], int defvalue = -1)
{
	bool result = false;
	char Splitter[4][64];
	if (ExplodeString(str, " ", Splitter, sizeof(Splitter), sizeof(Splitter[])) == 4 && String_IsNumeric(Splitter[0]) && String_IsNumeric(Splitter[1]) && String_IsNumeric(Splitter[2]) && String_IsNumeric(Splitter[3]))
	{
		color[0] = StringToInt(Splitter[0]);
		color[1] = StringToInt(Splitter[1]);
		color[2] = StringToInt(Splitter[2]);
		color[3] = StringToInt(Splitter[3]);
		result = true;
	}
	else
	{
		color[0] = defvalue;
		color[1] = defvalue;
		color[2] = defvalue;
		color[3] = defvalue;
	}
	return result;
}

void ColorToString(const int color[4], char[] buffer, int size)
{
	Format(buffer, size, "%d %d %d %d", color[0], color[1], color[2], color[3]);
}

bool String_IsNumeric(const char[] str)
{
	int x = 0;
	int numbersFound = 0;

	if (str[x] == '+' || str[x] == '-'){
		x++;
	}

	while (str[x] != '\0')
	{
		if (IsCharNumeric(str[x]))
		{
			numbersFound++;
		}
		else
		{
			return false;
		}
		x++;
	}
	if (!numbersFound){
		return false;
	}
	return true;
}