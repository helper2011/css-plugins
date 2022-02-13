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
		if (iFileType == FileType_File && IsValidFile(plugin, strlen(plugin)))
		{
			FormatEx(szBuffer, sizeof(szBuffer), "%s/%s", path, plugin);
			ServerCommand("sm plugins %s %s", bToggle ? "load":"unload", szBuffer);
		}
		else if (iFileType == FileType_Directory && strcmp(plugin, ".", true) && strcmp(plugin, "..", true))
		{
			FormatEx(szBuffer, sizeof(szBuffer), "%s/%s", fullPath, plugin);
			FormatEx(szBuffer2, sizeof(szBuffer), "%s/%s", path, plugin);
			TogglePlugins(szBuffer, szBuffer2, bToggle);
		}
	}
	
	delete hDir;
}

bool IsValidFile(const char[] path, int length)
{
	int i = length;
	while (--i > -1)
	{
		if (path[i] == '.') {
			return i > 0 && ((i + 1) != length) && strcmp(path[i + 1], "ztmp", false) && strcmp(path[i + 1], "bz2", false);
		}
	}
	return false;
}