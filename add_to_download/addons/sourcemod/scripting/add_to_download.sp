#include <sourcemod>
#include <sdktools_stringtables>

#pragma newdecls required

public Plugin myinfo = 
{
	name	= "Add To Download [Edited]",
	author	= "wS",
	version	= "1.2.3"
};

public void OnPluginStart()
{
	RegServerCmd("add_to_download", Command_Add);
}

public Action Command_Add(int iArgs)
{
	if(iArgs > 0)
	{
		char szBuffer[256];
		GetCmdArg(1, szBuffer, 256);
		LoadPath(szBuffer);
	}
	return Plugin_Handled;
}

public void OnMapStart()
{
	File hFile = OpenFile("cfg/add_to_download.txt", "rt");
	if(hFile)
	{
		char szBuffer[256];
		while (!hFile.EndOfFile() && hFile.ReadLine(szBuffer, 256))
		{
			LoadPath(szBuffer);
		}
		delete hFile;
	}
}

void LoadPath(char[] sEntry)
{
	int length;
	if ((length = TrimString(sEntry)) && sEntry[0] != '/')
	{
		ReplaceString(sEntry, 256, "\\", "/", true);
		if (DirExists(sEntry))
		{
			if (sEntry[length-1] == '/') { sEntry[length-1] = 0; }
			LoadFromDir(sEntry);
		}
		else if (ExtAllowed(sEntry, length)) {
			AddFileToDownloadsTable(sEntry);
		}
	}
}

void LoadFromDir(const char[] sDir)
{
	DirectoryListing hDir = OpenDirectory(sDir);
	if (hDir)
	{
		char sEntry[128], sPath[256];FileType t;
		while (hDir.GetNext(sEntry, 128, t))
		{
			switch(t)
			{
				case FileType_File:
				{
					if(ExtAllowed(sEntry, strlen(sEntry)))
					{
						FormatEx(sPath, sizeof(sPath), "%s/%s", sDir, sEntry);
						AddFileToDownloadsTable(sPath);
					
					}
				}
				case FileType_Directory:
				{
					if(strcmp(sEntry, ".", true) && strcmp(sEntry, "..", true))
					{
						FormatEx(sPath, sizeof(sPath), "%s/%s", sDir, sEntry);
						LoadFromDir(sPath);
					}
				}
			}
		}
		delete hDir;
	}
}

bool ExtAllowed(const char[] s, int length)
{
	int i = length;
	while (--i > -1)
	{
		if (s[i] == '.') 
		{
			return i > 0 && ((i+1) != length) && strcmp(s[i+1], "ztmp", false) && strcmp(s[i+1], "bz2", false);
		}
	}
	return false;
}