#include <sourcemod>

#pragma newdecls required

public Plugin myinfo = 
{
	name		= "MapPluginsLoader",
	version		= "1.0",
	description	= "",
	author		= "hEl"
};

public void OnPluginEnd()
{
	OnMap(false);
}

public void OnMapStart()
{
	OnMap(true);
}

public void OnMapEnd()
{
	OnMap(false);
}

void OnMap(bool bToggle)
{
	char prefix[16], map[64], path[PLATFORM_MAX_PATH], fullPath[PLATFORM_MAX_PATH];
	GetCurrentMap(map, 64);
	if(!map[0])
	{
		return;
	}
	int iSymbol = FindCharInString(map, '_');
	if(iSymbol != -1)
	{
		strcopy(prefix, 16, map);
		prefix[iSymbol] = 0;
		FormatEx(path, sizeof(path), "disabled/%s", prefix);
		BuildPath(Path_SM, fullPath, sizeof(fullPath), "plugins/%s", path);
		TogglePlugins(fullPath, path, bToggle);
	}
	FormatEx(path, sizeof(path), "disabled/%s", map);
	BuildPath(Path_SM, fullPath, sizeof(fullPath), "plugins/%s", path);
	TogglePlugins(fullPath, path, bToggle);
}

void TogglePlugins(const char[] fullPath, const char[] path, bool bToggle)
{
	DirectoryListing hDir = OpenDirectory(fullPath);
	if (!hDir)
		return;
	
	char plugin[256], szBuffer[PLATFORM_MAX_PATH], szBuffer2[PLATFORM_MAX_PATH]; FileType iFileType;
	while (hDir.GetNext(plugin, 256, iFileType))
	{
		switch(iFileType)
		{
			case FileType_File:
			{

				if(strcmp(plugin, "references", false) == 0)
				{
					FormatEx(szBuffer, sizeof(szBuffer), "%s/%s", fullPath, plugin);
					File hFile = OpenFile(szBuffer, "r");
					if(hFile)
					{
						while(!hFile.EndOfFile())
						{
							if(!hFile.ReadLine(plugin, 256) || TrimString(plugin) <= 0)
								continue;

							ServerCommand("sm plugins %s %s", bToggle ? "load":"unload", plugin);
						}
						delete hFile;
					}
				}
				else
				{
					FormatEx(szBuffer, sizeof(szBuffer), "%s/%s", path, plugin);
					ServerCommand("sm plugins %s %s", bToggle ? "load":"unload", szBuffer);
				}
			}
			case FileType_Directory:
			{
				if (strcmp(plugin, ".", true) && strcmp(plugin, "..", true))
				{
					FormatEx(szBuffer, sizeof(szBuffer), "%s/%s", fullPath, plugin);
					FormatEx(szBuffer2, sizeof(szBuffer), "%s/%s", path, plugin);
					TogglePlugins(szBuffer, szBuffer2, bToggle);
				}
			}
		}
	}
	
	delete hDir;
}