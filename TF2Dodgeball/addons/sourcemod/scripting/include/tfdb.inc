#if defined _tfdb_included
 #endinput
#endif
#define _tfdb_included

// ---- General settings -----------------------------------------------------------
#define FPS_LOGIC_RATE          20.0
#define FPS_LOGIC_INTERVAL      1.0 / FPS_LOGIC_RATE

// ---- Maximum structure sizes ----------------------------------------------------
#define MAX_ROCKETS             100
#define MAX_ROCKET_CLASSES      50
#define MAX_SPAWNER_CLASSES     50
#define MAX_SPAWN_POINTS        100

// ---- Flags and types constants --------------------------------------------------
enum BehaviourTypes
{
	Behaviour_Unknown,
	Behaviour_Homing,
	Behaviour_LegacyHoming
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
	RocketFlag_IsTRLimited      = 1 << 16,
	RocketFlag_IsSpeedLimited   = 1 << 17,
	RocketFlag_KeepDirection    = 1 << 18,
	RocketFlag_TeamlessHits     = 1 << 19,
	RocketFlag_ResetBounces     = 1 << 20,
	RocketFlag_NoBounceDrags    = 1 << 21,
	RocketFlag_OnNoTargetCmd    = 1 << 22,
	RocketFlag_CanBeStolen      = 1 << 23,
	RocketFlag_StealTeamCheck   = 1 << 24
};

enum RocketSound
{
	RocketSound_Spawn,
	RocketSound_Beep,
	RocketSound_Alert
};

enum RocketState
{
	RocketState_None     = 0,
	RocketState_Dragging = 1 << 0,
	RocketState_Bouncing = 1 << 1,
	RocketState_Stolen   = 1 << 2,
	RocketState_Delayed  = 1 << 3,
	RocketState_CanDrag  = 1 << 4
};

enum struct eRocketSteal
{
	bool stoleRocket;
	int rocketsStolen;
}

#define TestFlags(%1,%2)    (!!((%1) & (%2)))

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

// ---- Forwards --------------------------------------------------
forward void TFDB_OnRocketCreated(int iIndex, int iEntity);
forward Action TFDB_OnRocketCreatedPre(int iIndex, int &iClass, RocketFlags &iFlags);
forward void TFDB_OnRocketDeflect(int iIndex, int iEntity, int iOwner);
forward Action TFDB_OnRocketDeflectPre(int iIndex, int iEntity, int iOwner, int &iTarget);
forward void TFDB_OnRocketSteal(int iIndex, int iOwner, int iTarget, int iStealCount);
forward void TFDB_OnRocketNoTarget(int iIndex, int iTarget, int iOwner);
forward void TFDB_OnRocketDelay(int iIndex, int iTarget);
forward void TFDB_OnRocketBounce(int iIndex, int iEntity);
forward Action TFDB_OnRocketBouncePre(int iIndex, int iEntity, float fAngles[3], float fVelocity[3]);
forward void TFDB_OnRocketsConfigExecuted(const char[] strConfigFile);
forward void TFDB_OnRocketStateChanged(int iIndex, RocketState iState, RocketState iNewState);

// ---- Natives --------------------------------------------------
native bool TFDB_IsValidRocket(int iIndex);
native int TFDB_FindRocketByEntity(int iEntity);
native bool TFDB_IsDodgeballEnabled();
native int TFDB_GetRocketEntity(int iIndex);
native RocketFlags TFDB_GetRocketFlags(int iIndex);
native void TFDB_SetRocketFlags(int iIndex, RocketFlags iFlags);
native int TFDB_GetRocketTarget(int iIndex);
native void TFDB_SetRocketTarget(int iIndex, int iTarget);
native int TFDB_GetRocketEventDeflections(int iIndex);
native void TFDB_SetRocketEventDeflections(int iIndex, int iDeflections);
native int TFDB_GetRocketDeflections(int iIndex);
native void TFDB_SetRocketDeflections(int iIndex, int iDeflections);
native int TFDB_GetRocketClass(int iIndex);
native void TFDB_SetRocketClass(int iIndex, int iClass);
native int TFDB_GetRocketClassCount();
native BehaviourTypes TFDB_GetRocketClassBehaviour(int iClass);
native void TFDB_SetRocketClassBehaviour(int iClass, BehaviourTypes iBehaviour);
native RocketFlags TFDB_GetRocketClassFlags(int iClass);
native void TFDB_SetRocketClassFlags(int iClass, RocketFlags iFlags);
native float TFDB_GetRocketClassDamage(int iClass);
native void TFDB_SetRocketClassDamage(int iClass, float fDamage);
native float TFDB_GetRocketClassDamageIncrement(int iClass);
native void TFDB_SetRocketClassDamageIncrement(int iClass, float fDamage);
native float TFDB_GetRocketClassSpeed(int iClass);
native void TFDB_SetRocketClassSpeed(int iClass, float fSpeed);
native float TFDB_GetRocketClassSpeedIncrement(int iClass);
native void TFDB_SetRocketClassSpeedIncrement(int iClass, float fSpeed);
native float TFDB_GetRocketClassSpeedLimit(int iClass);
native void TFDB_SetRocketClassSpeedLimit(int iClass, float fSpeed);
native float TFDB_GetRocketClassTurnRate(int iClass);
native void TFDB_SetRocketClassTurnRate(int iClass, float fTurnRate);
native float TFDB_GetRocketClassTurnRateIncrement(int iClass);
native void TFDB_SetRocketClassTurnRateIncrement(int iClass, float fTurnRate);
native float TFDB_GetRocketClassTurnRateLimit(int iClass);
native void TFDB_SetRocketClassTurnRateLimit(int iClass, float fTurnRate);
native float TFDB_GetRocketClassElevationRate(int iClass);
native void TFDB_SetRocketClassElevationRate(int iClass, float fElevation);
native float TFDB_GetRocketClassElevationLimit(int iClass);
native void TFDB_SetRocketClassElevationLimit(int iClass, float fElevation);
native float TFDB_GetRocketClassRocketsModifier(int iClass);
native void TFDB_SetRocketClassRocketsModifier(int iClass, float fModifier);
native float TFDB_GetRocketClassPlayerModifier(int iClass);
native void TFDB_SetRocketClassPlayerModifier(int iClass, float fModifier);
native float TFDB_GetRocketClassControlDelay(int iClass);
native void TFDB_SetRocketClassControlDelay(int iClass, float fDelay);
native float TFDB_GetRocketClassDragTimeMin(int iClass);
native void TFDB_SetRocketClassDragTimeMin(int iClass, float fMin);
native float TFDB_GetRocketClassDragTimeMax(int iClass);
native void TFDB_SetRocketClassDragTimeMax(int iClass, float fMax);
native void TFDB_SetRocketClassCount(int iCount);
native void TFDB_SetRocketEntity(int iIndex, int iEntity);
native int TFDB_GetRocketClassMaxBounces(int iClass);
native void TFDB_SetRocketClassMaxBounces(int iClass, int iBounces);
native void TFDB_GetSpawnersName(int iSpawnerClass, char[] strBuffer, int iMaxLen);
native void TFDB_SetSpawnersName(int iSpawnerClass, const char[] strName);
native int TFDB_GetSpawnersMaxRockets(int iSpawnerClass);
native void TFDB_SetSpawnersMaxRockets(int iSpawnerClass, int iMaxRockets);
native float TFDB_GetSpawnersInterval(int iSpawnerClass);
native void TFDB_SetSpawnersInterval(int iSpawnerClass, float fInterval);
native ArrayList TFDB_GetSpawnersChancesTable(int iSpawnerClass);
native void TFDB_SetSpawnersChancesTable(int iSpawnerClass, ArrayList hTable);
native int TFDB_GetSpawnersCount();
native void TFDB_SetSpawnersCount(int iCount);
native int TFDB_GetCurrentRedSpawn();
native void TFDB_SetCurrentRedSpawn(int iRedSpawn);
native int TFDB_GetSpawnPointsRedCount();
native void TFDB_SetSpawnPointsRedCount(int iCount);
native int TFDB_GetSpawnPointsRedClass(int iSpawner);
native void TFDB_SetSpawnPointsRedClass(int iSpawner, int iSpawnerClass);
native int TFDB_GetSpawnPointsRedEntity(int iSpawner);
native void TFDB_SetSpawnPointsRedEntity(int iSpawner, int iEntity);
native int TFDB_GetCurrentBluSpawn();
native void TFDB_SetCurrentBluSpawn(int iBluSpawn);
native int TFDB_GetSpawnPointsBluCount();
native void TFDB_SetSpawnPointsBluCount(int iCount);
native int TFDB_GetSpawnPointsBluClass(int iSpawner);
native void TFDB_SetSpawnPointsBluClass(int iSpawner, int iSpawnerClass);
native int TFDB_GetSpawnPointsBluEntity(int iSpawner);
native void TFDB_SetSpawnPointsBluEntity(int iSpawner, int iEntity);
native bool TFDB_GetRoundStarted();
native int TFDB_GetRoundCount();
native int TFDB_GetRocketsFired();
native float TFDB_GetNextSpawnTime();
native void TFDB_SetNextSpawnTime(float fSpawnTime);
native int TFDB_GetLastDeadTeam();
native int TFDB_GetLastDeadClient();
native int TFDB_GetLastStealer();
native float TFDB_GetRocketSpeed(int iIndex);
native void TFDB_SetRocketSpeed(int iIndex, float fSpeed);
native float TFDB_GetRocketMphSpeed(int iIndex);
native void TFDB_SetRocketMphSpeed(int iIndex, float fSpeed);
native void TFDB_GetRocketDirection(int iIndex, float fBuffer[3]);
native void TFDB_SetRocketDirection(int iIndex, float fDirection[3]);
native float TFDB_GetRocketLastDeflectionTime(int iIndex);
native void TFDB_SetRocketLastDeflectionTime(int iIndex, float fTime);
native float TFDB_GetRocketLastBeepTime(int iIndex);
native void TFDB_SetRocketLastBeepTime(int iIndex, float fTime);
native int TFDB_GetRocketCount();
native float TFDB_GetLastSpawnTime(int iIndex);
native int TFDB_GetRocketBounces(int iIndex);
native void TFDB_SetRocketBounces(int iIndex, int iBounces);
native void TFDB_GetRocketClassName(int iClass, char[] strBuffer, int iMaxLen);
native void TFDB_SetRocketClassName(int iClass, const char[] strName);
native void TFDB_GetRocketClassLongName(int iClass, char[] strBuffer, int iMaxLen);
native void TFDB_SetRocketClassLongName(int iClass, const char[] strName);
native void TFDB_GetRocketClassModel(int iClass, char[] strBuffer, int iMaxLen);
native void TFDB_SetRocketClassModel(int iClass, const char[] strPath);
native float TFDB_GetRocketClassBeepInterval(int iClass);
native void TFDB_SetRocketClassBeepInterval(int iClass, float fInterval);
native void TFDB_GetRocketClassSpawnSound(int iClass, char[] strBuffer, int iMaxLen);
native void TFDB_SetRocketClassSpawnSound(int iClass, const char[] strPath);
native void TFDB_GetRocketClassBeepSound(int iClass, char[] strBuffer, int iMaxLen);
native void TFDB_SetRocketClassBeepSound(int iClass, const char[] strPath);
native void TFDB_GetRocketClassAlertSound(int iClass, char[] strBuffer, int iMaxLen);
native void TFDB_SetRocketClassAlertSound(int iClass, const char[] strPath);
native float TFDB_GetRocketClassCritChance(int iClass);
native void TFDB_SetRocketClassCritChance(int iClass, float fChance);
native float TFDB_GetRocketClassTargetWeight(int iClass);
native void TFDB_SetRocketClassTargetWeight(int iClass, float fWeight);
native DataPack TFDB_GetRocketClassCmdsOnSpawn(int iClass);
native void TFDB_SetRocketClassCmdsOnSpawn(int iClass, DataPack hCmds);
native DataPack TFDB_GetRocketClassCmdsOnDeflect(int iClass);
native void TFDB_SetRocketClassCmdsOnDeflect(int iClass, DataPack hCmds);
native DataPack TFDB_GetRocketClassCmdsOnKill(int iClass);
native void TFDB_SetRocketClassCmdsOnKill(int iClass, DataPack hCmds);
native DataPack TFDB_GetRocketClassCmdsOnExplode(int iClass);
native void TFDB_SetRocketClassCmdsOnExplode(int iClass, DataPack hCmds);
native DataPack TFDB_GetRocketClassCmdsOnNoTarget(int iClass);
native void TFDB_SetRocketClassCmdsOnNoTarget(int iClass, DataPack hCmds);
native float TFDB_GetRocketClassBounceScale(int iClass);
native void TFDB_SetRocketClassBounceScale(int iClass, float fScale);
native void TFDB_CreateRocket(int iSpawnerEntity, int iSpawnerClass, int iTeam, int iClass = -1);
native void TFDB_DestroyRocket(int iIndex);
native void TFDB_DestroyRockets();
native void TFDB_DestroyRocketClasses();
native void TFDB_DestroySpawners();
native void TFDB_ParseConfigurations(const char[] strConfigFile = "general.cfg");
native void TFDB_PopulateSpawnPoints();
native void TFDB_HomingRocketThink(int iIndex);
native void TFDB_RocketLegacyThink(int iIndex);
native RocketState TFDB_GetRocketState(int iIndex);
native void TFDB_SetRocketState(int iIndex, RocketState iState);
native void TFDB_GetStealInfo(int iClient, bool &stole, int &count);
native void TFDB_SetStealInfo(int iClient, bool stole, int count);

public SharedPlugin __pl_TFDB =
{
	name = "tfdb",
	file = "TF2Dodgeball.smx",
	
	#if defined REQUIRE_PLUGIN
		required=1,
	#else
		required=0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_TFDB_SetNTVOptional()
{
	MarkNativeAsOptional("TFDB_IsValidRocket");
	MarkNativeAsOptional("TFDB_FindRocketByEntity");
	MarkNativeAsOptional("TFDB_IsDodgeballEnabled");
	MarkNativeAsOptional("TFDB_GetRocketEntity");
	MarkNativeAsOptional("TFDB_GetRocketFlags");
	MarkNativeAsOptional("TFDB_SetRocketFlags");
	MarkNativeAsOptional("TFDB_GetRocketTarget");
	MarkNativeAsOptional("TFDB_SetRocketTarget");
	MarkNativeAsOptional("TFDB_GetRocketEventDeflections");
	MarkNativeAsOptional("TFDB_SetRocketEventDeflections");
	MarkNativeAsOptional("TFDB_GetRocketDeflections");
	MarkNativeAsOptional("TFDB_SetRocketDeflections");
	MarkNativeAsOptional("TFDB_GetRocketClass");
	MarkNativeAsOptional("TFDB_SetRocketClass");
	MarkNativeAsOptional("TFDB_GetRocketClassCount");
	MarkNativeAsOptional("TFDB_GetRocketClassBehaviour");
	MarkNativeAsOptional("TFDB_SetRocketClassBehaviour");
	MarkNativeAsOptional("TFDB_GetRocketClassFlags");
	MarkNativeAsOptional("TFDB_SetRocketClassFlags");
	MarkNativeAsOptional("TFDB_GetRocketClassDamage");
	MarkNativeAsOptional("TFDB_SetRocketClassDamage");
	MarkNativeAsOptional("TFDB_GetRocketClassDamageIncrement");
	MarkNativeAsOptional("TFDB_SetRocketClassDamageIncrement");
	MarkNativeAsOptional("TFDB_GetRocketClassSpeed");
	MarkNativeAsOptional("TFDB_SetRocketClassSpeed");
	MarkNativeAsOptional("TFDB_GetRocketClassSpeedIncrement");
	MarkNativeAsOptional("TFDB_SetRocketClassSpeedIncrement");
	MarkNativeAsOptional("TFDB_GetRocketClassSpeedLimit");
	MarkNativeAsOptional("TFDB_SetRocketClassSpeedLimit");
	MarkNativeAsOptional("TFDB_GetRocketClassTurnRate");
	MarkNativeAsOptional("TFDB_SetRocketClassTurnRate");
	MarkNativeAsOptional("TFDB_GetRocketClassTurnRateIncrement");
	MarkNativeAsOptional("TFDB_SetRocketClassTurnRateIncrement");
	MarkNativeAsOptional("TFDB_GetRocketClassTurnRateLimit");
	MarkNativeAsOptional("TFDB_SetRocketClassTurnRateLimit");
	MarkNativeAsOptional("TFDB_GetRocketClassElevationRate");
	MarkNativeAsOptional("TFDB_SetRocketClassElevationRate");
	MarkNativeAsOptional("TFDB_GetRocketClassElevationLimit");
	MarkNativeAsOptional("TFDB_SetRocketClassElevationLimit");
	MarkNativeAsOptional("TFDB_GetRocketClassRocketsModifier");
	MarkNativeAsOptional("TFDB_SetRocketClassRocketsModifier");
	MarkNativeAsOptional("TFDB_GetRocketClassPlayerModifier");
	MarkNativeAsOptional("TFDB_SetRocketClassPlayerModifier");
	MarkNativeAsOptional("TFDB_GetRocketClassControlDelay");
	MarkNativeAsOptional("TFDB_SetRocketClassControlDelay");
	MarkNativeAsOptional("TFDB_GetRocketClassDragTimeMin");
	MarkNativeAsOptional("TFDB_SetRocketClassDragTimeMin");
	MarkNativeAsOptional("TFDB_GetRocketClassDragTimeMax");
	MarkNativeAsOptional("TFDB_SetRocketClassDragTimeMax");
	MarkNativeAsOptional("TFDB_SetRocketClassCount");
	MarkNativeAsOptional("TFDB_SetRocketEntity");
	MarkNativeAsOptional("TFDB_GetRocketClassMaxBounces");
	MarkNativeAsOptional("TFDB_SetRocketClassMaxBounces");
	MarkNativeAsOptional("TFDB_GetSpawnersName");
	MarkNativeAsOptional("TFDB_SetSpawnersName");
	MarkNativeAsOptional("TFDB_GetSpawnersMaxRockets");
	MarkNativeAsOptional("TFDB_SetSpawnersMaxRockets");
	MarkNativeAsOptional("TFDB_GetSpawnersInterval");
	MarkNativeAsOptional("TFDB_SetSpawnersInterval");
	MarkNativeAsOptional("TFDB_GetSpawnersChancesTable");
	MarkNativeAsOptional("TFDB_SetSpawnersChancesTable");
	MarkNativeAsOptional("TFDB_GetSpawnersCount");
	MarkNativeAsOptional("TFDB_SetSpawnersCount");
	MarkNativeAsOptional("TFDB_GetCurrentRedSpawn");
	MarkNativeAsOptional("TFDB_SetCurrentRedSpawn");
	MarkNativeAsOptional("TFDB_GetSpawnPointsRedCount");
	MarkNativeAsOptional("TFDB_SetSpawnPointsRedCount");
	MarkNativeAsOptional("TFDB_GetSpawnPointsRedClass");
	MarkNativeAsOptional("TFDB_SetSpawnPointsRedClass");
	MarkNativeAsOptional("TFDB_GetSpawnPointsRedEntity");
	MarkNativeAsOptional("TFDB_SetSpawnPointsRedEntity");
	MarkNativeAsOptional("TFDB_GetCurrentBluSpawn");
	MarkNativeAsOptional("TFDB_SetCurrentBluSpawn");
	MarkNativeAsOptional("TFDB_GetSpawnPointsBluCount");
	MarkNativeAsOptional("TFDB_SetSpawnPointsBluCount");
	MarkNativeAsOptional("TFDB_GetSpawnPointsBluClass");
	MarkNativeAsOptional("TFDB_SetSpawnPointsBluClass");
	MarkNativeAsOptional("TFDB_GetSpawnPointsBluEntity");
	MarkNativeAsOptional("TFDB_SetSpawnPointsBluEntity");
	MarkNativeAsOptional("TFDB_GetRoundStarted");
	MarkNativeAsOptional("TFDB_GetRoundCount");
	MarkNativeAsOptional("TFDB_GetRocketsFired");
	MarkNativeAsOptional("TFDB_GetNextSpawnTime");
	MarkNativeAsOptional("TFDB_SetNextSpawnTime");
	MarkNativeAsOptional("TFDB_GetLastDeadTeam");
	MarkNativeAsOptional("TFDB_GetLastDeadClient");
	MarkNativeAsOptional("TFDB_GetLastStealer");
	MarkNativeAsOptional("TFDB_GetRocketSpeed");
	MarkNativeAsOptional("TFDB_SetRocketSpeed");
	MarkNativeAsOptional("TFDB_GetRocketMphSpeed");
	MarkNativeAsOptional("TFDB_SetRocketMphSpeed");
	MarkNativeAsOptional("TFDB_GetRocketDirection");
	MarkNativeAsOptional("TFDB_SetRocketDirection");
	MarkNativeAsOptional("TFDB_GetRocketLastDeflectionTime");
	MarkNativeAsOptional("TFDB_SetRocketLastDeflectionTime");
	MarkNativeAsOptional("TFDB_GetRocketLastBeepTime");
	MarkNativeAsOptional("TFDB_SetRocketLastBeepTime");
	MarkNativeAsOptional("TFDB_GetRocketCount");
	MarkNativeAsOptional("TFDB_GetLastSpawnTime");
	MarkNativeAsOptional("TFDB_GetRocketBounces");
	MarkNativeAsOptional("TFDB_SetRocketBounces");
	MarkNativeAsOptional("TFDB_GetRocketClassName");
	MarkNativeAsOptional("TFDB_SetRocketClassName");
	MarkNativeAsOptional("TFDB_GetRocketClassLongName");
	MarkNativeAsOptional("TFDB_SetRocketClassLongName");
	MarkNativeAsOptional("TFDB_GetRocketClassModel");
	MarkNativeAsOptional("TFDB_SetRocketClassModel");
	MarkNativeAsOptional("TFDB_GetRocketClassBeepInterval");
	MarkNativeAsOptional("TFDB_SetRocketClassBeepInterval");
	MarkNativeAsOptional("TFDB_GetRocketClassSpawnSound");
	MarkNativeAsOptional("TFDB_SetRocketClassSpawnSound");
	MarkNativeAsOptional("TFDB_GetRocketClassBeepSound");
	MarkNativeAsOptional("TFDB_SetRocketClassBeepSound");
	MarkNativeAsOptional("TFDB_GetRocketClassAlertSound");
	MarkNativeAsOptional("TFDB_SetRocketClassAlertSound");
	MarkNativeAsOptional("TFDB_GetRocketClassCritChance");
	MarkNativeAsOptional("TFDB_SetRocketClassCritChance");
	MarkNativeAsOptional("TFDB_GetRocketClassTargetWeight");
	MarkNativeAsOptional("TFDB_SetRocketClassTargetWeight");
	MarkNativeAsOptional("TFDB_GetRocketClassCmdsOnSpawn");
	MarkNativeAsOptional("TFDB_SetRocketClassCmdsOnSpawn");
	MarkNativeAsOptional("TFDB_GetRocketClassCmdsOnDeflect");
	MarkNativeAsOptional("TFDB_SetRocketClassCmdsOnDeflect");
	MarkNativeAsOptional("TFDB_GetRocketClassCmdsOnKill");
	MarkNativeAsOptional("TFDB_SetRocketClassCmdsOnKill");
	MarkNativeAsOptional("TFDB_GetRocketClassCmdsOnExplode");
	MarkNativeAsOptional("TFDB_SetRocketClassCmdsOnExplode");
	MarkNativeAsOptional("TFDB_GetRocketClassCmdsOnNoTarget");
	MarkNativeAsOptional("TFDB_SetRocketClassCmdsOnNoTarget");
	MarkNativeAsOptional("TFDB_GetRocketClassBounceScale");
	MarkNativeAsOptional("TFDB_SetRocketClassBounceScale");
	MarkNativeAsOptional("TFDB_CreateRocket");
	MarkNativeAsOptional("TFDB_DestroyRocket");
	MarkNativeAsOptional("TFDB_DestroyRockets");
	MarkNativeAsOptional("TFDB_DestroyRocketClasses");
	MarkNativeAsOptional("TFDB_DestroySpawners");
	MarkNativeAsOptional("TFDB_ParseConfigurations");
	MarkNativeAsOptional("TFDB_PopulateSpawnPoints");
	MarkNativeAsOptional("TFDB_HomingRocketThink");
	MarkNativeAsOptional("TFDB_RocketLegacyThink");
	MarkNativeAsOptional("TFDB_GetRocketState");
	MarkNativeAsOptional("TFDB_SetRocketState");
	MarkNativeAsOptional("TFDB_GetStealInfo");
	MarkNativeAsOptional("TFDB_SetStealInfo");
}
#endif