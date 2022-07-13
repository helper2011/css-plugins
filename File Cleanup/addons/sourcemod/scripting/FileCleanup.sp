/**
 * =============================================================================
 * File Cleanup
 * Deletes obsolete files.
 * Based on DemoCleanup from this thread: https://hlmod.ru/posts/378098
 *
 * File:  FileCleanup.sp
 * Role:  -
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#include <sourcemod>
#include <files>

#pragma newdecls  required
#pragma semicolon 1

public Plugin myinfo = {
  description = "Deletes obsolete files. Based on Demo Cleanup.",
  version     = "1.0.3",
  author      = "CrazyHackGUT aka Kruzya",
  name        = "[ANY] File Cleanup",
  url         = "https://kruzya.me"
};

stock const char  g_szBasePath[]  = "logs/file_cleanup";

int   g_iLogPosition;
char  g_szLog[PLATFORM_MAX_PATH];
char  g_szConfig[PLATFORM_MAX_PATH];

#define Log(%0)     LogToFileEx(g_szLog, "[File Cleanup] " ... %0)
#define LogErr(%0)  LogError("[File Cleanup] " ... %0); Log(%0)

// Debug. Uncomment this line, comment another for enabling.
// #define Debug(%0)   Log("[DEBUG] " ... %0);
#define Debug(%0)

public void OnPluginStart() {
  BuildPath(Path_SM, g_szLog, sizeof(g_szLog), "%s", g_szBasePath);
  UTIL_MakeDirectory(g_szLog);

  g_iLogPosition = BuildPath(Path_SM, g_szLog, sizeof(g_szLog), "%s/000000.log", g_szBasePath);
  BuildPath(Path_SM, g_szConfig, sizeof(g_szConfig), "data/file_cleanup.cfg");

  // set padding
  // file name and extension: 4
  // datetime:                6
  // total:                   10
  g_iLogPosition -= 10;
}

bool bOnce;

public void OnMapStart() {

  if(bOnce)
    return;

  bOnce = true;
  // Append current date to log path...
  FormatTime(g_szLog[g_iLogPosition], sizeof(g_szLog)-g_iLogPosition, "%y%m%d");
  g_szLog[g_iLogPosition+6] = '.';

  // First, go to config.
  int iCol, iLine;
  SMCParser hSMC = new SMCParser();
  SMC_SetReaders(hSMC, OnNewSection, OnKeyValue, OnEndSection);
  SMCError iErr = SMC_ParseFile(hSMC, g_szConfig, iCol, iLine);
  CloseHandle(hSMC);

  // In this moment, we're already "deleted" all obsolete files.
  // So, we can relax and just write in log file error when processing parsing (if exists).
  if (iErr == SMCError_Okay) {
    return; // TOTALLY SUCCESS.
  }

  // LogErr() just a macro-function, so we prepare message before call.
  char szError[256];
  int iPos = FormatEx(szError, sizeof(szError), "We're got an error when processing configuration file (%s) on line %d, column %d: ", g_szConfig, iLine, iCol);
  SMC_GetErrorString(iErr, szError[iPos], sizeof(szError)-iPos);
  LogErr("%s", szError);
}

/**
 * Initiates a cleanup directory.
 *
 * @var szDirectory       Path to "cleanable" directory.
 * @var iCleanupTime      UNKNOWN.
 * @var eCleanupMode      File time mode for monitoring.
 * @var szFileEnding      If file name ends with this content, he will be deleted. If empty - ignored.
 * @var szFileStarts      If file name starts with this content, he will be deleted. If empty - ignored.
 * @var bIncludeSubdirs   Check subdirectories?
 */
void CleanDirectory(const char[] szDirectory, int iCleanupTime, FileTimeMode eCleanupMode, const char[] szFileEnding, const char[] szFileStarts, bool bIncludeSubdirs) {
  Debug("CleanDirectory(\"%s\", %d, %d, \"%s\", \"%s\", %d)", szDirectory, iCleanupTime, eCleanupMode, szFileEnding, szFileStarts, bIncludeSubdirs)

  int iMaxTime = GetTime() - iCleanupTime;
  DirectoryListing hDirectory = OpenDirectory(szDirectory);
  ArrayList hFilesToDelete = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));

  Debug("CleanDirectory(): iMaxTime   = %d", iMaxTime)
  Debug("CleanDirectory(): hDirectory = %x", hDirectory)

  char szEntry[PLATFORM_MAX_PATH];
  FileType eType;
  int iLength;
  int iTimeFile;

  bool bTriggered;

  while (ReadDirEntry(hDirectory, szEntry, sizeof(szEntry), eType)) {
    Debug("CleanDirectory(): ReadDirEntry() returned file type %d, file name %s", eType, szEntry)

    if (eType != FileType_File) {
      if (eType == FileType_Directory && bIncludeSubdirs) {
        if (strcmp(szEntry, ".") && strcmp(szEntry, "..")) {
          char szNewDirectory[PLATFORM_MAX_PATH];
          FormatEx(szNewDirectory, sizeof(szNewDirectory), "%s%s/", szDirectory, szEntry);

          // RECURSIVE!
          Log("We're allowed check subdirectories. Checking %s started.", szNewDirectory);
          CleanDirectory(szNewDirectory, iCleanupTime, eCleanupMode, szFileEnding, szFileStarts, bIncludeSubdirs);
        }
      }

      continue;
    }

    bTriggered = false;
    iLength = strlen(szEntry);

    Debug("CleanDirectory(): WORKING WITH %s (length %d)", szEntry, iLength)

    int iFileStartsLength = strlen(szFileStarts);
    int iFileEndingLength = strlen(szFileEnding);

    Debug("CleanDirectory(): iFileStartsLength = %d", iFileStartsLength)
    Debug("CleanDirectory(): iFileEndingLength = %d", iFileEndingLength)

    bTriggered = (
      (
        !szFileEnding[0] || (iFileEndingLength < iLength && !strncmp(szEntry[iLength-iFileEndingLength], szFileEnding, iFileEndingLength, true))
      ) && (
        !szFileStarts[0] || (iFileStartsLength < iLength && !strncmp(szEntry, szFileStarts, iFileStartsLength, true))
      )
    );

    Debug("CleanDirectory(): bTriggered = %d", bTriggered)
    Debug("CleanDirectory(): bTriggered statement: ((%d || (%d && %d)) && (%d || %d))", !szFileEnding[0], iFileEndingLength < iLength, !strncmp(szEntry[iLength-iFileEndingLength], szFileEnding, iFileEndingLength, true), !szFileStarts[0], iFileStartsLength < iLength, !strncmp(szEntry, szFileStarts, iFileStartsLength, true))

    // Skip file, if required.
    if (!bTriggered) {
      continue;
    }

    // Format the full path.
    char szFilePath[PLATFORM_MAX_PATH];
    FormatEx(szFilePath, sizeof(szFilePath), "%s%s", szDirectory, szEntry);

    // Check time.
    iTimeFile = GetFileTime(szFilePath, eCleanupMode);
    Debug("CleanDirectory(): GetFileTime(\"%s\", %d) == %d", szFilePath, eCleanupMode, iTimeFile)
    
    if (iTimeFile == -1 || iTimeFile > iMaxTime)
      continue;

    // THIS FILE SHOULD BE DELETED.
    Log("Mark %s as entry for deleting", szFilePath);

    PushArrayString(hFilesToDelete, szFilePath);
  }

  CloseHandle(hDirectory);
  if (GetArraySize(hFilesToDelete)) {
    RequestFrame(OnPurgeFiles, hFilesToDelete);
    return;
  }

  Log("Nothing to delete in %s.", szDirectory);
  CloseHandle(hFilesToDelete);
}

public void OnPurgeFiles(ArrayList hFilesToDelete) {
  Log("Starting cleanup...");

  char szEntry[PLATFORM_MAX_PATH];
  szEntry[0] = '/';
  int iCount = GetArraySize(hFilesToDelete);
  for (int i = iCount-1; i != -1; --i) {
    GetArrayString(hFilesToDelete, i, szEntry[1], sizeof(szEntry)-1);
    FileExists(szEntry) && DeleteFile(szEntry);
  }
}

/**
 * Parser callbacks.
 */
// const char[] szDirectory, int iCleanupTime, FileTimeMode eCleanupMode, const char[] szFileEnding, const char[] szFileStarts, bool bIncludeSubdirs
FileTimeMode  gc_eCleanupMode;
char          gc_szDirectory[PLATFORM_MAX_PATH];
char          gc_szFileStarts[PLATFORM_MAX_PATH];
char          gc_szFileEnding[PLATFORM_MAX_PATH];
bool          gc_bIncludeSubdirs;
int           gc_iCleanupTime;

char          gc_szKeyName[64];

public SMCResult OnNewSection(SMCParser hSMC, const char[] szName, bool bOptQuotes) {
  // Do cleanup in config variables.
  gc_eCleanupMode = FileTime_LastChange;
  gc_szDirectory[0] = gc_szFileStarts[0] = gc_szFileEnding[0] = 0;
  gc_bIncludeSubdirs = false;
  gc_iCleanupTime = 0;

  strcopy(gc_szKeyName, sizeof(gc_szKeyName), szName);
}

public SMCResult OnEndSection(SMCParser hSMC) {
  if (!gc_szDirectory[0]) {
    LogErr("Can't start cleanup with keyname %s: directory not passed.", gc_szKeyName);
    return;
  }

  if (!DirExists(gc_szDirectory)) {
    LogErr("Can't start cleanup with keyname %s: passed directory (%s) doesn't exists.", gc_szKeyName, gc_szDirectory);
    return;
  }

  if (gc_iCleanupTime < 1) {
    LogErr("Can't start cleanup with keyname %s: maximum lifetime for files not passed.", gc_szKeyName);
    return;
  }

  if (!UTIL_InArray(gc_eCleanupMode, {FileTime_LastChange, FileTime_Created, FileTime_LastAccess}, 3)) {
    LogErr("Detected error in cleanup with keyname %s: invalid timemode. Switching to default (last change)...", gc_szKeyName);
    gc_eCleanupMode = FileTime_LastChange;
  }

  CleanDirectory(gc_szDirectory, gc_iCleanupTime, gc_eCleanupMode, gc_szFileEnding, gc_szFileStarts, gc_bIncludeSubdirs);
}

public SMCResult OnKeyValue(SMCParser hSMC, const char[] szKey, const char[] szValue, bool bKeyQuotes, bool bValueQuotes) {
  if (!strcmp(szKey, "path", false)) {
    strcopy(gc_szDirectory, sizeof(gc_szDirectory), szValue);
    int iLength = strlen(szValue);

    if (szValue[iLength-1] != '/') {
      strcopy(gc_szDirectory[iLength], sizeof(gc_szDirectory), "/");
    }

    return;
  }

  if (!strcmp(szKey, "lifetime", false)) {
    gc_iCleanupTime = UTIL_ParseTime(szValue);
    return;
  }

  if (!strcmp(szKey, "starts_with", false)) {
    strcopy(gc_szFileStarts, sizeof(gc_szFileStarts), szValue);
    return;
  }

  if (!strcmp(szKey, "ends_with", false)) {
    strcopy(gc_szFileEnding, sizeof(gc_szFileEnding), szValue);
    return;
  }

  if (!strcmp(szKey, "include_subdirectories", false)) {
    gc_bIncludeSubdirs = (szValue[0] != '0');
    return;
  }

  if (!strcmp(szKey, "timemode", false)) {
    gc_eCleanupMode = view_as<FileTimeMode>(StringToInt(szValue));
    return;
  }
}

/**
 * UTILs
 */

#define FPERM_U_ALL   (FPERM_U_READ | FPERM_U_WRITE | FPERM_U_EXEC)
#define FPERM_G_ALL   (FPERM_G_READ | FPERM_G_WRITE | FPERM_G_EXEC)
#define FPERM_O_ALL   (FPERM_O_READ | FPERM_O_WRITE | FPERM_O_EXEC)

#define FPERM_DEFAULT (FPERM_U_ALL | FPERM_G_ALL | FPERM_O_EXEC)

/**
 * Creates a new directory, if not exists.
 *
 * @noreturn
 * @throws
 */
stock void UTIL_MakeDirectory(const char[] szPath) {
  if (DirExists(szPath)) {
    return;
  }

  if (CreateDirectory(szPath, FPERM_DEFAULT)) {
    return;
  }

  ThrowError("Can't create directory %s: Permission denied (?)", szPath);
}

// Copied from https://dev-cs.ru/posts/33403
stock int UTIL_ParseTime(const char[] szStr) {
  static int  iTime[]   = {60,  3600, 86400, 2592000, 31104000};
  static char szTime[]  = "ihdmy";

  int iDummy, iResult;
  int iPos, iTPos;
  char cData;

  while (szStr[iPos] != EOS) {
    cData = szStr[iPos++];

    if (cData >= '0' && cData <= '9') {
      iDummy = (iDummy * 10) + (cData - '0');
      continue;
    }

    for (iTPos = 0; iTPos < sizeof(iTime); ++iTPos) {
      if (cData == szTime[iTPos]) {
        iResult += iDummy * iTime[iTPos];
        iDummy = 0;
        break;
      }
    }
  }

  iResult += iDummy;
  return iResult;
}

stock bool UTIL_InArray(any item, any[] arr, int iArrSize) {
  for (int iItem = 0; iItem < iArrSize; ++iItem) {
    if (item == arr[iItem]) {
      return true;
    }
  }

  return false;
}
