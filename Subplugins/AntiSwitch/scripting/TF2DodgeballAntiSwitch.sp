#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#include <tfdb>

#define PLUGIN_NAME        "[TFDB] Anti switch"
#define PLUGIN_AUTHOR      "x07x08"
#define PLUGIN_DESCRIPTION "Locks the target of any rocket"
#define PLUGIN_VERSION     "1.0.0"
#define PLUGIN_URL         "https://github.com/x07x08/TF2-Dodgeball-Modified"

int g_iTarget[MAXPLAYERS + 1] = {-1, ...};
ConVar g_hCvarBotOnly;

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
	g_hCvarBotOnly = CreateConVar("tf_dodgeball_switch_bot", "1", "Lock targets only for bots?", _, true, 0.0, true, 1.0);
}

public void OnClientDisconnect(int iClient)
{
	g_iTarget[iClient] = -1;
}

public void OnClientConnected(int iClient)
{
	g_iTarget[iClient] = -1;
}

public Action TFDB_OnRocketDeflectPre(int iIndex, int iEntity, int iOwner, int &iTarget)
{
	int iPreviousTarget = EntRefToEntIndex(g_iTarget[iOwner]);
	
	if ((iPreviousTarget == -1) ||
	    !IsPlayerAlive(iPreviousTarget) ||
	    (!(TFDB_GetRocketFlags(iIndex) & RocketFlag_IsNeutral) && (GetClientTeam(iOwner) == GetClientTeam(iPreviousTarget))))
	{
		g_iTarget[iOwner] = EntIndexToEntRef(iTarget);
		iPreviousTarget = iTarget;
	}
	
	if (!g_hCvarBotOnly.BoolValue || IsFakeClient(iOwner))
	{
		iTarget = iPreviousTarget;
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}
