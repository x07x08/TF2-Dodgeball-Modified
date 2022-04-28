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
    RocketFlag_CustomTrail      = 1 << 22,
    RocketFlag_CustomSprite     = 1 << 23,
    RocketFlag_RemoveParticles  = 1 << 24,
    RocketFlag_ReplaceParticles = 1 << 25,
    RocketFlag_OnNoTargetCmd    = 1 << 26,
    RocketFlag_CanBeStolen      = 1 << 27,
    RocketFlag_StealTeamCheck   = 1 << 28
};

enum RocketSound
{
    RocketSound_Spawn,
    RocketSound_Beep,
    RocketSound_Alert
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
/**
 * Called whenever a rocket has been fully created, set up and spawned.
 *
 * @param iIndex     Rocket index.
 * @param iEntity    Rocket entity.
*/

forward void TFDB_OnRocketCreated(int iIndex, int iEntity);

/**
 * Called before a rocket is created.
 *
 * @param iIndex    Rocket index.
 * @param iClass    Rocket class.
 * @param iFlags    Rocket flags.
 * @return          Plugin_Handled or Plugin_Stop to stop spawning the rocket, Plugin_Changed to override the class and the flags of the rocket.
*/

forward Action TFDB_OnRocketCreatedPre(int iIndex, int &iClass, RocketFlags &iFlags);

/**
 * Called when a rocket has been deflected, right before a drag.
 *
 * @note This does not fire on legacy homing rockets.
 *
 * @param iIndex     Rocket index.
 * @param iEntity    Rocket entity.
 * @param iOwner     Rocket owner.
*/

forward void TFDB_OnRocketAltDeflect(int iIndex, int iEntity, int iOwner);

/**
 * Called when a rocket has been deflected.
 *
 * @param iIndex     Rocket index.
 * @param iEntity    Rocket entity.
 * @param iOwner     Rocket owner.
*/

forward void TFDB_OnRocketDeflect(int iIndex, int iEntity, int iOwner);

/**
 * Called when a rocket has been deflected, before the "alert" sound is played.
 *
 * @param iIndex     Rocket index.
 * @param iEntity    Rocket entity.
 * @param iOwner     Rocket owner.
 * @param iTarget    Rocket target.
 * @return           Plugin_Handled or Plugin_Stop to stop the deflect, Plugin_Changed to change the target.
*/

forward Action TFDB_OnRocketDeflectPre(int iIndex, int iEntity, int iOwner, int &iTarget);

/**
 * Called when a rocket has been stolen.
 *
 * @param iIndex          Rocket index.
 * @param iOwner          Client who stole the rocket.
 * @param iTarget         Rocket target.
 * @param iStealCount     Count of the all the rockets the client stole.
*/

forward void TFDB_OnRocketSteal(int iIndex, int iOwner, int iTarget, int iStealCount);

/**
 * Called when a rocket has no target.
 *
 * @param iIndex     Rocket index.
 * @param iTarget    New rocket target.
 * @param iOwner     Previous rocket target.
*/

forward void TFDB_OnRocketNoTarget(int iIndex, int iTarget, int iOwner);

/**
 * Called when a client has delayed a rocket.
 *
 * @param iIndex     Rocket index.
 * @param iTarget    Rocket target which delayed.
*/

forward void TFDB_OnRocketDelay(int iIndex, int iTarget);

/**
 * Called when a rocket has bounced.
 *
 * @param iIndex     Rocket index.
 * @param iEntity    Rocket entity.
*/

forward void TFDB_OnRocketBounce(int iIndex, int iEntity);

/**
 * Called when a rocket has bounced, before it has its angles and velocity updated.
 *
 * @param iIndex       Rocket index.
 * @param iEntity      Rocket entity.
 * @param fAngles      New bounce angles.
 * @param fVelocity    New bounce velocity.
 * @return             Plugin_Handled or Plugin_Stop to unhook the rocket, Plugin_Changed to change the angles and velocity.
*/

forward Action TFDB_OnRocketBouncePre(int iIndex, int iEntity, float fAngles[3], float fVelocity[3]);

// ---- Natives --------------------------------------------------
/**
 * Checks if a rocket structure is valid.
 *
 * @param iIndex    Rocket index.
 * @return          True if valid, false otherwise.
 * @error           Index out of bounds.
*/

native bool TFDB_IsValidRocket(int iIndex);

/**
 * Finds a rocket index from its entity.
 *
 * @param iEntity    Entity index.
 * @return           Rocket index, -1 on failure.
 * @error            Invalid entity.
*/

native int TFDB_FindRocketByEntity(int iEntity);

/**
 * Checks if the dodgeball gamemode is enabled.
 *
 * @return    True if enabled, false otherwise.
*/

native bool TFDB_IsDodgeballEnabled();

/**
 * Gets the entity reference of a rocket.
 *
 * @param iIndex    Rocket index.
 * @return          Rocket entity reference.
 * @error           Invalid index.
*/

native int TFDB_GetRocketEntity(int iIndex);

/**
 * Gets the flags bitmask of a rocket.
 *
 * @param iIndex    Rocket index.
 * @return          Rocket flags bitmask.
 * @error           Invalid index.
*/

native RocketFlags TFDB_GetRocketFlags(int iIndex);

/**
 * Sets the flags bitmask of a rocket.
 *
 * @param iIndex    Rocket index.
 * @param iFlags    New flags bitmask.
 * @noreturn
 * @error           Invalid index.
*/

native void TFDB_SetRocketFlags(int iIndex, RocketFlags iFlags);

/**
 * Gets the target reference of a rocket.
 *
 * @param iIndex    Rocket index.
 * @return          Rocket target reference.
 * @error           Invalid index.
*/

native int TFDB_GetRocketTarget(int iIndex);

/**
 * Sets the target of a rocket.
 *
 * @param iIndex     Rocket index.
 * @param iTarget    New rocket target reference.
 * @noreturn
 * @error            Invalid index.
*/

native void TFDB_SetRocketTarget(int iIndex, int iTarget);

/**
 * Gets the "event" deflections count of a rocket.
 *
 * @note This returns "g_iRocketEventDeflections", which is updated on every deflect.
 *
 * @param iIndex    Rocket index.
 * @return          Deflections count.
 * @error           Invalid index.
*/

native int TFDB_GetRocketEventDeflections(int iIndex);

/**
 * Sets the "event" deflections count of a rocket.
 *
 * @note This changes "g_iRocketEventDeflections".
 *
 * @param iIndex          Rocket index.
 * @param iDeflections    New deflections count.
 * @noreturn
 * @error                 Invalid index.
*/

native void TFDB_SetRocketEventDeflections(int iIndex, int iDeflections);

/**
 * Gets the "alt" deflections count of a rocket.
 *
 * @note This returns "g_iRocketAltDeflections", which is updated after "g_iRocketEventDeflections".
 *
 * @param iIndex    Rocket index.
 * @return          Deflections count, 0 if the rocket behaviour is "legacy homing".
 * @error           Invalid index.
*/

native int TFDB_GetRocketAltDeflections(int iIndex);

/**
 * Sets the "alt" deflections count of a rocket.
 *
 * @note This changes "g_iRocketAltDeflections".
 *       Calling this function on a "legacy homing" rocket will have no effects.
 *
 * @param iIndex          Rocket index.
 * @param iDeflections    New deflections count.
 * @noreturn
 * @error                 Invalid index.
*/

native void TFDB_SetRocketAltDeflections(int iIndex, int iDeflections);

/**
 * Gets the deflections count of a rocket.
 *
 * @note This returns "g_iRocketDeflections", which is updated after "g_iRocketAltDeflections".
 *       If the behaviour is legacy homing, it is updated after "g_iRocketEventDeflections".
 *
 * @param iIndex    Rocket index.
 * @return          Deflections count.
 * @error           Invalid index.
*/

native int TFDB_GetRocketDeflections(int iIndex);

/**
 * Sets the deflections count of a rocket.
 *
 * @note This changes "g_iRocketDeflections".
 *
 * @param iIndex          Rocket index.
 * @param iDeflections    New deflections count.
 * @noreturn
 * @error                 Invalid index.
*/

native void TFDB_SetRocketDeflections(int iIndex, int iDeflections);

/**
 * Gets the class of a rocket.
 *
 * @param iIndex    Rocket index.
 * @return          Rocket class.
 * @error           Invalid index.
*/

native int TFDB_GetRocketClass(int iIndex);

/**
 * Sets the class of a rocket.
 *
 * @param iIndex    Rocket index.
 * @param iClass    New rocket class.
 * @noreturn
 * @error           Invalid index or class index out of bounds.
*/

native void TFDB_SetRocketClass(int iIndex, int iClass);

/**
 * Gets the count of all the valid rocket classes.
 *
 * @return    Rocket classes count.
*/

native int TFDB_GetRocketClassCount();

/**
 * Gets the behaviour type of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class behaviour type.
 * @error           Invalid class.
*/

native BehaviourTypes TFDB_GetRocketClassBehaviour(int iClass);

/**
 * Sets the behaviour type of a rocket class.
 *
 * @param iClass        Rocket class.
 * @param iBehaviour    New rocket class behaviour.
 * @noreturn
 * @error               Invalid class.
*/

native void TFDB_SetRocketClassBehaviour(int iClass, BehaviourTypes iBehaviour);

/**
 * Gets the flags bitmask of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class flags bitmask.
 * @error           Invalid class.
*/

native RocketFlags TFDB_GetRocketClassFlags(int iClass);

/**
 * Sets the flags bitmask of a rocket class.
 *
 * @param iClass    Rocket class.
 * @param iFlags    New rocket class flags bitmask.
 * @noreturn
 * @error           Invalid class.
*/

native void TFDB_SetRocketClassFlags(int iClass, RocketFlags iFlags);

/**
 * Gets the base damage of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class base damage.
 * @error           Invalid class.
*/

native float TFDB_GetRocketClassDamage(int iClass);

/**
 * Sets the base damage of a rocket class.
 *
 * @param iClass     Rocket class.
 * @param fDamage    New rocket class base damage.
 * @noreturn
 * @error            Invalid class.
*/

native void TFDB_SetRocketClassDamage(int iClass, float fDamage);

/**
 * Gets the damage increment of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class damage increment.
 * @error           Invalid class.
*/

native float TFDB_GetRocketClassDamageIncrement(int iClass);

/**
 * Sets the damage increment of a rocket class.
 *
 * @param iClass     Rocket class.
 * @param fDamage    New rocket class damage increment.
 * @noreturn
 * @error            Invalid class.
*/

native void TFDB_SetRocketClassDamageIncrement(int iClass, float fDamage);

/**
 * Gets the base speed of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class base speed.
 * @error           Invalid class.
*/

native float TFDB_GetRocketClassSpeed(int iClass);

/**
 * Sets the base speed of a rocket class.
 *
 * @param iClass    Rocket class.
 * @param fSpeed    New rocket class base speed.
 * @noreturn
 * @error           Invalid class.
*/

native void TFDB_SetRocketClassSpeed(int iClass, float fSpeed);

/**
 * Gets the speed increment of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class speed increment.
 * @error           Invalid class.
*/

native float TFDB_GetRocketClassSpeedIncrement(int iClass);

/**
 * Sets the speed increment of a rocket class.
 *
 * @param iClass    Rocket class.
 * @param fSpeed    New rocket class speed increment.
 * @noreturn
 * @error           Invalid class.
*/

native void TFDB_SetRocketClassSpeedIncrement(int iClass, float fSpeed);

/**
 * Gets the speed limit of a rocket class.
 *
 * @note Make sure the rocket has the "RocketFlag_IsSpeedLimited" flag.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class speed limit.
 * @error           Invalid class.
*/

native float TFDB_GetRocketClassSpeedLimit(int iClass);

/**
 * Sets the speed limit of a rocket class.
 *
 * @note Make sure the rocket has the "RocketFlag_IsSpeedLimited" flag.
 *
 * @param iClass    Rocket class.
 * @param fSpeed    New rocket class speed limit.
 * @noreturn
 * @error           Invalid class.
*/

native void TFDB_SetRocketClassSpeedLimit(int iClass, float fSpeed);

/**
 * Gets the base turnrate of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class base turnrate.
 * @error           Invalid class.
*/

native float TFDB_GetRocketClassTurnRate(int iClass);

/**
 * Sets the base turnrate of a rocket class.
 *
 * @param iClass       Rocket class.
 * @param fTurnRate    New rocket class base turnrate.
 * @noreturn
 * @error              Invalid class.
*/

native void TFDB_SetRocketClassTurnRate(int iClass, float fTurnRate);

/**
 * Gets the turnrate increment of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class turnrate increment.
 * @error           Invalid class.
*/

native float TFDB_GetRocketClassTurnRateIncrement(int iClass);

/**
 * Sets the turnrate increment of a rocket class.
 *
 * @param iClass       Rocket class.
 * @param fTurnRate    New rocket class turnrate increment.
 * @noreturn
 * @error              Invalid class.
*/

native void TFDB_SetRocketClassTurnRateIncrement(int iClass, float fTurnRate);

/**
 * Gets the turnrate limit of a rocket class.
 *
 * @note Make sure the rocket has the "RocketFlag_IsTRLimited" flag.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class turnrate limit.
 * @error           Invalid class.
*/

native float TFDB_GetRocketClassTurnRateLimit(int iClass);

/**
 * Sets the turnrate limit of a rocket class.
 *
 * @note Make sure the rocket has the "RocketFlag_IsTRLimited" flag.
 *
 * @param iClass       Rocket class.
 * @param fTurnRate    New rocket class turnrate limit.
 * @noreturn
 * @error              Invalid class.
*/

native void TFDB_SetRocketClassTurnRateLimit(int iClass, float fTurnRate);

/**
 * Gets the elevation rate of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class elevation rate.
 * @error           Invalid class.
*/

native float TFDB_GetRocketClassElevationRate(int iClass);

/**
 * Sets the elevation rate of a rocket class.
 *
 * @param iClass        Rocket class.
 * @param fElevation    New rocket class elevation rate.
 * @noreturn
 * @error               Invalid class.
*/

native void TFDB_SetRocketClassElevationRate(int iClass, float fElevation);

/**
 * Gets the elevation limit of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class elevation limit.
 * @error           Invalid class.
*/

native float TFDB_GetRocketClassElevationLimit(int iClass);

/**
 * Sets the elevation limit of a rocket class.
 *
 * @param iClass        Rocket class.
 * @param fElevation    New rocket class elevation limit.
 * @noreturn
 * @error               Invalid class.
*/

native void TFDB_SetRocketClassElevationLimit(int iClass, float fElevation);

/**
 * Gets the rockets no. modifier of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class rockets no. modifier.
 * @error           Invalid class.
*/

native float TFDB_GetRocketClassRocketsModifier(int iClass);

/**
 * Sets the rockets no. modifier of a rocket class.
 *
 * @param iClass       Rocket class.
 * @param fModifier    New rocket class rockets no. modifier.
 * @noreturn
 * @error              Invalid class.
*/

native void TFDB_SetRocketClassRocketsModifier(int iClass, float fModifier);

/**
 * Gets the players no. modifier of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class players no. modifier.
 * @error           Invalid class.
*/

native float TFDB_GetRocketClassPlayerModifier(int iClass);

/**
 * Sets the players no. modifier of a rocket class.
 *
 * @param iClass       Rocket class.
 * @param fModifier    New rocket class players no. modifier.
 * @noreturn
 * @error              Invalid class.
*/

native void TFDB_SetRocketClassPlayerModifier(int iClass, float fModifier);

/**
 * Gets the control delay of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class control delay.
 * @error           Invalid class.
*/

native float TFDB_GetRocketClassControlDelay(int iClass);

/**
 * Sets the control delay of a rocket class.
 *
 * @param iClass    Rocket class.
 * @param fDelay    New rocket class control delay.
 * @noreturn
 * @error           Invalid class.
*/

native void TFDB_SetRocketClassControlDelay(int iClass, float fDelay);

/**
 * Gets the min. drag time of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class min. drag time.
 * @error           Invalid class.
*/

native float TFDB_GetRocketClassDragTimeMin(int iClass);

/**
 * Sets the min. drag time of a rocket class.
 *
 * @param iClass    Rocket class.
 * @param fMin      New rocket class min. drag time.
 * @noreturn
 * @error           Invalid class.
*/

native void TFDB_SetRocketClassDragTimeMin(int iClass, float fMin);

/**
 * Gets the max. drag time of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class max. drag time.
 * @error           Invalid class.
*/

native float TFDB_GetRocketClassDragTimeMax(int iClass);

/**
 * Sets the max. drag time of a rocket class.
 *
 * @param iClass    Rocket class.
 * @param fMax      New rocket class max. drag time.
 * @noreturn
 * @error           Invalid class.
*/

native void TFDB_SetRocketClassDragTimeMax(int iClass, float fMax);

/**
 * Sets the rocket classes count.
 *
 * @param iCount    New rocket classes count.
 * @noreturn
*/

native void TFDB_SetRocketClassCount(int iCount);

/**
 * Sets the entity reference of a rocket.
 *
 * @param iIndex     Rocket index.
 * @param iEntity    New rocket entity reference.
 * @noreturn
 * @error            Invalid index.
*/

native void TFDB_SetRocketEntity(int iIndex, int iEntity);

/**
 * Gets the saved parameters of a rocket class.
 *
 * Valid iParam values are :
 *
 * 0 - Speed
 * 1 - Speed increment
 * 2 - Speed limit
 * 3 - Turnrate
 * 4 - Turnrate increment
 * 5 - Turnrate limit
 * 6 - Elevation rate
 * 7 - Elevation limit
 * 8 - Drag time min
 * 9 - Drag time max
 *
 * @param iClass    Rocket class.
 * @param iParam    Saved rocket class property.
 * @return          Rocket class saved parameter.
 * @error           Invalid class or invalid parameter.
*/

native float TFDB_GetSavedParameters(int iClass, int iParam);

/**
 * Sets the saved parameters of a rocket class.
 *
 * Valid iParam values are :
 *
 * 0 - Speed
 * 1 - Speed increment
 * 2 - Speed limit
 * 3 - Turnrate
 * 4 - Turnrate increment
 * 5 - Turnrate limit
 * 6 - Elevation rate
 * 7 - Elevation limit
 * 8 - Drag time min
 * 9 - Drag time max
 *
 * @param iClass    Rocket class.
 * @param iParam    Saved rocket class property.
 * @param fValue    New rocket class saved parameter value.
 * @noreturn
 * @error           Invalid class or invalid parameter.
*/

native void TFDB_SetSavedParameters(int iClass, int iParam, float fValue);

/**
 * Gets the saved flags bitmask of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class saved flags bitmask.
 * @error           Invalid class.
*/

native RocketFlags TFDB_GetSavedRocketClassFlags(int iClass);

/**
 * Sets the saved flags bitmask of a rocket class.
 *
 * @param iClass    Rocket class.
 * @param iFlags    New rocket class saved flags bitmask.
 * @noreturn
 * @error           Invalid class.
*/

native void TFDB_SetSavedRocketClassFlags(int iClass, RocketFlags iFlags);

/**
 * Gets the max. bounces count of a rocket.
 *
 * @param iClass    Rocket index.
 * @return          Rocket class max. bounces count.
 * @error           Invalid class.
*/

native int TFDB_GetRocketClassMaxBounces(int iClass);

/**
 * Sets the max. bounces count of a rocket.
 *
 * @param iClass      Rocket index.
 * @param iBounces    New rocket class max. bounces count.
 * @noreturn
 * @error             Invalid class.
*/

native void TFDB_SetRocketClassMaxBounces(int iClass, int iBounces);

/**
 * Gets the saved max. bounces count of a rocket.
 *
 * @param iClass    Rocket index.
 * @return          Rocket class saved max. bounces count.
 * @error           Invalid class.
*/

native int TFDB_GetRocketClassSavedMaxBounces(int iClass);

/**
 * Sets the saved max. bounces count of a rocket.
 *
 * @param iClass      Rocket index.
 * @param iBounces    New rocket class saved max. bounces count.
 * @noreturn
 * @error             Invalid class.
*/

native void TFDB_SetRocketClassSavedMaxBounces(int iClass, int iBounces);

/**
 * Gets the name of a spawner class.
 *
 * @param iSpawnerClass    Spawner class.
 * @param strBuffer        Buffer to store the name of the spawner class.
 * @param iMaxLen          Size of the buffer array.
 * @noreturn
 * @error                  Invalid spawner class.
*/

native void TFDB_GetSpawnersName(int iSpawnerClass, char[] strBuffer, int iMaxLen);

/**
 * Sets the name of a spawner class.
 *
 * @param iSpawnerClass    Spawner class.
 * @param strName          New spawner class name.
 * @noreturn
 * @error                  Invalid spawner class.
*/

native void TFDB_SetSpawnersName(int iSpawnerClass, char[] strName);

/**
 * Gets the max rockets count of a spawner class.
 *
 * @param iSpawnerClass    Spawner class.
 * @return                 Spawner class max rockets count.
 * @error                  Invalid spawner class.
*/

native int TFDB_GetSpawnersMaxRockets(int iSpawnerClass);

/**
 * Sets the max rockets count of a spawner class.
 *
 * @param iSpawnerClass    Spawner class.
 * @param iMaxRockets      New spawner class max rockets count.
 * @noreturn
 * @error                  Invalid spawner class.
*/

native void TFDB_SetSpawnersMaxRockets(int iSpawnerClass, int iMaxRockets);

/**
 * Gets the rocket spawn interval of a spawner class.
 *
 * @param iSpawnerClass    Spawner class.
 * @return                 Spawner class rocket spawn interval.
 * @error                  Invalid spawner class.
*/

native float TFDB_GetSpawnersInterval(int iSpawnerClass);

/**
 * Sets the rocket spawn interval of a spawner class.
 *
 * @param iSpawnerClass    Spawner class.
 * @param fInterval        New spawner class rocket spawn interval.
 * @noreturn
 * @error                  Invalid spawner class.
*/

native void TFDB_SetSpawnersInterval(int iSpawnerClass, float fInterval);

/**
 * Gets the rockets spawn chances list of a spawner class.
 *
 * @note Once finished, close the handle.
 *
 * @param iSpawnerClass    Spawner class.
 * @return                 Handle for the rockets spawn chances arraylist of the spawner class.
 * @error                  Invalid spawner class.
*/

native ArrayList TFDB_GetSpawnersChancesTable(int iSpawnerClass);

/**
 * Sets the rockets spawn chances list of a spawner class.
 *
 * @param iSpawnerClass    Spawner class.
 * @param hTable           New spawner class rockets spawn chances arraylist.
 * @noreturn
 * @error                  Invalid spawner class.
*/

native void TFDB_SetSpawnersChancesTable(int iSpawnerClass, ArrayList hTable);

/**
 * Gets the saved rockets spawn chances list of a spawner class.
 *
 * @note Once finished, close the handle.
 *
 * @param iSpawnerClass    Spawner class.
 * @return                 Handle for the saved rockets spawn chances arraylist of the spawner class.
 * @error                  Invalid spawner class.
*/

native ArrayList TFDB_GetSavedChancesTable(int iSpawnerClass);

/**
 * Sets the saved rockets spawn chances list of a spawner class.
 *
 * @param iSpawnerClass    Spawner class.
 * @param hTable           New spawner class saved rockets spawn chances arraylist.
 * @noreturn
 * @error                  Invalid spawner class.
*/

native void TFDB_SetSavedChancesTable(int iSpawnerClass, ArrayList hTable);

/**
 * Gets the spawners count.
 *
 * @return    Spawners count.
*/

native int TFDB_GetSpawnersCount();

/**
 * Sets the spawners count.
 *
 * @param iCount    New spawners count.
 * @noreturn
*/

native void TFDB_SetSpawnersCount(int iCount);

/**
 * Gets the current red spawn point.
 *
 * @return    Current red spawn point.
*/

native int TFDB_GetCurrentRedSpawn();

/**
 * Sets the current red spawn point.
 *
 * @param iRedSpawn    New red spawn point.
 * @noreturn
*/

native void TFDB_SetCurrentRedSpawn(int iRedSpawn);

/**
 * Gets the red spawn points count.
 *
 * @return    Red spawn points count.
*/

native int TFDB_GetSpawnPointsRedCount();

/**
 * Sets the red spawn points count.
 *
 * @param iCount    New red spawn points count.
 * @noreturn
*/

native void TFDB_SetSpawnPointsRedCount(int iCount);

/**
 * Gets the spawner class of a red spawn point.
 *
 * @param iSpawner    Spawn point.
 * @return            Red spawn point spawner class.
 * @error             Invalid spawn point.
*/

native int TFDB_GetSpawnPointsRedClass(int iSpawner);

/**
 * Sets the spawner class of a red spawn point.
 *
 * @param iSpawner         Spawn point.
 * @param iSpawnerClass    New red spawn point spawner class.
 * @noreturn
 * @error                  Invalid spawn point or invalid spawner class.
*/

native void TFDB_SetSpawnPointsRedClass(int iSpawner, int iSpawnerClass);

/**
 * Gets the entity of a red spawn point.
 *
 * @param iSpawner    Spawn point.
 * @return            Red spawn point entity.
 * @error             Invalid spawn point.
*/

native int TFDB_GetSpawnPointsRedEntity(int iSpawner);

/**
 * Sets the entity of a red spawn point.
 *
 * @param iSpawner    Spawn point.
 * @param iEntity     New red spawn point entity.
 * @noreturn
 * @error             Invalid spawn point.
*/

native void TFDB_SetSpawnPointsRedEntity(int iSpawner, int iEntity);

/**
 * Gets the current blu spawn point.
 *
 * @return    Current blu spawn point.
*/

native int TFDB_GetCurrentBluSpawn();

/**
 * Sets the current blu spawn point.
 *
 * @param iBluSpawn    New blu spawn point.
 * @noreturn
*/

native void TFDB_SetCurrentBluSpawn(int iBluSpawn);

/**
 * Gets the blu spawn points count.
 *
 * @return    Blu spawn points count.
*/

native int TFDB_GetSpawnPointsBluCount();

/**
 * Sets the blu spawn points count.
 *
 * @param iCount    New blu spawn points count.
 * @noreturn
*/

native void TFDB_SetSpawnPointsBluCount(int iCount);

/**
 * Gets the spawner class of a blu spawn point.
 *
 * @param iSpawner    Spawn point.
 * @return            Blu spawn point spawner class.
 * @error             Invalid spawn point.
*/

native int TFDB_GetSpawnPointsBluClass(int iSpawner);

/**
 * Sets the spawner class of a blu spawn point.
 *
 * @param iSpawner         Spawn point.
 * @param iSpawnerClass    New blu spawn point spawner class.
 * @noreturn
 * @error                  Invalid spawn point or invalid spawner class.
*/

native void TFDB_SetSpawnPointsBluClass(int iSpawner, int iSpawnerClass);

/**
 * Gets the entity of a blu spawn point.
 *
 * @param iSpawner    Spawn point.
 * @return            Blu spawn point entity.
 * @error             Invalid spawn point.
*/

native int TFDB_GetSpawnPointsBluEntity(int iSpawner);

/**
 * Sets the entity of a blu spawn point.
 *
 * @param iSpawner    Spawn point.
 * @param iEntity     New blu spawn point entity.
 * @noreturn
 * @error             Invalid spawn point.
*/

native void TFDB_SetSpawnPointsBluEntity(int iSpawner, int iEntity);

/**
 * Checks if the round has started.
 *
 * @return    True if the round has started, false otherwise.
*/

native bool TFDB_GetRoundStarted();

/**
 * Gets the number of rounds since the map has started.
 *
 * @return    Round count.
*/

native int TFDB_GetRoundCount();

/**
 * Gets the number of fired rockets since the round has started.
 *
 * @return    Fired rockets count.
*/

native int TFDB_GetRocketsFired();

/**
 * Gets the time until the next rocket will spawn.
 *
 * @return    Next spawn time.
*/

native float TFDB_GetNextSpawnTime();

/**
 * Sets the time until the next rocket will spawn.
 *
 * @param fSpawnTime    New spawn time.
 * @noreturn
*/

native void TFDB_SetNextSpawnTime(float fSpawnTime);

/**
 * Gets the last dead team.
 *
 * @return    Last dead team.
*/

native int TFDB_GetLastDeadTeam();

/**
 * Gets the last dead client.
 *
 * @return    Last dead client.
*/

native int TFDB_GetLastDeadClient();

/**
 * Gets the last rocket stealer.
 *
 * @return    Last stealer.
*/

native int TFDB_GetLastStealer();

/**
 * Gets the fake entity reference of a rocket.
 *
 * @note Make sure to check if the rocket has the "RocketFlag_RemoveParticles" flag.
 *
 * @param iIndex    Rocket index.
 * @return          Fake entity reference.
 * @error           Invalid index.
*/

native int TFDB_GetRocketFakeEntity(int iIndex);

/**
 * Sets the fake entity reference of a rocket.
 *
 * @note Make sure to check if the rocket has the "RocketFlag_RemoveParticles" flag.
 *
 * @param iIndex         Rocket index.
 * @param iFakeEntity    New fake entity reference.
 * @noreturn
 * @error                Invalid index.
*/

native void TFDB_SetRocketFakeEntity(int iIndex, int iFakeEntity);

/**
 * Gets the speed of a rocket.
 *
 * @param iIndex    Rocket index.
 * @return          Rocket speed.
 * @error           Invalid index.
*/

native float TFDB_GetRocketSpeed(int iIndex);

/**
 * Sets the speed of a rocket.
 *
 * @param iIndex    Rocket index.
 * @param fSpeed    New rocket speed.
 * @noreturn
 * @error           Invalid index.
*/

native void TFDB_SetRocketSpeed(int iIndex, float fSpeed);

/**
 * Gets the MpH speed of a rocket.
 *
 * @param iIndex    Rocket index.
 * @return          Rocket MpH speed.
 * @error           Invalid index.
*/

native float TFDB_GetRocketMphSpeed(int iIndex);

/**
 * Sets the MpH speed of a rocket.
 *
 * @param iIndex    Rocket index.
 * @param fSpeed    New rocket MpH speed.
 * @noreturn
 * @error           Invalid index.
*/

native void TFDB_SetRocketMphSpeed(int iIndex, float fSpeed);

/**
 * Gets the direction of a rocket.
 *
 * @param iIndex     Rocket index.
 * @param fBuffer    Vector buffer to store the direction.
 * @noreturn
 * @error            Invalid index.
*/

native void TFDB_GetRocketDirection(int iIndex, float fBuffer[3]);

/**
 * Sets the direction of a rocket.
 *
 * @param iIndex        Rocket index.
 * @param fDirection    New rocket direction.
 * @noreturn
 * @error               Invalid index.
*/

native void TFDB_SetRocketDirection(int iIndex, float fDirection[3]);

/**
 * Gets the last time a rocket was deflected.
 *
 * @param iIndex    Rocket index.
 * @return          Last deflection time.
 * @error           Invalid index.
*/

native float TFDB_GetRocketLastDeflectionTime(int iIndex);

/**
 * Gets the current rockets count.
 *
 * @return    Rockets count.
*/

native int TFDB_GetRocketCount();

/**
 * Gets whether a rocket is "bouncing" or not.
 *
 * @note Make sure to check if the behaviour of the rocket is not "legacy homing".
 *       The bouncing state has no effect on the legacy homing behaviour.
 *
 * @param iIndex    Rocket index.
 * @return          True if the rocket is bouncing, false if not.
 * @error           Invalid index.
*/

native bool TFDB_GetIsRocketBouncing(int iIndex);

/**
 * Sets whether a rocket is "bouncing" or not.
 *
 * @note Make sure to check if the behaviour of the rocket is not "legacy homing".
 *       The bouncing state has no effect on the legacy homing behaviour.
 *
 * @param iIndex       Rocket index.
 * @param bBouncing    Bouncing state.
 * @noreturn
 * @error              Invalid index.
*/

native void TFDB_SetIsRocketBouncing(int iIndex, bool bBouncing);

/**
 * Gets whether a rocket is "stolen" or not.
 *
 * @param iIndex    Rocket index.
 * @return          True if the rocket has been stolen, false if not.
 * @error           Invalid index.
*/

native bool TFDB_GetIsRocketStolen(int iIndex);

/**
 * Gets if a rocket is being delayed by a player.
 *
 * @param iIndex    Rocket index.
 * @return          True if the rocket is being delayed, false otherwise.
 * @error           Invalid index.
*/

native bool TFDB_GetPreventingDelay(int iIndex);

/**
 * Gets if a rocket can be dragged.
 *
 * @note Drag settings have no effect on legacy homing rockets.
 *
 * @param iIndex    Rocket index.
 * @return          True if the rocket can be dragged, false otherwise.
 * @error           Invalid index.
*/

native bool TFDB_GetIsRocketDraggable(int iIndex);

/**
 * Sets if a rocket can be dragged.
 *
 * @note Drag settings have no effect on legacy homing rockets.
 *
 * @param iIndex        Rocket index.
 * @param bDraggable    Can be dragged or not.
 * @noreturn
 * @error               Invalid index.
*/

native void TFDB_SetIsRocketDraggable(int iIndex, bool bDraggable);

/**
 * Gets the bounces count of a rocket.
 *
 * @param iIndex    Rocket index.
 * @return          Bounces count.
 * @error           Invalid index.
*/

native int TFDB_GetRocketBounces(int iIndex);

/**
 * Sets the bounces count of a rocket.
 *
 * @param iIndex      Rocket index.
 * @param iBounces    New rocket bounces count.
 * @noreturn
 * @error             Invalid index.
*/

native void TFDB_SetRocketBounces(int iIndex, int iBounces);

/**
 * Gets the name of a rocket class.
 *
 * @param iClass       Rocket class.
 * @param strBuffer    Buffer to store the name of the rocket class.
 * @param iMaxLen      Size of the buffer array.
 * @noreturn
 * @error              Invalid rocket class.
*/

native void TFDB_GetRocketClassName(int iClass, char[] strBuffer, int iMaxLen);

/**
 * Sets the name of a rocket class.
 *
 * @param iClass     Rocket class.
 * @param strName    New rocket class name.
 * @noreturn
 * @error            Invalid rocket class.
*/

native void TFDB_SetRocketClassName(int iClass, char[] strName);

/**
 * Gets the long name of a rocket class.
 *
 * @param iClass       Rocket class.
 * @param strBuffer    Buffer to store the long name of the rocket class.
 * @param iMaxLen      Size of the buffer array.
 * @noreturn
 * @error              Invalid rocket class.
*/

native void TFDB_GetRocketClassLongName(int iClass, char[] strBuffer, int iMaxLen);

/**
 * Sets the long name of a rocket class.
 *
 * @param iClass     Rocket class.
 * @param strName    New rocket class long name.
 * @noreturn
 * @error            Invalid rocket class.
*/

native void TFDB_SetRocketClassLongName(int iClass, char[] strName);

/**
 * Gets the custom model path of a rocket class.
 *
 * @param iClass       Rocket class.
 * @param strBuffer    Buffer to store the custom model path of the rocket class.
 * @param iMaxLen      Size of the buffer array.
 * @noreturn
 * @error              Invalid rocket class.
*/

native void TFDB_GetRocketClassModel(int iClass, char[] strBuffer, int iMaxLen);

/**
 * Sets the custom model path of a rocket class.
 *
 * @param iClass     Rocket class.
 * @param strPath    New rocket class custom model path.
 * @noreturn
 * @error            Invalid rocket class.
*/

native void TFDB_SetRocketClassModel(int iClass, char[] strPath);

/**
 * Gets the trail particle of a rocket class.
 *
 * @param iClass       Rocket class.
 * @param strBuffer    Buffer to store the trail particle of the rocket class.
 * @param iMaxLen      Size of the buffer array.
 * @noreturn
 * @error              Invalid rocket class.
*/

native void TFDB_GetRocketClassTrail(int iClass, char[] strBuffer, int iMaxLen);

/**
 * Sets the trail particle of a rocket class.
 *
 * @param iClass     Rocket class.
 * @param strPath    New rocket class trail particle.
 * @noreturn
 * @error            Invalid rocket class.
*/

native void TFDB_SetRocketClassTrail(int iClass, char[] strPath);

/**
 * Gets the sprite trail material path of a rocket class (no extension).
 *
 * @param iClass       Rocket class.
 * @param strBuffer    Buffer to store the sprite trail material path of the rocket class.
 * @param iMaxLen      Size of the buffer array.
 * @noreturn
 * @error              Invalid rocket class.
*/

native void TFDB_GetRocketClassSprite(int iClass, char[] strBuffer, int iMaxLen);

/**
 * Sets the sprite trail material path of a rocket class (no extension).
 *
 * @param iClass     Rocket class.
 * @param strPath    New rocket class sprite trail material path.
 * @noreturn
 * @error            Invalid rocket class.
*/

native void TFDB_SetRocketClassSprite(int iClass, char[] strPath);

/**
 * Gets the sprite trail color of a rocket class.
 *
 * @param iClass       Rocket class.
 * @param strBuffer    Buffer to store the sprite trail color of the rocket class.
 * @param iMaxLen      Size of the buffer array.
 * @noreturn
 * @error              Invalid rocket class.
*/

native void TFDB_GetRocketClassSpriteColor(int iClass, char[] strBuffer, int iMaxLen);

/**
 * Sets the sprite trail color of a rocket class.
 *
 * @param iClass     Rocket class.
 * @param strPath    New rocket class sprite trail color.
 * @noreturn
 * @error            Invalid rocket class.
*/

native void TFDB_SetRocketClassSpriteColor(int iClass, char[] strPath);

/**
 * Gets the sprite trail lifetime of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class sprite trail lifetime.
 * @error           Invalid rocket class.
*/

native float TFDB_GetRocketClassSpriteLifetime(int iClass);

/**
 * Sets the sprite trail lifetime of a rocket class.
 *
 * @param iClass       Rocket class.
 * @param fLifetime    New rocket class sprite trail lifetime.
 * @noreturn
 * @error              Invalid rocket class.
*/

native void TFDB_SetRocketClassSpriteLifetime(int iClass, float fLifetime);

/**
 * Gets the sprite trail start width of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class sprite trail start width.
 * @error           Invalid rocket class.
*/

native float TFDB_GetRocketClassSpriteStartWidth(int iClass);

/**
 * Sets the sprite trail start width of a rocket class.
 *
 * @param iClass    Rocket class.
 * @param fWidth    New rocket class sprite trail start width.
 * @noreturn
 * @error           Invalid rocket class.
*/

native void TFDB_SetRocketClassSpriteStartWidth(int iClass, float fWidth);

/**
 * Gets the sprite trail end width of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class sprite trail end width.
 * @error           Invalid rocket class.
*/

native float TFDB_GetRocketClassSpriteEndWidth(int iClass);

/**
 * Sets the sprite trail end width of a rocket class.
 *
 * @param iClass    Rocket class.
 * @param fWidth    New rocket class sprite trail end width.
 * @noreturn
 * @error           Invalid rocket class.
*/

native void TFDB_SetRocketClassSpriteEndWidth(int iClass, float fWidth);

/**
 * Gets the beep interval of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class beep interval.
 * @error           Invalid rocket class.
*/

native float TFDB_GetRocketClassBeepInterval(int iClass);

/**
 * Sets the beep interval of a rocket class.
 *
 * @param iClass       Rocket class.
 * @param fInterval    New rocket class beep interval.
 * @noreturn
 * @error              Invalid rocket class.
*/

native void TFDB_SetRocketClassBeepInterval(int iClass, float fInterval);

/**
 * Gets the custom spawn sound of a rocket class.
 *
 * @param iClass       Rocket class.
 * @param strBuffer    Buffer to store the custom spawn sound path of the rocket class.
 * @param iMaxLen      Size of the buffer array.
 * @noreturn
 * @error              Invalid rocket class.
*/

native void TFDB_GetRocketClassSpawnSound(int iClass, char[] strBuffer, int iMaxLen);

/**
 * Sets the custom spawn sound of a rocket class.
 *
 * @param iClass     Rocket class.
 * @param strPath    New rocket class custom spawn sound path.
 * @noreturn
 * @error            Invalid rocket class.
*/

native void TFDB_SetRocketClassSpawnSound(int iClass, char[] strPath);

/**
 * Gets the custom beep sound of a rocket class.
 *
 * @param iClass       Rocket class.
 * @param strBuffer    Buffer to store the custom beep sound path of the rocket class.
 * @param iMaxLen      Size of the buffer array.
 * @noreturn
 * @error              Invalid rocket class.
*/

native void TFDB_GetRocketClassBeepSound(int iClass, char[] strBuffer, int iMaxLen);

/**
 * Sets the custom beep sound of a rocket class.
 *
 * @param iClass     Rocket class.
 * @param strPath    New rocket class custom beep sound path.
 * @noreturn
 * @error            Invalid rocket class.
*/

native void TFDB_SetRocketClassBeepSound(int iClass, char[] strPath);

/**
 * Gets the custom alert sound of a rocket class.
 *
 * @param iClass       Rocket class.
 * @param strBuffer    Buffer to store the custom alert sound path of the rocket class.
 * @param iMaxLen      Size of the buffer array.
 * @noreturn
 * @error              Invalid rocket class.
*/

native void TFDB_GetRocketClassAlertSound(int iClass, char[] strBuffer, int iMaxLen);

/**
 * Sets the custom alert sound of a rocket class.
 *
 * @param iClass     Rocket class.
 * @param strPath    New rocket class custom alert sound path.
 * @noreturn
 * @error            Invalid rocket class.
*/

native void TFDB_SetRocketClassAlertSound(int iClass, char[] strPath);

/**
 * Gets the critical rocket spawn chance of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class critical chance.
 * @error           Invalid rocket class.
*/

native float TFDB_GetRocketClassCritChance(int iClass);

/**
 * Sets the critical rocket spawn chance of a rocket class.
 *
 * @param iClass     Rocket class.
 * @param fChance    New rocket class critical chance.
 * @noreturn
 * @error            Invalid rocket class.
*/

native void TFDB_SetRocketClassCritChance(int iClass, float fChance);

/**
 * Gets the target weight of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class target weight.
 * @error           Invalid rocket class.
*/

native float TFDB_GetRocketClassTargetWeight(int iClass);

/**
 * Sets the target weight of a rocket class.
 *
 * @param iClass     Rocket class.
 * @param fWeight    New rocket class target weight.
 * @noreturn
 * @error            Invalid rocket class.
*/

native void TFDB_SetRocketClassTargetWeight(int iClass, float fWeight);

/**
 * Gets the spawn commands datapack of a rocket class.
 *
 * @note Once finished, close the handle.
 *
 * @param iClass    Rocket class.
 * @return          Handle for the spawn commands datapack of the rocket class.
 * @error           Invalid rocket class.
*/

native DataPack TFDB_GetRocketClassCmdsOnSpawn(int iClass);

/**
 * Sets the spawn commands datapack of a rocket class.
 *
 * @param iClass    Rocket class.
 * @param hCmds     New rocket class spawn commands datapack.
 * @noreturn
 * @error           Invalid rocket class.
*/

native void TFDB_SetRocketClassCmdsOnSpawn(int iClass, DataPack hCmds);

/**
 * Gets the deflect commands datapack of a rocket class.
 *
 * @note Once finished, close the handle.
 *
 * @param iClass    Rocket class.
 * @return          Handle for the deflect commands datapack of the rocket class.
 * @error           Invalid rocket class.
*/

native DataPack TFDB_GetRocketClassCmdsOnDeflect(int iClass);

/**
 * Sets the deflect commands datapack of a rocket class.
 *
 * @param iClass    Rocket class.
 * @param hCmds     New rocket class deflect commands datapack.
 * @noreturn
 * @error           Invalid rocket class.
*/

native void TFDB_SetRocketClassCmdsOnDeflect(int iClass, DataPack hCmds);

/**
 * Gets the kill commands datapack of a rocket class.
 *
 * @note Once finished, close the handle.
 *
 * @param iClass    Rocket class.
 * @return          Handle for the kill commands datapack of the rocket class.
 * @error           Invalid rocket class.
*/

native DataPack TFDB_GetRocketClassCmdsOnKill(int iClass);

/**
 * Sets the kill commands datapack of a rocket class.
 *
 * @param iClass    Rocket class.
 * @param hCmds     New rocket class kill commands datapack.
 * @noreturn
 * @error           Invalid rocket class.
*/

native void TFDB_SetRocketClassCmdsOnKill(int iClass, DataPack hCmds);

/**
 * Gets the explode commands datapack of a rocket class.
 *
 * @note Once finished, close the handle.
 *
 * @param iClass    Rocket class.
 * @return          Handle for the explode commands datapack of the rocket class.
 * @error           Invalid rocket class.
*/

native DataPack TFDB_GetRocketClassCmdsOnExplode(int iClass);

/**
 * Sets the explode commands datapack of a rocket class.
 *
 * @param iClass    Rocket class.
 * @param hCmds     New rocket class explode commands datapack.
 * @noreturn
 * @error           Invalid rocket class.
*/

native void TFDB_SetRocketClassCmdsOnExplode(int iClass, DataPack hCmds);

/**
 * Gets the no target commands datapack of a rocket class.
 *
 * @note Once finished, close the handle.
 *
 * @param iClass    Rocket class.
 * @return          Handle for the no target commands datapack of the rocket class.
 * @error           Invalid rocket class.
*/

native DataPack TFDB_GetRocketClassCmdsOnNoTarget(int iClass);

/**
 * Sets the no target commands datapack of a rocket class.
 *
 * @param iClass    Rocket class.
 * @param hCmds     New rocket class no target commands datapack.
 * @noreturn
 * @error           Invalid rocket class.
*/

native void TFDB_SetRocketClassCmdsOnNoTarget(int iClass, DataPack hCmds);

/**
 * Gets the bounce scale of a rocket class.
 *
 * @param iClass    Rocket class.
 * @return          Rocket class bounce scale.
 * @error           Invalid rocket class.
*/

native float TFDB_GetRocketClassBounceScale(int iClass);

/**
 * Sets the bounce scale of a rocket class.
 *
 * @param iClass    Rocket class.
 * @param fScale    New rocket class bounce scale.
 * @noreturn
 * @error           Invalid rocket class.
*/

native void TFDB_SetRocketClassBounceScale(int iClass, float fScale);

/**
 * Creates a rocket.
 *
 * @param iSpawnerEntity    Entity from where the rocket comes from.
 * @param iSpawnerClass     Spawner class from which the rocket class is chosen.
 * @param iTeam             Rocket team.
 * @param iClass            Rocket class to use if specified (-1 by default).
 * @noreturn
*/

native void TFDB_CreateRocket(int iSpawnerEntity, int iSpawnerClass, int iTeam, int iClass = -1);

/**
 * Destroys a rocket.
 *
 * @param iIndex    Rocket index.
 * @noreturn
*/

native void TFDB_DestroyRocket(int iIndex);

/**
 * Destroys all current rockets.
 *
 * @noreturn
*/

native void TFDB_DestroyRockets();

/**
 * Destroys all current rocket classes.
 *
 * @noreturn
*/

native void TFDB_DestroyRocketClasses();

/**
 * Destroys all current spawners and spawner classes.
 *
 * @noreturn
*/

native void TFDB_DestroySpawners();

/**
 * Parses a configuration file.
 *
 * @param strConfigFile    Configuration file (general.cfg by default).
 * @noreturn
*/

native void TFDB_ParseConfigurations(char[] strConfigFile = "general.cfg");

/**
 * Assigns all spawn points a spawner.
 *
 * @noreturn
*/

native void TFDB_PopulateSpawnPoints();

/**
 * Calls the homing rocket think function on a rocket index.
 *
 * @param iIndex    Rocket index.
 * @noreturn
*/

native void TFDB_HomingRocketThink(int iIndex);

/**
 * Calls the timer part of the homing rocket think function on a rocket index.
 *
 * @param iIndex    Rocket index.
 * @noreturn
*/

native void TFDB_RocketOtherThink(int iIndex);

/**
 * Calls the legacy homing rocket think function on a rocket index.
 *
 * @param iIndex    Rocket index.
 * @noreturn
*/

native void TFDB_RocketLegacyThink(int iIndex);

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
public __pl_TFDB_SetNTVOptional()
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
	MarkNativeAsOptional("TFDB_GetRocketAltDeflections");
	MarkNativeAsOptional("TFDB_SetRocketAltDeflections");
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
	MarkNativeAsOptional("TFDB_GetSavedParameters");
	MarkNativeAsOptional("TFDB_SetSavedParameters");
	MarkNativeAsOptional("TFDB_GetSavedRocketClassFlags");
	MarkNativeAsOptional("TFDB_SetSavedRocketClassFlags");
	MarkNativeAsOptional("TFDB_GetRocketClassMaxBounces");
	MarkNativeAsOptional("TFDB_SetRocketClassMaxBounces");
	MarkNativeAsOptional("TFDB_GetRocketClassSavedMaxBounces");
	MarkNativeAsOptional("TFDB_SetRocketClassSavedMaxBounces");
	MarkNativeAsOptional("TFDB_GetSpawnersName");
	MarkNativeAsOptional("TFDB_SetSpawnersName");
	MarkNativeAsOptional("TFDB_GetSpawnersMaxRockets");
	MarkNativeAsOptional("TFDB_SetSpawnersMaxRockets");
	MarkNativeAsOptional("TFDB_GetSpawnersInterval");
	MarkNativeAsOptional("TFDB_SetSpawnersInterval");
	MarkNativeAsOptional("TFDB_GetSpawnersChancesTable");
	MarkNativeAsOptional("TFDB_SetSpawnersChancesTable");
	MarkNativeAsOptional("TFDB_GetSavedChancesTable");
	MarkNativeAsOptional("TFDB_SetSavedChancesTable");
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
	MarkNativeAsOptional("TFDB_GetRocketFakeEntity");
	MarkNativeAsOptional("TFDB_SetRocketFakeEntity");
	MarkNativeAsOptional("TFDB_GetRocketSpeed");
	MarkNativeAsOptional("TFDB_SetRocketSpeed");
	MarkNativeAsOptional("TFDB_GetRocketMphSpeed");
	MarkNativeAsOptional("TFDB_SetRocketMphSpeed");
	MarkNativeAsOptional("TFDB_GetRocketDirection");
	MarkNativeAsOptional("TFDB_SetRocketDirection");
	MarkNativeAsOptional("TFDB_GetRocketLastDeflectionTime");
	MarkNativeAsOptional("TFDB_GetRocketCount");
	MarkNativeAsOptional("TFDB_GetIsRocketBouncing");
	MarkNativeAsOptional("TFDB_SetIsRocketBouncing");
	MarkNativeAsOptional("TFDB_GetIsRocketStolen");
	MarkNativeAsOptional("TFDB_GetPreventingDelay");
	MarkNativeAsOptional("TFDB_GetIsRocketDraggable");
	MarkNativeAsOptional("TFDB_SetIsRocketDraggable");
	MarkNativeAsOptional("TFDB_GetRocketBounces");
	MarkNativeAsOptional("TFDB_SetRocketBounces");
	MarkNativeAsOptional("TFDB_GetRocketClassName");
	MarkNativeAsOptional("TFDB_SetRocketClassName");
	MarkNativeAsOptional("TFDB_GetRocketClassLongName");
	MarkNativeAsOptional("TFDB_SetRocketClassLongName");
	MarkNativeAsOptional("TFDB_GetRocketClassModel");
	MarkNativeAsOptional("TFDB_SetRocketClassModel");
	MarkNativeAsOptional("TFDB_GetRocketClassTrail");
	MarkNativeAsOptional("TFDB_SetRocketClassTrail");
	MarkNativeAsOptional("TFDB_GetRocketClassSprite");
	MarkNativeAsOptional("TFDB_SetRocketClassSprite");
	MarkNativeAsOptional("TFDB_GetRocketClassSpriteColor");
	MarkNativeAsOptional("TFDB_SetRocketClassSpriteColor");
	MarkNativeAsOptional("TFDB_GetRocketClassSpriteLifetime");
	MarkNativeAsOptional("TFDB_SetRocketClassSpriteLifetime");
	MarkNativeAsOptional("TFDB_GetRocketClassSpriteStartWidth");
	MarkNativeAsOptional("TFDB_SetRocketClassSpriteStartWidth");
	MarkNativeAsOptional("TFDB_GetRocketClassSpriteEndWidth");
	MarkNativeAsOptional("TFDB_SetRocketClassSpriteEndWidth");
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
	MarkNativeAsOptional("TFDB_RocketOtherThink");
	MarkNativeAsOptional("TFDB_RocketLegacyThink");
}
#endif
