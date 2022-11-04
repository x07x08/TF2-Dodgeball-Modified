#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_AUTHOR "x07x08"
#define PLUGIN_VERSION "1.2.0"

#include <sourcemod>
#include <sdkhooks>
#include <collisionhook>

#include <tfdb>

ConVar g_hCvarHookDamage;
ConVar g_hCvarHookCollision;

public Plugin myinfo = 
{
	name = "[TFDB] Anti-Sniping & Anti-Teamkilling",
	author = PLUGIN_AUTHOR,
	description = "Blocks snipes and teamkills.",
	version = PLUGIN_VERSION,
	url = "https://github.com/x07x08/TF2-Dodgeball-Modified"
};

public void OnPluginStart()
{
	g_hCvarHookDamage    = CreateConVar("tf_dodgeball_as_damage", "1", "Hook damage for anti-sniping?", _, true, 0.0, true, 1.0);
	g_hCvarHookCollision = CreateConVar("tf_dodgeball_as_collision", "1", "Change player collisions for anti-sniping?", _, true, 0.0, true, 1.0);
}

public void OnClientPutInServer(int iClient)
{
	if (!TFDB_IsDodgeballEnabled()) return;
	
	SDKHook(iClient, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
}

public Action OnPlayerTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType)
{
	if (!TFDB_IsDodgeballEnabled() || !g_hCvarHookDamage.BoolValue) return Plugin_Continue;
	
	int iIndex = TFDB_FindRocketByEntity(iInflictor);
	
	if (iIndex != -1)
	{
		int iTarget = EntRefToEntIndex(TFDB_GetRocketTarget(iIndex));
		
		if (IsValidClient(iTarget) && (iVictim != iTarget))
		{
			fDamage = 0.0;
			
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public Action CH_PassFilter(int iEntity1, int iEntity2, bool &bResult)
{
	if (!TFDB_IsDodgeballEnabled() || !g_hCvarHookCollision.BoolValue) return Plugin_Continue;
	
	int iIndex1 = TFDB_FindRocketByEntity(iEntity1);
	int iIndex2 = TFDB_FindRocketByEntity(iEntity2);
	
	if (((iIndex1 != -1) && (EntRefToEntIndex(TFDB_GetRocketTarget(iIndex1)) != iEntity2))
	    || ((iIndex2 != -1) && (EntRefToEntIndex(TFDB_GetRocketTarget(iIndex2)) != iEntity1)))
	{
		bResult = false;
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

stock bool IsValidClient(int iClient, bool bAlive = false)
{
	return iClient >= 1 &&
	       iClient <= MaxClients &&
	       IsClientInGame(iClient) &&
	       (!bAlive || IsPlayerAlive(iClient));
}