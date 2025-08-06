#if defined _dodgeball_natives_included
  #endinput
#endif
#define _dodgeball_natives_included

/**
 * [cite_start]Implements the native functions exposed by the TF2 Dodgeball plugin. [cite: 49, 50]
 * [cite_start]These natives allow other plugins to interact with and control the gamemode. [cite: 50]
 */

// *********************************************************************************
// NATIVES - GENERAL & STATE
// *********************************************************************************

public any Native_IsValidRocket(Handle hPlugin, int iNumParams) {
	return IsValidRocket(GetNativeCell(1));
}

public any Native_FindRocketByEntity(Handle hPlugin, int iNumParams) {
	return FindRocketByEntity(GetNativeCell(1));
}

public any Native_IsDodgeballEnabled(Handle hPlugin, int iNumParams) {
	return g_bEnabled;
}

// *********************************************************************************
// NATIVES - ROCKET GETTERS/SETTERS
// *********************************************************************************

public any Native_GetRocketEntity(Handle hPlugin, int iNumParams) {
	return EntRefToEntIndex(g_iRocketEntity[GetNativeCell(1)]);
}

public any Native_SetRocketEntity(Handle hPlugin, int iNumParams) {
	g_iRocketEntity[GetNativeCell(1)] = EntIndexToEntRef(GetNativeCell(2));
	return 0;
}

public any Native_GetRocketFlags(Handle hPlugin, int iNumParams) {
	return g_iRocketFlags[GetNativeCell(1)];
}

public any Native_SetRocketFlags(Handle hPlugin, int iNumParams) {
	g_iRocketFlags[GetNativeCell(1)] = view_as<RocketFlags>(GetNativeCell(2));
	return 0;
}

public any Native_GetRocketTarget(Handle hPlugin, int iNumParams) {
	return EntRefToEntIndex(g_iRocketTarget[GetNativeCell(1)]);
}

public any Native_SetRocketTarget(Handle hPlugin, int iNumParams) {
	g_iRocketTarget[GetNativeCell(1)] = EntIndexToEntRef(GetNativeCell(2));
	return 0;
}

public any Native_GetRocketEventDeflections(Handle hPlugin, int iNumParams) {
	return g_iRocketEventDeflections[GetNativeCell(1)];
}

public any Native_SetRocketEventDeflections(Handle hPlugin, int iNumParams) {
	g_iRocketEventDeflections[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketDeflections(Handle hPlugin, int iNumParams) {
	return g_iRocketDeflections[GetNativeCell(1)];
}

public any Native_SetRocketDeflections(Handle hPlugin, int iNumParams) {
	g_iRocketDeflections[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketClass(Handle hPlugin, int iNumParams) {
	return g_iRocketClass[GetNativeCell(1)];
}

public any Native_SetRocketClass(Handle hPlugin, int iNumParams) {
	g_iRocketClass[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketSpeed(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketSpeed[GetNativeCell(1)]);
}

public any Native_SetRocketSpeed(Handle hPlugin, int iNumParams) {
	g_fRocketSpeed[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketMphSpeed(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketMphSpeed[GetNativeCell(1)]);
}

public any Native_SetRocketMphSpeed(Handle hPlugin, int iNumParams) {
	g_fRocketMphSpeed[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketDirection(Handle hPlugin, int iNumParams) {
	SetNativeArray(2, g_fRocketDirection[GetNativeCell(1)], 3);
	return 0;
}

public any Native_SetRocketDirection(Handle hPlugin, int iNumParams) {
	float fDirection[3];
	GetNativeArray(2, fDirection, sizeof(fDirection));
	CopyVectors(fDirection, g_fRocketDirection[GetNativeCell(1)]);
	return 0;
}

public any Native_GetRocketLastDeflectionTime(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketLastDeflectionTime[GetNativeCell(1)]);
}

public any Native_SetRocketLastDeflectionTime(Handle hPlugin, int iNumParams) {
	g_fRocketLastDeflectionTime[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketLastBeepTime(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketLastBeepTime[GetNativeCell(1)]);
}

public any Native_SetRocketLastBeepTime(Handle hPlugin, int iNumParams) {
	g_fRocketLastBeepTime[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketCount(Handle hPlugin, int iNumParams) {
	return g_iRocketCount;
}

public any Native_GetLastSpawnTime(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fLastSpawnTime[GetNativeCell(1)]);
}

public any Native_GetRocketBounces(Handle hPlugin, int iNumParams) {
	return g_iRocketBounces[GetNativeCell(1)];
}

public any Native_SetRocketBounces(Handle hPlugin, int iNumParams) {
	g_iRocketBounces[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketState(Handle hPlugin, int iNumParams) {
	return g_iRocketState[GetNativeCell(1)];
}

public any Native_SetRocketState(Handle hPlugin, int iNumParams) {
	Internal_SetRocketState(GetNativeCell(1), view_as<RocketState>(GetNativeCell(2)));
	return 0;
}

// *********************************************************************************
// NATIVES - ROCKET CLASS GETTERS/SETTERS
// *********************************************************************************

public any Native_GetRocketClassCount(Handle hPlugin, int iNumParams) {
	return g_iRocketClassCount;
}

public any Native_SetRocketClassCount(Handle hPlugin, int iNumParams) {
	g_iRocketClassCount = GetNativeCell(1);
	return 0;
}

public any Native_GetRocketClassBehaviour(Handle hPlugin, int iNumParams) {
	return g_iRocketClassBehaviour[GetNativeCell(1)];
}

public any Native_SetRocketClassBehaviour(Handle hPlugin, int iNumParams) {
	g_iRocketClassBehaviour[GetNativeCell(1)] = view_as<BehaviourTypes>(GetNativeCell(2));
	return 0;
}

public any Native_GetRocketClassFlags(Handle hPlugin, int iNumParams) {
	return g_iRocketClassFlags[GetNativeCell(1)];
}

public any Native_SetRocketClassFlags(Handle hPlugin, int iNumParams) {
	g_iRocketClassFlags[GetNativeCell(1)] = view_as<RocketFlags>(GetNativeCell(2));
	return 0;
}

public any Native_GetRocketClassDamage(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketClassDamage[GetNativeCell(1)]);
}

public any Native_SetRocketClassDamage(Handle hPlugin, int iNumParams) {
	g_fRocketClassDamage[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketClassDamageIncrement(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketClassDamageIncrement[GetNativeCell(1)]);
}

public any Native_SetRocketClassDamageIncrement(Handle hPlugin, int iNumParams) {
	g_fRocketClassDamageIncrement[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketClassSpeed(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketClassSpeed[GetNativeCell(1)]);
}

public any Native_SetRocketClassSpeed(Handle hPlugin, int iNumParams) {
	g_fRocketClassSpeed[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketClassSpeedIncrement(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketClassSpeedIncrement[GetNativeCell(1)]);
}

public any Native_SetRocketClassSpeedIncrement(Handle hPlugin, int iNumParams) {
	g_fRocketClassSpeedIncrement[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketClassSpeedLimit(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketClassSpeedLimit[GetNativeCell(1)]);
}

public any Native_SetRocketClassSpeedLimit(Handle hPlugin, int iNumParams) {
	g_fRocketClassSpeedLimit[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketClassTurnRate(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketClassTurnRate[GetNativeCell(1)]);
}

public any Native_SetRocketClassTurnRate(Handle hPlugin, int iNumParams) {
	g_fRocketClassTurnRate[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketClassTurnRateIncrement(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketClassTurnRateIncrement[GetNativeCell(1)]);
}

public any Native_SetRocketClassTurnRateIncrement(Handle hPlugin, int iNumParams) {
	g_fRocketClassTurnRateIncrement[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketClassTurnRateLimit(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketClassTurnRateLimit[GetNativeCell(1)]);
}

public any Native_SetRocketClassTurnRateLimit(Handle hPlugin, int iNumParams) {
	g_fRocketClassTurnRateLimit[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketClassElevationRate(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketClassElevationRate[GetNativeCell(1)]);
}

public any Native_SetRocketClassElevationRate(Handle hPlugin, int iNumParams) {
	g_fRocketClassElevationRate[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketClassElevationLimit(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketClassElevationLimit[GetNativeCell(1)]);
}

public any Native_SetRocketClassElevationLimit(Handle hPlugin, int iNumParams) {
	g_fRocketClassElevationLimit[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketClassRocketsModifier(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketClassRocketsModifier[GetNativeCell(1)]);
}

public any Native_SetRocketClassRocketsModifier(Handle hPlugin, int iNumParams) {
	g_fRocketClassRocketsModifier[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketClassPlayerModifier(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketClassPlayerModifier[GetNativeCell(1)]);
}

public any Native_SetRocketClassPlayerModifier(Handle hPlugin, int iNumParams) {
	g_fRocketClassPlayerModifier[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketClassControlDelay(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketClassControlDelay[GetNativeCell(1)]);
}

public any Native_SetRocketClassControlDelay(Handle hPlugin, int iNumParams) {
	g_fRocketClassControlDelay[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketClassDragTimeMin(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketClassDragTimeMin[GetNativeCell(1)]);
}

public any Native_SetRocketClassDragTimeMin(Handle hPlugin, int iNumParams) {
	g_fRocketClassDragTimeMin[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketClassDragTimeMax(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketClassDragTimeMax[GetNativeCell(1)]);
}

public any Native_SetRocketClassDragTimeMax(Handle hPlugin, int iNumParams) {
	g_fRocketClassDragTimeMax[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketClassMaxBounces(Handle hPlugin, int iNumParams) {
	return g_iRocketClassMaxBounces[GetNativeCell(1)];
}

public any Native_SetRocketClassMaxBounces(Handle hPlugin, int iNumParams) {
	g_iRocketClassMaxBounces[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketClassName(Handle hPlugin, int iNumParams) {
	SetNativeString(2, g_strRocketClassName[GetNativeCell(1)], GetNativeCell(3));
	return 0;
}

public any Native_SetRocketClassName(Handle hPlugin, int iNumParams) {
	int iClass = GetNativeCell(1);
	int iMaxLen;
	GetNativeStringLength(2, iMaxLen);
	char[] strBuffer = new char[iMaxLen + 1];
	GetNativeString(2, strBuffer, iMaxLen + 1);
	strcopy(g_strRocketClassName[iClass], sizeof(g_strRocketClassName[]), strBuffer);
	return 0;
}

public any Native_GetRocketClassLongName(Handle hPlugin, int iNumParams) {
	SetNativeString(2, g_strRocketClassLongName[GetNativeCell(1)], GetNativeCell(3));
	return 0;
}

public any Native_SetRocketClassLongName(Handle hPlugin, int iNumParams) {
	int iClass = GetNativeCell(1);
	int iMaxLen;
	GetNativeStringLength(2, iMaxLen);
	char[] strBuffer = new char[iMaxLen + 1];
	GetNativeString(2, strBuffer, iMaxLen + 1);
	strcopy(g_strRocketClassLongName[iClass], sizeof(g_strRocketClassLongName[]), strBuffer);
	return 0;
}

public any Native_GetRocketClassModel(Handle hPlugin, int iNumParams) {
	SetNativeString(2, g_strRocketClassModel[GetNativeCell(1)], GetNativeCell(3));
	return 0;
}

public any Native_SetRocketClassModel(Handle hPlugin, int iNumParams) {
	int iClass = GetNativeCell(1);
	int iMaxLen;
	GetNativeStringLength(2, iMaxLen);
	char[] strBuffer = new char[iMaxLen + 1];
	GetNativeString(2, strBuffer, iMaxLen + 1);
	strcopy(g_strRocketClassModel[iClass], sizeof(g_strRocketClassModel[]), strBuffer);
	return 0;
}

public any Native_GetRocketClassBeepInterval(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketClassBeepInterval[GetNativeCell(1)]);
}

public any Native_SetRocketClassBeepInterval(Handle hPlugin, int iNumParams) {
	g_fRocketClassBeepInterval[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketClassSpawnSound(Handle hPlugin, int iNumParams) {
	SetNativeString(2, g_strRocketClassSpawnSound[GetNativeCell(1)], GetNativeCell(3));
	return 0;
}

public any Native_SetRocketClassSpawnSound(Handle hPlugin, int iNumParams) {
	int iClass = GetNativeCell(1);
	int iMaxLen;
	GetNativeStringLength(2, iMaxLen);
	char[] strBuffer = new char[iMaxLen + 1];
	GetNativeString(2, strBuffer, iMaxLen + 1);
	strcopy(g_strRocketClassSpawnSound[iClass], sizeof(g_strRocketClassSpawnSound[]), strBuffer);
	return 0;
}

public any Native_GetRocketClassBeepSound(Handle hPlugin, int iNumParams) {
	SetNativeString(2, g_strRocketClassBeepSound[GetNativeCell(1)], GetNativeCell(3));
	return 0;
}

public any Native_SetRocketClassBeepSound(Handle hPlugin, int iNumParams) {
	int iClass = GetNativeCell(1);
	int iMaxLen;
	GetNativeStringLength(2, iMaxLen);
	char[] strBuffer = new char[iMaxLen + 1];
	GetNativeString(2, strBuffer, iMaxLen + 1);
	strcopy(g_strRocketClassBeepSound[iClass], sizeof(g_strRocketClassBeepSound[]), strBuffer);
	return 0;
}

public any Native_GetRocketClassAlertSound(Handle hPlugin, int iNumParams) {
	SetNativeString(2, g_strRocketClassAlertSound[GetNativeCell(1)], GetNativeCell(3));
	return 0;
}

public any Native_SetRocketClassAlertSound(Handle hPlugin, int iNumParams) {
	int iClass = GetNativeCell(1);
	int iMaxLen;
	GetNativeStringLength(2, iMaxLen);
	char[] strBuffer = new char[iMaxLen + 1];
	GetNativeString(2, strBuffer, iMaxLen + 1);
	strcopy(g_strRocketClassAlertSound[iClass], sizeof(g_strRocketClassAlertSound[]), strBuffer);
	return 0;
}

public any Native_GetRocketClassCritChance(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketClassCritChance[GetNativeCell(1)]);
}

public any Native_SetRocketClassCritChance(Handle hPlugin, int iNumParams) {
	g_fRocketClassCritChance[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketClassTargetWeight(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketClassTargetWeight[GetNativeCell(1)]);
}

public any Native_SetRocketClassTargetWeight(Handle hPlugin, int iNumParams) {
	g_fRocketClassTargetWeight[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetRocketClassBounceScale(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fRocketClassBounceScale[GetNativeCell(1)]);
}

public any Native_SetRocketClassBounceScale(Handle hPlugin, int iNumParams) {
	g_fRocketClassBounceScale[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

// *********************************************************************************
// NATIVES - SPAWNER GETTERS/SETTERS
// *********************************************************************************

public any Native_GetSpawnersName(Handle hPlugin, int iNumParams) {
	SetNativeString(2, g_strSpawnersName[GetNativeCell(1)], GetNativeCell(3));
	return 0;
}

public any Native_SetSpawnersName(Handle hPlugin, int iNumParams) {
	int iSpawnerClass = GetNativeCell(1);
	int iMaxLen;
	GetNativeStringLength(2, iMaxLen);
	char[] strBuffer = new char[iMaxLen + 1];
	GetNativeString(2, strBuffer, iMaxLen + 1);
	strcopy(g_strSpawnersName[iSpawnerClass], sizeof(g_strSpawnersName[]), strBuffer);
	return 0;
}

public any Native_GetSpawnersMaxRockets(Handle hPlugin, int iNumParams) {
	return g_iSpawnersMaxRockets[GetNativeCell(1)];
}

public any Native_SetSpawnersMaxRockets(Handle hPlugin, int iNumParams) {
	g_iSpawnersMaxRockets[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetSpawnersInterval(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fSpawnersInterval[GetNativeCell(1)]);
}

public any Native_SetSpawnersInterval(Handle hPlugin, int iNumParams) {
	g_fSpawnersInterval[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetSpawnersChancesTable(Handle hPlugin, int iNumParams) {
	return CloneHandle(g_hSpawnersChancesTable[GetNativeCell(1)], hPlugin);
}

public any Native_SetSpawnersChancesTable(Handle hPlugin, int iNumParams) {
	int iSpawnerClass = GetNativeCell(1);
	ArrayList hTable = view_as<ArrayList>(GetNativeCell(2));
	ArrayList hClonedTable = view_as<ArrayList>(CloneHandle(hTable, GetMyHandle()));
	delete g_hSpawnersChancesTable[iSpawnerClass];
	g_hSpawnersChancesTable[iSpawnerClass] = hClonedTable;
	return 0;
}

public any Native_GetSpawnersCount(Handle hPlugin, int iNumParams) {
	return g_iSpawnersCount;
}

public any Native_SetSpawnersCount(Handle hPlugin, int iNumParams) {
	g_iSpawnersCount = GetNativeCell(1);
	return 0;
}

// *********************************************************************************
// NATIVES - SPAWN POINT GETTERS/SETTERS
// *********************************************************************************

public any Native_GetCurrentRedSpawn(Handle hPlugin, int iNumParams) {
	return g_iCurrentRedSpawn;
}

public any Native_SetCurrentRedSpawn(Handle hPlugin, int iNumParams) {
	g_iCurrentRedSpawn = GetNativeCell(1);
	return 0;
}

public any Native_GetSpawnPointsRedCount(Handle hPlugin, int iNumParams) {
	return g_iSpawnPointsRedCount;
}

public any Native_SetSpawnPointsRedCount(Handle hPlugin, int iNumParams) {
	g_iSpawnPointsRedCount = GetNativeCell(1);
	return 0;
}

public any Native_GetSpawnPointsRedClass(Handle hPlugin, int iNumParams) {
	return g_iSpawnPointsRedClass[GetNativeCell(1)];
}

public any Native_SetSpawnPointsRedClass(Handle hPlugin, int iNumParams) {
	g_iSpawnPointsRedClass[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetSpawnPointsRedEntity(Handle hPlugin, int iNumParams) {
	return g_iSpawnPointsRedEntity[GetNativeCell(1)];
}

public any Native_SetSpawnPointsRedEntity(Handle hPlugin, int iNumParams) {
	g_iSpawnPointsRedEntity[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetCurrentBluSpawn(Handle hPlugin, int iNumParams) {
	return g_iCurrentBluSpawn;
}

public any Native_SetCurrentBluSpawn(Handle hPlugin, int iNumParams) {
	g_iCurrentBluSpawn = GetNativeCell(1);
	return 0;
}

public any Native_GetSpawnPointsBluCount(Handle hPlugin, int iNumParams) {
	return g_iSpawnPointsBluCount;
}

public any Native_SetSpawnPointsBluCount(Handle hPlugin, int iNumParams) {
	g_iSpawnPointsBluCount = GetNativeCell(1);
	return 0;
}

public any Native_GetSpawnPointsBluClass(Handle hPlugin, int iNumParams) {
	return g_iSpawnPointsBluClass[GetNativeCell(1)];
}

public any Native_SetSpawnPointsBluClass(Handle hPlugin, int iNumParams) {
	g_iSpawnPointsBluClass[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetSpawnPointsBluEntity(Handle hPlugin, int iNumParams) {
	return g_iSpawnPointsBluEntity[GetNativeCell(1)];
}

public any Native_SetSpawnPointsBluEntity(Handle hPlugin, int iNumParams) {
	g_iSpawnPointsBluEntity[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

// *********************************************************************************
// NATIVES - GAMEPLAY GETTERS/SETTERS
// *********************************************************************************

public any Native_GetRoundStarted(Handle hPlugin, int iNumParams) {
	return g_bRoundStarted;
}

public any Native_GetRoundCount(Handle hPlugin, int iNumParams) {
	return g_iRoundCount;
}

public any Native_GetRocketsFired(Handle hPlugin, int iNumParams) {
	return g_iRocketsFired;
}

public any Native_GetNextSpawnTime(Handle hPlugin, int iNumParams) {
	return view_as<any>(g_fNextSpawnTime);
}

public any Native_SetNextSpawnTime(Handle hPlugin, int iNumParams) {
	g_fNextSpawnTime = GetNativeCell(1);
	return 0;
}

public any Native_GetLastDeadTeam(Handle hPlugin, int iNumParams) {
	return g_iLastDeadTeam;
}

public any Native_GetLastDeadClient(Handle hPlugin, int iNumParams) {
	return g_iLastDeadClient;
}

public any Native_GetLastStealer(Handle hPlugin, int iNumParams) {
	return g_iLastStealer;
}

public any Native_GetStealInfo(Handle hPlugin, int iNumParams) {
	int iClient = GetNativeCell(1);
	if (iClient < 1 || iClient > MaxClients) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", iClient);
	}
	DataPack hPack = new DataPack();
	hPack.WriteCell(g_eStealInfo[iClient].stoleRocket ? 1 : 0);
	hPack.WriteCell(g_eStealInfo[iClient].rocketsStolen);
	return hPack;
}

public any Native_SetStealInfo(Handle hPlugin, int iNumParams) {
	int iClient = GetNativeCell(1);
	if (iClient < 1 || iClient > MaxClients) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", iClient);
	}
	DataPack hPack = view_as<DataPack>(GetNativeCell(2));
	if (hPack == null) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid DataPack handle provided");
	}
	hPack.Reset(false);
	g_eStealInfo[iClient].stoleRocket = (hPack.ReadCell() != 0);
	g_eStealInfo[iClient].rocketsStolen = hPack.ReadCell();
	return 0;
}

// *********************************************************************************
// NATIVES - DATAPACK-BASED GETTERS/SETTERS
// *********************************************************************************

public any Native_GetRocketClassCmdsOnSpawn(Handle hPlugin, int iNumParams) {
	return CloneHandle(g_hRocketClassCmdsOnSpawn[GetNativeCell(1)], hPlugin);
}

public any Native_SetRocketClassCmdsOnSpawn(Handle hPlugin, int iNumParams) {
	int iClass = GetNativeCell(1);
	DataPack hCmds = view_as<DataPack>(GetNativeCell(2));
	DataPack hClonedPack = view_as<DataPack>(CloneHandle(hCmds, GetMyHandle()));
	delete g_hRocketClassCmdsOnSpawn[iClass];
	g_hRocketClassCmdsOnSpawn[iClass] = hClonedPack;
	return 0;
}

public any Native_GetRocketClassCmdsOnDeflect(Handle hPlugin, int iNumParams) {
	return CloneHandle(g_hRocketClassCmdsOnDeflect[GetNativeCell(1)], hPlugin);
}

public any Native_SetRocketClassCmdsOnDeflect(Handle hPlugin, int iNumParams) {
	int iClass = GetNativeCell(1);
	DataPack hCmds = view_as<DataPack>(GetNativeCell(2));
	DataPack hClonedPack = view_as<DataPack>(CloneHandle(hCmds, GetMyHandle()));
	delete g_hRocketClassCmdsOnDeflect[iClass];
	g_hRocketClassCmdsOnDeflect[iClass] = hClonedPack;
	return 0;
}

public any Native_GetRocketClassCmdsOnKill(Handle hPlugin, int iNumParams) {
	return CloneHandle(g_hRocketClassCmdsOnKill[GetNativeCell(1)], hPlugin);
}

public any Native_SetRocketClassCmdsOnKill(Handle hPlugin, int iNumParams) {
	int iClass = GetNativeCell(1);
	DataPack hCmds = view_as<DataPack>(GetNativeCell(2));
	DataPack hClonedPack = view_as<DataPack>(CloneHandle(hCmds, GetMyHandle()));
	delete g_hRocketClassCmdsOnKill[iClass];
	g_hRocketClassCmdsOnKill[iClass] = hClonedPack;
	return 0;
}

public any Native_GetRocketClassCmdsOnExplode(Handle hPlugin, int iNumParams) {
	return CloneHandle(g_hRocketClassCmdsOnExplode[GetNativeCell(1)], hPlugin);
}

public any Native_SetRocketClassCmdsOnExplode(Handle hPlugin, int iNumParams) {
	int iClass = GetNativeCell(1);
	DataPack hCmds = view_as<DataPack>(GetNativeCell(2));
	DataPack hClonedPack = view_as<DataPack>(CloneHandle(hCmds, GetMyHandle()));
	delete g_hRocketClassCmdsOnExplode[iClass];
	g_hRocketClassCmdsOnExplode[iClass] = hClonedPack;
	return 0;
}

public any Native_GetRocketClassCmdsOnNoTarget(Handle hPlugin, int iNumParams) {
	return CloneHandle(g_hRocketClassCmdsOnNoTarget[GetNativeCell(1)], hPlugin);
}

public any Native_SetRocketClassCmdsOnNoTarget(Handle hPlugin, int iNumParams) {
	int iClass = GetNativeCell(1);
	DataPack hCmds = view_as<DataPack>(GetNativeCell(2));
	DataPack hClonedPack = view_as<DataPack>(CloneHandle(hCmds, GetMyHandle()));
	delete g_hRocketClassCmdsOnNoTarget[iClass];
	g_hRocketClassCmdsOnNoTarget[iClass] = hClonedPack;
	return 0;
}

// *********************************************************************************
// NATIVES - ACTION FUNCTIONS
// *********************************************************************************

public any Native_CreateRocket(Handle hPlugin, int iNumParams) {
	CreateRocket(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4));
	return 0;
}

public any Native_DestroyRocket(Handle hPlugin, int iNumParams) {
	DestroyRocket(GetNativeCell(1));
	return 0;
}

public any Native_DestroyRockets(Handle hPlugin, int iNumParams) {
	DestroyRockets();
	return 0;
}

public any Native_DestroyRocketClasses(Handle hPlugin, int iNumParams) {
	DestroyRocketClasses();
	return 0;
}

public any Native_DestroySpawners(Handle hPlugin, int iNumParams) {
	DestroySpawners();
	return 0;
}

public any Native_ParseConfigurations(Handle hPlugin, int iNumParams) {
	int iMaxLen;
	GetNativeStringLength(1, iMaxLen);
	char[] strBuffer = new char[iMaxLen + 1];
	GetNativeString(1, strBuffer, iMaxLen + 1);
	ParseConfigurations(strBuffer);
	return 0;
}

public any Native_PopulateSpawnPoints(Handle hPlugin, int iNumParams) {
	PopulateSpawnPoints();
	return 0;
}

public any Native_HomingRocketThink(Handle hPlugin, int iNumParams) {
	HomingRocketThink(GetNativeCell(1));
	return 0;
}

public any Native_RocketLegacyThink(Handle hPlugin, int iNumParams) {
	RocketLegacyThink(GetNativeCell(1));
	return 0;
}