#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_AUTHOR "x07x08"
#define PLUGIN_VERSION "1.1.1"

#include <sourcemod>
#include <sdkhooks>

#include <tfdb>

int  g_iSavedCollisionType[MAXPLAYERS + 1] = {-1, ...};
int  g_iSavedSolidFlags   [MAXPLAYERS + 1] = {-1, ...};

ConVar g_hCvarAntiSnipeEnabled;
ConVar g_hCvarHookDamage;
ConVar g_hCvarHookCollision;

enum Collision_Group_t // in const.h - m_CollisionGroup
{
    COLLISION_GROUP_NONE  = 0,
    COLLISION_GROUP_DEBRIS,             // Collides with nothing but world and static stuff
    COLLISION_GROUP_DEBRIS_TRIGGER,     // Same as debris, but hits triggers
    COLLISION_GROUP_INTERACTIVE_DEBRIS, // Collides with everything except other interactive debris or debris
    COLLISION_GROUP_INTERACTIVE,        // Collides with everything except interactive debris or debris         // Can be hit by bullets, explosions, players, projectiles, melee
    COLLISION_GROUP_PLAYER,                                                                                     // Can be hit by bullets, explosions, players, projectiles, melee
    COLLISION_GROUP_BREAKABLE_GLASS,
    COLLISION_GROUP_VEHICLE,
    COLLISION_GROUP_PLAYER_MOVEMENT,    // For HL2, same as Collision_Group_Player, for
                                        // TF2, this filters out other players and CBaseObjects
    COLLISION_GROUP_NPC,                // Generic NPC group
    COLLISION_GROUP_IN_VEHICLE,         // for any entity inside a vehicle                                      // Can be hit by explosions. Melee unknown.
    COLLISION_GROUP_WEAPON,             // for any weapons that need collision detection
    COLLISION_GROUP_VEHICLE_CLIP,       // vehicle clip brush to restrict vehicle movement
    COLLISION_GROUP_PROJECTILE,         // Projectiles!
    COLLISION_GROUP_DOOR_BLOCKER,       // Blocks entities not permitted to get near moving doors
    COLLISION_GROUP_PASSABLE_DOOR,      // ** sarysa TF2 note: Must be scripted, not passable on physics prop (Doors that the player shouldn't collide with)
    COLLISION_GROUP_DISSOLVING,         // Things that are dissolving are in this group
    COLLISION_GROUP_PUSHAWAY,           // ** sarysa TF2 note: I could swear the collision detection is better for this than NONE. (Nonsolid on client and server, pushaway in player code) // Can be hit by bullets, explosions, projectiles, melee

    COLLISION_GROUP_NPC_ACTOR,          // Used so NPCs in scripts ignore the player.
    COLLISION_GROUP_NPC_SCRIPTED = 19,  // USed for NPCs in scripts that should not collide with each other.

    LAST_SHARED_COLLISION_GROUP
};

enum SolidFlags_t // in const.h - m_usSolidFlags
{
    FSOLID_CUSTOMRAYTEST        = 0x0001,    // Ignore solid type + always call into the entity for ray tests
    FSOLID_CUSTOMBOXTEST        = 0x0002,    // Ignore solid type + always call into the entity for swept box tests
    FSOLID_NOT_SOLID            = 0x0004,    // Are we currently not solid?
    FSOLID_TRIGGER              = 0x0008,    // This is something may be collideable but fires touch functions
                                             // even when it's not collideable (when the FSOLID_NOT_SOLID flag is set)
    FSOLID_NOT_STANDABLE        = 0x0010,    // You can't stand on this
    FSOLID_VOLUME_CONTENTS      = 0x0020,    // Contains volumetric contents (like water)
    FSOLID_FORCE_WORLD_ALIGNED  = 0x0040,    // Forces the collision rep to be world-aligned even if it's SOLID_BSP or SOLID_VPHYSICS
    FSOLID_USE_TRIGGER_BOUNDS   = 0x0080,    // Uses a special trigger bounds separate from the normal OBB
    FSOLID_ROOT_PARENT_ALIGNED  = 0x0100,    // Collisions are defined in root parent's local coordinate space
    FSOLID_TRIGGER_TOUCH_DEBRIS = 0x0200,    // This trigger will touch debris objects

    FSOLID_MAX_BITS = 10
};

#define NEW_COLLISION  (COLLISION_GROUP_DEBRIS_TRIGGER)
#define NEW_SOLIDFLAGS (FSOLID_CUSTOMBOXTEST | FSOLID_NOT_STANDABLE)

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
	g_hCvarAntiSnipeEnabled = CreateConVar("tf_dodgeball_antisnipe", "1", "Enable anti-sniping?", _, true, 0.0, true, 1.0);
	g_hCvarHookDamage       = CreateConVar("tf_dodgeball_as_damage", "1", "Hook damage for anti-sniping?", _, true, 0.0, true, 1.0);
	g_hCvarHookCollision    = CreateConVar("tf_dodgeball_as_collision", "1", "Change player collisions for anti-sniping?", _, true, 0.0, true, 1.0);
	
	g_hCvarAntiSnipeEnabled.AddChangeHook(CvarHook);
	g_hCvarHookCollision.AddChangeHook(CvarHook);
	
	HookEvent("player_spawn", OnPlayerSpawn);
}

public void OnMapEnd()
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		g_iSavedCollisionType[iClient] = -1;
		g_iSavedSolidFlags[iClient]    = -1;
	}
}

public void OnClientDisconnect(int iClient)
{
	g_iSavedCollisionType[iClient] = -1;
	g_iSavedSolidFlags[iClient]    = -1;
}

public void OnClientPutInServer(int iClient)
{
	if (IsValidClient(iClient))
	{
		SDKHook(iClient, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
	}
}

public Action OnPlayerTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType)
{
	if (g_hCvarAntiSnipeEnabled.BoolValue && g_hCvarHookDamage.BoolValue)
	{
		int iIndex = TFDB_FindRocketByEntity(iInflictor);
		if (iIndex != -1)
		{
			int iTarget = EntRefToEntIndex(TFDB_GetRocketTarget(iIndex));
			if (IsValidClient(iVictim) && IsValidClient(iTarget) && (iVictim != iTarget))
			{
				fDamage = 0.0;
				
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}

public void OnPlayerSpawn(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
	if (GetClientTeam(iClient) >= 2)
	{
		if (g_iSavedCollisionType[iClient] == -1)
		{
			g_iSavedCollisionType[iClient] = GetEntProp(iClient, Prop_Send, "m_CollisionGroup");
		}
		
		if (g_iSavedSolidFlags[iClient] == -1)
		{
			g_iSavedSolidFlags[iClient] = GetEntProp(iClient, Prop_Send, "m_usSolidFlags");
		}
	}
}

public void CvarHook(ConVar hConVar, const char[] strOldValue, const char[] strNewValue)
{
	bool bEnable = hConVar.BoolValue;
	
	if (!bEnable)
	{
		for (int iIndex = 1; iIndex <= MaxClients; iIndex++)
		{
			if (IsClientInGame(iIndex) && IsPlayerAlive(iIndex))
			{
				if ((g_iSavedCollisionType[iIndex] != -1) && ((GetEntProp(iIndex, Prop_Send, "m_CollisionGroup")) == view_as<int>(NEW_COLLISION)))
				{
					SetEntProp(iIndex, Prop_Send, "m_CollisionGroup", g_iSavedCollisionType[iIndex]);
				}
				
				if ((g_iSavedSolidFlags[iIndex] != -1) && ((GetEntProp(iIndex, Prop_Send, "m_usSolidFlags")) == view_as<int>(NEW_SOLIDFLAGS)))
				{
					SetEntProp(iIndex, Prop_Send, "m_usSolidFlags", g_iSavedSolidFlags[iIndex]);
				}
			}
		}
	}
}

public void TFDB_OnRocketCreated()
{
	ToggleClientsCollision();
}

public void TFDB_OnRocketDeflect()
{
	ToggleClientsCollision();
}

public void TFDB_OnRocketNoTarget()
{
	ToggleClientsCollision();
}

void ToggleClientsCollision()
{
	if (!(g_hCvarAntiSnipeEnabled.BoolValue && g_hCvarHookCollision.BoolValue))
	{
		return;
	}
	
	bool[] bIsTarget = new bool[MaxClients + 1];
	int iRocketTarget = -1;
	
	for (int iRocketIndex = 0; iRocketIndex < MAX_ROCKETS; iRocketIndex++)
	{
		if (!TFDB_IsValidRocket(iRocketIndex)) continue;
		
		iRocketTarget = EntRefToEntIndex(TFDB_GetRocketTarget(iRocketIndex));
		if (IsValidClient(iRocketTarget, true))
		{
			bIsTarget[iRocketTarget] = true;
		}
	}
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient) && IsPlayerAlive(iClient))
		{
			if (bIsTarget[iClient])
			{
				if (g_iSavedCollisionType[iClient] != -1)
				{
					SetEntProp(iClient, Prop_Send, "m_CollisionGroup", g_iSavedCollisionType[iClient]);
				}
				
				if (g_iSavedSolidFlags[iClient] != -1)
				{
					SetEntProp(iClient, Prop_Send, "m_usSolidFlags", g_iSavedSolidFlags[iClient]);
				}
			}
			else
			{
				if (g_iSavedCollisionType[iClient] != -1)
				{
					SetEntProp(iClient, Prop_Send, "m_CollisionGroup", NEW_COLLISION);
				}
				
				if (g_iSavedSolidFlags[iClient] != -1)
				{
					SetEntProp(iClient, Prop_Send, "m_usSolidFlags", NEW_SOLIDFLAGS);
				}
			}
		}
	}
}

stock bool IsValidClient(int iClient, bool bAlive = false)
{
	return iClient >= 1 &&
	       iClient <= MaxClients &&
	       IsClientInGame(iClient) &&
	       (!bAlive || IsPlayerAlive(iClient));
}