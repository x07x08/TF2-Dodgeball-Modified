#pragma newdecls required

#include <sourcemod>

ConVar g_hCvarPreventionEnabled;
bool g_bClientEnabled[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "Airblast push prevention",
	author = "BloodyNightmare, Mitchell, added friagram's flag method",
	description = "Prevents users from pushing each other by airblasting.",
	version = "1.0",
	url = "https://github.com/x07x08/TF2_Dodgeball_Modified"
};

public void OnPluginStart()
{
	g_hCvarPreventionEnabled = CreateConVar("tf_dodgeball_airblast", "1", "Enable the plugin?", _, true, 0.0, true, 1.0);
	RegConsoleCmd("sm_ab", CmdAirblastPrevention, "Toggles push prevention.");
	HookEvent("player_spawn", OnPlayerSpawn);
	g_hCvarPreventionEnabled.AddChangeHook(CvarHook)
}

public Action OnPlayerSpawn(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
	if (g_hCvarPreventionEnabled.BoolValue && (GetClientTeam(iClient) >= 2) && g_bClientEnabled[iClient] && !(GetEntityFlags(iClient) & FL_NOTARGET))
	{
		SetEntityFlags(iClient, GetEntityFlags(iClient) | FL_NOTARGET);
	}
	
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

void ToggleAirblastPrevention(int iClient)
{
	if (g_bClientEnabled[iClient] ? !(GetEntityFlags(iClient) & FL_NOTARGET) : !!(GetEntityFlags(iClient) & FL_NOTARGET))
	{
		SetEntityFlags(iClient, g_bClientEnabled[iClient] ? GetEntityFlags(iClient) | FL_NOTARGET : GetEntityFlags(iClient) & ~FL_NOTARGET);
	}
}

public void CvarHook(ConVar hConVar, const char[] strOldValue, const char[] strNewValue)
{
	bool bConVar = hConVar.BoolValue;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient))
		{
			continue;
		}
		if (IsPlayerAlive(iClient) && g_bClientEnabled[iClient] && bConVar ? !(GetEntityFlags(iClient) & FL_NOTARGET) : !!(GetEntityFlags(iClient) & FL_NOTARGET))
		{
			SetEntityFlags(iClient, bConVar ? GetEntityFlags(iClient) | FL_NOTARGET : GetEntityFlags(iClient) & ~FL_NOTARGET);
		}
	}
}