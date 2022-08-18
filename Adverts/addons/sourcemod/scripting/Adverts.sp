#include <sourcemod>

#pragma newdecls required

ConVar Delay, Path;
Handle g_hTimer;
KeyValues g_hKeyValues;
int Adverts[64], ID;

char MC[32], C1[32], C2[32], PREFIX[64];

static const char Types[][] = {"hint", "chat", "center", "hud"};

public Plugin myinfo = 
{
	name		= "Adverts",
	version		= "1.0",
	description	= "Simple translatable ads",
	author		= "hEl"
}

public void OnPluginStart()
{
	LoadTranslations("adverts.phrases");
	Path = CreateConVar("advert_path", "configs/adverts.cfg");
	Delay = CreateConVar("advert_delay", "45.0");
	
	Path.AddChangeHook(OnConVarChange);
	
	RegServerCmd("advert_reload", AdvertReload);
	
	LoadAdvertData();
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	LoadAdvertData();
}

public Action AdvertReload(int iArgs)
{
	LoadAdvertData();
	return Plugin_Handled;
}

void LoadAdvertData()
{
	delete g_hTimer;
	delete g_hKeyValues;
	g_hKeyValues = new KeyValues("Adverts");
	
	char szBuffer[256];
	Path.GetString(szBuffer, 256);
	BuildPath(Path_SM, szBuffer, 256, szBuffer);
	if(!g_hKeyValues.ImportFromFile(szBuffer))
		SetFailState("[Adverts] Config file \"%s\" doesnt exists...", szBuffer);
		
	g_hKeyValues.GetString("C1", C1, 32);
	g_hKeyValues.GetString("C2", C2, 32);
	g_hKeyValues.GetString("MC", MC, 32);
	g_hKeyValues.GetString("TAG", PREFIX, 64);
	
	g_hKeyValues.GotoFirstSubKey();
	int iIndex, iCount, iTemp;
	do
	{
		Adverts[iCount++] = iCount;
	}
	while (g_hKeyValues.GotoNextKey() && iCount < 64);
	for(int i; i < iCount; i++)
	{
		iIndex = GetRandomInt(i, iCount - 1);
		iTemp = Adverts[iIndex];
		Adverts[iIndex] = Adverts[i];
		Adverts[i] = iTemp;
	}
	
	if(iCount < 64)
	{
		Adverts[iCount] = 0;
	}
	
	g_hTimer = CreateTimer(Delay.FloatValue, Timer_Advert);
}

public Action Timer_Advert(Handle hTimer)
{
	g_hTimer = null;
	char szBuffer[256];
	IntToString(Adverts[(++ID > 63 || !Adverts[ID]) ? (ID = 0):ID], szBuffer, 16);
	g_hKeyValues.Rewind();
	g_hKeyValues.JumpToKey(szBuffer);
	
	int iLanguage[10], iLanguages, iSymbol;
	g_hKeyValues.GetString("langid", szBuffer, 256, "-1");
	
	while((iSymbol = FindCharInString(szBuffer, '_', true)) != -1 && iLanguages < 10)
	{
		iLanguage[iLanguages++] = StringToInt(szBuffer[iSymbol + 1]);
		szBuffer[iSymbol] = 0;
	}
	if(strcmp(szBuffer, "-1", false) != 0)
	{
		iLanguage[iLanguages++] = StringToInt(szBuffer);
	}
	
	
	bool Translate = view_as<bool>(g_hKeyValues.GetNum("translate"));
	for(int i;i < 4; i++)
	{
		g_hKeyValues.GetString(Types[i], szBuffer, 256);
		if(!szBuffer[0])
			continue;
		
		if(i == 3)
		{
			SendHudMessageAll(iLanguage, iLanguages, Translate ? "%t":"%s", szBuffer);
			continue;
		}
			
		
		for(int j = 1; j <= MaxClients; j++)
		{
			if(IsClientInGame(j) && !IsFakeClient(j) && IsValidClientLanguage(j, iLanguage, iLanguages))
			{
				
				switch(i)
				{
					case 0: PrintHintText2(		j, Translate ? "%t":"%s", szBuffer);
					case 1: PrintToChat2(		j, Translate ? "\x01%t":"\x01%s", szBuffer);
					case 2: PrintCenterText(	j, Translate ? "%t":"%s", szBuffer);
				}
			}
		}
	}
	
	g_hTimer = CreateTimer(g_hKeyValues.GetFloat("timer", Delay.FloatValue), Timer_Advert);
	return Plugin_Continue;
}

bool IsValidClientLanguage(int iClient, int[] iLanguage, int iLanguages)
{
	int iClientLanguage = GetClientLanguage(iClient);
	if(iLanguages == 0)
	{
		return true;
	}
	
	for(int k; k < iLanguages; k++)
	{
		if(iClientLanguage == iLanguage[k])
		{
			return true;
		}
	}
	
	return false;
}

void PrintHintText2(int iClient, const char[] message, any ...)
{
	int iLen = strlen(message) + 255;
	char[] szBuffer = new char[iLen];
	SetGlobalTransTarget(iClient);
	VFormat(szBuffer, iLen, message, 3);
	ReplaceString(szBuffer, iLen, "\\n", "\n");
	PrintHintText(iClient, szBuffer);
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
	ReplaceString(szBuffer, iSize, "{TAG}",	PREFIX);
	ReplaceString(szBuffer, iSize, "{C1}",	C1);
	ReplaceString(szBuffer, iSize, "{C2}",	C2);
	ReplaceString(szBuffer, iSize, "{MC}",	MC);

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

stock void SendHudMessageAll(int[] iLanguage, int iLanguages, const char[] format, any ...)
{
	int		rgba[2][4];
	
	g_hKeyValues.GetColor4("color1", rgba[0]);
	g_hKeyValues.GetColor4("color2", rgba[1]);

	int		channel = g_hKeyValues.GetNum("channel", 3),
			effect	= g_hKeyValues.GetNum("effect");
			
	float	posx = g_hKeyValues.GetFloat("posx", -1.0),
			posy = g_hKeyValues.GetFloat("posy", -1.0),
			fade = g_hKeyValues.GetFloat("fade", 1.0),
			fadeout = g_hKeyValues.GetFloat("fadeout", 1.0),
			hold = g_hKeyValues.GetFloat("hold", 1.5),
			fx = g_hKeyValues.GetFloat("fx", 5.0);
			
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i) || !IsValidClientLanguage(i, iLanguage, iLanguages))
			continue;
		
		SetGlobalTransTarget(i);
		int iLen = strlen(format) + 255;
		char[] szBuffer = new char[iLen];
		VFormat(szBuffer, iLen, format, 4);
		
		Handle hBf = StartMessageOne("HudMsg", i);
		BfWriteByte(hBf, channel);
		BfWriteFloat(hBf, posx);
		BfWriteFloat(hBf, posy);
		
		for(int j; j < 2; j++)
		{
			for(int k; k < 4; k++)
			{
				BfWriteByte(hBf, rgba[j][k]);
			}
		}
		
		BfWriteByte(hBf, effect);
		BfWriteFloat(hBf, fade);
		BfWriteFloat(hBf, fadeout);
		BfWriteFloat(hBf, hold);
		BfWriteFloat(hBf, fx);
		BfWriteString(hBf, szBuffer);
		EndMessage();
	}
}