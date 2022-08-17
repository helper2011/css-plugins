#include <sourcemod>

#pragma newdecls required

KeyValues Config;

char Tag[256], Colors[5][32];

public Plugin myinfo = 
{
    name = "Console Chat Manager",
    version = "1.0",
	description = "",
    author = "hEl",
	url = ""
};

public void OnPluginStart()
{
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, 256, "configs/consolechatmanager/settings.cfg");
	KeyValues hKeyValues = new KeyValues("Settings");
	if(!hKeyValues.ImportFromFile(szBuffer))
	{
		SetFailState("Config file \"%s\" not founded", szBuffer);
	}
	hKeyValues.GetString("Tag", Tag, 256);
	hKeyValues.GetString("Colors", szBuffer, 256);
	delete hKeyValues;
	
	ExplodeString(szBuffer, " ", Colors, 5, 32);
	AddCommandListener(OnSayCommand, "say");
}

public void OnMapStart()
{
	char szBuffer[256];
	GetCurrentMap(szBuffer, 256);
	StringToLowerCase(szBuffer);
	BuildPath(Path_SM, szBuffer, 256, "configs/consolechatmanager/%s.cfg", szBuffer);
	Config = new KeyValues("Messages");
	Config.ImportFromFile(szBuffer);
}

public void OnMapEnd()
{
	delete Config;
}

public Action OnSayCommand(int iClient, const char[] command, int iArgs)
{
	if(iClient)
	{
		return Plugin_Continue;
	}
	char szBuffer[256];
	GetCmdArgString(szBuffer, 256);
	
	if(Config && Config.JumpToKey(szBuffer))
	{
		char szBuffer2[256], szBuffer3[256], code[4];
		Config.GetString("default", szBuffer2, 256);
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				GetLanguageInfo(GetClientLanguage(i), code, 4);
				Config.GetString(code, szBuffer3, 256);
				PrintToChat2(i, "%s", szBuffer3[0] ? szBuffer3:szBuffer2[0] ? szBuffer2:szBuffer);
			}
		}
		
		Config.Rewind();
	}
	else
	{
		PrintToChatAll2(szBuffer);
	}
	
	
	return Plugin_Handled;
}

stock void PrintToChatAll2(const char[] message, any ...)
{
	int iLen = strlen(message) + 255;
	char[] szBuffer = new char[iLen];
	for(int i = 1;i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			SetGlobalTransTarget(i);
			VFormat(szBuffer, iLen, message, 2);
			SendMessage(i, szBuffer, 256);
		}
	}
}

stock void PrintToChat2(int iClient, const char[] message, any ...)
{
	int iLen = strlen(message) + 255;
	char[] szBuffer = new char[iLen];
	SetGlobalTransTarget(iClient);
	VFormat(szBuffer, iLen, message, 3);
	SendMessage(iClient, szBuffer, 256);
}



stock void SendMessage(int iClient, char[] szBuffer, int iSize)
{
	Format(szBuffer, iSize, "%s%s", Tag, szBuffer);
	ReplaceString(szBuffer, iSize, "{C1}",	Colors[0]);
	ReplaceString(szBuffer, iSize, "{C2}",	Colors[1]);
	ReplaceString(szBuffer, iSize, "{C3}",	Colors[2]);
	ReplaceString(szBuffer, iSize, "{C4}",	Colors[3]);
	ReplaceString(szBuffer, iSize, "{C5}",	Colors[4]);

	ReplaceString(szBuffer, iSize, "{C}",	"\x07");
	ReplaceString(szBuffer, iSize, "\\n", 	"\n");
		
	Handle buf = StartMessageOne("SayText2", iClient, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf) 
	{
		PbSetInt(buf, "ent_idx", iClient);
		PbSetBool(buf, "chat", true);
		PbSetString(buf, "msg_name", szBuffer);
		
		for(int k;k < 4;k++)	
			PbAddString(buf, "params", "");
	} 
	else 
	{
		BfWriteByte(buf, iClient); // Message author
		BfWriteByte(buf, true); // Chat message
		BfWriteString(buf, szBuffer); // Message text
	}
	EndMessage();
}

stock void StringToLowerCase(char[] sText)
{
	int iLen = strlen(sText);
	for(int i; i < iLen; i++)
	{
		if(IsCharUpper(sText[i]))
		{
			sText[i] = CharToLower(sText[i]);
		}
	}
}