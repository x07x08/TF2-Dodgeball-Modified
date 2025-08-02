// *********************************************************************************
// PREPROCESSOR
// *********************************************************************************
#pragma semicolon 1
#pragma newdecls required

// *********************************************************************************
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <multicolors>

#include <tfdb>

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
#define PLUGIN_NAME             "[TF2] Dodgeball"
#define PLUGIN_AUTHOR           "Damizean, x07x08 continued by Silorak"
#define PLUGIN_VERSION          "2.0.0"
#define PLUGIN_CONTACT          "https://github.com/Silorak/TF2-Dodgeball-Modified"

enum Musics
{
	Music_RoundStart,
	Music_RoundWin,
	Music_RoundLose,
	Music_Gameplay,
	SizeOfMusicsArray
}

// *********************************************************************************
// VARIABLES
// *********************************************************************************

// -----<<< Cvars >>>-----
ConVar g_hCvarEnabled;
ConVar g_hCvarEnableCfgFile;
ConVar g_hCvarDisableCfgFile;
ConVar g_hCvarStealPreventionNumber;
ConVar g_hCvarStealPreventionDamage;
ConVar g_hCvarStealDistance;
ConVar g_hCvarDelayPrevention;
ConVar g_hCvarDelayPreventionTime;
ConVar g_hCvarDelayPreventionSpeedup;
ConVar g_hCvarNoTargetRedirectDamage;
ConVar g_hCvarStealMessage;
ConVar g_hCvarDelayMessage;

// -----<<< Gameplay >>>-----
bool   g_bEnabled;
bool   g_bRoundStarted;
int    g_iRoundCount;
int    g_iRocketsFired;
Handle g_hLogicTimer;
float  g_fNextSpawnTime;
int    g_iLastDeadTeam;
int    g_iLastDeadClient;
int    g_iPlayerCount;
float  g_fTickModifier;
int    g_iLastStealer;

eRocketSteal g_eStealInfo[MAXPLAYERS + 1];

// -----<<< Configuration >>>-----
bool g_bMusicEnabled;
bool g_bMusic[view_as<int>(SizeOfMusicsArray)];
char g_strMusic[view_as<int>(SizeOfMusicsArray)][PLATFORM_MAX_PATH];
bool g_bUseWebPlayer;
char g_strWebPlayerUrl[256];

// -----<<< Structures >>>-----
// Rockets
bool        g_bRocketIsValid[MAX_ROCKETS];
int         g_iRocketEntity[MAX_ROCKETS];
int         g_iRocketTarget[MAX_ROCKETS];
int         g_iRocketClass[MAX_ROCKETS];
RocketFlags g_iRocketFlags[MAX_ROCKETS];
RocketState g_iRocketState[MAX_ROCKETS];
float       g_fRocketSpeed[MAX_ROCKETS];
float       g_fRocketMphSpeed[MAX_ROCKETS];
float       g_fRocketDirection[MAX_ROCKETS][3];
int         g_iRocketDeflections[MAX_ROCKETS];
int         g_iRocketEventDeflections[MAX_ROCKETS];
float       g_fRocketLastDeflectionTime[MAX_ROCKETS];
float       g_fRocketLastBeepTime[MAX_ROCKETS];
float       g_fLastSpawnTime[MAX_ROCKETS];
int         g_iRocketBounces[MAX_ROCKETS];
int         g_iRocketCount;

// Classes
char           g_strRocketClassName[MAX_ROCKET_CLASSES][16];
char           g_strRocketClassLongName[MAX_ROCKET_CLASSES][32];
BehaviourTypes g_iRocketClassBehaviour[MAX_ROCKET_CLASSES];
char           g_strRocketClassModel[MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
RocketFlags    g_iRocketClassFlags[MAX_ROCKET_CLASSES];
float          g_fRocketClassBeepInterval[MAX_ROCKET_CLASSES];
char           g_strRocketClassSpawnSound[MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
char           g_strRocketClassBeepSound[MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
char           g_strRocketClassAlertSound[MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
float          g_fRocketClassCritChance[MAX_ROCKET_CLASSES];
float          g_fRocketClassDamage[MAX_ROCKET_CLASSES];
float          g_fRocketClassDamageIncrement[MAX_ROCKET_CLASSES];
float          g_fRocketClassSpeed[MAX_ROCKET_CLASSES];
float          g_fRocketClassSpeedIncrement[MAX_ROCKET_CLASSES];
float          g_fRocketClassSpeedLimit[MAX_ROCKET_CLASSES];
float          g_fRocketClassTurnRate[MAX_ROCKET_CLASSES];
float          g_fRocketClassTurnRateIncrement[MAX_ROCKET_CLASSES];
float          g_fRocketClassTurnRateLimit[MAX_ROCKET_CLASSES];
float          g_fRocketClassElevationRate[MAX_ROCKET_CLASSES];
float          g_fRocketClassElevationLimit[MAX_ROCKET_CLASSES];
float          g_fRocketClassRocketsModifier[MAX_ROCKET_CLASSES];
float          g_fRocketClassPlayerModifier[MAX_ROCKET_CLASSES];
float          g_fRocketClassControlDelay[MAX_ROCKET_CLASSES];
float          g_fRocketClassDragTimeMin[MAX_ROCKET_CLASSES];
float          g_fRocketClassDragTimeMax[MAX_ROCKET_CLASSES];
float          g_fRocketClassTargetWeight[MAX_ROCKET_CLASSES];
DataPack       g_hRocketClassCmdsOnSpawn[MAX_ROCKET_CLASSES];
DataPack       g_hRocketClassCmdsOnDeflect[MAX_ROCKET_CLASSES];
DataPack       g_hRocketClassCmdsOnKill[MAX_ROCKET_CLASSES];
DataPack       g_hRocketClassCmdsOnExplode[MAX_ROCKET_CLASSES];
DataPack       g_hRocketClassCmdsOnNoTarget[MAX_ROCKET_CLASSES];
int            g_iRocketClassMaxBounces[MAX_ROCKET_CLASSES];
float          g_fRocketClassBounceScale[MAX_ROCKET_CLASSES];
int            g_iRocketClassCount;

// Spawner classes
char      g_strSpawnersName[MAX_SPAWNER_CLASSES][32];
int       g_iSpawnersMaxRockets[MAX_SPAWNER_CLASSES];
float     g_fSpawnersInterval[MAX_SPAWNER_CLASSES];
ArrayList g_hSpawnersChancesTable[MAX_SPAWNER_CLASSES];
StringMap g_hSpawnersTrie;
int       g_iSpawnersCount;

int g_iCurrentRedSpawn;
int g_iSpawnPointsRedCount;
int g_iSpawnPointsRedClass[MAX_SPAWN_POINTS];
int g_iSpawnPointsRedEntity[MAX_SPAWN_POINTS];

int g_iCurrentBluSpawn;
int g_iSpawnPointsBluCount;
int g_iSpawnPointsBluClass[MAX_SPAWN_POINTS];
int g_iSpawnPointsBluEntity[MAX_SPAWN_POINTS];

int g_iDefaultRedSpawner;
int g_iDefaultBluSpawner;

// -----<<< Forward handles >>>-----
Handle g_hForwardOnRocketCreated;
Handle g_hForwardOnRocketCreatedPre;
Handle g_hForwardOnRocketDeflect;
Handle g_hForwardOnRocketDeflectPre;
Handle g_hForwardOnRocketSteal;
Handle g_hForwardOnRocketNoTarget;
Handle g_hForwardOnRocketDelay;
Handle g_hForwardOnRocketBounce;
Handle g_hForwardOnRocketBouncePre;
Handle g_hForwardOnRocketsConfigExecuted;
Handle g_hForwardOnRocketStateChanged;

// *********************************************************************************
// PLUGIN LOGIC (INCLUDES)
// *********************************************************************************
#include "dodgeball_utilities.inc"
#include "dodgeball_config.inc"
#include "dodgeball_rockets.inc"
#include "dodgeball_events.inc"
#include "dodgeball_core.inc"
#include "dodgeball_natives.inc"

// *********************************************************************************
// PLUGIN INFO & LIFECYCLE
// *********************************************************************************
public Plugin myinfo =
{
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTHOR,
	description = PLUGIN_NAME,
	version     = PLUGIN_VERSION,
	url         = PLUGIN_CONTACT
};

public void OnPluginStart()
{
	char strModName[32]; GetGameFolderName(strModName, sizeof(strModName));
	if (!StrEqual(strModName, "tf")) SetFailState("This plugin is only for Team Fortress 2.");

	LoadTranslations("tfdb.phrases.txt");

	CreateConVar("tf_dodgeball_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	g_hCvarEnabled = CreateConVar("tf_dodgeball_enabled", "1", "Enable Dodgeball on TFDB maps?", _, true, 0.0, true, 1.0);
	g_hCvarEnableCfgFile = CreateConVar("tf_dodgeball_enablecfg", "sourcemod/dodgeball_enable.cfg", "Config file to execute when enabling the Dodgeball game mode.");
	g_hCvarDisableCfgFile = CreateConVar("tf_dodgeball_disablecfg", "sourcemod/dodgeball_disable.cfg", "Config file to execute when disabling the Dodgeball game mode.");
	g_hCvarStealPreventionNumber = CreateConVar("tf_dodgeball_sp_number", "3", "How many steals before you get slayed?", _, true, 0.0, false);
	g_hCvarStealPreventionDamage = CreateConVar("tf_dodgeball_sp_damage", "0", "Reduce all damage on stolen rockets?", _, true, 0.0, true, 1.0);
	g_hCvarStealDistance = CreateConVar("tf_dodgeball_sp_distance", "48.0", "The distance between players for a steal to register.", _, true, 0.0, false);
	g_hCvarDelayPrevention = CreateConVar("tf_dodgeball_delay_prevention", "1", "Enable delay prevention?", _, true, 0.0, true, 1.0);
	g_hCvarDelayPreventionTime = CreateConVar("tf_dodgeball_dp_time", "5", "How much time (in seconds) before delay prevention activates?", _, true, 0.0, false);
	g_hCvarDelayPreventionSpeedup = CreateConVar("tf_dodgeball_dp_speedup", "100", "How much speed (in hammer units per second) should the rocket gain when delayed?", _, true, 0.0, false);
	g_hCvarNoTargetRedirectDamage = CreateConVar("tf_dodgeball_redirect_damage", "1", "Reduce all damage when a rocket has an invalid target?", _, true, 0.0, true, 1.0);
	g_hCvarStealMessage = CreateConVar("tf_dodgeball_sp_message", "1", "Display the steal message(s)?", _, true, 0.0, true, 1.0);
	g_hCvarDelayMessage = CreateConVar("tf_dodgeball_dp_message", "1", "Display the delay message(s)?", _, true, 0.0, true, 1.0);

	g_hSpawnersTrie = new StringMap();
	g_fTickModifier = 0.1 / GetTickInterval();

	AddTempEntHook("TFExplosion", OnTFExplosion);

	RegisterCommands();
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] strError, int iErrMax)
{
	CreateNative("TFDB_IsValidRocket", Native_IsValidRocket);
	CreateNative("TFDB_FindRocketByEntity", Native_FindRocketByEntity);
	CreateNative("TFDB_IsDodgeballEnabled", Native_IsDodgeballEnabled);
	CreateNative("TFDB_GetRocketEntity", Native_GetRocketEntity);
	CreateNative("TFDB_GetRocketFlags", Native_GetRocketFlags);
	CreateNative("TFDB_SetRocketFlags", Native_SetRocketFlags);
	CreateNative("TFDB_GetRocketTarget", Native_GetRocketTarget);
	CreateNative("TFDB_SetRocketTarget", Native_SetRocketTarget);
	CreateNative("TFDB_GetRocketEventDeflections", Native_GetRocketEventDeflections);
	CreateNative("TFDB_SetRocketEventDeflections", Native_SetRocketEventDeflections);
	CreateNative("TFDB_GetRocketDeflections", Native_GetRocketDeflections);
	CreateNative("TFDB_SetRocketDeflections", Native_SetRocketDeflections);
	CreateNative("TFDB_GetRocketClass", Native_GetRocketClass);
	CreateNative("TFDB_SetRocketClass", Native_SetRocketClass);
	CreateNative("TFDB_GetRocketClassCount", Native_GetRocketClassCount);
	CreateNative("TFDB_GetRocketClassBehaviour", Native_GetRocketClassBehaviour);
	CreateNative("TFDB_SetRocketClassBehaviour", Native_SetRocketClassBehaviour);
	CreateNative("TFDB_GetRocketClassFlags", Native_GetRocketClassFlags);
	CreateNative("TFDB_SetRocketClassFlags", Native_SetRocketClassFlags);
	CreateNative("TFDB_GetRocketClassDamage", Native_GetRocketClassDamage);
	CreateNative("TFDB_SetRocketClassDamage", Native_SetRocketClassDamage);
	CreateNative("TFDB_GetRocketClassDamageIncrement", Native_GetRocketClassDamageIncrement);
	CreateNative("TFDB_SetRocketClassDamageIncrement", Native_SetRocketClassDamageIncrement);
	CreateNative("TFDB_GetRocketClassSpeed", Native_GetRocketClassSpeed);
	CreateNative("TFDB_SetRocketClassSpeed", Native_SetRocketClassSpeed);
	CreateNative("TFDB_GetRocketClassSpeedIncrement", Native_GetRocketClassSpeedIncrement);
	CreateNative("TFDB_SetRocketClassSpeedIncrement", Native_SetRocketClassSpeedIncrement);
	CreateNative("TFDB_GetRocketClassSpeedLimit", Native_GetRocketClassSpeedLimit);
	CreateNative("TFDB_SetRocketClassSpeedLimit", Native_SetRocketClassSpeedLimit);
	CreateNative("TFDB_GetRocketClassTurnRate", Native_GetRocketClassTurnRate);
	CreateNative("TFDB_SetRocketClassTurnRate", Native_SetRocketClassTurnRate);
	CreateNative("TFDB_GetRocketClassTurnRateIncrement", Native_GetRocketClassTurnRateIncrement);
	CreateNative("TFDB_SetRocketClassTurnRateIncrement", Native_SetRocketClassTurnRateIncrement);
	CreateNative("TFDB_GetRocketClassTurnRateLimit", Native_GetRocketClassTurnRateLimit);
	CreateNative("TFDB_SetRocketClassTurnRateLimit", Native_SetRocketClassTurnRateLimit);
	CreateNative("TFDB_GetRocketClassElevationRate", Native_GetRocketClassElevationRate);
	CreateNative("TFDB_SetRocketClassElevationRate", Native_SetRocketClassElevationRate);
	CreateNative("TFDB_GetRocketClassElevationLimit", Native_GetRocketClassElevationLimit);
	CreateNative("TFDB_SetRocketClassElevationLimit", Native_SetRocketClassElevationLimit);
	CreateNative("TFDB_GetRocketClassRocketsModifier", Native_GetRocketClassRocketsModifier);
	CreateNative("TFDB_SetRocketClassRocketsModifier", Native_SetRocketClassRocketsModifier);
	CreateNative("TFDB_GetRocketClassPlayerModifier", Native_GetRocketClassPlayerModifier);
	CreateNative("TFDB_SetRocketClassPlayerModifier", Native_SetRocketClassPlayerModifier);
	CreateNative("TFDB_GetRocketClassControlDelay", Native_GetRocketClassControlDelay);
	CreateNative("TFDB_SetRocketClassControlDelay", Native_SetRocketClassControlDelay);
	CreateNative("TFDB_GetRocketClassDragTimeMin", Native_GetRocketClassDragTimeMin);
	CreateNative("TFDB_SetRocketClassDragTimeMin", Native_SetRocketClassDragTimeMin);
	CreateNative("TFDB_GetRocketClassDragTimeMax", Native_GetRocketClassDragTimeMax);
	CreateNative("TFDB_SetRocketClassDragTimeMax", Native_SetRocketClassDragTimeMax);
	CreateNative("TFDB_SetRocketClassCount", Native_SetRocketClassCount);
	CreateNative("TFDB_SetRocketEntity", Native_SetRocketEntity);
	CreateNative("TFDB_GetRocketClassMaxBounces", Native_GetRocketClassMaxBounces);
	CreateNative("TFDB_SetRocketClassMaxBounces", Native_SetRocketClassMaxBounces);
	CreateNative("TFDB_GetSpawnersName", Native_GetSpawnersName);
	CreateNative("TFDB_SetSpawnersName", Native_SetSpawnersName);
	CreateNative("TFDB_GetSpawnersMaxRockets", Native_GetSpawnersMaxRockets);
	CreateNative("TFDB_SetSpawnersMaxRockets", Native_SetSpawnersMaxRockets);
	CreateNative("TFDB_GetSpawnersInterval", Native_GetSpawnersInterval);
	CreateNative("TFDB_SetSpawnersInterval", Native_SetSpawnersInterval);
	CreateNative("TFDB_GetSpawnersChancesTable", Native_GetSpawnersChancesTable);
	CreateNative("TFDB_SetSpawnersChancesTable", Native_SetSpawnersChancesTable);
	CreateNative("TFDB_GetSpawnersCount", Native_GetSpawnersCount);
	CreateNative("TFDB_SetSpawnersCount", Native_SetSpawnersCount);
	CreateNative("TFDB_GetCurrentRedSpawn", Native_GetCurrentRedSpawn);
	CreateNative("TFDB_SetCurrentRedSpawn", Native_SetCurrentRedSpawn);
	CreateNative("TFDB_GetSpawnPointsRedCount", Native_GetSpawnPointsRedCount);
	CreateNative("TFDB_SetSpawnPointsRedCount", Native_SetSpawnPointsRedCount);
	CreateNative("TFDB_GetSpawnPointsRedClass", Native_GetSpawnPointsRedClass);
	CreateNative("TFDB_SetSpawnPointsRedClass", Native_SetSpawnPointsRedClass);
	CreateNative("TFDB_GetSpawnPointsRedEntity", Native_GetSpawnPointsRedEntity);
	CreateNative("TFDB_SetSpawnPointsRedEntity", Native_SetSpawnPointsRedEntity);
	CreateNative("TFDB_GetCurrentBluSpawn", Native_GetCurrentBluSpawn);
	CreateNative("TFDB_SetCurrentBluSpawn", Native_SetCurrentBluSpawn);
	CreateNative("TFDB_GetSpawnPointsBluCount", Native_GetSpawnPointsBluCount);
	CreateNative("TFDB_SetSpawnPointsBluCount", Native_SetSpawnPointsBluCount);
	CreateNative("TFDB_GetSpawnPointsBluClass", Native_GetSpawnPointsBluClass);
	CreateNative("TFDB_SetSpawnPointsBluClass", Native_SetSpawnPointsBluClass);
	CreateNative("TFDB_GetSpawnPointsBluEntity", Native_GetSpawnPointsBluEntity);
	CreateNative("TFDB_SetSpawnPointsBluEntity", Native_SetSpawnPointsBluEntity);
	CreateNative("TFDB_GetRoundStarted", Native_GetRoundStarted);
	CreateNative("TFDB_GetRoundCount", Native_GetRoundCount);
	CreateNative("TFDB_GetRocketsFired", Native_GetRocketsFired);
	CreateNative("TFDB_GetNextSpawnTime", Native_GetNextSpawnTime);
	CreateNative("TFDB_SetNextSpawnTime", Native_SetNextSpawnTime);
	CreateNative("TFDB_GetLastDeadTeam", Native_GetLastDeadTeam);
	CreateNative("TFDB_GetLastDeadClient", Native_GetLastDeadClient);
	CreateNative("TFDB_GetLastStealer", Native_GetLastStealer);
	CreateNative("TFDB_GetRocketSpeed", Native_GetRocketSpeed);
	CreateNative("TFDB_SetRocketSpeed", Native_SetRocketSpeed);
	CreateNative("TFDB_GetRocketMphSpeed", Native_GetRocketMphSpeed);
	CreateNative("TFDB_SetRocketMphSpeed", Native_SetRocketMphSpeed);
	CreateNative("TFDB_GetRocketDirection", Native_GetRocketDirection);
	CreateNative("TFDB_SetRocketDirection", Native_SetRocketDirection);
	CreateNative("TFDB_GetRocketLastDeflectionTime", Native_GetRocketLastDeflectionTime);
	CreateNative("TFDB_SetRocketLastDeflectionTime", Native_SetRocketLastDeflectionTime);
	CreateNative("TFDB_GetRocketLastBeepTime", Native_GetRocketLastBeepTime);
	CreateNative("TFDB_SetRocketLastBeepTime", Native_SetRocketLastBeepTime);
	CreateNative("TFDB_GetRocketCount", Native_GetRocketCount);
	CreateNative("TFDB_GetLastSpawnTime", Native_GetLastSpawnTime);
	CreateNative("TFDB_GetRocketBounces", Native_GetRocketBounces);
	CreateNative("TFDB_SetRocketBounces", Native_SetRocketBounces);
	CreateNative("TFDB_GetRocketClassName", Native_GetRocketClassName);
	CreateNative("TFDB_SetRocketClassName", Native_SetRocketClassName);
	CreateNative("TFDB_GetRocketClassLongName", Native_GetRocketClassLongName);
	CreateNative("TFDB_SetRocketClassLongName", Native_SetRocketClassLongName);
	CreateNative("TFDB_GetRocketClassModel", Native_GetRocketClassModel);
	CreateNative("TFDB_SetRocketClassModel", Native_SetRocketClassModel);
	CreateNative("TFDB_GetRocketClassBeepInterval", Native_GetRocketClassBeepInterval);
	CreateNative("TFDB_SetRocketClassBeepInterval", Native_SetRocketClassBeepInterval);
	CreateNative("TFDB_GetRocketClassSpawnSound", Native_GetRocketClassSpawnSound);
	CreateNative("TFDB_SetRocketClassSpawnSound", Native_SetRocketClassSpawnSound);
	CreateNative("TFDB_GetRocketClassBeepSound", Native_GetRocketClassBeepSound);
	CreateNative("TFDB_SetRocketClassBeepSound", Native_SetRocketClassBeepSound);
	CreateNative("TFDB_GetRocketClassAlertSound", Native_GetRocketClassAlertSound);
	CreateNative("TFDB_SetRocketClassAlertSound", Native_SetRocketClassAlertSound);
	CreateNative("TFDB_GetRocketClassCritChance", Native_GetRocketClassCritChance);
	CreateNative("TFDB_SetRocketClassCritChance", Native_SetRocketClassCritChance);
	CreateNative("TFDB_GetRocketClassTargetWeight", Native_GetRocketClassTargetWeight);
	CreateNative("TFDB_SetRocketClassTargetWeight", Native_SetRocketClassTargetWeight);
	CreateNative("TFDB_GetRocketClassCmdsOnSpawn", Native_GetRocketClassCmdsOnSpawn);
	CreateNative("TFDB_SetRocketClassCmdsOnSpawn", Native_SetRocketClassCmdsOnSpawn);
	CreateNative("TFDB_GetRocketClassCmdsOnDeflect", Native_GetRocketClassCmdsOnDeflect);
	CreateNative("TFDB_SetRocketClassCmdsOnDeflect", Native_SetRocketClassCmdsOnDeflect);
	CreateNative("TFDB_GetRocketClassCmdsOnKill", Native_GetRocketClassCmdsOnKill);
	CreateNative("TFDB_SetRocketClassCmdsOnKill", Native_SetRocketClassCmdsOnKill);
	CreateNative("TFDB_GetRocketClassCmdsOnExplode", Native_GetRocketClassCmdsOnExplode);
	CreateNative("TFDB_SetRocketClassCmdsOnExplode", Native_SetRocketClassCmdsOnExplode);
	CreateNative("TFDB_GetRocketClassCmdsOnNoTarget", Native_GetRocketClassCmdsOnNoTarget);
	CreateNative("TFDB_SetRocketClassCmdsOnNoTarget", Native_SetRocketClassCmdsOnNoTarget);
	CreateNative("TFDB_GetRocketClassBounceScale", Native_GetRocketClassBounceScale);
	CreateNative("TFDB_SetRocketClassBounceScale", Native_SetRocketClassBounceScale);
	CreateNative("TFDB_CreateRocket", Native_CreateRocket);
	CreateNative("TFDB_DestroyRocket", Native_DestroyRocket);
	CreateNative("TFDB_DestroyRockets", Native_DestroyRockets);
	CreateNative("TFDB_DestroyRocketClasses", Native_DestroyRocketClasses);
	CreateNative("TFDB_DestroySpawners", Native_DestroySpawners);
	CreateNative("TFDB_ParseConfigurations", Native_ParseConfigurations);
	CreateNative("TFDB_PopulateSpawnPoints", Native_PopulateSpawnPoints);
	CreateNative("TFDB_HomingRocketThink", Native_HomingRocketThink);
	CreateNative("TFDB_RocketOtherThink", Native_RocketOtherThink);
	CreateNative("TFDB_RocketLegacyThink", Native_RocketLegacyThink);
	CreateNative("TFDB_GetRocketState", Native_GetRocketState);
	CreateNative("TFDB_SetRocketState", Native_SetRocketState);
	CreateNative("TFDB_GetStealInfo", Native_GetStealInfo);
	CreateNative("TFDB_SetStealInfo", Native_SetStealInfo);

	SetupForwards();

	RegPluginLibrary("tfdb");

	return APLRes_Success;
}

void SetupForwards()
{
	g_hForwardOnRocketCreated = CreateGlobalForward("TFDB_OnRocketCreated", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardOnRocketCreatedPre = CreateGlobalForward("TFDB_OnRocketCreatedPre", ET_Event, Param_Cell, Param_CellByRef, Param_CellByRef);
	g_hForwardOnRocketDeflect = CreateGlobalForward("TFDB_OnRocketDeflect", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardOnRocketDeflectPre = CreateGlobalForward("TFDB_OnRocketDeflectPre", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_CellByRef);
	g_hForwardOnRocketSteal = CreateGlobalForward("TFDB_OnRocketSteal", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardOnRocketNoTarget = CreateGlobalForward("TFDB_OnRocketNoTarget", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardOnRocketDelay = CreateGlobalForward("TFDB_OnRocketDelay", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardOnRocketBounce = CreateGlobalForward("TFDB_OnRocketBounce", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardOnRocketBouncePre = CreateGlobalForward("TFDB_OnRocketBouncePre", ET_Event, Param_Cell, Param_Cell, Param_Array, Param_Array);
	g_hForwardOnRocketsConfigExecuted = CreateGlobalForward("TFDB_OnRocketsConfigExecuted", ET_Ignore, Param_String);
	g_hForwardOnRocketStateChanged = CreateGlobalForward("TFDB_OnRocketStateChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
}

public void OnConfigsExecuted()
{
	if (!(g_hCvarEnabled.BoolValue && IsDodgeBallMap())) return;

	EnableDodgeBall();
}

public void OnMapEnd()
{
	DisableDodgeBall();
}

void Forward_OnRocketCreated(int iIndex, int iEntity)
{
	Call_StartForward(g_hForwardOnRocketCreated);
	Call_PushCell(iIndex);
	Call_PushCell(iEntity);
	Call_Finish();
}

Action Forward_OnRocketCreatedPre(int iIndex, int &iClass, RocketFlags &iFlags)
{
	Action aResult;

	Call_StartForward(g_hForwardOnRocketCreatedPre);
	Call_PushCell(iIndex);
	Call_PushCellRef(iClass);
	Call_PushCellRef(iFlags);
	Call_Finish(aResult);

	return aResult;
}

void Forward_OnRocketDeflect(int iIndex, int iEntity, int iOwner)
{
	Call_StartForward(g_hForwardOnRocketDeflect);
	Call_PushCell(iIndex);
	Call_PushCell(iEntity);
	Call_PushCell(iOwner);
	Call_Finish();
}

Action Forward_OnRocketDeflectPre(int iIndex, int iEntity, int iOwner, int &iTarget)
{
	Action aResult;

	Call_StartForward(g_hForwardOnRocketDeflectPre);
	Call_PushCell(iIndex);
	Call_PushCell(iEntity);
	Call_PushCell(iOwner);
	Call_PushCellRef(iTarget);
	Call_Finish(aResult);

	return aResult;
}

void Forward_OnRocketSteal(int iIndex, int iOwner, int iTarget, int iStealCount)
{
	Call_StartForward(g_hForwardOnRocketSteal);
	Call_PushCell(iIndex);
	Call_PushCell(iOwner);
	Call_PushCell(iTarget);
	Call_PushCell(iStealCount);
	Call_Finish();
}

void Forward_OnRocketNoTarget(int iIndex, int iTarget, int iOwner)
{
	Call_StartForward(g_hForwardOnRocketNoTarget);
	Call_PushCell(iIndex);
	Call_PushCell(iTarget);
	Call_PushCell(iOwner);
	Call_Finish();
}

void Forward_OnRocketDelay(int iIndex, int iTarget)
{
	Call_StartForward(g_hForwardOnRocketDelay);
	Call_PushCell(iIndex);
	Call_PushCell(iTarget);
	Call_Finish();
}

void Forward_OnRocketBounce(int iIndex, int iEntity)
{
	Call_StartForward(g_hForwardOnRocketBounce);
	Call_PushCell(iIndex);
	Call_PushCell(iEntity);
	Call_Finish();
}

Action Forward_OnRocketBouncePre(int iIndex, int iEntity, float fAngles[3], float fVelocity[3])
{
	Action aResult;

	Call_StartForward(g_hForwardOnRocketBouncePre);
	Call_PushCell(iIndex);
	Call_PushCell(iEntity);
	Call_PushArrayEx(fAngles, sizeof(fAngles), SM_PARAM_COPYBACK);
	Call_PushArrayEx(fVelocity, sizeof(fVelocity), SM_PARAM_COPYBACK);
	Call_Finish(aResult);

	return aResult;
}

void Forward_OnRocketsConfigExecuted(const char[] strConfigFile)
{
	Call_StartForward(g_hForwardOnRocketsConfigExecuted);
	Call_PushString(strConfigFile);
	Call_Finish();
}

void Forward_OnRocketStateChanged(int iIndex, RocketState iState, RocketState iNewState)
{
	Call_StartForward(g_hForwardOnRocketStateChanged);
	Call_PushCell(iIndex);
	Call_PushCell(iState);
	Call_PushCell(iNewState);
	Call_Finish();
}

void Internal_SetRocketState(int iIndex, RocketState iNewState)
{
	RocketState iState = g_iRocketState[iIndex];
	if (iState == iNewState)
	{
		return;
	}

	g_iRocketState[iIndex] = iNewState;
	Forward_OnRocketStateChanged(iIndex, iState, iNewState);
}

public bool MLTargetFilterStealer(const char[] strPattern, ArrayList hClients)
{
	bool bReverse = (StrContains(strPattern, "!", false) == 1);
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!(IsClientInGame(iClient) && (hClients.FindValue(iClient) == -1))) continue;

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

	return !!hClients.Length;
}

#if defined _multicolors_included && defined _more_colors_included && defined _colors_included
stock void CSkipNextClient(int iClient)
{
	if (!IsSource2009())
	{
		C_SkipNextClient(iClient);
	}
	else
	{
		MC_SkipNextClient(iClient);
	}
}
#endif