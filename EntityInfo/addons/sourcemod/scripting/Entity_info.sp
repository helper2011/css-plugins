#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name		= "Entity info",
	version		= "1.0",
	description	= "",
	author		= "hEl"
};

public void OnPluginStart()
{
	RegAdminCmd("entity_list", EntityList, ADMFLAG_RCON);
	RegAdminCmd("whoent", WhoEnt, ADMFLAG_RCON);
	RegAdminCmd("nearents", NearEntities, ADMFLAG_RCON);
	RegAdminCmd("tpent", TeleportEntity_Command, ADMFLAG_RCON);
	RegAdminCmd("gotoent", GoToEnt, ADMFLAG_RCON);
	RegAdminCmd("findent", FindEntity, ADMFLAG_RCON);
	RegAdminCmd("delent", DeleteEntity, ADMFLAG_RCON);
	RegAdminCmd("getentmodel", GetEntityModel, ADMFLAG_RCON);

}

public Action GetEntityModel(int iClient, int iArgs)
{
	if(iArgs == 1)
	{
		char szBuffer[256];
		GetCmdArg(1, szBuffer, 64);
		int iEntity = StringToInt(szBuffer);
		
		if(IsValidEntity(iEntity))
		{
			GetEntPropString(iEntity, Prop_Data, "m_ModelName", szBuffer, 256);
			PrintToChat(iClient, szBuffer);
		}
	}
	return Plugin_Handled;
}

public Action DeleteEntity(int iClient, int iArgs)
{
	if(iArgs == 1)
	{
		char szBuffer[64];
		GetCmdArg(1, szBuffer, 64);
		int iEntity = StringToInt(szBuffer);
		
		if(iEntity && IsValidEntity(iEntity))
		{
			AcceptEntityInput(iEntity, "kill");
		}
	}
	return Plugin_Handled;
}

public Action FindEntity(int iClient, int iArgs)
{
	if(iArgs == 2)
	{
		char szBuffer[64];
		GetCmdArg(1, szBuffer, 64);
		int iMode = StringToInt(szBuffer);
		GetCmdArg(2, szBuffer, 64);
		switch(iMode)
		{
			case 1:
			{
				int iEntity = INVALID_ENT_REFERENCE;
		
				while((iEntity = FindEntityByClassname(iEntity, szBuffer)) != INVALID_ENT_REFERENCE)
				{
					GetPropInfo(iClient, iEntity, szBuffer);
				}
			}
			case 2:
			{
				if(!szBuffer[0])
					return Plugin_Handled;
				
				
				int iEntity = INVALID_ENT_REFERENCE;
		
				while((iEntity = FindEntityByClassname(iEntity, "*")) != INVALID_ENT_REFERENCE)
				{
					char szBuffer2[64];
					if((GetEntPropString(iEntity, Prop_Data, "m_iName", szBuffer2, 64)) && !strcmp(szBuffer, szBuffer2, false))
					{
						GetPropInfo(iClient, iEntity);
					}
				}
				
			}
			case 3:
			{
				int iEntity = INVALID_ENT_REFERENCE, iHammerID = StringToInt(szBuffer);
				
				if(iHammerID <= 0)
					return Plugin_Handled;
		
				while((iEntity = FindEntityByClassname(iEntity, "*")) != INVALID_ENT_REFERENCE)
				{
					if(iHammerID == GetEntProp(iEntity, Prop_Data, "m_iHammerID"))
					{
						GetPropInfo(iClient, iEntity);
					}
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action GoToEnt(int iClient, int iArgs)
{	
	char szBuffer[16];
	GetCmdArg(1, szBuffer, 16);
	int iEntity = StringToInt(szBuffer);
	if(IsValidEntity(iEntity))
	{
		float fPos[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPos);
		TeleportEntity(iClient, fPos, NULL_VECTOR, NULL_VECTOR);
	}

	return Plugin_Handled;
}

public Action TeleportEntity_Command(int iClient, int iArgs)
{
	if(iArgs < 2 || iArgs > 5)
		return Plugin_Handled;
		
	char szBuffer[64];
	GetCmdArg(1, szBuffer, 64);
	
	int iEntity = StringToInt(szBuffer);
	
	if(!IsValidEntity(iEntity))
		return Plugin_Handled;
	
	bool bSumma = true; float fPos[2][3];
	
	for(int i = 2; i <= iArgs; i++)
	{
		GetCmdArg(i, szBuffer, 64);
		if(iArgs < 5)
		{
			fPos[0][i - 2] = StringToFloat(szBuffer);
		}
		else
		{
			bSumma = view_as<bool>(StringToInt(szBuffer));
		}
	}
	
	if(bSumma)
	{
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fPos[1]);
		
		for(int i; i < 3; i++)
		{
			fPos[0][i] += fPos[1][i];
		}
	}
	
	TeleportEntity(iEntity, fPos[0], NULL_VECTOR, NULL_VECTOR);
	PrintToChat(iClient, "[Entity manager] Entity %i teleported to %f %f %f", iEntity, fPos[0][0], fPos[0][1], fPos[0][2]);
	
	return Plugin_Handled;
}

public Action NearEntities(int iClient, int iArgs)
{
	char szBuffer[64];
	GetCmdArg(1, szBuffer, 64);
	float fDistance = StringToFloat(szBuffer), fPos[2][3];
	GetClientAbsOrigin(iClient, fPos[0]);
	
	if(fDistance <= 0.0)
		fDistance = 100.0;
	if(iArgs != 2)
	{
		int iEntities = GetMaxEntities();
		for(int i = MaxClients + 1; i <= iEntities; i++)
		{
			if(IsValidEdict(i) && GetEntPropVector(i, Prop_Data, "m_vecOrigin", fPos[1]) && GetVectorDistance(fPos[0], fPos[1]) <= fDistance)
			{
				GetPropInfo(iClient, i);
			}
		}
	}
	else
	{
		GetCmdArg(2, szBuffer, 64);
		int iEntity = -1;
		
		while((iEntity = FindEntityByClassname(iEntity, szBuffer)) != -1)
		{
			if(IsValidEntity(iEntity) && GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fPos[1]) && GetVectorDistance(fPos[0], fPos[1]) <= fDistance)
			{
				GetPropInfo(iClient, iEntity);
			}
		}
	}
	return Plugin_Handled;
}

public Action WhoEnt(int iClient, int iArgs)
{
	float killer_origin[3], x_origin[3];
	GetClientEyePosition(iClient, killer_origin); GetClientEyeAngles(iClient, x_origin);
	TR_TraceRayFilter(killer_origin, x_origin, MASK_SOLID, RayType_Infinite, TraceFilter);
	int iIndex = TR_GetEntityIndex();
	
	if(iIndex && IsValidEntity(iIndex))
	{
		GetPropInfo(iClient, iIndex);
	}
	return Plugin_Handled;
}

public bool TraceFilter(int iValue, int iValue2)
{
	return (iValue > MaxClients);
}

public Action EntityList(int iClient, int iArgs)
{	
	PrintToChat(iClient, "ID (REFFERENCE) | HAMMER ID | TargetName | CLASSNAME | POSITION");
	
	if(iArgs == 0)
	{
		int iEntities = GetMaxEntities();
		for(int i; i <= iEntities; i++)
		{
			if(IsValidEntity(i)) 
			{
				GetPropInfo(iClient, i);
			}
		}
	}
	else
	{
		char szBuffer[64];
		GetCmdArg(1, szBuffer, 64);
		int iEntity = -1;
		
		while((iEntity = FindEntityByClassname(iEntity, szBuffer)) != -1)
		{
			if(IsValidEntity(iEntity))
			{
				GetPropInfo(iClient, iEntity);
			}
		}
	}
	return Plugin_Handled;
}


void GetPropInfo(int iClient, int iEntity, const char[] classname = "")
{
	char szBuffer[2][64]; float fPos[3];
	if(!classname[0])
	{
		GetEntityClassname(iEntity, szBuffer[1], 64);
	}
	
	GetEntPropString(iEntity, Prop_Data, "m_iName", szBuffer[0], 64);

	GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fPos);
	PrintToChat(iClient, "#%i | HID: %i | %s | %s | %f, %f, %f", iEntity, GetEntProp(iEntity, Prop_Data, "m_iHammerID"), szBuffer[0], classname[0] ? classname:szBuffer[1], fPos[0], fPos[1], fPos[2]);
}