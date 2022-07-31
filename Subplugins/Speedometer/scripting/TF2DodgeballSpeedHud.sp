#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <multicolors>
#include <clientprefs>
#include <tf2>

#include <tfdb>

#define PLUGIN_NAME        "[TFDB] Rocket Speedometer"
#define PLUGIN_AUTHOR      "x07x08"
#define PLUGIN_DESCRIPTION "Shows the speed of the last deflected rocket"
#define PLUGIN_VERSION     "1.1.0"
#define PLUGIN_URL         "https://github.com/x07x08/TF2-Dodgeball-Modified"

int    g_iLastRocket = -1;
bool   g_bShowHud[MAXPLAYERS + 1];
char   g_strMultiHudText[225]; // This seems to be limit for ShowHudText / ShowSyncHudText
Cookie g_hCookieShowHud;
Handle g_hHudTimer;
Handle g_hMainHudSync;
Handle g_hMultiHudSync;

public Plugin myinfo = 
{
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version     = PLUGIN_VERSION,
	url         = PLUGIN_URL
};

public void OnPluginStart()
{
	LoadTranslations("tfdb.phrases.txt");
	
	RegConsoleCmd("sm_rockethud", CmdToggleSpeedometer);
	RegConsoleCmd("sm_rocketspeedo", CmdToggleSpeedometer);
	
	g_hCookieShowHud = new Cookie("tfdb_rockethud", "Show rocket speedometer", CookieAccess_Protected);
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!AreClientCookiesCached(iClient)) continue;
		
		OnClientCookiesCached(iClient);
	}
	
	if (TFDB_IsDodgeballEnabled())
	{
		TFDB_OnRocketsConfigExecuted();
		
		if (TFDB_GetRoundStarted())
		{
			g_iLastRocket = FindLastRocket();
			g_strMultiHudText = "\0";
			
			g_hHudTimer = CreateTimer(0.1, HudTimerCallback, _, TIMER_REPEAT);
		}
	}
}

public void OnMapEnd()
{
	g_iLastRocket = -1;
	g_strMultiHudText = "\0";
	
	if (g_hHudTimer != null) KillTimer(g_hHudTimer);
	g_hHudTimer = null;
	
	delete g_hMainHudSync;
	delete g_hMultiHudSync;
	
	UnhookEvent("teamplay_round_win", OnRoundEnd);
	UnhookEvent("arena_round_start", OnSetupFinished);
}

public void TFDB_OnRocketsConfigExecuted()
{
	if (g_hMainHudSync  == null) g_hMainHudSync  = CreateHudSynchronizer();
	if (g_hMultiHudSync == null) g_hMultiHudSync = CreateHudSynchronizer();
	
	HookEvent("teamplay_round_win", OnRoundEnd);
	HookEvent("arena_round_start", OnSetupFinished);
}

public void OnClientDisconnect(int iClient)
{
	g_bShowHud[iClient] = false;
}

public void OnClientConnected(int iClient)
{
	g_bShowHud[iClient] = true;
}

public void OnClientCookiesCached(int iClient)
{
	char strValue[4]; g_hCookieShowHud.Get(iClient, strValue, sizeof(strValue));
	
	// Taken from FF2
	
	if (!strValue[0])
	{
		g_hCookieShowHud.Set(iClient, "1");
		strValue = "1";
	}
	
	g_bShowHud[iClient] = !!StringToInt(strValue);
}

public void OnRoundEnd(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	g_iLastRocket = -1;
	g_strMultiHudText = "\0";
	
	if (g_hHudTimer != null)
	{
		KillTimer(g_hHudTimer);
		g_hHudTimer = null;
	}
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient)) continue;
		
		ClearSyncHud(iClient, g_hMainHudSync);
		ClearSyncHud(iClient, g_hMultiHudSync);
	}
}

public void OnSetupFinished(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	if (BothTeamsPlaying() == true)
	{
		g_iLastRocket = -1;
		g_strMultiHudText = "\0";
		
		g_hHudTimer = CreateTimer(0.1, HudTimerCallback, _, TIMER_REPEAT);
	}
}

public Action CmdToggleSpeedometer(int iClient, int iArgs)
{
	if (iClient == 0)
	{
		ReplyToCommand(iClient, "Command is in-game only.");
		
		return Plugin_Handled;
	}
	
	if (!TFDB_IsDodgeballEnabled())
	{
		CReplyToCommand(iClient, "%t", "Command_Disabled");
		
		return Plugin_Handled;
	}
	
	g_bShowHud[iClient] = !g_bShowHud[iClient];
	
	char strValue[4]; IntToString(g_bShowHud[iClient], strValue, sizeof(strValue));
	g_hCookieShowHud.Set(iClient, strValue);
	
	if (!g_bShowHud[iClient])
	{
		ClearSyncHud(iClient, g_hMainHudSync);
		ClearSyncHud(iClient, g_hMultiHudSync);
	}
	
	CReplyToCommand(iClient, "%t", g_bShowHud[iClient] ? "Hud_Enabled" : "Hud_Disabled");
	
	return Plugin_Handled;
}

public Action TFDB_OnRocketDeflectPre(int iIndex)
{
	g_iLastRocket = iIndex;
	
	ShowMainRocketHudAll(iIndex);
	
	return Plugin_Continue;
}

public void TFDB_OnRocketCreated(int iIndex)
{
	g_iLastRocket = iIndex;
	
	ShowMainRocketHudAll(iIndex);
}

// https://forums.alliedmods.net/showthread.php?t=208847

public Action HudTimerCallback(Handle hTimer)
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient) || !g_bShowHud[iClient]) continue;
		
		g_strMultiHudText = "\0";
		
		for (int iIndex = 0; iIndex < MAX_ROCKETS; iIndex++)
		{
			if (!TFDB_IsValidRocket(iIndex)) continue;
			
			if (iIndex == g_iLastRocket)
			{
				ShowMainRocketHud(iClient, iIndex);
			}
			else
			{
				FormatMultiRocketHud(iClient, iIndex, g_strMultiHudText, sizeof(g_strMultiHudText));
			}
		}
		
		if (g_strMultiHudText[0])
		{
			SetHudTextParams(0.05, 0.05, 0.1, 255, 255, 255, 255, 0, 0.0, 0.12, 0.12);
			
			ShowSyncHudText(iClient, g_hMultiHudSync, g_strMultiHudText);
		}
	}
	
	return Plugin_Continue;
}

void ShowMainRocketHud(int iClient, int iIndex)
{
	SetHudTextParams(-1.0, 0.9, 0.1, 255, 255, 255, 255, 0, 0.0, 0.1, 0.1);
	
	ShowSyncHudText(iClient, g_hMainHudSync, "%t", "Hud_Speedometer", TFDB_GetRocketMphSpeed(iIndex),
	                                                                  TFDB_GetRocketSpeed(iIndex),
	                                                                  TFDB_GetRocketDeflections(iIndex),
	                                                                  iIndex,
	                                                                  GetRocketLongName(iIndex));
}

void ShowMainRocketHudAll(int iIndex)
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient) || !g_bShowHud[iClient]) continue;
		
		ShowMainRocketHud(iClient, iIndex);
	}
}

void FormatMultiRocketHud(int iClient, int iIndex, char[] strBuffer, int iMaxLen)
{
	static int iLength;
	
	if ((iLength + strlen(strBuffer)) >= iMaxLen) return;
	
	iLength = strlen(strBuffer);
	
	Format(strBuffer, iMaxLen, "%s%T\n", strBuffer, "Hud_SpeedometerEx", iClient, TFDB_GetRocketMphSpeed(iIndex),
	                                                                              TFDB_GetRocketSpeed(iIndex),
	                                                                              TFDB_GetRocketDeflections(iIndex),
	                                                                              iIndex,
	                                                                              GetRocketLongName(iIndex));
	
	iLength = strlen(strBuffer) - iLength;
}

stock bool BothTeamsPlaying()
{
	bool bRedFound, bBluFound;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient) || !IsPlayerAlive(iClient)) continue;
		int iTeam = GetClientTeam(iClient);
		if (iTeam == view_as<int>(TFTeam_Red)) bRedFound = true;
		if (iTeam == view_as<int>(TFTeam_Blue)) bBluFound = true;
	}
	
	return bRedFound && bBluFound;
}

char[] GetRocketLongName(int iIndex)
{
	char strBuffer[32]; TFDB_GetRocketClassLongName(TFDB_GetRocketClass(iIndex), strBuffer, sizeof(strBuffer));
	
	return strBuffer;
}

int FindLastRocket()
{
	float fDeflectionTime;
	float fSpawnTime;
	int   iDeflectionIndex;
	int   iSpawnIndex;
	
	for (int iIndex = 0; iIndex < MAX_ROCKETS; iIndex++)
	{
		if (!TFDB_IsValidRocket(iIndex)) continue;
		
		if (TFDB_GetRocketLastDeflectionTime(iIndex) > fDeflectionTime)
		{
			iDeflectionIndex = iIndex;
			fDeflectionTime  = TFDB_GetRocketLastDeflectionTime(iIndex);
		}
		
		if (TFDB_GetLastSpawnTime(iIndex) > fSpawnTime)
		{
			iSpawnIndex = iIndex;
			fSpawnTime  = TFDB_GetLastSpawnTime(iIndex);
		}
	}
	
	return fDeflectionTime < fSpawnTime ? iSpawnIndex : iDeflectionIndex;
}
