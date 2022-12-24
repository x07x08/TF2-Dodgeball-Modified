#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <multicolors>

#include <tfdb>

#define PLUGIN_NAME        "[TFDB] Airblast push prevention"
#define PLUGIN_AUTHOR      "BloodyNightmare, Mitchell, edited by x07x08"
#define PLUGIN_DESCRIPTION "Prevents users from pushing each other by airblasting."
#define PLUGIN_VERSION     "1.2.2"
#define PLUGIN_URL         "https://github.com/x07x08/TF2-Dodgeball-Modified"

ConVar g_hCvarCommandEnabled;
bool   g_bClientEnabled[MAXPLAYERS + 1] = {true, ...};
bool   g_bLoaded;

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
	
	g_hCvarCommandEnabled = CreateConVar("tf_dodgeball_ab_command", "1", "Allow people to toggle airblast prevention?\n Turning this off also enables airblast prevention on all clients.", _, true, 0.0, true, 1.0);
	
	RegConsoleCmd("sm_ab", CmdAirblastPrevention, "Toggles push prevention.");
	
	if (!TFDB_IsDodgeballEnabled()) return;
	
	TFDB_OnRocketsConfigExecuted();
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient)) continue;
		
		SDKHook(iClient, SDKHook_WeaponCanUse, WeaponCanUseCallback);
		
		// Enabled by default
		SetEntityFlags(iClient, GetEntityFlags(iClient) | FL_NOTARGET);
	}
}

public void TFDB_OnRocketsConfigExecuted()
{
	if (g_bLoaded) return;
	
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	
	g_hCvarCommandEnabled.AddChangeHook(CvarCommandCallback);
	
	g_bLoaded = true;
}

public void OnMapEnd()
{
	if (!g_bLoaded) return;
	
	UnhookEvent("player_spawn", OnPlayerSpawn);
	UnhookEvent("player_death", OnPlayerDeath);
	
	g_hCvarCommandEnabled.RemoveChangeHook(CvarCommandCallback);
	
	g_bLoaded = false;
}

public void OnPlayerSpawn(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
	if (g_bClientEnabled[iClient])
	{
		// Sound issue.
		SetEntityFlags(iClient, GetEntityFlags(iClient) | FL_NOTARGET);
	}
}

public void OnPlayerDeath(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
	// If you spectate an enemy, he will "airblast" you.
	// Forcefully adding FL_NOTARGET seems to fix the problem.
	SetEntityFlags(iClient, GetEntityFlags(iClient) | FL_NOTARGET);
}

public Action CmdAirblastPrevention(int iClient, int iArgs)
{
	if (iClient == 0)
	{
		ReplyToCommand(iClient, "Command is in-game only.");
		
		return Plugin_Handled;
	}
	
	if (!TFDB_IsDodgeballEnabled() || !g_hCvarCommandEnabled.BoolValue)
	{
		CReplyToCommand(iClient, "%t", "Command_Disabled");
		
		return Plugin_Handled;
	}
	
	g_bClientEnabled[iClient] = !g_bClientEnabled[iClient];
	
	if (IsPlayerAlive(iClient))
	{
		ToggleAirblastPrevention(iClient);
	}
	
	CReplyToCommand(iClient, "%t", g_bClientEnabled[iClient] ? "Dodgeball_AirblastPreventionCmd_Enabled" : "Dodgeball_AirblastPreventionCmd_Disabled");
	
	return Plugin_Handled;
}

public void OnClientDisconnect(int iClient)
{
	g_bClientEnabled[iClient] = false;
}

public void OnClientConnected(int iClient)
{
	g_bClientEnabled[iClient] = true;
}

public void OnClientPutInServer(int iClient)
{
	if (!g_bLoaded) return;
	
	SDKHook(iClient, SDKHook_WeaponCanUse, WeaponCanUseCallback);
}

// https://forums.alliedmods.net/showthread.php?t=265707
// SDKHook_WeaponCanUse fires for any weapon change (including pickup)

public Action WeaponCanUseCallback(int iClient, int iWeapon)
{
	int iFlags = GetEntityFlags(iClient);
	
	if (!(iFlags & FL_NOTARGET)) return Plugin_Continue;
	
	SetEntityFlags(iClient, iFlags & ~FL_NOTARGET);
	
	RequestFrame(ResetAirblastPrevention, GetClientUserId(iClient));
	
	return Plugin_Continue;
}

public void ResetAirblastPrevention(any iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if (iClient == 0 || !IsClientInGame(iClient) || !g_bClientEnabled[iClient]) return;
	
	SetEntityFlags(iClient, GetEntityFlags(iClient) | FL_NOTARGET);
}

void ToggleAirblastPrevention(int iClient)
{
	int iFlags = GetEntityFlags(iClient);
	
	SetEntityFlags(iClient, g_bClientEnabled[iClient] ? iFlags | FL_NOTARGET : iFlags & ~FL_NOTARGET);
}

public void CvarCommandCallback(ConVar hConVar, const char[] strOldValue, const char[] strNewValue)
{
	if (hConVar.BoolValue) return;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient)) continue;
		
		g_bClientEnabled[iClient] = true;
		
		if (IsPlayerAlive(iClient)) SetEntityFlags(iClient, GetEntityFlags(iClient) | FL_NOTARGET);
	}
}
