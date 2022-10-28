#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

ConVar g_hCvarPreventionEnabled;
bool   g_bClientEnabled[MAXPLAYERS + 1] = {true, ...};

public Plugin myinfo =
{
	name        = "[TFDB] Airblast push prevention",
	author      = "BloodyNightmare, Mitchell, edited by x07x08",
	description = "Prevents users from pushing each other by airblasting.",
	version     = "1.1.0",
	url         = "https://github.com/x07x08/TF2-Dodgeball-Modified"
};

public void OnPluginStart()
{
	g_hCvarPreventionEnabled = CreateConVar("tf_dodgeball_airblast", "1", "Enable the plugin?", _, true, 0.0, true, 1.0);
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient))
		{
			SDKHook(iClient, SDKHook_WeaponCanUse, WeaponCanUseCallback);
			
			// Enabled by default
			if (IsPlayerAlive(iClient)) SetEntityFlags(iClient, GetEntityFlags(iClient) | FL_NOTARGET);
		}
	}
	
	RegConsoleCmd("sm_ab", CmdAirblastPrevention, "Toggles push prevention.");
	
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	
	g_hCvarPreventionEnabled.AddChangeHook(CvarHook);
}

public Action OnPlayerSpawn(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	int iFlags  = GetEntityFlags(iClient);
	
	if (g_hCvarPreventionEnabled.BoolValue &&
	    (GetClientTeam(iClient) >= 2) &&
	    g_bClientEnabled[iClient] &&
	    !(iFlags & FL_NOTARGET))
	{
		SetEntityFlags(iClient, iFlags | FL_NOTARGET);
	}
	
	return Plugin_Continue;
}

public Action OnPlayerDeath(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
	// If you spectate an enemy while having anti-airblast enabled, they will "airblast" you.
	// I don't know if this fixes the problem.
	SetEntityFlags(iClient, GetEntityFlags(iClient) & ~FL_NOTARGET);
	
	return Plugin_Continue;
}

public Action CmdAirblastPrevention(int iClient, int iArgs)
{
	if (iClient == 0 || (!IsClientInGame(iClient)))
	{
		return Plugin_Handled;
	}
	else if (g_hCvarPreventionEnabled.BoolValue)
	{
		g_bClientEnabled[iClient] = !g_bClientEnabled[iClient];
		
		if (IsPlayerAlive(iClient))
		{
			ToggleAirblastPrevention(iClient);
		}
		
		ReplyToCommand(iClient, "[SM] %s airblast push prevention.", g_bClientEnabled[iClient] ? "Enabled" : "Disabled");
	}
	else
	{
		ReplyToCommand(iClient, "[SM] Command disabled.");
	}
	
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
	SDKHook(iClient, SDKHook_WeaponCanUse, WeaponCanUseCallback);
}

// https://forums.alliedmods.net/showthread.php?t=265707
// SDKHook_WeaponCanUse fires for any weapon change (including pickup)

public Action WeaponCanUseCallback(int iClient, int iWeapon)
{
	int iFlags = GetEntityFlags(iClient);
	
	if (!(iFlags & FL_NOTARGET)) return Plugin_Continue;
	
	SetEntityFlags(iClient, iFlags & ~FL_NOTARGET);
	
	return Plugin_Continue;
}

void ToggleAirblastPrevention(int iClient)
{
	int iFlags = GetEntityFlags(iClient);
	
	if (g_bClientEnabled[iClient] ? !(iFlags & FL_NOTARGET) : !!(iFlags & FL_NOTARGET))
	{
		SetEntityFlags(iClient, g_bClientEnabled[iClient] ? iFlags | FL_NOTARGET : iFlags & ~FL_NOTARGET);
	}
}

public void CvarHook(ConVar hConVar, const char[] strOldValue, const char[] strNewValue)
{
	bool bConVar = hConVar.BoolValue;
	int iFlags;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient)) continue;
		
		iFlags = GetEntityFlags(iClient);
		
		if (IsPlayerAlive(iClient) &&
		    g_bClientEnabled[iClient] &&
		    bConVar ? !(iFlags & FL_NOTARGET) : !!(iFlags & FL_NOTARGET))
		{
			SetEntityFlags(iClient, bConVar ? iFlags | FL_NOTARGET : iFlags & ~FL_NOTARGET);
		}
	}
}