#pragma semicolon 1

#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#pragma newdecls required

int originalWepIndex = -1;
int oldDeflects      = 0;

public Plugin myinfo =
{
	name        = "[TF2] FlameSoundFix",
	author      = "Walgrim",
	description = "Fix the annoying flame sound on player hurt",
	version     = "1.2.1",
	url         = "http://steamcommunity.com/id/walgrim/"
};

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int client, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3])
{
	// weapon is actually our SetEntPropEnt(entity, Prop_Send, "m_hOriginalLauncher", entity) on line 40
	if (originalWepIndex != -1 && IsEntityConnectedAClient(GetEntPropEnt(weapon, Prop_Send, "m_hLauncher")))
	{
		weapon = originalWepIndex;
	}
	return Plugin_Changed;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if ((StrEqual(classname, "tf_projectile_rocket") || StrEqual(classname, "tf_projectile_sentryrocket")))
	{
		originalWepIndex = -1;
		SetEntPropEnt(entity, Prop_Send, "m_hOriginalLauncher", entity);
		RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
	}
}

public void OnNextFrame(any entityRef)
{
	int entity = EntRefToEntIndex(entityRef);
	if (!IsValidEntity(entity) || entity == -1)
	{
		oldDeflects = 0;
		return;
	}
	int deflects = GetEntProp(entity, Prop_Send, "m_iDeflected");
	if (deflects > oldDeflects)
	{
		/*
		    So what is happening here ?
		    We know that this sound is produced by the attacker's weapon
		    When there's a deflect, m_hLauncher takes the weapon index of the attacker
		    And on impact that causes this sound (why idk but it's linked somehow)
		    What we are doing here is taking the weapon index on deflect and store it into our variable
		    Just after we change m_hLauncher to an another entity index so it's no more linked to our weapon
		    So now we just have to replace the wrong weapon index (our m_hOriginalLauncher) to the correct one on player hit
		 */
		originalWepIndex = GetEntPropEnt(entity, Prop_Send, "m_hLauncher");
		SetEntPropEnt(entity, Prop_Send, "m_hLauncher", GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"));
		oldDeflects = deflects;
	}
	RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
}

bool IsEntityConnectedAClient(int client)
{
	if (IsClientInGame(client) && 0 < client <= MaxClients)
	{
		return true;
	}
	return false;
}