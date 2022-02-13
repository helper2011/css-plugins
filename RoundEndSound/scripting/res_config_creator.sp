#include <soundlib>

static const char g_szFile[] = "addons/sourcemod/configs/res.cfg";

const int MAX_SOUNDS = 100;

int Sounds;
char Title[MAX_SOUNDS][128], Sound[MAX_SOUNDS][256];
float Delay[MAX_SOUNDS];


public void OnPluginStart()
{
	if(!FileExists(g_szFile))
	{
		LoadSongs();
		CreateConfigFile();
	}
}

void LoadSongs()
{
	char szBuffer[64], file[256]; FileType type; Handle dir;
	File hFile = OpenFile("addons/sourcemod/configs/res.txt", "r");
	
	while (!hFile.EndOfFile() && hFile.ReadLine(szBuffer, 256))
	{
		if (TrimString(szBuffer) == 0)
			continue;
		
		ReplaceString(szBuffer, 64, "\\", "/");
		ReplaceString(szBuffer, 64, "sound/", "", false);
		Format(szBuffer, 64, "sound/%s", szBuffer);
		if ((dir = OpenDirectory(szBuffer)))	
		{
			while (ReadDirEntry(dir, file, 256, type))
			{
				if (type == FileType_File)
				{
					FormatEx(Sound[Sounds++], 64, "%s%s", szBuffer, file);
				}
			}
			continue;
		}
		
		Sound[Sounds++] = szBuffer;
	}
	
	delete dir;
	delete hFile;
	
	for(int i;i < Sounds; i++)
	{
		AddSong(i);
	}

}

void AddSong(int id)
{
	int iLen = strlen(Sound[id]);
	if(iLen < 4 || strcmp(Sound[id][iLen - 4], ".mp3", false))
		return;
	
	char szArtist[64], szTitle[64];
	Handle Song = OpenSoundFile(Sound[id][6]);
	if(Song != INVALID_HANDLE)
	{
		
		GetSoundArtist(Song, szArtist, 64);
		GetSoundTitle(Song, szTitle, 64);
		
		if(!(5.0 < (Delay[id] = GetSoundLengthFloat(Song)) < 20.0))
		{
			Delay[id] = 10.0;
		}
		
		FormatEx(Title[id], 128, "%s - %s", szArtist, szTitle);
		CloseHandle(Song);
	}
}

void CreateConfigFile()
{
	KeyValues hKeyValues = new KeyValues("Sounds");
	char szBuffer[16];
	for(int i;i < Sounds; i++)
	{
		IntToString(i, szBuffer, 16);
		hKeyValues.JumpToKey(szBuffer, true);
		hKeyValues.SetString("sound", Sound[i][6]);
		hKeyValues.SetString("title", Title[i]);
		hKeyValues.SetFloat("duration", Delay[i]);
		hKeyValues.GoBack();
	}
	hKeyValues.Rewind();
	hKeyValues.ExportToFile(g_szFile);
	delete hKeyValues;
}