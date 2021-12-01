// *********************************************************************************
// PREPROCESSOR
// *********************************************************************************
#pragma semicolon 1                  // Force strict semicolon mode.
#pragma newdecls required

// *********************************************************************************
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <multicolors>

// *********************************************************************************
// CONSTANTS 
// *********************************************************************************
// ---- Plugin-related constants ---------------------------------------------------
#define PLUGIN_NAME             "[TF2] Dodgeball"
#define PLUGIN_AUTHOR           "Damizean, edited by x07x08 with features from YADBP 1.4.2 & Redux"
#define PLUGIN_VERSION          "1.5"
#define PLUGIN_CONTACT          "https://github.com/x07x08/TF2_Dodgeball_Modified"
#define CVAR_FLAGS              FCVAR_PLUGIN

// ---- General settings -----------------------------------------------------------
#define FPS_LOGIC_RATE          20.0
#define FPS_LOGIC_INTERVAL      1.0 / FPS_LOGIC_RATE

// ---- Maximum structure sizes ----------------------------------------------------
#define MAX_ROCKETS             100
#define MAX_ROCKET_CLASSES      50
#define MAX_SPAWNER_CLASSES     50
#define MAX_SPAWN_POINTS        100

// ---- Flags and types constants --------------------------------------------------
enum Musics
{
    Music_RoundStart,
    Music_RoundWin,
    Music_RoundLose,
    Music_Gameplay,
    SizeOfMusicsArray
};

enum BehaviourTypes
{
    Behaviour_Unknown,
    Behaviour_Homing
};

enum RocketFlags
{
    RocketFlag_None             = 0,
    RocketFlag_PlaySpawnSound   = 1 << 0,
    RocketFlag_PlayBeepSound    = 1 << 1,
    RocketFlag_PlayAlertSound   = 1 << 2,
    RocketFlag_ElevateOnDeflect = 1 << 3,
    RocketFlag_IsNeutral        = 1 << 4,
    RocketFlag_Exploded         = 1 << 5,
    RocketFlag_OnSpawnCmd       = 1 << 6,
    RocketFlag_OnDeflectCmd     = 1 << 7,
    RocketFlag_OnKillCmd        = 1 << 8,
    RocketFlag_OnExplodeCmd     = 1 << 9,
    RocketFlag_CustomModel      = 1 << 10,
    RocketFlag_CustomSpawnSound = 1 << 11,
    RocketFlag_CustomBeepSound  = 1 << 12,
    RocketFlag_CustomAlertSound = 1 << 13,
    RocketFlag_Elevating        = 1 << 14,
    RocketFlag_IsAnimated       = 1 << 15,
    RocketFlag_IsLimited        = 1 << 16,
    RocketFlag_IsSpeedLimited   = 1 << 17,
    RocketFlag_KeepDirection    = 1 << 18,
    RocketFlag_TeamlessHits     = 1 << 19,
    RocketFlag_ResetBounces     = 1 << 20,
    RocketFlag_CustomTrail      = 1 << 21,
    RocketFlag_CustomSprite     = 1 << 22,
    RocketFlag_RemoveParticles  = 1 << 23,
    RocketFlag_ReplaceParticles = 1 << 24,
    RocketFlag_OnNoTargetCmd    = 1 << 25
};

enum ParticleAttachmentType
{
    PATTACH_ABSORIGIN = 0,    // Create at absorigin, but don't follow
    PATTACH_ABSORIGIN_FOLLOW, // Create at absorigin, and update to follow the entity
    PATTACH_CUSTOMORIGIN,     // Create at a custom origin, but don't follow
    PATTACH_POINT,            // Create on attachment point, but don't follow
    PATTACH_POINT_FOLLOW,     // Create on attachment point, and update to follow the entity
    PATTACH_WORLDORIGIN,      // Used for control points that don't attach to an entity
    PATTACH_ROOTBONE_FOLLOW   // Create at the root bone of the entity, and update to follow
};

enum RocketSound
{
    RocketSound_Spawn,
    RocketSound_Beep,
    RocketSound_Alert
};

enum SpawnerFlags
{
    SpawnerFlag_Team_Red  = 1,
    SpawnerFlag_Team_Blu  = 2,
    SpawnerFlag_Team_Both = 3
};

#define TestFlags(%1,%2)    (!!((%1) & (%2)))
#define TestFlagsAnd(%1,%2) (((%1) & (%2)) == %2)

// ---- Other resources ------------------------------------------------------------
#define SOUND_DEFAULT_SPAWN     "weapons/sentry_rocket.wav"
#define SOUND_DEFAULT_BEEP      "weapons/sentry_scan.wav"
#define SOUND_DEFAULT_ALERT     "weapons/sentry_spot.wav"
#define SOUND_DEFAULT_SPEEDUP   "misc/doomsday_lift_warning.wav"
#define SNDCHAN_MUSIC           32
#define PARTICLE_NUKE_1         "fireSmokeExplosion"
#define PARTICLE_NUKE_2         "fireSmokeExplosion1"
#define PARTICLE_NUKE_3         "fireSmokeExplosion2"
#define PARTICLE_NUKE_4         "fireSmokeExplosion3"
#define PARTICLE_NUKE_5         "fireSmokeExplosion4"
#define PARTICLE_NUKE_COLLUMN   "fireSmoke_collumnP"
#define PARTICLE_NUKE_1_ANGLES  view_as<float>({270.0, 0.0, 0.0})
#define PARTICLE_NUKE_2_ANGLES  PARTICLE_NUKE_1_ANGLES
#define PARTICLE_NUKE_3_ANGLES  PARTICLE_NUKE_1_ANGLES
#define PARTICLE_NUKE_4_ANGLES  PARTICLE_NUKE_1_ANGLES
#define PARTICLE_NUKE_5_ANGLES  PARTICLE_NUKE_1_ANGLES
#define PARTICLE_NUKE_COLLUMN_ANGLES  PARTICLE_NUKE_1_ANGLES

// Debug
//#define DEBUG

// *********************************************************************************
// VARIABLES
// *********************************************************************************

// -----<<< Cvars >>>-----
ConVar g_hCvarEnabled;
ConVar g_hCvarEnableCfgFile;
ConVar g_hCvarDisableCfgFile;
ConVar g_hCvarStealPrevention;
ConVar g_hCvarStealPreventionNumber;
ConVar g_hCvarStealPreventionDamage;
ConVar g_hCvarStealDistance;
ConVar g_hCvarDelayPrevention;
ConVar g_hCvarDelayPreventionTime;
ConVar g_hCvarDelayPreventionSpeedup;
ConVar g_hCvarNoTargetRedirectDamage;

// -----<<< Gameplay >>>-----
bool   g_bEnabled;                // Is the plugin enabled?
bool   g_bRoundStarted;           // Has the round started?
int    g_iRoundCount;             // Current round count since map start
int    g_iRocketsFired;           // No. of rockets fired since round start
Handle g_hLogicTimer;             // Logic timer
float  g_fNextSpawnTime;          // Time at wich the next rocket will be able to spawn
int    g_iLastDeadTeam;           // The team of the last dead client. If none, it's a random team.
int    g_iLastDeadClient;         // The last dead client. If none, it's a random client.
int    g_iPlayerCount;
float  g_fStealDistance = 48.0;
int    g_iEmptyModel = -1;
bool   g_bClientHideTrails [MAXPLAYERS + 1];
bool   g_bClientHideSprites[MAXPLAYERS + 1];
int    g_iLastStealer;

enum struct eRocketSteal
{
	bool stoleRocket;
	int rocketsStolen;
}

eRocketSteal bStealArray[MAXPLAYERS + 1];

// -----<<< Configuration >>>-----
bool g_bMusicEnabled;
bool g_bMusic[view_as<int>(SizeOfMusicsArray)];
char g_strMusic[view_as<int>(SizeOfMusicsArray)][PLATFORM_MAX_PATH];
bool g_bUseWebPlayer;
char g_strWebPlayerUrl[256];

// -----<<< Structures >>>-----
// Rockets
bool        g_bRocketIsValid            [MAX_ROCKETS];
int         g_iRocketEntity             [MAX_ROCKETS];
int         g_iRocketFakeEntity         [MAX_ROCKETS];
int         g_iRocketRedCriticalEntity  [MAX_ROCKETS];
int         g_iRocketBluCriticalEntity  [MAX_ROCKETS];
int         g_iRocketTarget             [MAX_ROCKETS];
int         g_iRocketSpawner            [MAX_ROCKETS];
int         g_iRocketClass              [MAX_ROCKETS];
RocketFlags g_iRocketFlags              [MAX_ROCKETS];
float       g_fRocketSpeed              [MAX_ROCKETS];
float       g_fRocketMphSpeed           [MAX_ROCKETS];
float       g_fRocketDirection          [MAX_ROCKETS][3];
int         g_iRocketDeflections        [MAX_ROCKETS];
float       g_fRocketLastDeflectionTime [MAX_ROCKETS];
float       g_fRocketLastBeepTime       [MAX_ROCKETS];
int         g_iLastCreatedRocket;
int         g_iRocketCount;
bool        g_bIsRocketStolen           [MAX_ROCKETS];
bool        g_bPreventingDelay          [MAX_ROCKETS];
float       g_fLastSpawnTime            [MAX_ROCKETS];
int         g_iRocketBounces            [MAX_ROCKETS];

// Classes
char           g_strRocketClassName           [MAX_ROCKET_CLASSES][16];
char           g_strRocketClassLongName       [MAX_ROCKET_CLASSES][32];
BehaviourTypes g_iRocketClassBehaviour        [MAX_ROCKET_CLASSES];
char           g_strRocketClassModel          [MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
char           g_strRocketClassTrail          [MAX_ROCKET_CLASSES][128];
char           g_strRocketClassSprite         [MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
char           g_strRocketClassSpriteColor    [MAX_ROCKET_CLASSES][32];
RocketFlags    g_iRocketClassFlags            [MAX_ROCKET_CLASSES];
float          g_fRocketClassBeepInterval     [MAX_ROCKET_CLASSES];
char           g_strRocketClassSpawnSound     [MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
char           g_strRocketClassBeepSound      [MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
char           g_strRocketClassAlertSound     [MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
float          g_fRocketClassCritChance       [MAX_ROCKET_CLASSES];
float          g_fRocketClassDamage           [MAX_ROCKET_CLASSES];
float          g_fRocketClassDamageIncrement  [MAX_ROCKET_CLASSES];
float          g_fRocketClassSpeed            [MAX_ROCKET_CLASSES];
float          g_fRocketClassSpeedIncrement   [MAX_ROCKET_CLASSES];
float          g_fRocketClassSpeedLimit       [MAX_ROCKET_CLASSES];
float          g_fRocketClassTurnRate         [MAX_ROCKET_CLASSES];
float          g_fRocketClassTurnRateIncrement[MAX_ROCKET_CLASSES];
float          g_fRocketClassTurnRateLimit    [MAX_ROCKET_CLASSES];
float          g_fRocketClassElevationRate    [MAX_ROCKET_CLASSES];
float          g_fRocketClassElevationLimit   [MAX_ROCKET_CLASSES];
float          g_fRocketClassRocketsModifier  [MAX_ROCKET_CLASSES];
float          g_fRocketClassPlayerModifier   [MAX_ROCKET_CLASSES];
float          g_fRocketClassControlDelay     [MAX_ROCKET_CLASSES];
float          g_fRocketClassTargetWeight     [MAX_ROCKET_CLASSES];
DataPack       g_hRocketClassCmdsOnSpawn      [MAX_ROCKET_CLASSES];
DataPack       g_hRocketClassCmdsOnDeflect    [MAX_ROCKET_CLASSES];
DataPack       g_hRocketClassCmdsOnKill       [MAX_ROCKET_CLASSES];
DataPack       g_hRocketClassCmdsOnExplode    [MAX_ROCKET_CLASSES];
DataPack       g_hRocketClassCmdsOnNoTarget   [MAX_ROCKET_CLASSES];
StringMap      g_hRocketClassTrie;
int            g_iRocketClassCount;
float          g_fSavedParameters             [MAX_ROCKET_CLASSES][8];
RocketFlags    g_iSavedRocketClassFlags       [MAX_ROCKET_CLASSES];
int            g_iRocketClassMaxBounces       [MAX_ROCKET_CLASSES];
int            g_iRocketClassSavedMaxBounces  [MAX_ROCKET_CLASSES];

// Spawner classes
char      g_strSpawnersName        [MAX_SPAWNER_CLASSES][32];
//new SpawnerFlags:g_iSpawnersFlags         [MAX_SPAWNER_CLASSES];
int       g_iSpawnersMaxRockets    [MAX_SPAWNER_CLASSES];
float     g_fSpawnersInterval      [MAX_SPAWNER_CLASSES];
ArrayList g_hSpawnersChancesTable  [MAX_SPAWNER_CLASSES];
ArrayList g_hSavedChancesTable     [MAX_SPAWNER_CLASSES];
StringMap g_hSpawnersTrie;
int       g_iSpawnersCount;

// Array containing the spawn points for the Red team, and
// their associated spawner class.
int g_iCurrentRedSpawn;
int g_iSpawnPointsRedCount;
int g_iSpawnPointsRedClass  [MAX_SPAWN_POINTS];
int g_iSpawnPointsRedEntity [MAX_SPAWN_POINTS];

// Array containing the spawn points for the Blu team, and
// their associated spawner class.
int g_iCurrentBluSpawn;
int g_iSpawnPointsBluCount;
int g_iSpawnPointsBluClass  [MAX_SPAWN_POINTS];
int g_iSpawnPointsBluEntity [MAX_SPAWN_POINTS];

// The default spawner class.
int g_iDefaultRedSpawner;
int g_iDefaultBluSpawner;

// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_NAME,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
};

// *********************************************************************************
// METHODS
// *********************************************************************************

/* OnPluginStart()
**
** When the plugin is loaded.
** -------------------------------------------------------------------------- */
public void OnPluginStart()
{
    char strModName[32]; GetGameFolderName(strModName, sizeof(strModName));
    if (!StrEqual(strModName, "tf")) SetFailState("This plugin is only for Team Fortress 2.");
    
    LoadTranslations("yadbp.phrases.txt");
    
    CreateConVar("tf_dodgeball_version", PLUGIN_VERSION, PLUGIN_NAME, _);
    g_hCvarEnabled = CreateConVar("tf_dodgeball_enabled", "1", "Enable Dodgeball on TFDB maps?", _, true, 0.0, true, 1.0);
    g_hCvarEnableCfgFile = CreateConVar("tf_dodgeball_enablecfg", "sourcemod/dodgeball_enable.cfg", "Config file to execute when enabling the Dodgeball game mode.");
    g_hCvarDisableCfgFile = CreateConVar("tf_dodgeball_disablecfg", "sourcemod/dodgeball_disable.cfg", "Config file to execute when disabling the Dodgeball game mode.");
    g_hCvarStealPrevention = CreateConVar("tf_dodgeball_steal_prevention", "0", "Enable steal prevention?", _, true, 0.0, true, 1.0);
    g_hCvarStealPreventionNumber = CreateConVar("tf_dodgeball_sp_number", "3", "How many steals before you get slayed?", _, true, 0.0, false);
    g_hCvarStealPreventionDamage = CreateConVar("tf_dodgeball_sp_damage", "0", "Reduce all damage on stolen rockets?", _, true, 0.0, true, 1.0);
    g_hCvarStealDistance = CreateConVar("tf_dodgeball_sp_distance", "48.0", "The distance between players for a steal to register.", _, true, 0.0, false);
    g_hCvarDelayPrevention = CreateConVar("tf_dodgeball_delay_prevention", "1", "Enable delay prevention?", _, true, 0.0, true, 1.0);
    g_hCvarDelayPreventionTime = CreateConVar("tf_dodgeball_dp_time", "5", "How much time (in seconds) before delay prevention activates?", _, true, 0.0, false);
    g_hCvarDelayPreventionSpeedup = CreateConVar("tf_dodgeball_dp_speedup", "100", "How much speed (in hammer units per second) should the rocket gain when delayed?", _, true, 0.0, false);
    g_hCvarNoTargetRedirectDamage = CreateConVar("tf_dodgeball_redirect_damage", "1", "Reduce all damage when a rocket has an invalid target?", _, true, 0.0, true, 1.0);
    
    g_hCvarStealDistance.AddChangeHook(tf2dodgeball_cvarhook);
    
    g_hRocketClassTrie = new StringMap();
    g_hSpawnersTrie = new StringMap();
    
    RegisterCommands();
}

/* OnConfigsExecuted()
**
** When all the configuration files have been executed, try to enable the
** Dodgeball.
** -------------------------------------------------------------------------- */
public void OnConfigsExecuted()
{
    if (g_hCvarEnabled.BoolValue && IsDodgeBallMap())
    {
        EnableDodgeBall();
    }
}

/* OnMapEnd()
**
** When the map ends, disable DodgeBall.
** -------------------------------------------------------------------------- */
public void OnMapEnd()
{
    DisableDodgeBall();
}

/*
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
**     __  ___                                                  __ 
**    /  |/  /___ _____  ____ _____ ____  ____ ___  ___  ____  / /_
**   / /|_/ / __ `/ __ \/ __ `/ __ `/ _ \/ __ `__ \/ _ \/ __ \/ __/
**  / /  / / /_/ / / / / /_/ / /_/ /  __/ / / / / /  __/ / / / /_  
** /_/  /_/\__,_/_/ /_/\__,_/\__, /\___/_/ /_/ /_/\___/_/ /_/\__/  
**                          /____/                                 
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
*/

//   ___                       _ 
//  / __|___ _ _  ___ _ _ __ _| |
// | (_ / -_) ' \/ -_) '_/ _` | |
//  \___\___|_||_\___|_| \__,_|_|

/* IsDodgeBallMap()
**
** Checks if the current map is a dodgeball map.
** -------------------------------------------------------------------------- */
bool IsDodgeBallMap()
{
    char strMap[64];
    GetCurrentMap(strMap, sizeof(strMap));
    return StrContains(strMap, "tfdb_", false) == 0;
}

/* EnableDodgeBall()
**
** Enables and hooks all the required events.
** -------------------------------------------------------------------------- */
void EnableDodgeBall()
{
    if (g_bEnabled == false)
    {
        // Parse configuration files
        char strMapName[64]; GetCurrentMap(strMapName, sizeof(strMapName));
        char strMapFile[PLATFORM_MAX_PATH]; FormatEx(strMapFile, sizeof(strMapFile), "%s.cfg", strMapName);
        ParseConfigurations();
        ParseConfigurations(strMapFile);
        
        // Check if we have all the required information
        if (g_iRocketClassCount == 0)   SetFailState("No rocket class defined.");
        if (g_iSpawnersCount == 0)      SetFailState("No spawner class defined.");
        if (g_iDefaultRedSpawner == -1) SetFailState("No spawner class definition for the Red spawners exists in the config file.");
        if (g_iDefaultBluSpawner == -1) SetFailState("No spawner class definition for the Blu spawners exists in the config file.");
        
        // Hook events and info_target outputs.
        HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
        HookEvent("arena_round_start", OnSetupFinished, EventHookMode_PostNoCopy); // teamplay_setup_finished will not fire on maps that lack team_round_timer
        HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
        HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
        HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
        HookEvent("post_inventory_application", OnPlayerInventory, EventHookMode_Post);
        HookEvent("teamplay_broadcast_audio", OnBroadcastAudio, EventHookMode_Pre);
        HookEvent("object_deflected", OnObjectDeflected);
        
        g_iEmptyModel = PrecacheModel("models/empty.mdl", true);
        PrecacheParticleSystem("rockettrail_fire"); // Why isn't this particle already precached?
        
        AddMultiTargetFilter("@stealer", MLTargetFilterStealer, "last stealer", false);
        AddMultiTargetFilter("@!stealer", MLTargetFilterStealer, "non last stealer", false); // Sounds weird not gonna lie
        
        // Precache sounds
        PrecacheSound(SOUND_DEFAULT_SPAWN, true);
        PrecacheSound(SOUND_DEFAULT_BEEP, true);
        PrecacheSound(SOUND_DEFAULT_ALERT, true);
        PrecacheSound(SOUND_DEFAULT_SPEEDUP, true);
        if (g_bMusicEnabled == true)
        {
            if (g_bMusic[Music_RoundStart]) PrecacheSoundEx(g_strMusic[Music_RoundStart], true, true);
            if (g_bMusic[Music_RoundWin])   PrecacheSoundEx(g_strMusic[Music_RoundWin], true, true);
            if (g_bMusic[Music_RoundLose])  PrecacheSoundEx(g_strMusic[Music_RoundLose], true, true);
            if (g_bMusic[Music_Gameplay])   PrecacheSoundEx(g_strMusic[Music_Gameplay], true, true);
        }
        
        // Precache particles
        PrecacheParticle(PARTICLE_NUKE_1);
        PrecacheParticle(PARTICLE_NUKE_2);
        PrecacheParticle(PARTICLE_NUKE_3);
        PrecacheParticle(PARTICLE_NUKE_4);
        PrecacheParticle(PARTICLE_NUKE_5);
        PrecacheParticle(PARTICLE_NUKE_COLLUMN);
        
        // Precache rocket resources
        for (int i = 0; i < g_iRocketClassCount; i++)
        {
            RocketFlags iFlags = g_iRocketClassFlags[i];
            if (TestFlags(iFlags, RocketFlag_CustomModel))      PrecacheModelEx(g_strRocketClassModel[i], true, true);
            if (TestFlags(iFlags, RocketFlag_CustomSpawnSound)) PrecacheSoundEx(g_strRocketClassSpawnSound[i], true, true);
            if (TestFlags(iFlags, RocketFlag_CustomBeepSound))  PrecacheSoundEx(g_strRocketClassBeepSound[i], true, true);
            if (TestFlags(iFlags, RocketFlag_CustomAlertSound)) PrecacheSoundEx(g_strRocketClassAlertSound[i], true, true);
            if (TestFlags(iFlags, RocketFlag_CustomTrail))      PrecacheParticleSystem(g_strRocketClassTrail[i]);
            if (TestFlags(iFlags, RocketFlag_CustomSprite))     PrecacheTrail(g_strRocketClassSprite[i]);
        }
        
        // Execute enable config file
        char strCfgFile[64]; g_hCvarEnableCfgFile.GetString(strCfgFile, sizeof(strCfgFile));
        ServerCommand("exec \"%s\"", strCfgFile);
        
        // Done.
        g_bEnabled        = true;
        g_bRoundStarted   = false;
        g_iRoundCount     = 0;
    }
}

/* DisableDodgeBall()
**
** Disables all hooks and frees arrays.
** -------------------------------------------------------------------------- */
void DisableDodgeBall()
{
    if (g_bEnabled == true)
    {
        // Clean up everything
        DestroyRockets();
        DestroyRocketClasses();
        DestroySpawners();
        if (g_hLogicTimer != null) KillTimer(g_hLogicTimer);
        g_hLogicTimer = null;
        
        // Disable music
        g_bMusic[Music_RoundStart] =
        g_bMusic[Music_RoundWin]   = 
        g_bMusic[Music_RoundLose]  = 
        g_bMusic[Music_Gameplay]   = false;
        
        // Unhook events and info_target outputs;
        UnhookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
        UnhookEvent("arena_round_start", OnSetupFinished, EventHookMode_PostNoCopy);
        UnhookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
        UnhookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
        UnhookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
        UnhookEvent("post_inventory_application", OnPlayerInventory, EventHookMode_Post);
        UnhookEvent("teamplay_broadcast_audio", OnBroadcastAudio, EventHookMode_Pre);
        UnhookEvent("object_deflected", OnObjectDeflected);
        
        RemoveMultiTargetFilter("@stealer", MLTargetFilterStealer);
        RemoveMultiTargetFilter("@!stealer", MLTargetFilterStealer);
        
        // Execute enable config file
        char strCfgFile[64]; g_hCvarDisableCfgFile.GetString(strCfgFile, sizeof(strCfgFile));
        ServerCommand("exec \"%s\"", strCfgFile);
        
        // Done.
        g_bEnabled        = false;
        g_bRoundStarted   = false;
        g_iRoundCount     = 0;
    }
}

public void OnClientDisconnect(int client)
{
	if (g_hCvarStealPrevention.BoolValue)
	{
		bStealArray[client].stoleRocket = false;
		bStealArray[client].rocketsStolen = 0;
	}
	
	if (client == g_iLastDeadClient)
	{
		g_iLastDeadClient = 0;
	}
	
	if (client == g_iLastStealer)
	{
		g_iLastStealer = 0;
	}
	
	g_bClientHideTrails [client] = false;
	g_bClientHideSprites[client] = false;
}

//   ___                     _           
//  / __|__ _ _ __  ___ _ __| |__ _ _  _ 
// | (_ / _` | '  \/ -_) '_ \ / _` | || |
//  \___\__,_|_|_|_\___| .__/_\__,_|\_, |
//                     |_|          |__/ 

/* OnRoundStart()
**
** At round start, do something?
** -------------------------------------------------------------------------- */
public Action OnRoundStart(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
    if (g_bMusic[Music_RoundStart])
    {
        EmitSoundToAll(g_strMusic[Music_RoundStart]);
    }
    
    if (g_hCvarStealPrevention.BoolValue)
    {
        for (int i = 0; i <= MaxClients; i++)
        {
            bStealArray[i].stoleRocket = false;
            bStealArray[i].rocketsStolen = 0;
        }
    }
}

/* OnSetupFinished()
**
** When the setup finishes, populate the spawn points arrays and create the
** Dodgeball game logic timer.
** -------------------------------------------------------------------------- */
public Action OnSetupFinished(Event hEvent, char[] strEventName, bool bDontBroadcast)
{   
    if ((g_bEnabled == true) && (BothTeamsPlaying() == true))
    {
        PopulateSpawnPoints();
        
        if (g_iLastDeadTeam == 0) g_iLastDeadTeam = GetURandomIntRange(view_as<int>(TFTeam_Red), view_as<int>(TFTeam_Blue));
        if (!IsValidClient(g_iLastDeadClient)) g_iLastDeadClient = 0;
        
        g_hLogicTimer      = CreateTimer(FPS_LOGIC_INTERVAL, OnDodgeBallGameFrame, _, TIMER_REPEAT);
        g_iPlayerCount     = CountAlivePlayers();
        g_iRocketsFired    = 0;
        g_iCurrentRedSpawn = 0;
        g_iCurrentBluSpawn = 0;
        g_fNextSpawnTime   = GetGameTime();
        g_bRoundStarted    = true;
        g_iRoundCount++;
    }
}

/* OnRoundEnd()
**
** At round end, stop the Dodgeball game logic timer and destroy the remaining
** rockets.
** -------------------------------------------------------------------------- */
public Action OnRoundEnd(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
    if (g_hLogicTimer != null)
    {
        KillTimer(g_hLogicTimer);
        g_hLogicTimer = null;
    }
    
    if (g_bMusicEnabled == true)
    {
        if (g_bUseWebPlayer)
        {
            for (int iClient = 1; iClient <= MaxClients; iClient++)
            {
                if (IsValidClient(iClient))
                {
                    ShowHiddenMOTDPanel(iClient, "MusicPlayerStop", "http://0.0.0.0/");
                }
            }
        }
        else if (g_bMusic[Music_Gameplay])
        {
            StopSoundToAll(SNDCHAN_MUSIC, g_strMusic[Music_Gameplay]);
        }
    }
    
    DestroyRockets();
    g_bRoundStarted = false;
}

/* OnPlayerSpawn()
**
** When the player spawns, force class to Pyro.
** -------------------------------------------------------------------------- */
public Action OnPlayerSpawn(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
    int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
    if (!IsValidClient(iClient)) return;
    
    TFClassType iClass = TF2_GetPlayerClass(iClient);
    if (!(iClass == TFClass_Pyro || iClass == TFClass_Unknown))
    {
        TF2_SetPlayerClass(iClient, TFClass_Pyro, false, true);
        TF2_RespawnPlayer(iClient);
    }
}

/* OnPlayerDeath()
**
** When the player dies, set the last dead team to determine the next
** rocket's team.
** -------------------------------------------------------------------------- */
public Action OnPlayerDeath(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
    if (g_bRoundStarted == false) return;
    int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
    int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
    
    if (!IsValidClient(iAttacker))
    {
        iAttacker = 0;
    }
    
    if (IsValidClient(iVictim))
    {
        if (g_hCvarStealPrevention.BoolValue)
        {
            bStealArray[iVictim].stoleRocket = false;
            bStealArray[iVictim].rocketsStolen = 0;
        }
        
        g_iLastDeadClient = iVictim;
        g_iLastDeadTeam = GetClientTeam(iVictim);
        
        int iInflictor = hEvent.GetInt("inflictor_entindex");
        int iIndex = FindRocketByEntity(iInflictor);
        
        if (iIndex != -1)
        {
            int iClass = g_iRocketClass[iIndex];
            int iTarget = EntRefToEntIndex(g_iRocketTarget[iIndex]);
            float fSpeed = g_fRocketSpeed[iIndex];
            float fMphSpeed = g_fRocketMphSpeed[iIndex];
            int iDeflections = g_iRocketDeflections[iIndex];
            
            if ((g_iRocketFlags[iIndex] & RocketFlag_OnExplodeCmd) && !(g_iRocketFlags[iIndex] & RocketFlag_Exploded))
            {
                ExecuteCommands(g_hRocketClassCmdsOnExplode[iClass], iClass, iInflictor, iAttacker, iTarget, g_iLastDeadClient, fSpeed, iDeflections, fMphSpeed);
                g_iRocketFlags[iIndex] |= RocketFlag_Exploded;
            }
            
            if (TestFlags(g_iRocketFlags[iIndex], RocketFlag_OnKillCmd))
                ExecuteCommands(g_hRocketClassCmdsOnKill[iClass], iClass, iInflictor, iAttacker, iTarget, g_iLastDeadClient, fSpeed, iDeflections, fMphSpeed);
        }
    }
    
    SetRandomSeed(view_as<int>(GetGameTime()));
}

/* OnPlayerInventory()
**
** Make sure the client only has the flamethrower equipped.
** -------------------------------------------------------------------------- */
public Action OnPlayerInventory(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
    int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
    if (!IsValidClient(iClient)) return;
    
    for (int iSlot = 1; iSlot < 5; iSlot++)
    {
        int iEntity = GetPlayerWeaponSlot(iClient, iSlot);
        if (iEntity != -1) RemoveEdict(iEntity);
    }
}

/* OnPlayerRunCmd()
**
** Block flamethrower's Mouse1 attack.
** -------------------------------------------------------------------------- */
public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon)
{
    if (g_bEnabled == true) iButtons &= ~IN_ATTACK;
    return Plugin_Continue;
}

/* OnBroadcastAudio()
**
** Replaces the broadcasted audio for our custom music files.
** -------------------------------------------------------------------------- */
public Action OnBroadcastAudio(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
    if (g_bMusicEnabled == true)
    {
        char strSound[PLATFORM_MAX_PATH];
        hEvent.GetString("sound", strSound, sizeof(strSound));
        int iTeam = hEvent.GetInt("team");
        
        if (StrEqual(strSound, "Announcer.AM_RoundStartRandom") == true)
        {
            if (g_bUseWebPlayer == false)
            {
                if (g_bMusic[Music_Gameplay])
                {
                    EmitSoundToAll(g_strMusic[Music_Gameplay], SOUND_FROM_PLAYER, SNDCHAN_MUSIC);
                    return Plugin_Handled;
                }
            }
            else
            {
                for (int iClient = 1; iClient <= MaxClients; iClient++)
                    if (IsValidClient(iClient))
                        ShowHiddenMOTDPanel(iClient, "MusicPlayerStart", g_strWebPlayerUrl);
                    
                return Plugin_Handled;
            }
        }
        else if (StrEqual(strSound, "Game.YourTeamWon") == true)
        {
            if (g_bMusic[Music_RoundWin])
            {
                for (int iClient = 1; iClient <= MaxClients; iClient++)
                    if (IsValidClient(iClient) && (iTeam == GetClientTeam(iClient)))
                        EmitSoundToClient(iClient, g_strMusic[Music_RoundWin]);
                    
                return Plugin_Handled;
            }
        }
        else if (StrEqual(strSound, "Game.YourTeamLost") == true)
        {
            if (g_bMusic[Music_RoundLose])
            {
                for (int iClient = 1; iClient <= MaxClients; iClient++)
                    if (IsValidClient(iClient) && (iTeam == GetClientTeam(iClient)))
                        EmitSoundToClient(iClient, g_strMusic[Music_RoundLose]);
                    
                return Plugin_Handled;
            }
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public Action OnObjectDeflected(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iEntity = GetEventInt(hEvent, "object_entindex");
	int iIndex  = FindRocketByEntity(iEntity);
	
	if (iIndex != -1)
	{
		if (g_iRocketFlags[iIndex] & RocketFlag_ResetBounces)
		{
			g_iRocketBounces[iIndex] = 0;
		}
		
		if (g_iRocketFlags[iIndex] & RocketFlag_ReplaceParticles)
		{
			bool bCritical = !!GetEntProp(iEntity, Prop_Send, "m_bCritical");
			
			if (bCritical)
			{
				int iRedCriticalEntity = EntRefToEntIndex(g_iRocketRedCriticalEntity[iIndex]);
				int iBluCriticalEntity = EntRefToEntIndex(g_iRocketBluCriticalEntity[iIndex]);
				
				if (iRedCriticalEntity != -1 && iBluCriticalEntity != -1)
				{
					int iTeam = GetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1);
					
					if (iTeam == view_as<int>(TFTeam_Red))
					{
						AcceptEntityInput(iBluCriticalEntity, "Stop");
						AcceptEntityInput(iRedCriticalEntity, "Start");
					}
					else if (iTeam == view_as<int>(TFTeam_Blue))
					{
						AcceptEntityInput(iBluCriticalEntity, "Start");
						AcceptEntityInput(iRedCriticalEntity, "Stop");
					}
				}
			}
		}
		
		if (g_iRocketFlags[iIndex] & RocketFlag_IsNeutral)
		{
			SetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1, 1);
		}
	}
}

/* OnDodgeBallGameFrame()
**
** Every tick of the Dodgeball logic.
** -------------------------------------------------------------------------- */
public Action OnDodgeBallGameFrame(Handle hTimer, any Data)
{
    // Only if both teams are playing
    if (BothTeamsPlaying() == false) return;
    
    // Check if we need to fire more rockets.
    if (GetGameTime() >= g_fNextSpawnTime)
    {
        if (g_iLastDeadTeam == view_as<int>(TFTeam_Red))
        {
            int iSpawnerEntity = g_iSpawnPointsRedEntity[g_iCurrentRedSpawn];
            int iSpawnerClass  = g_iSpawnPointsRedClass[g_iCurrentRedSpawn];
            if (g_iRocketCount < g_iSpawnersMaxRockets[iSpawnerClass])
            {
                CreateRocket(iSpawnerEntity, iSpawnerClass, view_as<int>(TFTeam_Red));
                g_iCurrentRedSpawn = (g_iCurrentRedSpawn + 1) % g_iSpawnPointsRedCount;
            }
        }
        else
        {
            int iSpawnerEntity = g_iSpawnPointsBluEntity[g_iCurrentBluSpawn];
            int iSpawnerClass  = g_iSpawnPointsBluClass[g_iCurrentBluSpawn];
            if (g_iRocketCount < g_iSpawnersMaxRockets[iSpawnerClass])
            {
                CreateRocket(iSpawnerEntity, iSpawnerClass, view_as<int>(TFTeam_Blue));
                g_iCurrentBluSpawn = (g_iCurrentBluSpawn + 1) % g_iSpawnPointsBluCount;
            }
        }
    }
    
    // Manage the active rockets
    int iIndex = -1;
    while ((iIndex = FindNextValidRocket(iIndex)) != -1)
    {
        switch (g_iRocketClassBehaviour[g_iRocketClass[iIndex]])
        {
            case Behaviour_Unknown: {}
            case Behaviour_Homing:  { HomingRocketThink(iIndex); }
        }
    }
}

//  ___         _       _      
// | _ \___  __| |_____| |_ ___
// |   / _ \/ _| / / -_)  _(_-<
// |_|_\___/\__|_\_\___|\__/__/

/* CreateRocket()
**
** Fires a new rocket entity from the spawner's position.
** -------------------------------------------------------------------------- */
public void CreateRocket(int iSpawnerEntity, int iSpawnerClass, int iTeam)
{
    int iIndex = FindFreeRocketSlot();
    if (iIndex != -1)
    {
        // Fetch a random rocket class and it's parameters.
        int iClass = GetRandomRocketClass(iSpawnerClass);
        RocketFlags iFlags = g_iRocketClassFlags[iClass];
        
        // Create rocket entity.
        int iEntity = CreateEntityByName(TestFlags(iFlags, RocketFlag_IsAnimated)? "tf_projectile_sentryrocket" : "tf_projectile_rocket");
        if (iEntity && IsValidEntity(iEntity))
        {
            // Fetch spawn point's location and angles.
            float fPosition[3], fAngles[3], fDirection[3];
            GetEntPropVector(iSpawnerEntity, Prop_Send, "m_vecOrigin", fPosition);
            GetEntPropVector(iSpawnerEntity, Prop_Send, "m_angRotation", fAngles);
            GetAngleVectors(fAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
            
            // Setup rocket entity.
            SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", 0);
            SetEntProp(iEntity,    Prop_Send, "m_bCritical",    (GetURandomFloatRange(0.0, 100.0) <= g_fRocketClassCritChance[iClass])? 1 : 0, 1);
            SetEntProp(iEntity,    Prop_Send, "m_iTeamNum",     (TestFlags(iFlags, RocketFlag_IsNeutral))? 1 : iTeam, 1);
            SetEntProp(iEntity,    Prop_Send, "m_iDeflected",   1);
            TeleportEntity(iEntity, fPosition, fAngles, view_as<float>({0.0, 0.0, 0.0}));
            
            // Setup rocket structure with the newly created entity.
            int iTargetTeam = (TestFlags(iFlags, RocketFlag_IsNeutral))? 0 : GetAnalogueTeam(iTeam);
            int iTarget     = SelectTarget(iTargetTeam);
            float fModifier = CalculateModifier(iClass, 0);
            g_bRocketIsValid[iIndex]            = true;
            g_iRocketFlags[iIndex]              = iFlags;
            g_iRocketEntity[iIndex]             = EntIndexToEntRef(iEntity);
            g_iRocketTarget[iIndex]             = EntIndexToEntRef(iTarget);
            g_iRocketSpawner[iIndex]            = iSpawnerClass;
            g_iRocketClass[iIndex]              = iClass;
            g_iRocketDeflections[iIndex]        = 0;
            g_bPreventingDelay[iIndex]          = false;
            g_iRocketBounces[iIndex]            = 0;
            g_fRocketLastDeflectionTime[iIndex] = GetGameTime();
            g_fRocketLastBeepTime[iIndex]       = GetGameTime();
            g_fRocketSpeed[iIndex]              = CalculateRocketSpeed(iClass, fModifier);
            g_fRocketMphSpeed[iIndex]           = CalculateRocketSpeed(iClass, fModifier) * 0.042614;
            g_bIsRocketStolen[iIndex]           = false;
            CopyVectors(fDirection, g_fRocketDirection[iIndex]);
            SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, CalculateRocketDamage(iClass, fModifier), true);
            DispatchSpawn(iEntity);
            
            if (TestFlags(iFlags, RocketFlag_RemoveParticles))
            {
                int iOtherEntity = CreateEntityByName("prop_dynamic");
                if (iOtherEntity && IsValidEntity(iOtherEntity))
                {
                    SetEntProp(iEntity, Prop_Send, "m_nModelIndexOverrides", g_iEmptyModel);
                    
                    SetEntityModel(iOtherEntity, "models/weapons/w_models/w_rocket.mdl");
                    SetEntProp(iOtherEntity, Prop_Send, "m_CollisionGroup", 0);    // COLLISION_GROUP_NONE
                    SetEntProp(iOtherEntity, Prop_Send, "m_usSolidFlags", 0x0004); // FSOLID_NOT_SOLID
                    SetEntProp(iOtherEntity, Prop_Send, "m_nSolidType", 0);        // SOLID_NONE
                    TeleportEntity(iOtherEntity, fPosition, fAngles, view_as<float>({0.0, 0.0, 0.0}));
                    g_iRocketFakeEntity[iIndex] = EntIndexToEntRef(iOtherEntity);
                    DispatchSpawn(iOtherEntity);
                    
                    SetVariantString("!activator");
                    AcceptEntityInput(iOtherEntity, "SetParent", iEntity, iOtherEntity);
                    
                    if (TestFlags(iFlags, RocketFlag_ReplaceParticles))
                    {
                        CreateTempParticle("rockettrail_fire", fPosition, NULL_VECTOR, fAngles, iOtherEntity, PATTACH_POINT, 1); // If the rocket gets instantly destroyed, the temp ent still gets sent. Why?
                        
                        bool bCritical = !!GetEntProp(iEntity, Prop_Send, "m_bCritical");
                        if (bCritical)
                        {
                            int iRedCriticalEntity = CreateEntityByName("info_particle_system");
                            int iBluCriticalEntity = CreateEntityByName("info_particle_system");
                            
                            if ((iRedCriticalEntity && IsValidEdict(iRedCriticalEntity)) && (iBluCriticalEntity && IsValidEdict(iBluCriticalEntity)))
                            {
                                TeleportEntity(iRedCriticalEntity, fPosition, fAngles, view_as<float>({0.0, 0.0, 0.0}));
                                TeleportEntity(iBluCriticalEntity, fPosition, fAngles, view_as<float>({0.0, 0.0, 0.0}));
                                
                                DispatchKeyValue(iRedCriticalEntity, "effect_name", "critical_rocket_red");
                                DispatchKeyValue(iBluCriticalEntity, "effect_name", "critical_rocket_blue");
                                
                                g_iRocketRedCriticalEntity[iIndex] = EntIndexToEntRef(iRedCriticalEntity);
                                g_iRocketBluCriticalEntity[iIndex] = EntIndexToEntRef(iBluCriticalEntity);
                                
                                DispatchSpawn(iRedCriticalEntity);
                                DispatchSpawn(iBluCriticalEntity);
                                
                                ActivateEntity(iRedCriticalEntity);
                                ActivateEntity(iBluCriticalEntity);
                                
                                SetVariantString("!activator");
                                AcceptEntityInput(iRedCriticalEntity, "SetParent", iOtherEntity, iRedCriticalEntity);
                                
                                SetVariantString("!activator");
                                AcceptEntityInput(iBluCriticalEntity, "SetParent", iOtherEntity, iBluCriticalEntity);
                                
                                SetVariantString("trail");
                                AcceptEntityInput(iRedCriticalEntity, "SetParentAttachment", iOtherEntity, iRedCriticalEntity);
                                
                                SetVariantString("trail");
                                AcceptEntityInput(iBluCriticalEntity, "SetParentAttachment", iOtherEntity, iBluCriticalEntity);
                                
                                if (iTeam == view_as<int>(TFTeam_Red))
                                {
                                    AcceptEntityInput(iRedCriticalEntity, "Start");
                                }
                                else if (iTeam == view_as<int>(TFTeam_Blue))
                                {
                                    AcceptEntityInput(iBluCriticalEntity, "Start");
                                }
                            }
                        }
                    }
                }
            }
            
            if (TestFlags(iFlags, RocketFlag_CustomTrail))
            {
                int iTrailEntity = CreateEntityByName("info_particle_system");
                if (iTrailEntity && IsValidEdict(iTrailEntity))
                {
                    TeleportEntity(iTrailEntity, fPosition, fAngles, view_as<float>({0.0, 0.0, 0.0}));
                    DispatchKeyValue(iTrailEntity, "effect_name", g_strRocketClassTrail[iClass]);
                    DispatchSpawn(iTrailEntity);
                    ActivateEntity(iTrailEntity);
                    
                    if (TestFlags(iFlags, RocketFlag_RemoveParticles))
                    {
                        int iOtherEntity = EntRefToEntIndex(g_iRocketFakeEntity[iIndex]);
                        
                        if (iOtherEntity != -1)
                        {
                            SetVariantString("!activator");
                            AcceptEntityInput(iTrailEntity, "SetParent", iOtherEntity, iTrailEntity);
                            
                            SetVariantString("trail");
                            AcceptEntityInput(iTrailEntity, "SetParentAttachment", iOtherEntity, iTrailEntity);
                            
                            AcceptEntityInput(iTrailEntity, "Start");
                        }
                    }
                    else
                    {
                        SetVariantString("!activator");
                        AcceptEntityInput(iTrailEntity, "SetParent", iEntity, iTrailEntity);
                        
                        SetVariantString("trail");
                        AcceptEntityInput(iTrailEntity, "SetParentAttachment", iEntity, iTrailEntity);
                        
                        AcceptEntityInput(iTrailEntity, "Start");
                    }
                    
                    SetEdictFlags(iTrailEntity, (GetEdictFlags(iTrailEntity) & ~FL_EDICT_ALWAYS)); // Allows SetTransmit to work on info_particle_system
                    SDKHook(iTrailEntity, SDKHook_SetTransmit, TrailSetTransmit);
                }
            }
            
            if (TestFlags(iFlags, RocketFlag_CustomSprite))
            {
                int iSpriteEntity = CreateEntityByName("env_spritetrail");
                if (iSpriteEntity && IsValidEntity(iSpriteEntity))
                {
                    TeleportEntity(iSpriteEntity, fPosition, fAngles, view_as<float>({0.0, 0.0, 0.0}));
                    
                    char strSpritePath[PLATFORM_MAX_PATH];
                    FormatEx(strSpritePath, PLATFORM_MAX_PATH, "%s.vmt", g_strRocketClassSprite[iClass]);
                    
                    DispatchKeyValue(iSpriteEntity, "spritename", strSpritePath);
                    DispatchKeyValueFloat(iSpriteEntity, "lifetime", 1.0);
                    DispatchKeyValueFloat(iSpriteEntity, "endwidth", 15.0);
                    DispatchKeyValueFloat(iSpriteEntity, "startwidth", 6.0);
                    DispatchKeyValue(iSpriteEntity, "rendercolor", strlen(g_strRocketClassSpriteColor[iClass]) != 0 ? g_strRocketClassSpriteColor[iClass] : "255 255 255");
                    DispatchKeyValue(iSpriteEntity, "renderamt", "255");
                    DispatchKeyValue(iSpriteEntity, "rendermode", "3");
                    SetEntPropFloat(iSpriteEntity, Prop_Send, "m_flTextureRes", 0.05);
                    
                    if (TestFlags(iFlags, RocketFlag_RemoveParticles))
                    {
                        int iOtherEntity = EntRefToEntIndex(g_iRocketFakeEntity[iIndex]);
                        
                        if (iOtherEntity != -1)
                        {
                            SetVariantString("!activator");
                            AcceptEntityInput(iSpriteEntity, "SetParent", iOtherEntity, iSpriteEntity);
                            
                            SetVariantString("trail");
                            AcceptEntityInput(iSpriteEntity, "SetParentAttachment", iOtherEntity, iSpriteEntity);
                        }
                    }
                    else
                    {
                        SetVariantString("!activator");
                        AcceptEntityInput(iSpriteEntity, "SetParent", iEntity, iSpriteEntity);
                        
                        SetVariantString("trail");
                        AcceptEntityInput(iSpriteEntity, "SetParentAttachment", iEntity, iSpriteEntity);
                    }
                    
                    DispatchSpawn(iSpriteEntity);
                    SDKHook(iSpriteEntity, SDKHook_SetTransmit, SpriteSetTransmit);
                }
            }
            
            // Apply custom model, if specified on the flags.
            if (TestFlags(iFlags, RocketFlag_CustomModel))
            {
                SetEntityModel(iEntity, g_strRocketClassModel[iClass]);
                UpdateRocketSkin(iEntity, iTeam, TestFlags(iFlags, RocketFlag_IsNeutral));
                
                if (TestFlags(iFlags, RocketFlag_RemoveParticles))
                {
                    int iOtherEntity = EntRefToEntIndex(g_iRocketFakeEntity[iIndex]);
                    if (iOtherEntity != -1)
                    {
                        SetEntityModel(iOtherEntity, g_strRocketClassModel[iClass]);
                        UpdateRocketSkin(iOtherEntity, iTeam, TestFlags(iFlags, RocketFlag_IsNeutral));
                    }
                }
            }
            
            // Execute commands on spawn.
            if (TestFlags(iFlags, RocketFlag_OnSpawnCmd))
            {
                ExecuteCommands(g_hRocketClassCmdsOnSpawn[iClass], iClass, iEntity, 0, iTarget, g_iLastDeadClient, g_fRocketSpeed[iIndex], 0, g_fRocketMphSpeed[iIndex]);
            }
            
            // Emit required sounds.
            EmitRocketSound(RocketSound_Spawn, iClass, iEntity, iTarget, iFlags);
            EmitRocketSound(RocketSound_Alert, iClass, iEntity, iTarget, iFlags);
            
            // Done
            g_iRocketCount++;
            g_iRocketsFired++;
            g_fLastSpawnTime[iIndex] = GetGameTime();
            g_fNextSpawnTime = GetGameTime() + g_fSpawnersInterval[iSpawnerClass];
            
            SDKHook(iEntity, SDKHook_StartTouch, OnStartTouch);
        }
    }
}

public Action TrailSetTransmit(int iEntity, int iClient)
{
	if (IsValidEntity(iEntity))
	{
		if(GetEdictFlags(iEntity) & FL_EDICT_ALWAYS)
		{
			SetEdictFlags(iEntity, (GetEdictFlags(iEntity) ^ FL_EDICT_ALWAYS)); // Stops the game from setting back the flag
		}
	}
	
	return g_bClientHideTrails[iClient] ? Plugin_Handled : Plugin_Continue;
}

public Action SpriteSetTransmit(int iEntity, int iClient)
{
	return g_bClientHideSprites[iClient] ? Plugin_Handled : Plugin_Continue;
}

/* DestroyRocket()
**
** Destroys the rocket at the given index.
** -------------------------------------------------------------------------- */
void DestroyRocket(int iIndex)
{
    if (IsValidRocket(iIndex) == true)
    {
        int iEntity = EntRefToEntIndex(g_iRocketEntity[iIndex]);
        if (iEntity && IsValidEntity(iEntity)) RemoveEdict(iEntity);
        g_bRocketIsValid[iIndex] = false;
        g_iRocketCount--;
    }
}

/* DestroyRockets()
**
** Destroys all the rockets that are currently active.
** -------------------------------------------------------------------------- */
void DestroyRockets()
{
    for (int iIndex = 0; iIndex < MAX_ROCKETS; iIndex++)
    {
        DestroyRocket(iIndex);
    }
    g_iRocketCount = 0;
}

/* IsValidRocket()
**
** Checks if a rocket structure is valid.
** -------------------------------------------------------------------------- */
bool IsValidRocket(int iIndex)
{
    if ((iIndex >= 0) && (g_bRocketIsValid[iIndex] == true))
    {
        if (EntRefToEntIndex(g_iRocketEntity[iIndex]) == -1)
        {
            g_bRocketIsValid[iIndex] = false;
            g_iRocketCount--;
            return false;
        }
        return true;
    }
    return false;
}

/* FindNextValidRocket()
**
** Retrieves the index of the next valid rocket from the current offset.
** -------------------------------------------------------------------------- */
int FindNextValidRocket(int iIndex, bool bWrap = false)
{
    for (int iCurrent = iIndex + 1; iCurrent < MAX_ROCKETS; iCurrent++)
        if (IsValidRocket(iCurrent))
            return iCurrent;
        
    return (bWrap == true)? FindNextValidRocket(-1, false) : -1;
}

/* FindFreeRocketSlot()
**
** Retrieves the next free rocket slot since the current one. If all of them
** are full, returns -1.
** -------------------------------------------------------------------------- */
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

/* FindRocketByEntity()
**
** Finds a rocket index from it's entity.
** -------------------------------------------------------------------------- */
int FindRocketByEntity(int iEntity)
{
    int iIndex = -1;
    while ((iIndex = FindNextValidRocket(iIndex)) != -1)
        if (EntRefToEntIndex(g_iRocketEntity[iIndex]) == iEntity)
            return iIndex;
        
    return -1;
}

/* HomingRocketThinkg()
**
** Logic process for the Behaviour_Homing type rockets, wich is simply a
** follower rocket, picking a random target.
** -------------------------------------------------------------------------- */
void HomingRocketThink(int iIndex)
{
    // Retrieve the rocket's attributes.
    int iEntity          = EntRefToEntIndex(g_iRocketEntity[iIndex]);
    int iClass           = g_iRocketClass[iIndex];
    RocketFlags iFlags   = g_iRocketFlags[iIndex];
    int iTarget          = EntRefToEntIndex(g_iRocketTarget[iIndex]);
    int iTeam            = GetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1);
    int iTargetTeam      = (TestFlags(iFlags, RocketFlag_IsNeutral))? 0 : GetAnalogueTeam(iTeam);
    int iDeflectionCount = GetEntProp(iEntity, Prop_Send, "m_iDeflected") - 1;
    float fModifier      = CalculateModifier(iClass, iDeflectionCount);
    
    // Check if the target is available
    if (!IsValidClient(iTarget, true))
    {
        iTarget = SelectTarget(iTargetTeam);
        if (!IsValidClient(iTarget, true)) return;
        g_iRocketTarget[iIndex] = EntIndexToEntRef(iTarget);
        EmitRocketSound(RocketSound_Alert, iClass, iEntity, iTarget, iFlags);
        
        if (TestFlags(iFlags, RocketFlag_OnNoTargetCmd))
        {
            int iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
            if (!IsValidClient(iClient))
            {
                iClient = 0;
            }
            
            ExecuteCommands(g_hRocketClassCmdsOnNoTarget[iClass], iClass, iEntity, iClient, iTarget, g_iLastDeadClient, g_fRocketSpeed[iIndex], iDeflectionCount, g_fRocketMphSpeed[iIndex]);
        }
        
        if (g_hCvarNoTargetRedirectDamage.BoolValue)
        {
            SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 0.0, true);
        }
    }
    // Has the rocket been deflected recently? If so, set new target.
    else if ((iDeflectionCount > g_iRocketDeflections[iIndex]))
    {
        // Calculate new direction from the player's forward
        int iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
        g_bIsRocketStolen[iIndex] = false;
        if (IsValidClient(iClient))
        {
            float fViewAngles[3], fDirection[3];
            GetClientEyeAngles(iClient, fViewAngles);
            GetAngleVectors(fViewAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
            CopyVectors(fDirection, g_fRocketDirection[iIndex]);
            UpdateRocketSkin(iEntity, iTeam, TestFlags(iFlags, RocketFlag_IsNeutral));
            if (g_hCvarStealPrevention.BoolValue)
            {
                checkStolenRocket(iClient, iIndex);
            }
            
            if (TestFlags(iFlags, RocketFlag_RemoveParticles))
            {
                int iOtherEntity = EntRefToEntIndex(g_iRocketFakeEntity[iIndex]);
                if (iOtherEntity != -1)
                {
                    UpdateRocketSkin(iOtherEntity, iTeam, TestFlags(iFlags, RocketFlag_IsNeutral));
                }
            }
        }
        else
        {
            iClient = 0;
        }
        
        if (iDeflectionCount == 1)
        {
            if (iFlags & RocketFlag_IsNeutral)
            {
                SetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1, 1);
            }
            
            if (iFlags & RocketFlag_ResetBounces)
            {
                g_iRocketBounces[iIndex] = 0;
            }
            
            if (iFlags & RocketFlag_ReplaceParticles)
            {
                bool bCritical = !!GetEntProp(iEntity, Prop_Send, "m_bCritical");
                
                if (bCritical)
                {
                    int iRedCriticalEntity = EntRefToEntIndex(g_iRocketRedCriticalEntity[iIndex]);
                    int iBluCriticalEntity = EntRefToEntIndex(g_iRocketBluCriticalEntity[iIndex]);
                    
                    if (iRedCriticalEntity != -1 && iBluCriticalEntity != -1)
                    {
                        if (iTeam == view_as<int>(TFTeam_Red))
                        {
                            AcceptEntityInput(iBluCriticalEntity, "Stop");
                            AcceptEntityInput(iRedCriticalEntity, "Start");
                        }
                        else if (iTeam == view_as<int>(TFTeam_Blue))
                        {
                            AcceptEntityInput(iBluCriticalEntity, "Start");
                            AcceptEntityInput(iRedCriticalEntity, "Stop");
                        }
                    }
                }
            }
        }
        // Set new target & deflection count
        iTarget = SelectTarget(iTargetTeam, iIndex);
        g_iRocketTarget[iIndex]             = EntIndexToEntRef(iTarget);
        g_iRocketDeflections[iIndex]        = iDeflectionCount;
        g_fRocketLastDeflectionTime[iIndex] = GetGameTime();
        g_fRocketSpeed[iIndex]              = CalculateRocketSpeed(iClass, fModifier);
        g_fRocketMphSpeed[iIndex]           = CalculateRocketSpeed(iClass, fModifier) * 0.042614;
        g_bPreventingDelay[iIndex]          = false;
        SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, CalculateRocketDamage(iClass, fModifier), true);
        if (TestFlags(iFlags, RocketFlag_ElevateOnDeflect)) g_iRocketFlags[iIndex] |= RocketFlag_Elevating;
        EmitRocketSound(RocketSound_Alert, iClass, iEntity, iTarget, iFlags);
        
        if(g_iRocketFlags[iIndex] & RocketFlag_IsSpeedLimited)
        {
            if (g_fRocketSpeed[iIndex] >= g_fRocketClassSpeedLimit[iClass])
            {
                g_fRocketSpeed[iIndex] = g_fRocketClassSpeedLimit[iClass];
            }
        }
        
        if(g_bIsRocketStolen[iIndex] && g_hCvarStealPreventionDamage.BoolValue)
        {
            SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 0.0, true);
        }
        
        if (iFlags & RocketFlag_TeamlessHits)
        {
            SetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1, 1);
        }
        
        // Execute appropiate command
        if (TestFlags(iFlags, RocketFlag_OnDeflectCmd))
        {
            ExecuteCommands(g_hRocketClassCmdsOnDeflect[iClass], iClass, iEntity, iClient, iTarget, g_iLastDeadClient, g_fRocketSpeed[iIndex], iDeflectionCount, g_fRocketMphSpeed[iIndex]);
        }
    }
    else
    {
        // If the delay time since the last reflection has been elapsed, rotate towards the client.
        if ((GetGameTime() - g_fRocketLastDeflectionTime[iIndex]) >= g_fRocketClassControlDelay[iClass])
        {
            // Calculate turn rate and retrieve directions.
            float fTurnRate = CalculateRocketTurnRate(iClass, fModifier);
            float fDirectionToTarget[3]; CalculateDirectionToClient(iEntity, iTarget, fDirectionToTarget);
            
            // Elevate the rocket after a deflection (if it's enabled on the class definition, of course.)
            if (g_iRocketFlags[iIndex] & RocketFlag_Elevating)
            {
                if (g_fRocketDirection[iIndex][2] < g_fRocketClassElevationLimit[iClass])
                {
                    g_fRocketDirection[iIndex][2] = FMin(g_fRocketDirection[iIndex][2] + g_fRocketClassElevationRate[iClass], g_fRocketClassElevationLimit[iClass]);
                    fDirectionToTarget[2] = g_fRocketDirection[iIndex][2];
                }
                else
                {
                    g_iRocketFlags[iIndex] &= ~RocketFlag_Elevating;
                }
            }
            
            if(g_iRocketFlags[iIndex] & RocketFlag_IsLimited)
            {
                if (fTurnRate >= g_fRocketClassTurnRateLimit[iClass])
                {
                    fTurnRate = g_fRocketClassTurnRateLimit[iClass];
                }
            }
            
            // Smoothly change the orientation to the new one.
            LerpVectors(g_fRocketDirection[iIndex], fDirectionToTarget, g_fRocketDirection[iIndex], fTurnRate);
        }
        
        // If it's a nuke, beep every some time
        if ((GetGameTime() - g_fRocketLastBeepTime[iIndex]) >= g_fRocketClassBeepInterval[iClass])
        {
            EmitRocketSound(RocketSound_Beep, iClass, iEntity, iTarget, iFlags);
            g_fRocketLastBeepTime[iIndex] = GetGameTime();
        }
        
        if (g_hCvarDelayPrevention.BoolValue)
        {
            checkRoundDelays(iIndex);
        }
    }
    
    // Done
    ApplyRocketParameters(iIndex);
}

/* CalculateModifier()
**
** Gets the modifier for the damage/speed/rotation calculations.
** -------------------------------------------------------------------------- */
float CalculateModifier(int iClass, int iDeflections)
{
    return  iDeflections + 
            (g_iRocketsFired * g_fRocketClassRocketsModifier[iClass]) + 
            (g_iPlayerCount * g_fRocketClassPlayerModifier[iClass]);
}

/* CalculateRocketDamage()
**
** Calculates the damage of the rocket based on it's type and deflection count.
** -------------------------------------------------------------------------- */
float CalculateRocketDamage(int iClass, float fModifier)
{
    return g_fRocketClassDamage[iClass] + g_fRocketClassDamageIncrement[iClass] * fModifier;
}

/* CalculateRocketSpeed()
**
** Calculates the speed of the rocket based on it's type and deflection count.
** -------------------------------------------------------------------------- */
float CalculateRocketSpeed(int iClass, float fModifier)
{
    return g_fRocketClassSpeed[iClass] + g_fRocketClassSpeedIncrement[iClass] * fModifier;
}

/* CalculateRocketTurnRate()
**
** Calculates the rocket's turn rate based upon it's type and deflection count.
** -------------------------------------------------------------------------- */
float CalculateRocketTurnRate(int iClass, float fModifier)
{
    return g_fRocketClassTurnRate[iClass] + g_fRocketClassTurnRateIncrement[iClass] * fModifier;
}

/* CalculateDirectionToClient()
**
** As the name indicates, calculates the orientation for the rocket to move
** towards the specified client.
** -------------------------------------------------------------------------- */
void CalculateDirectionToClient(int iEntity, int iClient, float fOut[3])
{
    float fRocketPosition[3]; GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fRocketPosition);
    GetClientEyePosition(iClient, fOut);
    MakeVectorFromPoints(fRocketPosition, fOut, fOut);
    NormalizeVector(fOut, fOut);
}

/* ApplyRocketParameters()
**
** Transforms and applies the speed, direction and angles for the rocket
** entity.
** -------------------------------------------------------------------------- */
void ApplyRocketParameters(int iIndex)
{
    int iEntity = EntRefToEntIndex(g_iRocketEntity[iIndex]);
    float fAngles[3]; GetVectorAngles(g_fRocketDirection[iIndex], fAngles);
    float fVelocity[3]; CopyVectors(g_fRocketDirection[iIndex], fVelocity);
    ScaleVector(fVelocity, g_fRocketSpeed[iIndex]);
    SetEntPropVector(iEntity, Prop_Data, "m_vecAbsVelocity", fVelocity);
    SetEntPropVector(iEntity, Prop_Send, "m_angRotation", fAngles);
}

/* UpdateRocketSkin()
**
** Changes the skin of the rocket based on it's team.
** -------------------------------------------------------------------------- */
void UpdateRocketSkin(int iEntity, int iTeam, bool bNeutral)
{
    if (bNeutral == true) SetEntProp(iEntity, Prop_Send, "m_nSkin", 2);
    else                  SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam == view_as<int>(TFTeam_Blue))? 0 : 1);
}

/* GetRandomRocketClass()
**
** Generates a random value and retrieves a rocket class based upon a chances table.
** -------------------------------------------------------------------------- */
int GetRandomRocketClass(int iSpawnerClass)
{
    int iRandom = GetURandomIntRange(1, 100);
    ArrayList hTable = g_hSpawnersChancesTable[iSpawnerClass];
    int iTableSize = hTable.Length;
    int iChancesLower = 0;
    int iChancesUpper = 0;
    
    for (int iEntry = 0; iEntry < iTableSize; iEntry++)
    {
        iChancesLower += iChancesUpper;
        iChancesUpper  = iChancesLower + hTable.Get(iEntry);
        
        if ((iRandom >= iChancesLower) && (iRandom <= iChancesUpper))
        {
            return iEntry;
        }
    }
    
    return 0;
}

/* EmitRocketSound()
**
** Emits one of the rocket sounds
** -------------------------------------------------------------------------- */
void EmitRocketSound(RocketSound iSound, int iClass, int iEntity, int iTarget, RocketFlags iFlags)
{
    switch (iSound)
    {
        case RocketSound_Spawn:
        {
            if (TestFlags(iFlags, RocketFlag_PlaySpawnSound))
            {
                if (TestFlags(iFlags, RocketFlag_CustomSpawnSound)) EmitSoundToAll(g_strRocketClassSpawnSound[iClass], iEntity);
                else                                                EmitSoundToAll(SOUND_DEFAULT_SPAWN, iEntity);
            }
        }
        case RocketSound_Beep:
        {
            if (TestFlags(iFlags, RocketFlag_PlayBeepSound))
            {
                if (TestFlags(iFlags, RocketFlag_CustomBeepSound)) EmitSoundToAll(g_strRocketClassBeepSound[iClass], iEntity);
                else                                               EmitSoundToAll(SOUND_DEFAULT_BEEP, iEntity);
            }
        }
        case RocketSound_Alert:
        {
            if (TestFlags(iFlags, RocketFlag_PlayAlertSound))
            {
                if (TestFlags(iFlags, RocketFlag_CustomAlertSound)) EmitSoundToClient(iTarget, g_strRocketClassAlertSound[iClass]);
                else                                                EmitSoundToClient(iTarget, SOUND_DEFAULT_ALERT, _, _, _, _, 0.5);
            }
        }
    }
}

//  ___         _       _      ___ _                    
// | _ \___  __| |_____| |_   / __| |__ _ ______ ___ ___
// |   / _ \/ _| / / -_)  _| | (__| / _` (_-<_-</ -_|_-<
// |_|_\___/\__|_\_\___|\__|  \___|_\__,_/__/__/\___/__/
//                                                      

/* DestroyRocketClasses()
**
** Frees up all the rocket classes defined now.
** -------------------------------------------------------------------------- */
void DestroyRocketClasses()
{
    for (int iIndex = 0; iIndex < g_iRocketClassCount; iIndex++)
    {
        DataPack hCmdOnSpawn   = g_hRocketClassCmdsOnSpawn[iIndex];
        DataPack hCmdOnKill    = g_hRocketClassCmdsOnKill[iIndex];
        DataPack hCmdOnExplode = g_hRocketClassCmdsOnExplode[iIndex];
        DataPack hCmdOnDeflect = g_hRocketClassCmdsOnDeflect[iIndex];
        DataPack hCmdOnNoTarget = g_hRocketClassCmdsOnNoTarget[iIndex];
        if (hCmdOnSpawn   != null) delete hCmdOnSpawn;
        if (hCmdOnKill    != null) delete hCmdOnKill;
        if (hCmdOnExplode != null) delete hCmdOnExplode;
        if (hCmdOnDeflect != null) delete hCmdOnDeflect;
        if (hCmdOnNoTarget != null) delete hCmdOnNoTarget;
        g_hRocketClassCmdsOnSpawn[iIndex]   = null;
        g_hRocketClassCmdsOnKill[iIndex]    = null;
        g_hRocketClassCmdsOnExplode[iIndex] = null;
        g_hRocketClassCmdsOnDeflect[iIndex] = null;
        g_hRocketClassCmdsOnNoTarget[iIndex] = null;
    }
    g_iRocketClassCount = 0;
    g_hRocketClassTrie.Clear();
}

//  ___                          ___     _     _                     _    ___ _                    
// / __|_ __  __ ___ __ ___ _   | _ \___(_)_ _| |_ ___  __ _ _ _  __| |  / __| |__ _ ______ ___ ___
// \__ \ '_ \/ _` \ V  V / ' \  |  _/ _ \ | ' \  _(_-< / _` | ' \/ _` | | (__| / _` (_-<_-</ -_|_-<
// |___/ .__/\__,_|\_/\_/|_||_| |_| \___/_|_||_\__/__/ \__,_|_||_\__,_|  \___|_\__,_/__/__/\___/__/
//     |_|                                                                                         

/* DestroySpawners()
**
** Frees up all the spawner points defined up to now.
** -------------------------------------------------------------------------- */
void DestroySpawners()
{
    for (int iIndex = 0; iIndex < g_iSpawnersCount; iIndex++)
    {
        delete g_hSpawnersChancesTable[iIndex];
        delete g_hSavedChancesTable[iIndex];
    }
    g_iSpawnersCount  = 0;
    g_iSpawnPointsRedCount = 0;
    g_iSpawnPointsBluCount = 0;
    g_iDefaultRedSpawner = -1;
    g_iDefaultBluSpawner = -1;
    g_hSpawnersTrie.Clear();
}

/* PopulateSpawnPoints()
**
** Iterates through all the possible spawn points and assigns them an spawner.
** -------------------------------------------------------------------------- */
void PopulateSpawnPoints()
{
    // Clear the current settings
    g_iSpawnPointsRedCount = 0;
    g_iSpawnPointsBluCount = 0;
    
    // Iterate through all the info target points and check 'em out.
    int iEntity = -1;
    while ((iEntity = FindEntityByClassname(iEntity, "info_target")) != -1)
    {
        char strName[32]; GetEntPropString(iEntity, Prop_Data, "m_iName", strName, sizeof(strName));
        if ((StrContains(strName, "rocket_spawn_red") != -1) || (StrContains(strName, "tf_dodgeball_red") != -1))
        {
            // Find most appropiate spawner class for this entity.
            int iIndex = FindSpawnerByName(strName);
            if (!IsValidRocket(iIndex)) iIndex = g_iDefaultRedSpawner;
            
            // Upload to point list
            g_iSpawnPointsRedClass [g_iSpawnPointsRedCount] = iIndex;
            g_iSpawnPointsRedEntity[g_iSpawnPointsRedCount] = iEntity;
            g_iSpawnPointsRedCount++;
        }
        if ((StrContains(strName, "rocket_spawn_blu") != -1) || (StrContains(strName, "tf_dodgeball_blu") != -1))
        {
            // Find most appropiate spawner class for this entity.
            int iIndex = FindSpawnerByName(strName);
            if (!IsValidRocket(iIndex)) iIndex = g_iDefaultBluSpawner;
            
            // Upload to point list
            g_iSpawnPointsBluClass [g_iSpawnPointsBluCount] = iIndex;
            g_iSpawnPointsBluEntity[g_iSpawnPointsBluCount] = iEntity;
            g_iSpawnPointsBluCount++;
        }
    }
    
    // Check if there exists spawn points
    if (g_iSpawnPointsRedCount == 0) SetFailState("No RED spawn points found on this map.");
    if (g_iSpawnPointsBluCount == 0) SetFailState("No BLU spawn points found on this map.");
}

/* FindSpawnerByName()
**
** Finds the first spawner wich contains the given name.
** -------------------------------------------------------------------------- */
int FindSpawnerByName(char strName[32])
{
    int iIndex = -1;
    g_hSpawnersTrie.GetValue(strName, iIndex);
    return iIndex;
}        


/*
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
**    ______                                          __    
**   / ____/___  ____ ___  ____ ___  ____ _____  ____/ /____
**  / /   / __ \/ __ `__ \/ __ `__ \/ __ `/ __ \/ __  / ___/
** / /___/ /_/ / / / / / / / / / / / /_/ / / / / /_/ (__  ) 
** \____/\____/_/ /_/ /_/_/ /_/ /_/\__,_/_/ /_/\__,_/____/  
**                                                          
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
*/

/* RegisterCommands()
**
** Creates helper server commands to use with the plugin's events system.
** -------------------------------------------------------------------------- */
void RegisterCommands()
{
    RegServerCmd("tf_dodgeball_explosion", CmdExplosion);
    RegServerCmd("tf_dodgeball_shockwave", CmdShockwave);
    RegAdminCmd("tf_dodgeball_rocketspeed", CmdChangeSpeed, ADMFLAG_CONFIG, "Change rocket speed parameters.");
    RegAdminCmd("tf_dodgeball_rocketturnrate", CmdChangeTurnRate, ADMFLAG_CONFIG, "Change rocket turnrate parameters.");
    RegAdminCmd("tf_dodgeball_rocketelevation", CmdChangeElevation, ADMFLAG_CONFIG, "Change rocket elevation parameters.");
    RegAdminCmd("tf_dodgeball_spawners", CmdChangeSpawners, ADMFLAG_CONFIG, "Change the spawners' settings.");
    RegAdminCmd("tf_dodgeball_refresh", CmdRefresh, ADMFLAG_CONFIG, "Refresh the configuration.");
    RegAdminCmd("tf_dodgeball_destroyrockets", CmdDestroyRockets, ADMFLAG_CONFIG, "Destroy all current rockets.");
    RegAdminCmd("tf_dodgeball_rocketotherparams", CmdOtherParams, ADMFLAG_CONFIG, "Change other rocket parameters.");
    RegConsoleCmd("sm_togglerockettrails", CmdHideTrails);
    RegConsoleCmd("sm_togglerocketsprites", CmdHideSprites);
}

/* CmdExplosion()
**
** Creates a huge explosion at the location of the client.
** -------------------------------------------------------------------------- */
public Action CmdExplosion(int iArgs)
{
    if (iArgs == 1 && g_bEnabled)
    {
        char strBuffer[8]; int iClient;
        GetCmdArg(1, strBuffer, sizeof(strBuffer));
        iClient = StringToInt(strBuffer);
        if (IsValidEntity(iClient))
        {
            float fPosition[3]; GetClientAbsOrigin(iClient, fPosition);
            switch (GetURandomIntRange(0, 4))
            {
                case 0: { PlayParticle(fPosition, PARTICLE_NUKE_1_ANGLES, PARTICLE_NUKE_1); }
                case 1: { PlayParticle(fPosition, PARTICLE_NUKE_2_ANGLES, PARTICLE_NUKE_2); }
                case 2: { PlayParticle(fPosition, PARTICLE_NUKE_3_ANGLES, PARTICLE_NUKE_3); }
                case 3: { PlayParticle(fPosition, PARTICLE_NUKE_4_ANGLES, PARTICLE_NUKE_4); }
                case 4: { PlayParticle(fPosition, PARTICLE_NUKE_5_ANGLES, PARTICLE_NUKE_5); }
            }
            PlayParticle(fPosition, PARTICLE_NUKE_COLLUMN_ANGLES, PARTICLE_NUKE_COLLUMN);
        }
    }
    else
    {
        PrintToServer("%t", g_bEnabled ? "Command_DBExplosion_Usage" : "Command_Disabled");
    }
    
    return Plugin_Handled;
}

/* CmdShockwave()
**
** Creates a huge shockwave at the location of the client, with the given
** parameters.
** -------------------------------------------------------------------------- */
public Action CmdShockwave(int iArgs)
{
    if (iArgs == 5 && g_bEnabled)
    {
        char strBuffer[8]; int iClient, iTeam; float fPosition[3]; int iDamage; float fPushStrength, fRadius, fFalloffRadius;
        GetCmdArg(1, strBuffer, sizeof(strBuffer)); iClient        = StringToInt(strBuffer);
        GetCmdArg(2, strBuffer, sizeof(strBuffer)); iDamage        = StringToInt(strBuffer);
        GetCmdArg(3, strBuffer, sizeof(strBuffer)); fPushStrength  = StringToFloat(strBuffer);
        GetCmdArg(4, strBuffer, sizeof(strBuffer)); fRadius        = StringToFloat(strBuffer);
        GetCmdArg(5, strBuffer, sizeof(strBuffer)); fFalloffRadius = StringToFloat(strBuffer);
        
        if (IsValidClient(iClient))
        {
            iTeam = GetClientTeam(iClient);
            GetClientAbsOrigin(iClient, fPosition);
            
            for (iClient = 1; iClient <= MaxClients; iClient++)
            {
                if ((IsValidClient(iClient, true) == true) && (GetClientTeam(iClient) == iTeam))
                {
                    float fPlayerPosition[3]; GetClientEyePosition(iClient, fPlayerPosition);
                    float fDistanceToShockwave = GetVectorDistance(fPosition, fPlayerPosition);
                    
                    if (fDistanceToShockwave < fRadius)
                    {
                        float fImpulse[3], fFinalPush; int iFinalDamage;
                        fImpulse[0] = fPlayerPosition[0] - fPosition[0];
                        fImpulse[1] = fPlayerPosition[1] - fPosition[1];
                        fImpulse[2] = fPlayerPosition[2] - fPosition[2];
                        NormalizeVector(fImpulse, fImpulse);
                        if (fImpulse[2] < 0.4) { fImpulse[2] = 0.4; NormalizeVector(fImpulse, fImpulse); }
                        
                        if (fDistanceToShockwave < fFalloffRadius)
                        {
                            fFinalPush = fPushStrength;
                            iFinalDamage = iDamage;
                        }
                        else
                        {
                            float fImpact = (1.0 - ((fDistanceToShockwave - fFalloffRadius) / (fRadius - fFalloffRadius)));
                            fFinalPush   = fImpact * fPushStrength;
                            iFinalDamage = RoundToFloor(fImpact * iDamage);
                        }
                        ScaleVector(fImpulse, fFinalPush);
                        SlapPlayer(iClient, iFinalDamage, true);
                        SetEntPropVector(iClient, Prop_Data, "m_vecAbsVelocity", fImpulse);
                    }
                }
            }
        }
    }
    else
    {
        PrintToServer("%t", g_bEnabled ? "Command_DBShockwave_Usage" : "Command_Disabled");
    }
    
    return Plugin_Handled;
}

public Action CmdChangeSpeed(int iClient, int iArgs)
{
	if (iArgs == 4 && g_bEnabled)
	{
		char strBuffer[8]; int iIndex; float fRocketSpeed, fRocketSpeedIncrement, fRocketSpeedLimit;
		GetCmdArg(1, strBuffer, sizeof(strBuffer)); iIndex                = StringToInt(strBuffer);
		GetCmdArg(2, strBuffer, sizeof(strBuffer)); fRocketSpeed          = StringToFloat(strBuffer);
		GetCmdArg(3, strBuffer, sizeof(strBuffer)); fRocketSpeedIncrement = StringToFloat(strBuffer);
		GetCmdArg(4, strBuffer, sizeof(strBuffer)); fRocketSpeedLimit     = StringToFloat(strBuffer);
		
		if ((iIndex >= g_iRocketClassCount) || (iIndex < 0))
		{
			return Plugin_Handled;
		}
		
		if (fRocketSpeedLimit == 0)
		{
			if (g_iRocketClassFlags[iIndex] & RocketFlag_IsSpeedLimited)
			{
				g_iRocketClassFlags[iIndex] &= ~RocketFlag_IsSpeedLimited;
			}
		}
		else if (fRocketSpeedLimit == -1)
		{
			g_fRocketClassSpeedLimit[iIndex] = g_fSavedParameters[iIndex][2];
			
			if ((g_iSavedRocketClassFlags[iIndex] & RocketFlag_IsSpeedLimited) && !(g_iRocketClassFlags[iIndex] & RocketFlag_IsSpeedLimited))
			{
				g_iRocketClassFlags[iIndex] |= RocketFlag_IsSpeedLimited;
			}
			else if (!(g_iSavedRocketClassFlags[iIndex] & RocketFlag_IsSpeedLimited) && (g_iRocketClassFlags[iIndex] & RocketFlag_IsSpeedLimited))
			{
				g_iRocketClassFlags[iIndex] &= ~RocketFlag_IsSpeedLimited;
			}
		}
		else
		{
			if (!(g_iRocketClassFlags[iIndex] & RocketFlag_IsSpeedLimited))
			{
				g_iRocketClassFlags[iIndex] |= RocketFlag_IsSpeedLimited;
			}
			
			g_fRocketClassSpeedLimit[iIndex]  = fRocketSpeedLimit;
		}
		
		g_fRocketClassSpeed[iIndex]          = fRocketSpeed == -1 ? g_fSavedParameters[iIndex][0] : fRocketSpeed;
		g_fRocketClassSpeedIncrement[iIndex] = fRocketSpeedIncrement == -1 ? g_fSavedParameters[iIndex][1] : fRocketSpeedIncrement;
		
		DestroyRockets();
	}
	else
	{
		CReplyToCommand(iClient, "%t", g_bEnabled ? "Command_DBRocketSpeed_Usage" : "Command_Disabled");
	}
	
	return Plugin_Handled;
}

public Action CmdChangeTurnRate(int iClient, int iArgs)
{
	if (iArgs == 4 && g_bEnabled)
	{
		char strBuffer[8]; int iIndex; float fRocketTurnRate, fRocketTurnRateIncrement, fRocketTurnRateLimit;
		GetCmdArg(1, strBuffer, sizeof(strBuffer)); iIndex                   = StringToInt(strBuffer);
		GetCmdArg(2, strBuffer, sizeof(strBuffer)); fRocketTurnRate          = StringToFloat(strBuffer);
		GetCmdArg(3, strBuffer, sizeof(strBuffer)); fRocketTurnRateIncrement = StringToFloat(strBuffer);
		GetCmdArg(4, strBuffer, sizeof(strBuffer)); fRocketTurnRateLimit     = StringToFloat(strBuffer);
		
		if ((iIndex >= g_iRocketClassCount) || (iIndex < 0))
		{
			return Plugin_Handled;
		}
		
		if (fRocketTurnRateLimit == 0)
		{
			if (g_iRocketClassFlags[iIndex] & RocketFlag_IsLimited)
			{
				g_iRocketClassFlags[iIndex] &= ~RocketFlag_IsLimited;
			}
		}
		else if (fRocketTurnRateLimit == -1)
		{
			g_fRocketClassTurnRateLimit[iIndex] = g_fSavedParameters[iIndex][5];
			
			if ((g_iSavedRocketClassFlags[iIndex] & RocketFlag_IsLimited) && !(g_iRocketClassFlags[iIndex] & RocketFlag_IsLimited))
			{
				g_iRocketClassFlags[iIndex] |= RocketFlag_IsLimited;
			}
			else if (!(g_iSavedRocketClassFlags[iIndex] & RocketFlag_IsLimited) && (g_iRocketClassFlags[iIndex] & RocketFlag_IsLimited))
			{
				g_iRocketClassFlags[iIndex] &= ~RocketFlag_IsLimited;
			}
		}
		else
		{
			if (!(g_iRocketClassFlags[iIndex] & RocketFlag_IsLimited))
			{
				g_iRocketClassFlags[iIndex] |= RocketFlag_IsLimited;
			}
			
			g_fRocketClassTurnRateLimit[iIndex]  = fRocketTurnRateLimit;
		}
		
		g_fRocketClassTurnRate[iIndex]          = fRocketTurnRate == -1 ? g_fSavedParameters[iIndex][3] : fRocketTurnRate;
		g_fRocketClassTurnRateIncrement[iIndex] = fRocketTurnRateIncrement == -1 ? g_fSavedParameters[iIndex][4] : fRocketTurnRateIncrement;
		
		DestroyRockets();
	}
	else
	{
		CReplyToCommand(iClient, "%t", g_bEnabled ? "Command_DBRocketTurnRate_Usage" : "Command_Disabled");
	}
	
	return Plugin_Handled;
}

public Action CmdChangeElevation(int iClient, int iArgs)
{
	if (iArgs == 3 && g_bEnabled)
	{
		char strBuffer[8]; int iIndex; float fRocketElevationRate, fRocketElevationLimit;
		GetCmdArg(1, strBuffer, sizeof(strBuffer)); iIndex                = StringToInt(strBuffer);
		GetCmdArg(2, strBuffer, sizeof(strBuffer)); fRocketElevationRate  = StringToFloat(strBuffer);
		GetCmdArg(3, strBuffer, sizeof(strBuffer)); fRocketElevationLimit = StringToFloat(strBuffer);
		
		if ((iIndex >= g_iRocketClassCount) || (iIndex < 0))
		{
			return Plugin_Handled;
		}
		
		if (fRocketElevationLimit == 0)
		{
			if (g_iRocketClassFlags[iIndex] & RocketFlag_ElevateOnDeflect)
			{
				g_iRocketClassFlags[iIndex] &= ~RocketFlag_ElevateOnDeflect;
				g_iRocketFlags[iIndex]      &= ~RocketFlag_Elevating;
			}
		}
		else if (fRocketElevationLimit == -1)
		{
			g_fRocketClassElevationLimit[iIndex] = g_fSavedParameters[iIndex][7];
			
			if ((g_iSavedRocketClassFlags[iIndex] & RocketFlag_ElevateOnDeflect) && !(g_iRocketClassFlags[iIndex] & RocketFlag_ElevateOnDeflect))
			{
				g_iRocketClassFlags[iIndex] |= RocketFlag_ElevateOnDeflect;
			}
			else if (!(g_iSavedRocketClassFlags[iIndex] & RocketFlag_ElevateOnDeflect) && (g_iRocketClassFlags[iIndex] & RocketFlag_ElevateOnDeflect))
			{
				g_iRocketClassFlags[iIndex] &= ~RocketFlag_ElevateOnDeflect;
				g_iRocketClassFlags[iIndex] &= ~RocketFlag_Elevating;
			}
		}
		else
		{
			if (!(g_iRocketClassFlags[iIndex] & RocketFlag_ElevateOnDeflect))
			{
				g_iRocketClassFlags[iIndex] |= RocketFlag_ElevateOnDeflect;
			}
			
			g_fRocketClassElevationLimit[iIndex] = fRocketElevationLimit;
		}
		
		g_fRocketClassElevationRate[iIndex] = fRocketElevationRate == -1 ? g_fSavedParameters[iIndex][6] : fRocketElevationRate;
		
		DestroyRockets();
	}
	else
	{
		CReplyToCommand(iClient, "%t", g_bEnabled ? "Command_DBRocketElevation_Usage" : "Command_Disabled");
	}
	
	return Plugin_Handled;
}

public Action CmdChangeSpawners(int iClient, int iArgs)
{
	if (iArgs == 3 && g_bEnabled)
	{
		char strBuffer[8]; int iIndex, iMaxRockets, iChances;
		GetCmdArg(1, strBuffer, sizeof(strBuffer)); iMaxRockets = StringToInt(strBuffer);
		GetCmdArg(2, strBuffer, sizeof(strBuffer)); iIndex      = StringToInt(strBuffer);
		GetCmdArg(3, strBuffer, sizeof(strBuffer)); iChances    = StringToInt(strBuffer);
		
		int iSpawnerClassBlu = g_iSpawnPointsBluClass[g_iCurrentBluSpawn];
		g_iSpawnersMaxRockets[iSpawnerClassBlu] = iMaxRockets;
		
		int iSpawnerClassRed = g_iSpawnPointsRedClass[g_iCurrentRedSpawn];
		g_iSpawnersMaxRockets[iSpawnerClassRed] = iMaxRockets;
		
		int iTableSizeBlu = g_hSpawnersChancesTable[iSpawnerClassBlu].Length;
		int iTableSizeRed = g_hSpawnersChancesTable[iSpawnerClassRed].Length;
		
		if ((iIndex >= iTableSizeBlu) || (iIndex >= iTableSizeRed) || (iIndex < 0))
		{
			return Plugin_Handled;
		}
		
		if (iChances == -1)
		{
			int iDefaultChancesBlu = g_hSavedChancesTable[iSpawnerClassBlu].Get(iIndex);
			int iDefaultChancesRed = g_hSavedChancesTable[iSpawnerClassRed].Get(iIndex);
			
			g_hSpawnersChancesTable[iSpawnerClassBlu].Set(iIndex, iDefaultChancesBlu);
			g_hSpawnersChancesTable[iSpawnerClassRed].Set(iIndex, iDefaultChancesRed);
		}
		else
		{
			g_hSpawnersChancesTable[iSpawnerClassBlu].Set(iIndex, iChances);
			g_hSpawnersChancesTable[iSpawnerClassRed].Set(iIndex, iChances);
		}
	}
	else
	{
		CReplyToCommand(iClient, "%t", g_bEnabled ? "Command_DBSpawners_Usage" : "Command_Disabled");
	}
	
	return Plugin_Handled;
}

public Action CmdRefresh(int iClient, int iArgs)
{
	if (!iArgs && g_bEnabled)
	{
		// Clean up everything
		DestroyRocketClasses();
		DestroySpawners();
		// Then reinitialize
		char strMapName[64]; GetCurrentMap(strMapName, sizeof(strMapName));
		char strMapFile[PLATFORM_MAX_PATH]; FormatEx(strMapFile, sizeof(strMapFile), "%s.cfg", strMapName);
		ParseConfigurations();
		ParseConfigurations(strMapFile);
		PopulateSpawnPoints();
		CPrintToChatAll("%t", "Command_DBRefresh_Done", iClient);
	}
	else
	{
		CReplyToCommand(iClient, "%t", g_bEnabled ? "Command_DBRefresh_Usage" : "Command_Disabled");
	}
	
	return Plugin_Handled;
}

public Action CmdDestroyRockets(int iClient, int iArgs)
{
	if (!iArgs && g_bEnabled)
	{
		DestroyRockets();
	}
	else
	{
		CReplyToCommand(iClient, "%t", g_bEnabled ? "Command_DBRocketDestroy_Usage" : "Command_Disabled");
	}
	
	return Plugin_Handled;
}

public Action CmdOtherParams(int iClient, int iArgs)
{
	if (iArgs == 6 && g_bEnabled)
	{
		char strBuffer[8]; int iIndex, bIsNeutral, bKeepDirection, bTeamlessHits, bResetBounces, iMaxBounces;
		GetCmdArg(1, strBuffer, sizeof(strBuffer)); iIndex         = StringToInt(strBuffer);
		GetCmdArg(2, strBuffer, sizeof(strBuffer)); bIsNeutral     = StringToInt(strBuffer);
		GetCmdArg(3, strBuffer, sizeof(strBuffer)); bKeepDirection = StringToInt(strBuffer);
		GetCmdArg(4, strBuffer, sizeof(strBuffer)); bTeamlessHits  = StringToInt(strBuffer);
		GetCmdArg(5, strBuffer, sizeof(strBuffer)); bResetBounces  = StringToInt(strBuffer);
		GetCmdArg(6, strBuffer, sizeof(strBuffer)); iMaxBounces    = StringToInt(strBuffer);
		
		if ((iIndex >= g_iRocketClassCount) || (iIndex < 0))
		{
			return Plugin_Handled;
		}
		
		switch (bIsNeutral)
		{
			case -1:
			{
				if ((g_iSavedRocketClassFlags[iIndex] & RocketFlag_IsNeutral) && !(g_iRocketClassFlags[iIndex] & RocketFlag_IsNeutral))
				{
					g_iRocketClassFlags[iIndex] |= RocketFlag_IsNeutral;
				}
				else if (!(g_iSavedRocketClassFlags[iIndex] & RocketFlag_IsNeutral) && (g_iRocketClassFlags[iIndex] & RocketFlag_IsNeutral))
				{
					g_iRocketClassFlags[iIndex] &= ~RocketFlag_IsNeutral;
				}
			}
			case 0:
			{
				if (g_iRocketClassFlags[iIndex] & RocketFlag_IsNeutral)
				{
					g_iRocketClassFlags[iIndex] &= ~RocketFlag_IsNeutral;
				}
			}
			case 1:
			{
				if (!(g_iRocketClassFlags[iIndex] & RocketFlag_IsNeutral))
				{
					g_iRocketClassFlags[iIndex] |= RocketFlag_IsNeutral;
				}
			}
		}
		
		switch (bKeepDirection)
		{
			case -1:
			{
				if ((g_iSavedRocketClassFlags[iIndex] & RocketFlag_KeepDirection) && !(g_iRocketClassFlags[iIndex] & RocketFlag_KeepDirection))
				{
					g_iRocketClassFlags[iIndex] |= RocketFlag_KeepDirection;
				}
				else if (!(g_iSavedRocketClassFlags[iIndex] & RocketFlag_KeepDirection) && (g_iRocketClassFlags[iIndex] & RocketFlag_KeepDirection))
				{
					g_iRocketClassFlags[iIndex] &= ~RocketFlag_KeepDirection;
				}
			}
			case 0:
			{
				if (g_iRocketClassFlags[iIndex] & RocketFlag_KeepDirection)
				{
					g_iRocketClassFlags[iIndex] &= ~RocketFlag_KeepDirection;
				}
			}
			case 1:
			{
				if (!(g_iRocketClassFlags[iIndex] & RocketFlag_KeepDirection))
				{
					g_iRocketClassFlags[iIndex] |= RocketFlag_KeepDirection;
				}
			}
		}
		
		switch (bTeamlessHits)
		{
			case -1:
			{
				if ((g_iSavedRocketClassFlags[iIndex] & RocketFlag_TeamlessHits) && !(g_iRocketClassFlags[iIndex] & RocketFlag_TeamlessHits))
				{
					g_iRocketClassFlags[iIndex] |= RocketFlag_TeamlessHits;
				}
				else if (!(g_iSavedRocketClassFlags[iIndex] & RocketFlag_TeamlessHits) && (g_iRocketClassFlags[iIndex] & RocketFlag_TeamlessHits))
				{
					g_iRocketClassFlags[iIndex] &= ~RocketFlag_TeamlessHits;
				}
			}
			case 0:
			{
				if (g_iRocketClassFlags[iIndex] & RocketFlag_TeamlessHits)
				{
					g_iRocketClassFlags[iIndex] &= ~RocketFlag_TeamlessHits;
				}
			}
			case 1:
			{
				if (!(g_iRocketClassFlags[iIndex] & RocketFlag_TeamlessHits))
				{
					g_iRocketClassFlags[iIndex] |= RocketFlag_TeamlessHits;
				}
			}
		}
		
		switch (bResetBounces)
		{
			case -1:
			{
				if ((g_iSavedRocketClassFlags[iIndex] & RocketFlag_ResetBounces) && !(g_iRocketClassFlags[iIndex] & RocketFlag_ResetBounces))
				{
					g_iRocketClassFlags[iIndex] |= RocketFlag_ResetBounces;
				}
				else if (!(g_iSavedRocketClassFlags[iIndex] & RocketFlag_ResetBounces) && (g_iRocketClassFlags[iIndex] & RocketFlag_ResetBounces))
				{
					g_iRocketClassFlags[iIndex] &= ~RocketFlag_ResetBounces;
				}
			}
			case 0:
			{
				if (g_iRocketClassFlags[iIndex] & RocketFlag_ResetBounces)
				{
					g_iRocketClassFlags[iIndex] &= ~RocketFlag_ResetBounces;
				}
			}
			case 1:
			{
				if (!(g_iRocketClassFlags[iIndex] & RocketFlag_ResetBounces))
				{
					g_iRocketClassFlags[iIndex] |= RocketFlag_ResetBounces;
				}
			}
		}
		
		g_iRocketClassMaxBounces[iIndex] = iMaxBounces == -1 ? g_iRocketClassSavedMaxBounces[iIndex] : iMaxBounces;
		
		DestroyRockets();
	}
	else
	{
		CReplyToCommand(iClient, "%t", g_bEnabled ? "Command_DBRocketOtherParams_Usage" : "Command_Disabled");
	}
	
	return Plugin_Handled;
}

public Action CmdHideTrails(int iClient, int iArgs)
{
	if (iClient == 0)
	{
		ReplyToCommand(iClient, "Command is in-game only.");
		return Plugin_Handled;
	}
	
	if (!iArgs && g_bEnabled)
	{
		g_bClientHideTrails[iClient] = !g_bClientHideTrails[iClient];
		
		CPrintToChat(iClient, "%t", g_bClientHideTrails[iClient] ? "Command_DBHideParticles_Hidden" : "Command_DBHideParticles_Visible");
	}
	else
	{
		CReplyToCommand(iClient, "%t", g_bEnabled ? "Command_DBHideParticles_Usage" : "Command_Disabled");
	}
	
	return Plugin_Handled;
}

public Action CmdHideSprites(int iClient, int iArgs)
{
	if (iClient == 0)
	{
		ReplyToCommand(iClient, "Command is in-game only.");
		return Plugin_Handled;
	}
	
	if (!iArgs && g_bEnabled)
	{
		g_bClientHideSprites[iClient] = !g_bClientHideSprites[iClient];
		
		CPrintToChat(iClient, "%t", g_bClientHideSprites[iClient] ? "Command_DBHideSprites_Hidden" : "Command_DBHideSprites_Visible");
	}
	else
	{
		CReplyToCommand(iClient, "%t", g_bEnabled ? "Command_DBHideSprites_Usage" : "Command_Disabled");
	}
	
	return Plugin_Handled;
}

/* ExecuteCommands()
**
** The core of the plugin's event system, unpacks and correctly formats the
** given command strings to be executed.
** -------------------------------------------------------------------------- */
void ExecuteCommands(DataPack hDataPack, int iClass, int iRocket, int iOwner, int iTarget, int iLastDead, float fSpeed, int iNumDeflections, float fMphSpeed)
{
    hDataPack.Reset(false);
    int iNumCommands = hDataPack.ReadCell();
    while (iNumCommands-- > 0)
    {
        char strCmd[256], strBuffer[32];
        hDataPack.ReadString(strCmd, sizeof(strCmd));
        ReplaceString(strCmd, sizeof(strCmd), "@name", g_strRocketClassLongName[iClass]);
        FormatEx(strBuffer, sizeof(strBuffer), "%i", iRocket);                ReplaceString(strCmd, sizeof(strCmd), "@rocket", strBuffer);
        FormatEx(strBuffer, sizeof(strBuffer), "%i", iOwner);                 ReplaceString(strCmd, sizeof(strCmd), "@owner", strBuffer);
        FormatEx(strBuffer, sizeof(strBuffer), "%i", iTarget);                ReplaceString(strCmd, sizeof(strCmd), "@target", strBuffer);
        FormatEx(strBuffer, sizeof(strBuffer), "%i", iLastDead);              ReplaceString(strCmd, sizeof(strCmd), "@dead", strBuffer);
        FormatEx(strBuffer, sizeof(strBuffer), "%.2f", fSpeed);               ReplaceString(strCmd, sizeof(strCmd), "@speed", strBuffer);
        FormatEx(strBuffer, sizeof(strBuffer), "%i", iNumDeflections);        ReplaceString(strCmd, sizeof(strCmd), "@deflections", strBuffer);
        FormatEx(strBuffer, sizeof(strBuffer), "%i", RoundFloat(fMphSpeed));  ReplaceString(strCmd, sizeof(strCmd), "@mphspeed", strBuffer);
        FormatEx(strBuffer, sizeof(strBuffer), "%.2f", fMphSpeed / 0.042614); ReplaceString(strCmd, sizeof(strCmd), "@nocapspeed", strBuffer);
        ServerCommand(strCmd);
    }
}

/*
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
**    ______            _____      
**   / ____/___  ____  / __(_)___ _
**  / /   / __ \/ __ \/ /_/ / __ `/
** / /___/ /_/ / / / / __/ / /_/ / 
** \____/\____/_/ /_/_/ /_/\__, /  
**                        /____/   
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
*/

/* ParseConfiguration()
**
** Parses a Dodgeball configuration file. It doesn't clear any of the previous
** data, so multiple files can be parsed.
** -------------------------------------------------------------------------- */
bool ParseConfigurations(char[] strConfigFile = "general.cfg")
{
    // Parse configuration
    char strPath[PLATFORM_MAX_PATH];
    char strFileName[PLATFORM_MAX_PATH];
    FormatEx(strFileName, sizeof(strFileName), "configs/dodgeball/%s", strConfigFile);
    BuildPath(Path_SM, strPath, sizeof(strPath), strFileName);
    
    // Try to parse if it exists
    LogMessage("Executing configuration file %s", strPath);
    if (FileExists(strPath, true))
    {
        KeyValues kvConfig = new KeyValues("TF2_Dodgeball");
        if (kvConfig.ImportFromFile(strPath) == false) SetFailState("Error while parsing the configuration file.");
        kvConfig.GotoFirstSubKey();
        
        // Parse the subsections
        do
        {
            char strSection[64]; kvConfig.GetSectionName(strSection, sizeof(strSection));
            
            if (StrEqual(strSection, "general"))       ParseGeneral(kvConfig);
            else if (StrEqual(strSection, "classes"))  ParseClasses(kvConfig);
            else if (StrEqual(strSection, "spawners")) ParseSpawners(kvConfig);
        }
        while (kvConfig.GotoNextKey());
        
        delete kvConfig;
    }
}

/* ParseGeneral()
**
** Parses general settings, such as the music, urls, etc.
** -------------------------------------------------------------------------- */
void ParseGeneral(KeyValues kvConfig)
{
    g_bMusicEnabled = view_as<bool>(kvConfig.GetNum("music", 0));
    if (g_bMusicEnabled == true)
    {
        g_bUseWebPlayer = view_as<bool>(kvConfig.GetNum("use web player", 0));
        kvConfig.GetString("web player url", g_strWebPlayerUrl, sizeof(g_strWebPlayerUrl));
        
        g_bMusic[Music_RoundStart] = kvConfig.GetString("round start",      g_strMusic[Music_RoundStart], PLATFORM_MAX_PATH) && strlen(g_strMusic[Music_RoundStart]);
        g_bMusic[Music_RoundWin]   = kvConfig.GetString("round end (win)",  g_strMusic[Music_RoundWin],   PLATFORM_MAX_PATH) && strlen(g_strMusic[Music_RoundWin]);
        g_bMusic[Music_RoundLose]  = kvConfig.GetString("round end (lose)", g_strMusic[Music_RoundLose],  PLATFORM_MAX_PATH) && strlen(g_strMusic[Music_RoundLose]);
        g_bMusic[Music_Gameplay]   = kvConfig.GetString("gameplay",         g_strMusic[Music_Gameplay],   PLATFORM_MAX_PATH) && strlen(g_strMusic[Music_Gameplay]);
    }
}

/* ParseClasses()
**
** Parses the rocket classes data from the given configuration file.
** -------------------------------------------------------------------------- */
void ParseClasses(KeyValues kvConfig)
{
    char strName[64];
    char strBuffer[256];
    
    kvConfig.GotoFirstSubKey();
    do
    {
        int iIndex = g_iRocketClassCount;
        RocketFlags iFlags;
        
        // Basic parameters
        kvConfig.GetSectionName(strName, sizeof(strName));         strcopy(g_strRocketClassName[iIndex], 16, strName);
        kvConfig.GetString("name", strBuffer, sizeof(strBuffer));  strcopy(g_strRocketClassLongName[iIndex], 32, strBuffer);
        if (kvConfig.GetString("model", strBuffer, sizeof(strBuffer)))
        {
            strcopy(g_strRocketClassModel[iIndex], PLATFORM_MAX_PATH, strBuffer);
            if (strlen(g_strRocketClassModel[iIndex]) != 0)
            {
                iFlags |= RocketFlag_CustomModel;
                if (kvConfig.GetNum("is animated", 0)) iFlags |= RocketFlag_IsAnimated;
            }
        }
        
        if (kvConfig.GetString("trail particle", strBuffer, sizeof(strBuffer)))
        {
            strcopy(g_strRocketClassTrail[iIndex], sizeof(g_strRocketClassTrail[]), strBuffer);
            if (strlen(g_strRocketClassTrail[iIndex]) != 0)
            {
                iFlags |= RocketFlag_CustomTrail;
            }
        }
        
        if (kvConfig.GetString("trail sprite", strBuffer, sizeof(strBuffer)))
        {
            strcopy(g_strRocketClassSprite[iIndex], PLATFORM_MAX_PATH, strBuffer);
            if (strlen(g_strRocketClassSprite[iIndex]) != 0)
            {
                iFlags |= RocketFlag_CustomSprite;
                if (kvConfig.GetString("custom color", strBuffer, sizeof(strBuffer)))
                {
                    strcopy(g_strRocketClassSpriteColor[iIndex], sizeof(g_strRocketClassSpriteColor[]), strBuffer);
                }
            }
        }
        
        if (kvConfig.GetNum("remove particles", 0))
        {
            iFlags |= RocketFlag_RemoveParticles;
            if (kvConfig.GetNum("replace particles", 0)) iFlags |= RocketFlag_ReplaceParticles;
        }
        
        kvConfig.GetString("behaviour", strBuffer, sizeof(strBuffer), "homing");
        if (StrEqual(strBuffer, "homing")) g_iRocketClassBehaviour[iIndex] = Behaviour_Homing;
        else                               g_iRocketClassBehaviour[iIndex] = Behaviour_Unknown;
        
        if (kvConfig.GetNum("play spawn sound", 0) == 1)
        {
            iFlags |= RocketFlag_PlaySpawnSound;
            if (kvConfig.GetString("spawn sound", g_strRocketClassSpawnSound[iIndex], PLATFORM_MAX_PATH) && (strlen(g_strRocketClassSpawnSound[iIndex]) != 0))
            {
                iFlags |= RocketFlag_CustomSpawnSound;
            }
        }
        
        if (kvConfig.GetNum("play beep sound", 0) == 1)
        {
            iFlags |= RocketFlag_PlayBeepSound;
            g_fRocketClassBeepInterval[iIndex] = kvConfig.GetFloat("beep interval", 0.5);
            if (kvConfig.GetString("beep sound", g_strRocketClassBeepSound[iIndex], PLATFORM_MAX_PATH) && (strlen(g_strRocketClassBeepSound[iIndex]) != 0))
            {
                iFlags |= RocketFlag_CustomBeepSound;
            }
        }
        
        if (kvConfig.GetNum("play alert sound", 0) == 1)
        {
            iFlags |= RocketFlag_PlayAlertSound;
            if (kvConfig.GetString("alert sound", g_strRocketClassAlertSound[iIndex], PLATFORM_MAX_PATH) && strlen(g_strRocketClassAlertSound[iIndex]) != 0)
            {
                iFlags |= RocketFlag_CustomAlertSound;
            }
        }
        
        // Behaviour modifiers
        if (kvConfig.GetNum("elevate on deflect", 1) == 1) iFlags |= RocketFlag_ElevateOnDeflect;
        if (kvConfig.GetNum("neutral rocket", 0) == 1)     iFlags |= RocketFlag_IsNeutral;
        if (kvConfig.GetNum("limit turn rate", 0) == 1)    iFlags |= RocketFlag_IsLimited;
        if (kvConfig.GetNum("limit speed", 0) == 1)        iFlags |= RocketFlag_IsSpeedLimited;
        if (kvConfig.GetNum("keep direction", 0) == 1)     iFlags |= RocketFlag_KeepDirection;
        if (kvConfig.GetNum("teamless deflects", 0) == 1)  iFlags |= RocketFlag_TeamlessHits;
        if (kvConfig.GetNum("reset bounces", 0) == 1)      iFlags |= RocketFlag_ResetBounces;
        
        // Movement parameters
        g_fRocketClassDamage[iIndex]            = kvConfig.GetFloat("damage");
        g_fRocketClassDamageIncrement[iIndex]   = kvConfig.GetFloat("damage increment");
        g_fRocketClassCritChance[iIndex]        = kvConfig.GetFloat("critical chance");
        g_fRocketClassSpeed[iIndex]             = kvConfig.GetFloat("speed");
        g_fSavedParameters[iIndex][0]           = g_fRocketClassSpeed[iIndex];
        g_fRocketClassSpeedIncrement[iIndex]    = kvConfig.GetFloat("speed increment");
        g_fSavedParameters[iIndex][1]           = g_fRocketClassSpeedIncrement[iIndex];
        g_fRocketClassSpeedLimit[iIndex]        = kvConfig.GetFloat("speed limit");
        g_fSavedParameters[iIndex][2]           = g_fRocketClassSpeedLimit[iIndex];
        g_fRocketClassTurnRate[iIndex]          = kvConfig.GetFloat("turn rate");
        g_fSavedParameters[iIndex][3]           = g_fRocketClassTurnRate[iIndex];
        g_fRocketClassTurnRateIncrement[iIndex] = kvConfig.GetFloat("turn rate increment");
        g_fSavedParameters[iIndex][4]           = g_fRocketClassTurnRateIncrement[iIndex];
        g_fRocketClassTurnRateLimit[iIndex]     = kvConfig.GetFloat("turn rate limit");
        g_fSavedParameters[iIndex][5]           = g_fRocketClassTurnRateLimit[iIndex];
        g_fRocketClassElevationRate[iIndex]     = kvConfig.GetFloat("elevation rate");
        g_fSavedParameters[iIndex][6]           = g_fRocketClassElevationRate[iIndex];
        g_fRocketClassElevationLimit[iIndex]    = kvConfig.GetFloat("elevation limit");
        g_fSavedParameters[iIndex][7]           = g_fRocketClassElevationLimit[iIndex];
        g_fRocketClassControlDelay[iIndex]      = kvConfig.GetFloat("control delay");
        g_iRocketClassMaxBounces[iIndex]        = kvConfig.GetNum("max bounces");
        g_iRocketClassSavedMaxBounces[iIndex]   = g_iRocketClassMaxBounces[iIndex];
        g_fRocketClassPlayerModifier[iIndex]    = kvConfig.GetFloat("no. players modifier");
        g_fRocketClassRocketsModifier[iIndex]   = kvConfig.GetFloat("no. rockets modifier");
        g_fRocketClassTargetWeight[iIndex]      = kvConfig.GetFloat("direction to target weight");
        
        // Events
        DataPack hCmds = null;
        kvConfig.GetString("on spawn", strBuffer, sizeof(strBuffer));
        if ((hCmds = ParseCommands(strBuffer)) != null) { iFlags |= RocketFlag_OnSpawnCmd; g_hRocketClassCmdsOnSpawn[iIndex] = hCmds; }
        kvConfig.GetString("on deflect", strBuffer, sizeof(strBuffer));
        if ((hCmds = ParseCommands(strBuffer)) != null) { iFlags |= RocketFlag_OnDeflectCmd; g_hRocketClassCmdsOnDeflect[iIndex] = hCmds; }
        kvConfig.GetString("on kill", strBuffer, sizeof(strBuffer));
        if ((hCmds = ParseCommands(strBuffer)) != null) { iFlags |= RocketFlag_OnKillCmd; g_hRocketClassCmdsOnKill[iIndex] = hCmds; }
        kvConfig.GetString("on explode", strBuffer, sizeof(strBuffer));
        if ((hCmds = ParseCommands(strBuffer)) != null) { iFlags |= RocketFlag_OnExplodeCmd; g_hRocketClassCmdsOnExplode[iIndex] = hCmds; }
        kvConfig.GetString("on no target", strBuffer, sizeof(strBuffer));
        if ((hCmds = ParseCommands(strBuffer)) != null) { iFlags |= RocketFlag_OnNoTargetCmd; g_hRocketClassCmdsOnNoTarget[iIndex] = hCmds; }
        
        // Done
        g_hRocketClassTrie.SetValue(strName, iIndex);
        g_iRocketClassFlags[iIndex] = iFlags;
        g_iSavedRocketClassFlags[iIndex] = iFlags;
        g_iRocketClassCount++;
    }
    while (kvConfig.GotoNextKey());
    kvConfig.GoBack(); 
}

/* ParseSpawners()
**
** Parses the spawn points classes data from the given configuration file.
** -------------------------------------------------------------------------- */
void ParseSpawners(KeyValues kvConfig)
{
    char strBuffer[256];
    kvConfig.GotoFirstSubKey();
    
    do
    {
        int iIndex = g_iSpawnersCount;
        
        // Basic parameters
        kvConfig.GetSectionName(strBuffer, sizeof(strBuffer)); strcopy(g_strSpawnersName[iIndex], 32, strBuffer);
        g_iSpawnersMaxRockets[iIndex] = kvConfig.GetNum("max rockets", 1);
        g_fSpawnersInterval[iIndex]   = kvConfig.GetFloat("interval", 1.0);
        
        // Chances table
        g_hSpawnersChancesTable[iIndex] = new ArrayList();
        g_hSavedChancesTable[iIndex] = new ArrayList();
        for (int iClassIndex = 0; iClassIndex < g_iRocketClassCount; iClassIndex++)
        {
            FormatEx(strBuffer, sizeof(strBuffer), "%s%%", g_strRocketClassName[iClassIndex]);
            g_hSpawnersChancesTable[iIndex].Push(kvConfig.GetNum(strBuffer, 0));
            g_hSavedChancesTable[iIndex].Push(kvConfig.GetNum(strBuffer, 0));
        }
        
        // Done.
        g_hSpawnersTrie.SetValue(g_strSpawnersName[iIndex], iIndex);
        g_iSpawnersCount++;
    }
    while (kvConfig.GotoNextKey());
    kvConfig.GoBack();
    
    g_hSpawnersTrie.GetValue("red", g_iDefaultRedSpawner);
    g_hSpawnersTrie.GetValue("blu", g_iDefaultBluSpawner);
}

/* ParseCommands()
**
** Part of the event system, parses the given command strings and packs them
** to a Datapack.
** -------------------------------------------------------------------------- */
DataPack ParseCommands(char[] strLine)
{
    TrimString(strLine);
    if (strlen(strLine) == 0)
    {
        return null;
    }
    else
    {
        char strStrings[8][255];
        int iNumStrings = ExplodeString(strLine, ";", strStrings, 8, 255);
        
        DataPack hDataPack = new DataPack();
        hDataPack.WriteCell(iNumStrings);
        for (int i = 0; i < iNumStrings; i++)
        {
            hDataPack.WriteString(strStrings[i]);
        }
        
        return hDataPack;
    }
}

/*
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
**   ______            __    
**  /_  __/___  ____  / /____
**   / / / __ \/ __ \/ / ___/
**  / / / /_/ / /_/ / (__  ) 
** /_/  \____/\____/_/____/  
**
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
*/

/* CopyVectors()
**
** Copies the contents from a vector to another.
** -------------------------------------------------------------------------- */
stock void CopyVectors(float fFrom[3], float fTo[3])
{
    fTo[0] = fFrom[0];
    fTo[1] = fFrom[1];
    fTo[2] = fFrom[2];
}

/* LerpVectors()
**
** Calculates the linear interpolation of the two given vectors and stores
** it on the third one.
** -------------------------------------------------------------------------- */
stock void LerpVectors(float fA[3], float fB[3], float fC[3], float t)
{
    if (t < 0.0) t = 0.0;
    if (t > 1.0) t = 1.0;
    
    fC[0] = fA[0] + (fB[0] - fA[0]) * t;
    fC[1] = fA[1] + (fB[1] - fA[1]) * t;
    fC[2] = fA[2] + (fB[2] - fA[2]) * t;
}

/* IsValidClient()
**
** Checks if the given client index is valid, and if it's alive or not.
** -------------------------------------------------------------------------- */
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

/* BothTeamsPlaying()
**
** Checks if there are players on both teams.
** -------------------------------------------------------------------------- */
stock bool BothTeamsPlaying()
{
    bool bRedFound, bBluFound;
    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        if (IsValidClient(iClient, true) == false) continue;
        int iTeam = GetClientTeam(iClient);
        if (iTeam == view_as<int>(TFTeam_Red)) bRedFound = true;
        if (iTeam == view_as<int>(TFTeam_Blue)) bBluFound = true;
    }
    return bRedFound && bBluFound;
}

/* CountAlivePlayers()
**
** Retrieves the number of players alive.
** -------------------------------------------------------------------------- */
stock int CountAlivePlayers()
{
    int iCount = 0;
    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        if (IsValidClient(iClient, true)) iCount++;
    }
    return iCount;
}

/* SelectTarget()
**
** Determines a random target of the given team for the homing rocket.
** -------------------------------------------------------------------------- */
stock int SelectTarget(int iTeam, int iRocket = -1)
{
    int iTarget = -1;
    float fTargetWeight = 0.0;
    float fRocketPosition[3];
    float fRocketDirection[3];
    float fWeight;
    bool bUseRocket;
    int iOwner = -1;
    
    if (iRocket != -1)
    {
        int iClass = g_iRocketClass[iRocket];
        int iEntity = EntRefToEntIndex(g_iRocketEntity[iRocket]);
        iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
        
        GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fRocketPosition);
        CopyVectors(g_fRocketDirection[iRocket], fRocketDirection);
        fWeight = g_fRocketClassTargetWeight[iClass];
        
        bUseRocket = true;
    }
    
    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        // If the client isn't connected, skip.
        if (!IsValidClient(iClient, true)) continue;
        if (iTeam && GetClientTeam(iClient) != iTeam) continue;
        if (iClient == iOwner) continue;
        
        // Determine if this client should be the target.
        float fNewWeight = GetURandomFloatRange(0.0, 100.0);
        
        if (bUseRocket == true)
        {
            float fClientPosition[3]; GetClientEyePosition(iClient, fClientPosition);
            float fDirectionToClient[3]; MakeVectorFromPoints(fRocketPosition, fClientPosition, fDirectionToClient);
            fNewWeight += GetVectorDotProduct(fRocketDirection, fDirectionToClient) * fWeight;
        }
        
        if ((iTarget == -1) || fNewWeight >= fTargetWeight)
        {
            iTarget = iClient;
            fTargetWeight = fNewWeight;
        }
    }
    
    return iTarget;
}

/* StopSoundToAll()
**
** Stops a sound for all the clients on the given channel.
** -------------------------------------------------------------------------- */
stock void StopSoundToAll(int iChannel, const char[] strSound)
{
    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        if (IsValidClient(iClient)) StopSound(iClient, iChannel, strSound);
    }
}

/* PlayParticle()
**
** Plays a particle system at the given location & angles.
** -------------------------------------------------------------------------- */
stock void PlayParticle(float fPosition[3], float fAngles[3], char[] strParticleName, float fEffectTime = 5.0, float fLifeTime = 9.0)
{
    int iEntity = CreateEntityByName("info_particle_system");
    if (iEntity && IsValidEdict(iEntity))
    {
        TeleportEntity(iEntity, fPosition, fAngles, NULL_VECTOR);
        DispatchKeyValue(iEntity, "effect_name", strParticleName);
        ActivateEntity(iEntity);
        AcceptEntityInput(iEntity, "Start");
        CreateTimer(fEffectTime, StopParticle, EntIndexToEntRef(iEntity));
        CreateTimer(fLifeTime, KillParticle, EntIndexToEntRef(iEntity));
    }
    else
    {
        LogError("ShowParticle: could not create info_particle_system");
    }
}

/* StopParticle()
**
** Turns of the particle system. Automatically called by PlayParticle
** -------------------------------------------------------------------------- */
public Action StopParticle(Handle hTimer, any iEntityRef)
{
    if (iEntityRef != INVALID_ENT_REFERENCE)
    {
        int iEntity = EntRefToEntIndex(iEntityRef);
        if (iEntity && IsValidEntity(iEntity))
        {
            AcceptEntityInput(iEntity, "Stop");
        }
    }
}

/* KillParticle()
**
** Destroys the particle system. Automatically called by PlayParticle
** -------------------------------------------------------------------------- */
public Action KillParticle(Handle hTimer, any iEntityRef)
{
    if (iEntityRef != INVALID_ENT_REFERENCE)
    {
        int iEntity = EntRefToEntIndex(iEntityRef);
        if (iEntity && IsValidEntity(iEntity))
        {
            RemoveEdict(iEntity);
        }
    }
}

/* PrecacheParticle()
**
** Forces the client to precache a particle system.
** -------------------------------------------------------------------------- */
stock void PrecacheParticle(char[] strParticleName)
{
    PlayParticle(view_as<float>({0.0, 0.0, 0.0}), view_as<float>({0.0, 0.0, 0.0}), strParticleName, 0.1, 0.1);
}

/* FindEntityByClassnameSafe()
**
** Used to iterate through entity types, avoiding problems in cases where
** the entity may not exist anymore.
** -------------------------------------------------------------------------- */
stock int FindEntityByClassnameSafe(int iStart, const char[] strClassname)
{
    while (iStart > -1 && !IsValidEntity(iStart))
    {
        iStart--;
    }
    return FindEntityByClassname(iStart, strClassname);
}

/* GetAnalogueTeam()
**
** Gets the analogue team for this. In case of Red, it's Blue, and viceversa.
** -------------------------------------------------------------------------- */
stock int GetAnalogueTeam(int iTeam)
{
    if (iTeam == view_as<int>(TFTeam_Red)) return view_as<int>(TFTeam_Blue);
    return view_as<int>(TFTeam_Red);
}

/* ShowHiddenMOTDPanel()
**
** Shows a hidden MOTD panel, useful for streaming music.
** -------------------------------------------------------------------------- */
stock void ShowHiddenMOTDPanel(int iClient, char[] strTitle, char[] strMsg, char[] strType = "2")
{
    KeyValues hPanel = new KeyValues("data");
    hPanel.SetString("title", strTitle);
    hPanel.SetString("type", strType);
    hPanel.SetString("msg", strMsg);
    ShowVGUIPanel(iClient, "info", hPanel, false);
    delete hPanel;
}

/* PrecacheSoundEx()
**
** Precaches a sound and adds it to the download table.
** -------------------------------------------------------------------------- */
stock void PrecacheSoundEx(char[] strFileName, bool bPreload = false, bool bAddToDownloadTable = false)
{
    char strFinalPath[PLATFORM_MAX_PATH]; 
    FormatEx(strFinalPath, sizeof(strFinalPath), "sound/%s", strFileName);
    PrecacheSound(strFileName, bPreload);
    if (bAddToDownloadTable == true) AddFileToDownloadsTable(strFinalPath);
}

/* PrecacheModelEx()
**
** Precaches a models and adds it to the download table.
** -------------------------------------------------------------------------- */
stock void PrecacheModelEx(char[] strFileName, bool bPreload = false, bool bAddToDownloadTable = false)
{
    PrecacheModel(strFileName, bPreload);
    if (bAddToDownloadTable)
    {
        char strDepFileName[PLATFORM_MAX_PATH];
        FormatEx(strDepFileName, sizeof(strDepFileName), "%s.res", strFileName);
        
        if (FileExists(strDepFileName))
        {
            // Open stream, if possible
            File hStream = OpenFile(strDepFileName, "r");
            if (hStream == null) { LogMessage("Error, can't read file containing model dependencies."); return; }
            
            while(!hStream.EndOfFile())
            {
                char strBuffer[PLATFORM_MAX_PATH];
                hStream.ReadLine(strBuffer, sizeof(strBuffer));
                CleanString(strBuffer);
                
                // If file exists...
                if (FileExists(strBuffer, true))
                {
                    // Precache depending on type, and add to download table
                    if (StrContains(strBuffer, ".vmt", false) != -1)      PrecacheDecal(strBuffer, true);
                    else if (StrContains(strBuffer, ".mdl", false) != -1) PrecacheModel(strBuffer, true);
                    else if (StrContains(strBuffer, ".pcf", false) != -1) PrecacheGeneric(strBuffer, true);
                    AddFileToDownloadsTable(strBuffer);
                }
            }
            
            // Close file
            delete hStream;
        }
    }
}

/* CleanString()
**
** Cleans the given string from any illegal character.
** -------------------------------------------------------------------------- */
stock void CleanString(char[] strBuffer)
{
    // Cleanup any illegal characters
    int Length = strlen(strBuffer);
    for (int iPos=0; iPos<Length; iPos++)
    {
        switch(strBuffer[iPos])
        {
            case '\r': strBuffer[iPos] = ' ';
            case '\n': strBuffer[iPos] = ' ';
            case '\t': strBuffer[iPos] = ' ';
        }
    }
    
    // Trim string
    TrimString(strBuffer);
}

/* FMax()
**
** Returns the maximum of the two values given.
** -------------------------------------------------------------------------- */
stock float FMax(float a, float b)
{
    return (a > b)? a:b;
}

/* FMin()
**
** Returns the minimum of the two values given.
** -------------------------------------------------------------------------- */
stock float FMin(float a, float b)
{
    return (a < b)? a:b;
}

/* GetURandomIntRange()
**
** 
** -------------------------------------------------------------------------- */
stock int GetURandomIntRange(int iMin, int iMax)
{
    return iMin + (GetURandomInt() % (iMax - iMin + 1));
}

/* GetURandomFloatRange()
**
** 
** -------------------------------------------------------------------------- */
stock float GetURandomFloatRange(float fMin, float fMax)
{
    return fMin + (GetURandomFloat() * (fMax - fMin));
}

void checkStolenRocket(int clientId, int entId)
{
	int iTarget = EntRefToEntIndex(g_iRocketTarget[entId]);
	
	if (iTarget != clientId && !bStealArray[clientId].stoleRocket && (GetEntitiesDistance(iTarget, clientId) > g_fStealDistance) && (GetClientTeam(iTarget) == GetClientTeam(clientId)) && !g_bPreventingDelay[entId])
	{
		bStealArray[clientId].stoleRocket = true;
		if (bStealArray[clientId].rocketsStolen < g_hCvarStealPreventionNumber.IntValue)
		{
			bStealArray[clientId].rocketsStolen++;
			SlapPlayer(clientId, 0, true);
			CPrintToChat(clientId, "%t", "DBSteal_Warning_Client", bStealArray[clientId].rocketsStolen, g_hCvarStealPreventionNumber.IntValue);
			MC_SkipNextClient(clientId);
			CPrintToChatAll("%t", "DBSteal_Announce_All", clientId, iTarget);
			bStealArray[clientId].stoleRocket = false;
		}
		else
		{
			ForcePlayerSuicide(clientId);
			CPrintToChat(clientId, "%t", "DBSteal_Slay_Client");
			MC_SkipNextClient(clientId);
			CPrintToChatAll("%t", "DBSteal_Announce_Slay_All", clientId);
		}
		g_bIsRocketStolen[entId] = true;
		g_iLastStealer = clientId;
	}
}

public bool MLTargetFilterStealer(const char[] strPattern, ArrayList hClients)
{
	bool bReverse = (StrContains(strPattern, "!", false) == 1);
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient) && (hClients.FindValue(iClient) == -1))
		{
			if (iClient == g_iLastStealer)
			{
				if (!bReverse)
				{
					hClients.Push(iClient);
				}
			}
			else if (bReverse)
			{
				hClients.Push(iClient);
			}
		}
	}
	
	return !!hClients.Length;
}

// Asherkin's RocketBounce

public void tf2dodgeball_cvarhook(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_hCvarStealDistance)
	{
		g_fStealDistance = StringToFloat(newValue);
	}
}

public Action OnStartTouch(int entity, int other)
{
	if (other > 0 && other <= MaxClients)
		return Plugin_Continue;
		
	int iIndex = FindRocketByEntity(entity);
	
	if (iIndex != -1)
	{
		// Only allow a rocket to bounce x times.
		int iClass = g_iRocketClass[iIndex];
		
		if (g_iRocketBounces[iIndex] >= g_iRocketClassMaxBounces[iClass])
			return Plugin_Continue;
	}
	else
	{
		return Plugin_Continue;
	}
	
	SDKHook(entity, SDKHook_Touch, OnTouch);
	
	return Plugin_Handled;
}

public Action OnTouch(int entity, int other)
{
	float vOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vOrigin);
	
	float vAngles[3];
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
	
	float vVelocity[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vVelocity);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TEF_ExcludeEntity, entity);
	
	if(!TR_DidHit(trace))
	{
		delete trace;
		return Plugin_Continue;
	}
	
	float vNormal[3];
	TR_GetPlaneNormal(trace, vNormal);
	
	//PrintToServer("Surface Normal: [%.2f, %.2f, %.2f]", vNormal[0], vNormal[1], vNormal[2]);
	
	delete trace;
	
	float dotProduct = GetVectorDotProduct(vNormal, vVelocity);
	
	ScaleVector(vNormal, dotProduct);
	ScaleVector(vNormal, 2.0);
	
	float vBounceVec[3];
	SubtractVectors(vVelocity, vNormal, vBounceVec);
	
	float vNewAngles[3];
	GetVectorAngles(vBounceVec, vNewAngles);
	
	//PrintToServer("Angles: [%.2f, %.2f, %.2f] -> [%.2f, %.2f, %.2f]", vAngles[0], vAngles[1], vAngles[2], vNewAngles[0], vNewAngles[1], vNewAngles[2]);
	//PrintToServer("Velocity: [%.2f, %.2f, %.2f] |%.2f| -> [%.2f, %.2f, %.2f] |%.2f|", vVelocity[0], vVelocity[1], vVelocity[2], GetVectorLength(vVelocity), vBounceVec[0], vBounceVec[1], vBounceVec[2], GetVectorLength(vBounceVec));
	
	TeleportEntity(entity, NULL_VECTOR, vNewAngles, vBounceVec);
	
	int iIndex = FindRocketByEntity(entity);
	
	if (iIndex != -1)
	{
		g_iRocketBounces[iIndex]++;
		
		if(!(g_bPreventingDelay[iIndex]) && !(g_iRocketFlags[iIndex] & RocketFlag_KeepDirection))
		{
			float fDirection[3];
			GetAngleVectors(vNewAngles,fDirection,NULL_VECTOR,NULL_VECTOR);
			CopyVectors(fDirection, g_fRocketDirection[iIndex]);
		}
	}
	
	SDKUnhook(entity, SDKHook_Touch, OnTouch);
	
	return Plugin_Handled;
}

public bool TEF_ExcludeEntity(int entity, int contentsMask, any data)
{
	return (entity != data);
}

void checkRoundDelays(int entId)
{
	int iEntity = EntRefToEntIndex(g_iRocketEntity[entId]);
	int iTarget = EntRefToEntIndex(g_iRocketTarget[entId]);
	float timeToCheck;
	if (g_iRocketDeflections[entId] == 0)
		timeToCheck = g_fLastSpawnTime[entId];
	else
		timeToCheck = g_fRocketLastDeflectionTime[entId];
	
	if (iTarget != INVALID_ENT_REFERENCE && (GetGameTime() - timeToCheck) >= g_hCvarDelayPreventionTime.FloatValue)
	{
		g_fRocketSpeed[entId] += g_hCvarDelayPreventionSpeedup.FloatValue;
		if (!g_bPreventingDelay[entId])
		{
			CPrintToChatAll("%t", "DBDelay_Announce_All", iTarget);
			EmitSoundToAll(SOUND_DEFAULT_SPEEDUP, iEntity, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
		}
		g_bPreventingDelay[entId] = true;
	}
}

stock float GetEntitiesDistance(int ent1, int ent2)
{
	float orig1[3];
	GetEntPropVector(ent1, Prop_Send, "m_vecOrigin", orig1);
	
	float orig2[3];
	GetEntPropVector(ent2, Prop_Send, "m_vecOrigin", orig2);

	return GetVectorDistance(orig1, orig2);
}

stock void PrecacheTrail(char[] strFileName)
{
	char downloadString[PLATFORM_MAX_PATH];
	FormatEx(downloadString, sizeof(downloadString), "%s.vmt", strFileName);
	PrecacheGeneric(downloadString, true);
	AddFileToDownloadsTable(downloadString);
	FormatEx(downloadString, sizeof(downloadString), "%s.vtf", strFileName);
	PrecacheGeneric(downloadString, true);
	AddFileToDownloadsTable(downloadString);
}

stock void CreateTempParticle(const char[] strParticle, const float vecOrigin[3] = NULL_VECTOR, const float vecStart[3] = NULL_VECTOR, const float vecAngles[3] = NULL_VECTOR, int iEntity = -1, ParticleAttachmentType AttachmentType = PATTACH_ABSORIGIN, int iAttachmentPoint = -1, bool bResetParticles = false)
{
	int iParticleTable, iParticleIndex;
	
	iParticleTable = FindStringTable("ParticleEffectNames");
	if (iParticleTable == INVALID_STRING_TABLE)
	{
		ThrowError("Could not find string table: ParticleEffectNames");
	}
	
	iParticleIndex = FindStringIndex(iParticleTable, strParticle);
	if (iParticleIndex == INVALID_STRING_INDEX)
	{
		ThrowError("Could not find particle index: %s", strParticle);
	}
	
	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", vecOrigin[0]);
	TE_WriteFloat("m_vecOrigin[1]", vecOrigin[1]);
	TE_WriteFloat("m_vecOrigin[2]", vecOrigin[2]);
	TE_WriteFloat("m_vecStart[0]", vecStart[0]);
	TE_WriteFloat("m_vecStart[1]", vecStart[1]);
	TE_WriteFloat("m_vecStart[2]", vecStart[2]);
	TE_WriteVector("m_vecAngles", vecAngles);
	TE_WriteNum("m_iParticleSystemIndex", iParticleIndex);
	
	if (iEntity != -1)
	{
		TE_WriteNum("entindex", iEntity);
	}
	
	if (AttachmentType != PATTACH_ABSORIGIN)
	{
		TE_WriteNum("m_iAttachType", view_as<int>(AttachmentType));
	}
	
	if (iAttachmentPoint != -1)
	{
		TE_WriteNum("m_iAttachmentPointIndex", iAttachmentPoint);
	}
	
	TE_WriteNum("m_bResetParticles", bResetParticles ? 1 : 0);
	
	TE_SendToAll();
}

stock int PrecacheParticleSystem(const char[] particleSystem)
{
    static int particleEffectNames = INVALID_STRING_TABLE;

    if (particleEffectNames == INVALID_STRING_TABLE) {
        if ((particleEffectNames = FindStringTable("ParticleEffectNames")) == INVALID_STRING_TABLE) {
            return INVALID_STRING_INDEX;
        }
    }

    int index = FindStringIndex2(particleEffectNames, particleSystem);
    if (index == INVALID_STRING_INDEX) {
        int numStrings = GetStringTableNumStrings(particleEffectNames);
        if (numStrings >= GetStringTableMaxStrings(particleEffectNames)) {
            return INVALID_STRING_INDEX;
        }
        
        AddToStringTable(particleEffectNames, particleSystem);
        index = numStrings;
    }
    
    return index;
}

stock int FindStringIndex2(int tableidx, const char[] str)
{
    char buf[1024];
    
    int numStrings = GetStringTableNumStrings(tableidx);
    for (int i=0; i < numStrings; i++) {
        ReadStringTable(tableidx, i, buf, sizeof(buf));
        
        if (StrEqual(buf, str)) {
            return i;
        }
    }
    
    return INVALID_STRING_INDEX;
}

// EOF