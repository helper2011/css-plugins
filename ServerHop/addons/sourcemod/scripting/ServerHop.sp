#include <sourcemod>
#include <socket>

#pragma newdecls required

const int MAX_SERVERS = 10;
static const float REFRESH_TIME = 60.0;
static const float SERVER_TIMEOUT = 10.0;

#define A2S_INFO "\xFF\xFF\xFF\xFF\x54Source Engine Query"
#define A2S_SIZE 25

#define DEBUG_MODE 0

int			Servers, 
			Port[MAX_SERVERS],
			CurrentAdvertServer = -1;
char		Name[MAX_SERVERS][256], 
			ServerAddress[MAX_SERVERS][16],
			Info[MAX_SERVERS][256];
Handle		socket[MAX_SERVERS];
bool		socketError[MAX_SERVERS];
	
ConVar		DelayAdvert;

#if DEBUG_MODE 1
char DebugLogFile[PLATFORM_MAX_PATH];

void DebugMsg(const char[] sMsg, any ...)
{
	static char szBuffer[512];
	VFormat(szBuffer, 512, sMsg, 2);
	LogToFile(DebugLogFile, szBuffer);
}
#define DebugMessage(%0) DebugMsg(%0);


#else
#define DebugMessage(%0)
#endif


enum struct ByteReader {
	int data[1024];
	int size;
	int offset;

	void SetData(const char[] data, int dataSize, int offset) {
		for (int i = 0; i < dataSize; ++i) {
			this.data[i] = data[i];
		}
		this.data[dataSize] = 0;
		this.size = dataSize;
		this.offset = offset;
	}

	int GetByte() {
		return this.data[this.offset++];
	}

	void GetString(char[] str = "", int size = 0) {
		int j = 0;
		for (int i = this.offset; i < this.size; ++i, ++j) {
			if (j < size) {
				str[j] = this.data[i];
			}

			if (this.data[i] == '\x0') {
				break;
			}
		}

		this.offset += j + 1;
	}
}

public Plugin myinfo =
{
	name = "Server Hop",
	author = "[GRAVE] rig0r [Edited]",
	description = "Provides live server info with join option",
	version = "0.8.2",
	url = "http://www.gravedigger-company.nl"
};

public void OnPluginStart()
{
	#if DEBUG_MODE 1
	BuildPath(Path_SM, DebugLogFile, 256, "logs/Servers.log");
	#endif
	LoadTranslations("common.phrases");
	LoadTranslations("serverhop.phrases");
	DelayAdvert = CreateConVar("sm_hop_advertisement_interval", "60.0");
	AutoExecConfig(true, "plugin.serverhop");

	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, 256, "configs/serverhop.cfg" );
	KeyValues hKeyValues = new KeyValues("Servers");
	
	if(!hKeyValues.ImportFromFile(szBuffer) || !hKeyValues.GotoFirstSubKey())
	{
		SetFailState("Config file \"%s\" doesnt exists...", szBuffer);
	}
	int iIp = FindConVar("hostip").IntValue, iPort = FindConVar("hostport").IntValue;

	char buffer[16];
	int ips[4];
	ips[0] = (iIp >> 24) & 0x000000FF;
	ips[1] = (iIp >> 16) & 0x000000FF;
	ips[2] = (iIp >> 8) & 0x000000FF;
	ips[3] = iIp & 0x000000FF;

	Format(buffer, sizeof(buffer), "%i.%i.%i.%i", ips[0], ips[1], ips[2], ips[3]);
	do
	{
		hKeyValues.GetSectionName(Name[Servers], 256);
		hKeyValues.GetString("address", ServerAddress[Servers], 16);
		Port[Servers] = hKeyValues.GetNum("port", 27015);
		if(strcmp(ServerAddress[Servers], buffer, false) || Port[Servers] != iPort)
		{
			Servers++;
		}
	}
	while (hKeyValues.GotoNextKey() && Servers < MAX_SERVERS);
	delete hKeyValues;
	
	if(Servers == 0)
	{
		SetFailState("No servers");
	}
	
	RegConsoleCmd("sm_hop", Command_Servers);
	RegConsoleCmd("sm_servers", Command_Servers);
	RefreshServerInfo(null);
	CreateTimer(REFRESH_TIME, RefreshServerInfo, _, TIMER_REPEAT);
}

public void OnConfigsExecuted()
{
	StartAdvertTimer();
}

void StartAdvertTimer()
{
	float fValue = DelayAdvert.FloatValue;
	if(fValue > 0.0)
	{
		CreateTimer(fValue, Timer_Advert, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Command_Servers(int iClient, int iArgs)
{
	if(iClient == 0 || IsFakeClient(iClient))
		return Plugin_Continue;
		
	Menu hMenu = new Menu(MenuH, MenuAction_End | MenuAction_Select);
	hMenu.SetTitle("%T", "SelectServer", iClient);
	for(int i; i < Servers; i++)
	{
		hMenu.AddItem("", Info[i]);
	}
	DebugMessage("Menu: %L", iClient)
	hMenu.Display(iClient, 0);
	return Plugin_Handled;
}

public int MenuH(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete hMenu;
		}
		case MenuAction_Select:
		{
			AskConnectMenu(iClient, iItem);
		}
	}
	return 0;
}

void AskConnectMenu(int iClient, int iServerId)
{
	DebugMessage("Ask: %L (%s)", iClient, Name[iServerId])
	char szBuffer[256], szBuffer2[16];
	IntToString(iServerId, szBuffer2, 16);
	SetGlobalTransTarget(iClient);
	Menu hMenu = new Menu(AskMenuH, MenuAction_End | MenuAction_Select);
	hMenu.SetTitle("%t", "Ask menu title", Info[iServerId]);
	FormatEx(szBuffer, 256, "%t", "Yes");
	hMenu.AddItem(szBuffer2, szBuffer);
	FormatEx(szBuffer, 256, "%t", "No");
	hMenu.AddItem("", szBuffer);
	hMenu.ExitBackButton = false;
	hMenu.ExitButton = true;
	hMenu.Display(iClient, 0);
}

public int AskMenuH(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete hMenu;
		}
		case MenuAction_Select:
		{
			switch(iItem)
			{
				case 0:
				{
					char szBuffer[16];
					hMenu.GetItem(0, szBuffer, 16);
					int iServerId = StringToInt(szBuffer);
					DebugMessage("Connect: %L (%s)", iClient, Name[iServerId])
					PrintToChatAll("\x01[\x03hop\x01] %t", "HopNotification", iClient, Name[iServerId]);
					ClientCommand(iClient, "redirect %s:%i", ServerAddress[iServerId], Port[iServerId]);
				}
				case 1:
				{
					Command_Servers(iClient, 0);
				}
			}
		}
	}
	return 0;
}

public Action RefreshServerInfo(Handle timer)
{
	for (int i; i < Servers; i++) 
	{
		Info[i][0] = 0;
		socketError[i] = false;
		socket[i] = SocketCreate(SOCKET_UDP, OnSocketError);
		SocketSetArg(socket[i], i);
		SocketConnect(socket[i], OnSocketConnected, OnSocketReceive, OnSocketDisconnected, ServerAddress[i], Port[i]);
	}

	CreateTimer(SERVER_TIMEOUT, CleanUp);
	return Plugin_Continue;
}

public Action CleanUp(Handle timer)
{
	for (int i; i < Servers; i++) 
	{
		if (!Info[i][0] && !socketError[i] ) 
		{
			//LogError("Server %s:%i is down: no timely reply received", ServerAddress[i], Port[i]);
			CloseHandle(socket[i]);
		}
	}
	return Plugin_Continue;
}

public Action Timer_Advert(Handle hTimer)
{
	if(++CurrentAdvertServer >= Servers)
		CurrentAdvertServer = 0;
		
	if(!Info[CurrentAdvertServer][0])
	{
		for(int i = CurrentAdvertServer + 1; i < Servers; i++)
		{
			if(Info[i][0])
			{
				CurrentAdvertServer = i;
				break;
			}
		}
		if(!Info[CurrentAdvertServer][0])
		{
			for(int i; i < CurrentAdvertServer; i++)
			{
				if(Info[i][0])
				{
					CurrentAdvertServer = i;
					break;
				}
			}
		}
		
		if(!Info[CurrentAdvertServer][0])
		{
			StartAdvertTimer();
			return Plugin_Continue;
		}
	}
	
	PrintToChatAll("\x04[\x03hop\x04]\x01 %t", "Advert", Info[CurrentAdvertServer]);
	StartAdvertTimer();
	return Plugin_Continue;
}

public void OnSocketConnected(Handle sock, int iServerId)
{
	SocketSend(sock, A2S_INFO, A2S_SIZE);
}

stock int GetByte(const char[] receiveData, int offset )
{
	return receiveData[offset];
}

stock char[] GetString(char[] receiveData, int dataSize, int offset)
{
	char serverStr[256];
	for (int i = offset, j; i < dataSize; i++ ) 
	{
		serverStr[j] = receiveData[i];
		j++;
		if ( receiveData[i] == 0) 
		{
			break;
		}
	}
	return serverStr;
}

public void OnSocketReceive(Handle sock, char[] data, const int dataSize, int iServerId)
{
	ByteReader byteReader;
	byteReader.SetData(data, dataSize, 4); // begin at 5th byte, index 4

	// header
	if (byteReader.GetByte() == 'A') { // challenge response received
		static char reply[A2S_SIZE + 4] = A2S_INFO;

		for (int i = A2S_SIZE, j = byteReader.offset; i < sizeof(reply); ++i, ++j) {
			reply[i] = data[j];
		}
		
		SocketSend(sock, reply, sizeof(reply));

		return;
	}

	// skip protocol
	byteReader.offset += 1;

	char hostName[64];
	byteReader.GetString(hostName, sizeof(hostName));

	char mapName[80];
	byteReader.GetString(mapName, sizeof(mapName));

	// skip game directory
	byteReader.GetString();

	// skip game description
	byteReader.GetString();

	// skip gameid
	byteReader.offset += 2;

	int players = byteReader.GetByte();

	int maxPlayers = byteReader.GetByte();

	int bots = byteReader.GetByte();

	FormatEx(Info[iServerId], 256, "%s - %s (%i/%i)", Name[iServerId], mapName, players + bots, maxPlayers);
	delete socket[iServerId];
}

public void OnSocketDisconnected(Handle sock, int iServerId)
{
	delete socket[iServerId];
}

public void OnSocketError(Handle sock, const int errorType, const int errorNum, int iServerId)
{
	//LogError("Server %s:%i is down: socket error %i (errno %i)", ServerAddress[iServerId], Port[iServerId], errorType, errorNum);
	socketError[iServerId] = true;
	delete socket[iServerId];
}