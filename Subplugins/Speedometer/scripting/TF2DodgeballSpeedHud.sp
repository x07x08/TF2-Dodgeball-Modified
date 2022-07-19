#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <multicolors>
#include <clientprefs>

#include <tfdb>

#define PLUGIN_NAME        "[TFDB] Rocket Speedometer"
#define PLUGIN_AUTHOR      "x07x08"
#define PLUGIN_DESCRIPTION "Shows the speed of the last deflected rocket"
#define PLUGIN_VERSION     "1.0.0"
#define PLUGIN_URL         "https://github.com/x07x08/TF2-Dodgeball-Modified"

bool   g_bShowHud[MAXPLAYERS + 1];
Cookie g_hCookieShowHud;
Handle g_hHudSynchronizer;

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
}

public void OnMapEnd()
{
	delete g_hHudSynchronizer;
	
	UnhookEvent("teamplay_round_win", OnRoundEnd);
}

public void TFDB_OnRocketsConfigExecuted()
{
	g_hHudSynchronizer = CreateHudSynchronizer();
	
	HookEvent("teamplay_round_win", OnRoundEnd);
}

public void OnClientDisconnect(int iClient)
{
	g_bShowHud[iClient] = false;
}

public void OnClientConnected(int iClient)
{
	g_bShowHud[iClient] = true;
}

public void OnClientPutInServer(int iClient)
{
	if (AreClientCookiesCached(iClient))
	{
		OnClientCookiesCached(iClient);
	}
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
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient)) continue;
		
		ClearSyncHud(iClient, g_hHudSynchronizer);
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
	
	if (!g_bShowHud[iClient]) ClearSyncHud(iClient, g_hHudSynchronizer);
	
	CReplyToCommand(iClient, "%t", g_bShowHud[iClient] ? "Hud_Enabled" : "Hud_Disabled");
	
	return Plugin_Handled;
}

public Action TFDB_OnRocketDeflectPre(int iIndex)
{
	ShowRocketHud(iIndex);
	
	return Plugin_Continue;
}

public void TFDB_OnRocketCreated(int iIndex)
{
	ShowRocketHud(iIndex);
}

void ShowRocketHud(int iIndex)
{
	SetHudTextParams(-1.0, 0.9, 25.0, 255, 255, 255, 255);
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient)) continue;
		
		ClearSyncHud(iClient, g_hHudSynchronizer);
		
		if (!g_bShowHud[iClient]) continue;
		
		ShowSyncHudText(iClient, g_hHudSynchronizer, "%t", "Hud_Speedometer", TFDB_GetRocketMphSpeed(iIndex),
		                                                                      TFDB_GetRocketSpeed(iIndex),
		                                                                      TFDB_GetRocketDeflections(iIndex));
	}
}
