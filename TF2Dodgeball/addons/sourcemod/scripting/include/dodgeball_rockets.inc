#if defined _dodgeball_rockets_included
  #endinput
#endif
#define _dodgeball_rockets_included

/**
 * All logic directly related to creating, managing, and controlling rockets.
 */

void CreateRocket(int iSpawnerEntity, int iSpawnerClass, int iTeam, int iClass = -1)
{
	int iIndex = FindFreeRocketSlot();
	if (iIndex == -1) return;

	iClass = iClass == -1 ? GetRandomRocketClass(iSpawnerClass) : iClass;
	RocketFlags iFlags = g_iRocketClassFlags[iClass];

	int iClassRef = iClass;
	RocketFlags iFlagsRef = iFlags;
	Action aResult = Forward_OnRocketCreatedPre(iIndex, iClassRef, iFlagsRef);

	if (aResult == Plugin_Stop || aResult == Plugin_Handled)
	{
		return;
	}
	else if (aResult == Plugin_Changed)
	{
		iClass = iClassRef;
		iFlags = iFlagsRef;
	}

	int iEntity = CreateEntityByName(TestFlags(iFlags, RocketFlag_IsAnimated) ? "tf_projectile_sentryrocket" : "tf_projectile_rocket");
	if (iEntity == -1) return;

	static float fPosition[3], fAngles[3], fDirection[3];
	GetEntPropVector(iSpawnerEntity, Prop_Send, "m_vecOrigin", fPosition);
	GetEntPropVector(iSpawnerEntity, Prop_Send, "m_angRotation", fAngles);
	GetAngleVectors(fAngles, fDirection, NULL_VECTOR, NULL_VECTOR);

	SetEntProp(iEntity,    Prop_Send, "m_bCritical",    (GetURandomFloatRange(0.0, 100.0) <= g_fRocketClassCritChance[iClass]) ? 1 : 0, 1);
	SetEntProp(iEntity,    Prop_Send, "m_iTeamNum",     (TestFlags(iFlags, RocketFlag_IsNeutral)) ? 1 : iTeam, 1);
	SetEntProp(iEntity,    Prop_Send, "m_iDeflected",   0);
	TeleportEntity(iEntity, fPosition, fAngles, view_as<float>({0.0, 0.0, 0.0}));

	int iTargetTeam = (TestFlags(iFlags, RocketFlag_IsNeutral)) ? 0 : GetAnalogueTeam(iTeam);
	int iTarget     = SelectTarget(iTargetTeam);
	int iRocketOwner = SelectTarget(GetAnalogueTeam(GetClientTeam(iTarget)));
	
	SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", iRocketOwner);
	int iWeapon = GetPlayerWeaponSlot(iRocketOwner, TFWeaponSlot_Primary);
	SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", iWeapon == -1 ? iEntity : iWeapon);
	SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", iWeapon == -1 ? iEntity : iWeapon);

	float fModifier = CalculateModifier(iClass, 0);
	g_bRocketIsValid[iIndex]            = true;
	g_iRocketFlags[iIndex]              = iFlags;
	g_iRocketEntity[iIndex]             = EntIndexToEntRef(iEntity);
	g_iRocketTarget[iIndex]             = EntIndexToEntRef(iTarget);
	g_iRocketClass[iIndex]              = iClass;
	g_iRocketDeflections[iIndex]        = 0;
	g_iRocketEventDeflections[iIndex]   = 0;
	g_iRocketBounces[iIndex]            = 0;
	g_fRocketLastDeflectionTime[iIndex] = GetGameTime();
	g_fRocketLastBeepTime[iIndex]       = GetGameTime();
	g_fRocketSpeed[iIndex]              = CalculateRocketSpeed(iClass, fModifier);
	g_fRocketMphSpeed[iIndex]           = CalculateRocketSpeed(iClass, fModifier) * 0.042614;
	Internal_SetRocketState(iIndex, RocketState_None);

	CopyVectors(fDirection, g_fRocketDirection[iIndex]);
	SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, CalculateRocketDamage(iClass, fModifier), true);
	DispatchSpawn(iEntity);

	if (TestFlags(iFlags, RocketFlag_CustomModel))
	{
		SetEntityModel(iEntity, g_strRocketClassModel[iClass]);
		UpdateRocketSkin(iEntity, iTeam, TestFlags(iFlags, RocketFlag_IsNeutral));
	}

	if (TestFlags(iFlags, RocketFlag_OnSpawnCmd))
	{
		ExecuteCommands(g_hRocketClassCmdsOnSpawn[iClass], iClass, iEntity, 0, iTarget, g_iLastDeadClient, g_fRocketSpeed[iIndex], 0, g_fRocketMphSpeed[iIndex]);
	}

	EmitRocketSound(RocketSound_Spawn, iClass, iEntity, iTarget, iFlags);
	EmitRocketSound(RocketSound_Alert, iClass, iEntity, iTarget, iFlags);

	g_iRocketCount++;
	g_iRocketsFired++;
	g_fLastSpawnTime[iIndex] = GetGameTime();
	g_fNextSpawnTime = GetGameTime() + g_fSpawnersInterval[iSpawnerClass];

	SDKHook(iEntity, SDKHook_StartTouch, OnStartTouch);
	Forward_OnRocketCreated(iIndex, iEntity);
}

void DestroyRocket(int iIndex)
{
	if (!IsValidRocket(iIndex)) return;

	RemoveEdict(EntRefToEntIndex(g_iRocketEntity[iIndex]));
	g_bRocketIsValid[iIndex] = false;
	g_iRocketCount--;
}

void DestroyRockets()
{
	for (int iIndex = 0; iIndex < MAX_ROCKETS; iIndex++)
	{
		DestroyRocket(iIndex);
	}
	g_iRocketCount = 0;
}

bool IsValidRocket(int iIndex)
{
	if (!((iIndex >= 0) && g_bRocketIsValid[iIndex])) return false;
	
	if (EntRefToEntIndex(g_iRocketEntity[iIndex]) != -1) return true;

	g_bRocketIsValid[iIndex] = false;
	g_iRocketCount--;

	return false;
}

int FindNextValidRocket(int iIndex)
{
	for (int iCurrent = iIndex + 1; iCurrent < MAX_ROCKETS; iCurrent++)
	{
		if (IsValidRocket(iCurrent)) return iCurrent;
	}
	return -1;
}

int FindFreeRocketSlot()
{
	int iCurrent = 0;
	do
	{
		if (!IsValidRocket(iCurrent)) return iCurrent;
		if ((++iCurrent) == MAX_ROCKETS) iCurrent = 0;
	}
	while (iCurrent != 0);

	return -1;
}

int FindRocketByEntity(int iEntity)
{
	int iIndex = -1;
	while ((iIndex = FindNextValidRocket(iIndex)) != -1)
	{
		if (EntRefToEntIndex(g_iRocketEntity[iIndex]) == iEntity) return iIndex;
	}
	return -1;
}

void HomingRocketThink(int iIndex)
{
	int iEntity          = EntRefToEntIndex(g_iRocketEntity[iIndex]);
	int iClass           = g_iRocketClass[iIndex];
	RocketFlags iFlags   = g_iRocketFlags[iIndex];
	int iTarget          = EntRefToEntIndex(g_iRocketTarget[iIndex]);
	int iTeam            = GetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1);
	int iTargetTeam      = (TestFlags(iFlags, RocketFlag_IsNeutral)) ? 0 : GetAnalogueTeam(iTeam);
	int iDeflectionCount = g_iRocketEventDeflections[iIndex];
	float fModifier      = CalculateModifier(iClass, iDeflectionCount);
	
	if ((iDeflectionCount > g_iRocketDeflections[iIndex]) && !(g_iRocketState[iIndex] & RocketState_Dragging))
	{
		int iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
		Internal_SetRocketState(iIndex, (g_iRocketState[iIndex] | (RocketState_CanDrag | RocketState_Dragging)));
		if (iClient >= 1)
		{
			static float fViewAngles[3], fDirection[3];
			GetClientEyeAngles(iClient, fViewAngles);
			GetAngleVectors(fViewAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
			CopyVectors(fDirection, g_fRocketDirection[iIndex]);
			UpdateRocketSkin(iEntity, iTeam, TestFlags(iFlags, RocketFlag_IsNeutral));
		}
		g_fRocketLastDeflectionTime[iIndex] = GetGameTime();
	}
	else
	{
		if ((GetGameTime() - g_fRocketLastDeflectionTime[iIndex]) <= g_fRocketClassDragTimeMax[iClass] + GetTickInterval())
		{
			if ((g_fRocketClassDragTimeMin[iClass] <= (GetGameTime() - g_fRocketLastDeflectionTime[iIndex])) && (g_iRocketState[iIndex] & RocketState_CanDrag))
			{
				int iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
				if (iClient >= 1)
				{
					static float fViewAngles[3], fDirection[3];
					GetClientEyeAngles(iClient, fViewAngles);
					GetAngleVectors(fViewAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
					CopyVectors(fDirection, g_fRocketDirection[iIndex]);
				}
			}
		}
		else
		{
			if (!IsValidClient(iTarget, true))
			{
				int iOwner = iTarget;
				iTarget = SelectTarget(iTargetTeam, iIndex);

				if (!IsValidClient(iTarget, true)) return;
				g_iRocketTarget[iIndex] = EntIndexToEntRef(iTarget);
				EmitRocketSound(RocketSound_Alert, iClass, iEntity, iTarget, iFlags);

				if (TestFlags(iFlags, RocketFlag_OnNoTargetCmd))
				{
					ExecuteCommands(g_hRocketClassCmdsOnNoTarget[iClass], iClass, iEntity, iOwner, iTarget, g_iLastDeadClient, g_fRocketSpeed[iIndex], iDeflectionCount, g_fRocketMphSpeed[iIndex]);
				}

				if (g_hCvarNoTargetRedirectDamage.BoolValue)
				{
					SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 0.0, true);
				}
				Forward_OnRocketNoTarget(iIndex, iTarget, iOwner);
			}
			else if ((iDeflectionCount > g_iRocketDeflections[iIndex]))
			{
				int iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
				Internal_SetRocketState(iIndex, (g_iRocketState[iIndex] & ~(RocketState_Dragging | RocketState_Stolen)));

				if ((iClient >= 1) && !(iFlags & RocketFlag_CanBeStolen))
				{
					CheckStolenRocket(iClient, iIndex);
				}

				iTarget = SelectTarget(iTargetTeam, iIndex);
				g_iRocketTarget[iIndex]      = EntIndexToEntRef(iTarget);
				g_iRocketDeflections[iIndex] = iDeflectionCount;
				g_fRocketSpeed[iIndex]       = CalculateRocketSpeed(iClass, fModifier);
				g_fRocketMphSpeed[iIndex]    = CalculateRocketSpeed(iClass, fModifier) * 0.042614;
				SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, CalculateRocketDamage(iClass, fModifier), true);
				
				if (TestFlags(iFlags, RocketFlag_ElevateOnDeflect)) g_iRocketFlags[iIndex] |= RocketFlag_Elevating;

				if ((iFlags & RocketFlag_IsSpeedLimited) && (g_fRocketSpeed[iIndex] >= g_fRocketClassSpeedLimit[iClass]))
				{
					g_fRocketSpeed[iIndex] = g_fRocketClassSpeedLimit[iClass];
				}

				if (g_hCvarStealPreventionDamage.BoolValue && (g_iRocketState[iIndex] & RocketState_Stolen))
				{
					SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 0.0, true);
				}

				if (iFlags & RocketFlag_TeamlessHits)
				{
					SetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1, 1);
				}

				int iTargetRef = iTarget;
				Action aResult = Forward_OnRocketDeflectPre(iIndex, iEntity, iClient, iTargetRef);

				if (aResult == Plugin_Stop || aResult == Plugin_Handled)
				{
					return;
				}
				else if (aResult == Plugin_Changed)
				{
					iTarget = iTargetRef;
					g_iRocketTarget[iIndex] = EntIndexToEntRef(iTarget);
				}

				EmitRocketSound(RocketSound_Alert, iClass, iEntity, iTarget, iFlags);
				if (TestFlags(iFlags, RocketFlag_OnDeflectCmd))
				{
					ExecuteCommands(g_hRocketClassCmdsOnDeflect[iClass], iClass, iEntity, iClient, iTarget, g_iLastDeadClient, g_fRocketSpeed[iIndex], iDeflectionCount, g_fRocketMphSpeed[iIndex]);
				}
				Forward_OnRocketDeflect(iIndex, iEntity, iClient);
			}
			else
			{
				if ((GetGameTime() - g_fRocketLastDeflectionTime[iIndex]) >= g_fRocketClassControlDelay[iClass])
				{
					float fTurnRate = CalculateRocketTurnRate(iClass, fModifier) / g_fTickModifier;
					static float fDirectionToTarget[3]; CalculateDirectionToClient(iEntity, iTarget, fDirectionToTarget);

					if (g_iRocketFlags[iIndex] & RocketFlag_Elevating)
					{
						fDirectionToTarget[2] = g_fRocketDirection[iIndex][2];
					}

					if ((g_iRocketFlags[iIndex] & RocketFlag_IsTRLimited) && (fTurnRate >= g_fRocketClassTurnRateLimit[iClass] / g_fTickModifier))
					{
						fTurnRate = g_fRocketClassTurnRateLimit[iClass] / g_fTickModifier;
					}
					LerpVectors(g_fRocketDirection[iIndex], fDirectionToTarget, g_fRocketDirection[iIndex], fTurnRate);
				}
			}
		}
	}

	if (!(g_iRocketState[iIndex] & RocketState_Bouncing))
	{
		ApplyRocketParameters(iIndex);
	}
}

void RocketOtherThink(int iIndex)
{
	int iEntity          = EntRefToEntIndex(g_iRocketEntity[iIndex]);
	int iClass           = g_iRocketClass[iIndex];
	RocketFlags iFlags   = g_iRocketFlags[iIndex];
	int iTarget          = EntRefToEntIndex(g_iRocketTarget[iIndex]);
	int iDeflectionCount = g_iRocketEventDeflections[iIndex];
	
	if (!(iDeflectionCount > g_iRocketDeflections[iIndex]))
	{
		if (((GetGameTime() - g_fRocketLastDeflectionTime[iIndex]) >= g_fRocketClassControlDelay[iClass]) &&
		    (g_iRocketFlags[iIndex] & RocketFlag_Elevating))
		{
			if (g_fRocketDirection[iIndex][2] < g_fRocketClassElevationLimit[iClass])
			{
				g_fRocketDirection[iIndex][2] = FMin(g_fRocketDirection[iIndex][2] + g_fRocketClassElevationRate[iClass], g_fRocketClassElevationLimit[iClass]);
			}
			else
			{
				g_iRocketFlags[iIndex] &= ~RocketFlag_Elevating;
			}
		}

		if ((GetGameTime() - g_fRocketLastBeepTime[iIndex]) >= g_fRocketClassBeepInterval[iClass])
		{
			EmitRocketSound(RocketSound_Beep, iClass, iEntity, iTarget, iFlags);
			g_fRocketLastBeepTime[iIndex] = GetGameTime();
		}

		if (g_hCvarDelayPrevention.BoolValue)
		{
			CheckRoundDelays(iIndex);
		}
	}

	Internal_SetRocketState(iIndex, (g_iRocketState[iIndex] & ~RocketState_Bouncing));
}

void RocketLegacyThink(int iIndex)
{
	int iEntity          = EntRefToEntIndex(g_iRocketEntity[iIndex]);
	int iClass           = g_iRocketClass[iIndex];
	RocketFlags iFlags   = g_iRocketFlags[iIndex];
	int iTarget          = EntRefToEntIndex(g_iRocketTarget[iIndex]);
	int iTeam            = GetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1);
	int iTargetTeam      = (TestFlags(iFlags, RocketFlag_IsNeutral)) ? 0 : GetAnalogueTeam(iTeam);
	int iDeflectionCount = g_iRocketEventDeflections[iIndex];
	float fModifier      = CalculateModifier(iClass, iDeflectionCount);

	if (!IsValidClient(iTarget, true))
	{
		int iOwner = iTarget;
		iTarget = SelectTarget(iTargetTeam, iIndex);

		if (!IsValidClient(iTarget, true)) return;
		
		g_iRocketTarget[iIndex] = EntIndexToEntRef(iTarget);
		EmitRocketSound(RocketSound_Alert, iClass, iEntity, iTarget, iFlags);

		if (TestFlags(iFlags, RocketFlag_OnNoTargetCmd))
		{
			ExecuteCommands(g_hRocketClassCmdsOnNoTarget[iClass], iClass, iEntity, iOwner, iTarget, g_iLastDeadClient, g_fRocketSpeed[iIndex], iDeflectionCount, g_fRocketMphSpeed[iIndex]);
		}

		if (g_hCvarNoTargetRedirectDamage.BoolValue)
		{
			SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 0.0, true);
		}
		Forward_OnRocketNoTarget(iIndex, iTarget, iOwner);
	}
	else if ((iDeflectionCount > g_iRocketDeflections[iIndex]))
	{
		int iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
		Internal_SetRocketState(iIndex, (g_iRocketState[iIndex] & ~RocketState_Stolen));

		if (iClient >= 1)
		{
			static float fViewAngles[3], fDirection[3];
			GetClientEyeAngles(iClient, fViewAngles);
			GetAngleVectors(fViewAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
			CopyVectors(fDirection, g_fRocketDirection[iIndex]);
			UpdateRocketSkin(iEntity, iTeam, TestFlags(iFlags, RocketFlag_IsNeutral));

			if (!(iFlags & RocketFlag_CanBeStolen))
			{
				CheckStolenRocket(iClient, iIndex);
			}
		}

		iTarget = SelectTarget(iTargetTeam, iIndex);
		g_iRocketTarget[iIndex]             = EntIndexToEntRef(iTarget);
		g_iRocketDeflections[iIndex]        = iDeflectionCount;
		g_fRocketLastDeflectionTime[iIndex] = GetGameTime();
		g_fRocketSpeed[iIndex]              = CalculateRocketSpeed(iClass, fModifier);
		g_fRocketMphSpeed[iIndex]           = CalculateRocketSpeed(iClass, fModifier) * 0.042614;
		SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, CalculateRocketDamage(iClass, fModifier), true);

		if (TestFlags(iFlags, RocketFlag_ElevateOnDeflect)) g_iRocketFlags[iIndex] |= RocketFlag_Elevating;
		
		if ((iFlags & RocketFlag_IsSpeedLimited) && (g_fRocketSpeed[iIndex] >= g_fRocketClassSpeedLimit[iClass]))
		{
			g_fRocketSpeed[iIndex] = g_fRocketClassSpeedLimit[iClass];
		}

		if (g_hCvarStealPreventionDamage.BoolValue && (g_iRocketState[iIndex] & RocketState_Stolen))
		{
			SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, 0.0, true);
		}

		if (iFlags & RocketFlag_TeamlessHits)
		{
			SetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1, 1);
		}

		int iTargetRef = iTarget;
		Action aResult = Forward_OnRocketDeflectPre(iIndex, iEntity, iClient, iTargetRef);

		if (aResult == Plugin_Stop || aResult == Plugin_Handled)
		{
			return;
		}
		else if (aResult == Plugin_Changed)
		{
			iTarget = iTargetRef;
			g_iRocketTarget[iIndex] = EntIndexToEntRef(iTarget);
		}

		EmitRocketSound(RocketSound_Alert, iClass, iEntity, iTarget, iFlags);
		if (TestFlags(iFlags, RocketFlag_OnDeflectCmd))
		{
			ExecuteCommands(g_hRocketClassCmdsOnDeflect[iClass], iClass, iEntity, iClient, iTarget, g_iLastDeadClient, g_fRocketSpeed[iIndex], iDeflectionCount, g_fRocketMphSpeed[iIndex]);
		}
		Forward_OnRocketDeflect(iIndex, iEntity, iClient);
	}
	else
	{
		if ((GetGameTime() - g_fRocketLastDeflectionTime[iIndex]) >= g_fRocketClassControlDelay[iClass])
		{
			float fTurnRate = CalculateRocketTurnRate(iClass, fModifier);
			static float fDirectionToTarget[3];
			CalculateDirectionToClient(iEntity, iTarget, fDirectionToTarget);

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

			if ((g_iRocketFlags[iIndex] & RocketFlag_IsTRLimited) && (fTurnRate >= g_fRocketClassTurnRateLimit[iClass]))
			{
				fTurnRate = g_fRocketClassTurnRateLimit[iClass];
			}
			LerpVectors(g_fRocketDirection[iIndex], fDirectionToTarget, g_fRocketDirection[iIndex], fTurnRate);
		}

		if ((GetGameTime() - g_fRocketLastBeepTime[iIndex]) >= g_fRocketClassBeepInterval[iClass])
		{
			EmitRocketSound(RocketSound_Beep, iClass, iEntity, iTarget, iFlags);
			g_fRocketLastBeepTime[iIndex] = GetGameTime();
		}

		if (g_hCvarDelayPrevention.BoolValue)
		{
			CheckRoundDelays(iIndex);
		}
	}
	ApplyRocketParameters(iIndex);
}

float CalculateModifier(int iClass, int iDeflections)
{
	return iDeflections +
	       (g_iRocketsFired * g_fRocketClassRocketsModifier[iClass]) +
	       (g_iPlayerCount * g_fRocketClassPlayerModifier[iClass]);
}

float CalculateRocketDamage(int iClass, float fModifier)
{
	return g_fRocketClassDamage[iClass] + g_fRocketClassDamageIncrement[iClass] * fModifier;
}

float CalculateRocketSpeed(int iClass, float fModifier)
{
	return g_fRocketClassSpeed[iClass] + g_fRocketClassSpeedIncrement[iClass] * fModifier;
}

float CalculateRocketTurnRate(int iClass, float fModifier)
{
	return g_fRocketClassTurnRate[iClass] + g_fRocketClassTurnRateIncrement[iClass] * fModifier;
}

void CalculateDirectionToClient(int iEntity, int iClient, float fOut[3])
{
	static float fRocketPosition[3]; GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fRocketPosition);
	GetClientEyePosition(iClient, fOut);
	MakeVectorFromPoints(fRocketPosition, fOut, fOut);
	NormalizeVector(fOut, fOut);
}

void ApplyRocketParameters(int iIndex)
{
	int iEntity = EntRefToEntIndex(g_iRocketEntity[iIndex]);
	static float fAngles[3]; GetVectorAngles(g_fRocketDirection[iIndex], fAngles);
	static float fVelocity[3]; CopyVectors(g_fRocketDirection[iIndex], fVelocity);

	ScaleVector(fVelocity, g_fRocketSpeed[iIndex]);
	SetEntPropVector(iEntity, Prop_Data, "m_vecAbsVelocity", fVelocity);
	SetEntPropVector(iEntity, Prop_Send, "m_angRotation", fAngles);
}

void UpdateRocketSkin(int iEntity, int iTeam, bool bNeutral)
{
	if (bNeutral) SetEntProp(iEntity, Prop_Send, "m_nSkin", 2);
	else          SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam == view_as<int>(TFTeam_Blue)) ? 0 : 1);
}

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
			if (GetGameTime() - g_fRocketLastBeepTime[FindRocketByEntity(iEntity)] >= g_fRocketClassBeepInterval[iClass])
			{
				if (TestFlags(iFlags, RocketFlag_PlayBeepSound))
				{
					if (TestFlags(iFlags, RocketFlag_CustomBeepSound)) EmitSoundToAll(g_strRocketClassBeepSound[iClass], iEntity);
					else                                               EmitSoundToAll(SOUND_DEFAULT_BEEP, iEntity);
				}
				g_fRocketLastBeepTime[FindRocketByEntity(iEntity)] = GetGameTime();
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

void CheckStolenRocket(int iClient, int iIndex)
{
    if (g_hCvarStealTauntCheck.BoolValue)
    {
        int iOriginalTarget = EntRefToEntIndex(g_iRocketTarget[iIndex]);
        int iDeflectorTeam = GetClientTeam(iClient);

        // Find any teammate of the deflector who is taunting near the original target
        for (int iTaunter = 1; iTaunter <= MaxClients; iTaunter++)
        {
            // Check if it's a valid teammate (but not the deflector themselves)
            if (!IsValidClient(iTaunter, true) || GetClientTeam(iTaunter) != iDeflectorTeam || iTaunter == iClient)
            {
                continue;
            }

            // Check if this teammate is currently taunting
            if (TF2_IsPlayerInCondition(iTaunter, TFCond_Taunting))
            {
                // Condition 1: Proximity Check. Is the taunter close enough to the original target?
                float fTaunterPos[3], fOriginalTargetPos[3];
                GetClientAbsOrigin(iTaunter, fTaunterPos);
                GetClientAbsOrigin(iOriginalTarget, fOriginalTargetPos);
                if (GetVectorDistance(fTaunterPos, fOriginalTargetPos) > g_hCvarStealTauntDistance.FloatValue)
                {
                    continue; // Taunter is too far away, this taunt doesn't count.
                }

                // Condition 2: Cooldown Check. Has this player's taunt-block been used recently?
                if (GetGameTime() < g_fLastTauntBlockTime[iTaunter] + g_hCvarStealTauntCooldown.FloatValue)
                {
                    continue; // Taunter is on cooldown, this taunt doesn't count.
                }

                // Condition 3: Max Duration Check. Has this taunt been active for too long?
                if (GetGameTime() > g_fPlayerTauntStartTime[iTaunter] + g_hCvarStealTauntMaxTime.FloatValue)
                {
                    continue; // Taunt has expired, steal is allowed again.
                }

                // If all checks pass, the steal is blocked by this taunt.
                g_fLastTauntBlockTime[iTaunter] = GetGameTime(); // Set the cooldown for this player.
                return; // Exit function immediately, preventing the steal.
            }
        }
    }

    // --- Original Steal Logic ---
    // This code only runs if the taunt checks above did not block the steal.
    int iTarget = EntRefToEntIndex(g_iRocketTarget[iIndex]);

    if (!(iTarget != iClient &&
        !g_eStealInfo[iClient].stoleRocket &&
        (GetEntitiesDistance(iTarget, iClient) > g_hCvarStealDistance.FloatValue) &&
        (!(g_iRocketFlags[iIndex] & RocketFlag_StealTeamCheck) || (GetClientTeam(iTarget) == GetClientTeam(iClient))) &&
        !(g_iRocketState[iIndex] & RocketState_Delayed)))
    {
        return;
    }

    g_eStealInfo[iClient].stoleRocket = true;

    if (g_eStealInfo[iClient].rocketsStolen < g_hCvarStealPreventionNumber.IntValue)
    {
        g_eStealInfo[iClient].rocketsStolen++;
        SlapPlayer(iClient, 0, true);
        CPrintToChat(iClient, "%t", "DBSteal_Warning_Client", g_eStealInfo[iClient].rocketsStolen, g_hCvarStealPreventionNumber.IntValue);

        if (g_hCvarStealMessage.BoolValue)
        {
            CSkipNextClient(iClient);
            CPrintToChatAll("%t", "DBSteal_Announce_All", iClient, iTarget);
        }
        g_eStealInfo[iClient].stoleRocket = false;
    }
    else
    {
        ForcePlayerSuicide(iClient);
        CPrintToChat(iClient, "%t", "DBSteal_Slay_Client");

        if (g_hCvarStealMessage.BoolValue)
        {
            CSkipNextClient(iClient);
            CPrintToChatAll("%t", "DBSteal_Announce_Slay_All", iClient);
        }
    }

    Internal_SetRocketState(iIndex, (g_iRocketState[iIndex] | RocketState_Stolen));
    g_iLastStealer = iClient;

    Forward_OnRocketSteal(iIndex, iClient, iTarget, g_eStealInfo[iClient].rocketsStolen);
}

void CheckRoundDelays(int iIndex)
{
	int iEntity = EntRefToEntIndex(g_iRocketEntity[iIndex]);
	int iTarget = EntRefToEntIndex(g_iRocketTarget[iIndex]);
	float fTimeToCheck = g_iRocketDeflections[iIndex] == 0 ? g_fLastSpawnTime[iIndex] : g_fRocketLastDeflectionTime[iIndex];
	
	if (iTarget == -1 || (GetGameTime() - fTimeToCheck) < g_hCvarDelayPreventionTime.FloatValue) return;

	if (!(g_iRocketState[iIndex] & RocketState_Delayed))
	{
		if (g_hCvarDelayMessage.BoolValue)
		{
			CPrintToChatAll("%t", "DBDelay_Announce_All", iTarget);
		}
		EmitSoundToAll(SOUND_DEFAULT_SPEEDUP, iEntity, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
		Internal_SetRocketState(iIndex, (g_iRocketState[iIndex] | RocketState_Delayed));
		Forward_OnRocketDelay(iIndex, iTarget);
	}
	else
	{
		g_fRocketSpeed[iIndex] += g_hCvarDelayPreventionSpeedup.FloatValue;
	}

}
