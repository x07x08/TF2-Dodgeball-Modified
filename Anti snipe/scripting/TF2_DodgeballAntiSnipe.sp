#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_AUTHOR "x07x08"
#define PLUGIN_VERSION "1.0"

#define MAX_ROCKETS 100

#include <sourcemod>
#include <sdkhooks>

int  g_iSavedCollisionType[MAXPLAYERS + 1] = {-1, ...};
int  g_iSavedSolidFlags   [MAXPLAYERS + 1] = {-1, ...};
int  g_iRocketTarget      [MAX_ROCKETS]    = {-1, ...};
bool g_bRocketIsValid     [MAX_ROCKETS];
int  g_iRocketEntity      [MAX_ROCKETS];
int  g_iLastCreatedRocket;

ConVar g_CvarAntiSnipeEnabled;
ConVar g_CvarHookDamage;
ConVar g_CvarHookCollision;

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
	FSOLID_CUSTOMRAYTEST		= 0x0001,	// Ignore solid type + always call into the entity for ray tests
	FSOLID_CUSTOMBOXTEST		= 0x0002,	// Ignore solid type + always call into the entity for swept box tests
	FSOLID_NOT_SOLID			= 0x0004,	// Are we currently not solid?
	FSOLID_TRIGGER				= 0x0008,	// This is something may be collideable but fires touch functions
											// even when it's not collideable (when the FSOLID_NOT_SOLID flag is set)
	FSOLID_NOT_STANDABLE		= 0x0010,	// You can't stand on this
	FSOLID_VOLUME_CONTENTS		= 0x0020,	// Contains volumetric contents (like water)
	FSOLID_FORCE_WORLD_ALIGNED	= 0x0040,	// Forces the collision rep to be world-aligned even if it's SOLID_BSP or SOLID_VPHYSICS
	FSOLID_USE_TRIGGER_BOUNDS	= 0x0080,	// Uses a special trigger bounds separate from the normal OBB
	FSOLID_ROOT_PARENT_ALIGNED	= 0x0100,	// Collisions are defined in root parent's local coordinate space
	FSOLID_TRIGGER_TOUCH_DEBRIS	= 0x0200,	// This trigger will touch debris objects

	FSOLID_MAX_BITS	= 10
};

public Plugin myinfo = 
{
	name = "[YADBP] Anti-Sniping & Anti-Teamkilling",
	author = PLUGIN_AUTHOR,
	description = "Blocks snipes and teamkills.",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	g_CvarAntiSnipeEnabled = CreateConVar("tf_dodgeball_antisnipe", "1", "Enable anti-sniping?", _, true, 0.0, true, 1.0);
	g_CvarHookDamage       = CreateConVar("tf_dodgeball_as_damage", "1", "Hook damage for anti-sniping?", _, true, 0.0, true, 1.0);
	g_CvarHookCollision    = CreateConVar("tf_dodgeball_as_collision", "1", "Change player collisions for anti-sniping?", _, true, 0.0, true, 1.0);
	
	g_CvarAntiSnipeEnabled.AddChangeHook(CvarHook);
	g_CvarHookCollision.AddChangeHook(CvarHook);
	
	HookEvent("player_spawn", OnPlayerSpawn);
	
	RegServerCmd("tf_dodgeball_nosnipe", CmdAntiSnipe, "Changes collision and / or damage on the target and other players accordingly.");
}

public void OnMapEnd()
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		g_iSavedCollisionType[iClient] = -1;
		g_iSavedSolidFlags[iClient]    = -1;
	}
	
	for (int iIndex = 0; iIndex < MAX_ROCKETS; iIndex++)
	{
		g_iRocketTarget[iIndex]  = -1;
		g_bRocketIsValid[iIndex] = false;
	}
}

public void OnClientDisconnect(int iClient)
{
	g_iSavedCollisionType[iClient] = -1;
	g_iSavedSolidFlags[iClient]    = -1;
	
	for (int iIndex = 0; iIndex < MAX_ROCKETS; iIndex++)
	{
		if (EntRefToEntIndex(g_iRocketTarget[iIndex]) == iClient)
		{
			g_iRocketTarget[iIndex] = -1;
		}
	}
}

public void OnClientPutInServer(int iClient)
{
	if (IsValidClient(iClient))
	{
		SDKHook(iClient, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
	}
}

public Action OnPlayerTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType, int &iWeapon, float fDamageForce[3], float fDamagePosition[3])
{
	if (g_CvarAntiSnipeEnabled.BoolValue && g_CvarHookDamage.BoolValue)
	{
		char strEntityClassname[256]; GetEntityClassname(iInflictor, strEntityClassname, sizeof(strEntityClassname));
		
		if (StrEqual(strEntityClassname, "tf_projectile_rocket") || StrEqual(strEntityClassname, "tf_projectile_sentryrocket"))
		{
			int iIndex = FindRocketByEntity(iInflictor);
			if (iIndex != -1)
			{
				int iTarget = EntRefToEntIndex(g_iRocketTarget[iIndex]);
				if (IsValidClient(iVictim) && IsValidClient(iTarget))
				{
					if ((iVictim != iTarget))
					{
						fDamage = 0.0;
						
						return Plugin_Changed;
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action OnPlayerSpawn(Event hEvent, char[] strEventName, bool bDontBroadcast)
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

public Action CmdAntiSnipe(int iArgs)
{
	if (iArgs >= 2 && g_CvarAntiSnipeEnabled.BoolValue)
	{
		char strBuffer[8]; int iTarget, iEntity;
		GetCmdArg(1, strBuffer, sizeof(strBuffer)); iTarget = StringToInt(strBuffer);
		GetCmdArg(2, strBuffer, sizeof(strBuffer)); iEntity = StringToInt(strBuffer);
		
		if (IsValidClient(iTarget, true))
		{
			int iIndex = FindRocketByEntity(iEntity);
			if (iIndex != -1)
			{
				g_iRocketTarget[iIndex] = EntIndexToEntRef(iTarget);
				if (g_CvarHookCollision.BoolValue)
				{
					bool bIsTarget[MAXPLAYERS + 1];
					int iRocketTarget = -1;
					
					for (int iRocketIndex = 0; iRocketIndex < MAX_ROCKETS; iRocketIndex++)
					{
						if (!IsValidRocket(iRocketIndex))
						{
							continue;
						}
						
						iRocketTarget = EntRefToEntIndex(g_iRocketTarget[iRocketIndex]);
						if (IsValidClient(iRocketTarget, true))
						{
							bIsTarget[iRocketTarget] = true;
						}
					}
					
					for (int iClient = 1; iClient <= MaxClients; iClient++)
					{
						if (IsValidClient(iClient, true))
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
									SetEntProp(iClient, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
								}
								
								if (g_iSavedSolidFlags[iClient] != -1)
								{
									SetEntProp(iClient, Prop_Send, "m_usSolidFlags", FSOLID_CUSTOMBOXTEST | FSOLID_NOT_SOLID | FSOLID_NOT_STANDABLE);
								}
							}
						}
					}
				}
			}
		}
	}
	else
	{
		PrintToServer(g_CvarAntiSnipeEnabled.BoolValue ? "Usage : tf_dodgeball_nosnipe <client>" : "Command Disabled");
	}
	
	return Plugin_Handled;
}

public void CvarHook(ConVar hConVar, const char[] strOldValue, const char[] strNewValue)
{
	bool bEnable = hConVar.BoolValue;
	
	if (!bEnable)
	{
		for (int iIndex = 1; iIndex <= MaxClients; iIndex++)
		{
			if (IsClientInGame(iIndex))
			{
				if (IsPlayerAlive(iIndex))
				{
					if ((g_iSavedCollisionType[iIndex] != -1) && ((GetEntProp(iIndex, Prop_Send, "m_CollisionGroup")) == view_as<int>(COLLISION_GROUP_DEBRIS)))
					{
						SetEntProp(iIndex, Prop_Send, "m_CollisionGroup", g_iSavedCollisionType[iIndex]);
					}
					
					if ((g_iSavedSolidFlags[iIndex] != -1) && ((GetEntProp(iIndex, Prop_Send, "m_usSolidFlags")) == view_as<int>(FSOLID_CUSTOMBOXTEST | FSOLID_NOT_SOLID | FSOLID_NOT_STANDABLE)))
					{
						SetEntProp(iIndex, Prop_Send, "m_usSolidFlags", g_iSavedSolidFlags[iIndex]);
					}
				}
			}
		}
	}
}

public void OnEntityCreated(int iEntity, const char[] strClassname)
{
	if (StrEqual(strClassname, "tf_projectile_rocket") || StrEqual(strClassname, "tf_projectile_sentryrocket"))
	{
		if (IsValidEntity(iEntity))
		{
			int iIndex = FindFreeRocketSlot();
			if (iIndex != -1)
			{
				g_bRocketIsValid[iIndex] = true;
				g_iRocketEntity[iIndex]  = EntIndexToEntRef(iEntity);
			}
		}
	}
}

public void OnEntityDestroyed(int iEntity)
{
	if (iEntity <= 0 || !IsValidEntity(iEntity)) return;
	
	char strEntityClassname[256]; GetEntityClassname(iEntity, strEntityClassname, sizeof(strEntityClassname));
	
	if (StrEqual(strEntityClassname, "tf_projectile_rocket") || StrEqual(strEntityClassname, "tf_projectile_sentryrocket"))
	{
		for (int iIndex = 0; iIndex < MAX_ROCKETS; iIndex++)
		{
			if (EntRefToEntIndex(g_iRocketEntity[iIndex]) == iEntity)
			{
				if (g_bRocketIsValid[iIndex])
				{
					g_bRocketIsValid[iIndex] = false;
				}
				
				if (g_CvarHookCollision.BoolValue)
				{
					int iTarget = EntRefToEntIndex(g_iRocketTarget[iIndex]);
					if (IsValidClient(iTarget, true))
					{
						if ((g_iSavedCollisionType[iTarget] != -1) && ((GetEntProp(iTarget, Prop_Send, "m_CollisionGroup")) == g_iSavedCollisionType[iTarget]))
						{
							SetEntProp(iTarget, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
						}
						
						if ((g_iSavedSolidFlags[iTarget] != -1) && ((GetEntProp(iTarget, Prop_Send, "m_usSolidFlags")) == g_iSavedSolidFlags[iTarget]))
						{
							SetEntProp(iTarget, Prop_Send, "m_usSolidFlags", FSOLID_CUSTOMBOXTEST | FSOLID_NOT_SOLID | FSOLID_NOT_STANDABLE);
						}
					}
				}
				
				if (g_iRocketTarget[iIndex] != -1)
				{
					g_iRocketTarget[iIndex] = -1;
				}
			}
		}
	}
}

bool IsValidRocket(int iIndex)
{
    if ((iIndex >= 0) && (g_bRocketIsValid[iIndex] == true))
    {
        if (EntRefToEntIndex(g_iRocketEntity[iIndex]) == -1)
        {
            g_bRocketIsValid[iIndex] = false;
            g_iRocketTarget[iIndex] = -1;
            return false;
        }
        return true;
    }
    return false;
}

int FindNextValidRocket(int iIndex, bool bWrap = false)
{
    for (int iCurrent = iIndex + 1; iCurrent < MAX_ROCKETS; iCurrent++)
        if (IsValidRocket(iCurrent))
            return iCurrent;
        
    return (bWrap == true)? FindNextValidRocket(-1, false) : -1;
}

int FindFreeRocketSlot()
{
    int iIndex = g_iLastCreatedRocket;
    int iCurrent = iIndex;
    
    do
    {
        if (!IsValidRocket(iCurrent)) return iCurrent;
        if ((++iCurrent) == MAX_ROCKETS) iCurrent = 0;
    } while (iCurrent != iIndex);
    
    return -1;
}

int FindRocketByEntity(int iEntity)
{
    int iIndex = -1;
    while ((iIndex = FindNextValidRocket(iIndex)) != -1)
        if (EntRefToEntIndex(g_iRocketEntity[iIndex]) == iEntity)
            return iIndex;
        
    return -1;
}

stock bool IsValidClient(int iClient, bool bAlive = false)
{
    if (iClient >= 1 &&
    iClient <= MaxClients &&
    IsClientInGame(iClient) &&
    (bAlive == false || IsPlayerAlive(iClient)))
    {
        return true;
    }
    
    return false;
}