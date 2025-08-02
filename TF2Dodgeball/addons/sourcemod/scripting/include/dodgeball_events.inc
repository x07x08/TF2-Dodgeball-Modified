#if defined _dodgeball_events_included
  #endinput
#endif
#define _dodgeball_events_included

/**
 * Handles all game events hooked by the plugin.
 */

public void OnRoundStart(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	if (g_bMusic[Music_RoundStart])
	{
		EmitSoundToAll(g_strMusic[Music_RoundStart]);
	}

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		g_eStealInfo[iClient].stoleRocket = false;
		g_eStealInfo[iClient].rocketsStolen = 0;
	}
}

public void OnSetupFinished(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	if (!BothTeamsPlaying()) return;

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

public void OnRoundEnd(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	if (g_hLogicTimer != null)
	{
		KillTimer(g_hLogicTimer);
		g_hLogicTimer = null;
	}

	if (g_bMusicEnabled)
	{
		if (g_bUseWebPlayer)
		{
			for (int iClient = 1; iClient <= MaxClients; iClient++)
			{
				if (!IsValidClientEx(iClient)) continue;
				ShowHiddenMOTDPanel(iClient, "MusicPlayerStop", "http://0.0.0.0/");
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

public void OnPlayerSpawn(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (!IsValidClient(iClient)) return;

	TFClassType iClass = TF2_GetPlayerClass(iClient);
	if ((iClass == TFClass_Pyro || iClass == TFClass_Unknown)) return;

	TF2_SetPlayerClass(iClient, TFClass_Pyro, false, true);
	TF2_RespawnPlayer(iClient);
}

public void OnPlayerDeath(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	if (!g_bRoundStarted) return;

	SetRandomSeed(view_as<int>(GetGameTime()));

	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));

	if (!IsValidClient(iVictim)) return;

	g_eStealInfo[iVictim].stoleRocket = false;
	g_eStealInfo[iVictim].rocketsStolen = 0;

	g_iLastDeadClient = iVictim;
	g_iLastDeadTeam = GetClientTeam(iVictim);
	
	int iInflictor = hEvent.GetInt("inflictor_entindex");
	int iIndex = FindRocketByEntity(iInflictor);

	if (iIndex == -1) return;

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
	{
		ExecuteCommands(g_hRocketClassCmdsOnKill[iClass], iClass, iInflictor, iAttacker, iTarget, g_iLastDeadClient, fSpeed, iDeflections, fMphSpeed);
	}
}

public void OnPlayerInventory(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));

	if (!IsValidClient(iClient)) return;
	for (int iSlot = 1; iSlot < 5; iSlot++)
	{
		int iEntity = GetPlayerWeaponSlot(iClient, iSlot);
		if (iEntity != -1) RemoveEdict(iEntity);
	}
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon)
{
	if (g_bEnabled) iButtons &= ~IN_ATTACK;
	return Plugin_Continue;
}

public Action OnBroadcastAudio(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	if (!g_bMusicEnabled) return Plugin_Continue;

	char strSound[PLATFORM_MAX_PATH];
	hEvent.GetString("sound", strSound, sizeof(strSound));
	int iTeam = hEvent.GetInt("team");

	if (StrEqual(strSound, "Announcer.AM_RoundStartRandom"))
	{
		if (!g_bUseWebPlayer)
		{
			if (!g_bMusic[Music_Gameplay]) return Plugin_Continue;
			EmitSoundToAll(g_strMusic[Music_Gameplay], SOUND_FROM_PLAYER, SNDCHAN_MUSIC);
			return Plugin_Handled;
		}
		else
		{
			for (int iClient = 1; iClient <= MaxClients; iClient++)
			{
				if (!IsValidClientEx(iClient)) continue;
				ShowHiddenMOTDPanel(iClient, "MusicPlayerStart", g_strWebPlayerUrl);
			}
			return Plugin_Handled;
		}
	}
	else if (StrEqual(strSound, "Game.YourTeamWon"))
	{
		if (!g_bMusic[Music_RoundWin]) return Plugin_Continue;

		for (int iClient = 1; iClient <= MaxClients; iClient++)
		{
			if (!(IsValidClientEx(iClient) && (iTeam == GetClientTeam(iClient)))) continue;
			EmitSoundToClient(iClient, g_strMusic[Music_RoundWin]);
		}
		return Plugin_Handled;
	}
	else if (StrEqual(strSound, "Game.YourTeamLost"))
	{
		if (!g_bMusic[Music_RoundLose]) return Plugin_Continue;
		for (int iClient = 1; iClient <= MaxClients; iClient++)
		{
			if (!(IsValidClientEx(iClient) && (iTeam == GetClientTeam(iClient)))) continue;
			EmitSoundToClient(iClient, g_strMusic[Music_RoundLose]);
		}
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public void OnObjectDeflected(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iEntity = hEvent.GetInt("object_entindex");
	int iIndex  = FindRocketByEntity(iEntity);
	if (iIndex == -1) return;

	g_iRocketEventDeflections[iIndex]++;

	int iLauncher = GetEntPropEnt(iEntity, Prop_Send, "m_hLauncher");
	if (iLauncher != -1)
	{
		SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", iLauncher);
	}

	if (g_iRocketState[iIndex] & RocketState_Delayed)
	{
		Internal_SetRocketState(iIndex, (g_iRocketState[iIndex] & ~RocketState_Delayed));
		g_fRocketSpeed[iIndex] = CalculateRocketSpeed(g_iRocketClass[iIndex], CalculateModifier(g_iRocketClass[iIndex], g_iRocketDeflections[iIndex]));
	}

	if (g_iRocketFlags[iIndex] & RocketFlag_ResetBounces)
	{
		g_iRocketBounces[iIndex] = 0;
	}

	if (g_iRocketFlags[iIndex] & RocketFlag_IsNeutral)
	{
		SetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1, 1);
	}
}

public void OnGameFrame()
{
	if (!g_bEnabled || !g_bRoundStarted) return;

	int iIndex = -1;
	while ((iIndex = FindNextValidRocket(iIndex)) != -1)
	{
		switch (g_iRocketClassBehaviour[g_iRocketClass[iIndex]])
		{
			case Behaviour_Homing:
			{
				HomingRocketThink(iIndex);
				break;
			}
			case Behaviour_LegacyHoming:
			{
				RocketLegacyThink(iIndex);
				break;
			}
		}
	}
}

public void OnClientDisconnect(int iClient)
{
	g_eStealInfo[iClient].stoleRocket = false;
	g_eStealInfo[iClient].rocketsStolen = 0;

	if (iClient == g_iLastDeadClient)
	{
		g_iLastDeadClient = 0;
	}

	if (iClient == g_iLastStealer)
	{
		g_iLastStealer = 0;
	}
}

public Action OnStartTouch(int iEntity, int iOther)
{
	int iIndex = FindRocketByEntity(iEntity);

	if (iIndex == -1) return Plugin_Continue;
	
	if (iOther > 0 && iOther <= MaxClients)
	{
		if (g_iRocketDeflections[iIndex] == 0)
		{
			SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", 0);
			SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", -1);
			SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", -1);
		}
		return Plugin_Continue;
	}

	int iClass = g_iRocketClass[iIndex];
	if (g_iRocketBounces[iIndex] >= g_iRocketClassMaxBounces[iClass])
	{
		if (g_iRocketDeflections[iIndex] == 0)
		{
			SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", 0);
			SetEntPropEnt(iEntity, Prop_Send, "m_hOriginalLauncher", -1);
			SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", -1);
		}
		return Plugin_Continue;
	}

	SDKHook(iEntity, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}

public Action OnTouch(int iEntity, int iOther)
{
	int iIndex = FindRocketByEntity(iEntity);

	if (iIndex == -1)
	{
		SDKUnhook(iEntity, SDKHook_Touch, OnTouch);
		return Plugin_Continue;
	}

	int iClass = g_iRocketClass[iIndex];

	static float vOrigin[3];
	GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", vOrigin);

	static float vAngles[3];
	GetEntPropVector(iEntity, Prop_Data, "m_angRotation", vAngles);
	
	static float vVelocity[3];
	GetEntPropVector(iEntity, Prop_Data, "m_vecAbsVelocity", vVelocity);

	Handle hTrace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TEF_ExcludeEntity, iEntity);

	if (!TR_DidHit(hTrace))
	{
		delete hTrace;
		return Plugin_Continue;
	}

	static float vNormal[3];
	TR_GetPlaneNormal(hTrace, vNormal);
	delete hTrace;
	
	float dotProduct = GetVectorDotProduct(vNormal, vVelocity);
	ScaleVector(vNormal, dotProduct);
	ScaleVector(vNormal, 2.0);

	static float vBounceVec[3];
	SubtractVectors(vVelocity, vNormal, vBounceVec);
	ScaleVector(vBounceVec, g_fRocketClassBounceScale[iClass]);

	static float vNewAngles[3];
	GetVectorAngles(vBounceVec, vNewAngles);

	static float vNewAnglesRef[3]; CopyVectors(vNewAngles, vNewAnglesRef);
	static float vBounceVecRef[3]; CopyVectors(vBounceVec, vBounceVecRef);

	Action aResult = Forward_OnRocketBouncePre(iIndex, iEntity, vNewAnglesRef, vBounceVecRef);
	if (aResult == Plugin_Stop || aResult == Plugin_Handled)
	{
		SDKUnhook(iEntity, SDKHook_Touch, OnTouch);
		return Plugin_Continue;
	}
	else if (aResult == Plugin_Changed)
	{
		CopyVectors(vNewAnglesRef, vNewAngles);
		CopyVectors(vBounceVecRef, vBounceVec);
	}

	TeleportEntity(iEntity, NULL_VECTOR, vNewAngles, vBounceVec);
	g_iRocketBounces[iIndex]++;

	if (g_iRocketFlags[iIndex] & RocketFlag_NoBounceDrags)
	{
		Internal_SetRocketState(iIndex, (g_iRocketState[iIndex] & ~RocketState_CanDrag));
	}

	if ((g_iRocketState[iIndex] & RocketState_Delayed) || (g_iRocketFlags[iIndex] & RocketFlag_KeepDirection))
	{
		Internal_SetRocketState(iIndex, (g_iRocketState[iIndex] | RocketState_Bouncing));
	}
	else
	{
		static float fDirection[3];
		GetAngleVectors(vNewAngles,fDirection,NULL_VECTOR,NULL_VECTOR);
		CopyVectors(fDirection, g_fRocketDirection[iIndex]);
	}

	Forward_OnRocketBounce(iIndex, iEntity);
	SDKUnhook(iEntity, SDKHook_Touch, OnTouch);

	return Plugin_Handled;
}

public Action OnTFExplosion(const char[] strTEName, const int[] iClients, int iNumClients, float fDelay)
{
	static int bIgnoreHook;
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}

	if (bIgnoreHook)
	{
		bIgnoreHook = false;
		return Plugin_Continue;
	}

	TE_Start("TFExplosion");

	static float vecNormal[3]; TE_ReadVector("m_vecNormal", vecNormal);
	TE_WriteFloat("m_vecOrigin[0]", TE_ReadFloat("m_vecOrigin[0]"));
	TE_WriteFloat("m_vecOrigin[1]", TE_ReadFloat("m_vecOrigin[1]"));
	TE_WriteFloat("m_vecOrigin[2]", TE_ReadFloat("m_vecOrigin[2]"));
	TE_WriteVector("m_vecNormal", vecNormal);
	TE_WriteNum("m_iWeaponID", TE_ReadNum("m_iWeaponID"));
	TE_WriteNum("entindex",    TE_ReadNum("entindex"));
	TE_WriteNum("m_nDefID",    -1);
	TE_WriteNum("m_nSound",    TE_ReadNum("m_nSound"));
	TE_WriteNum("m_iCustomParticleIndex", TE_ReadNum("m_iCustomParticleIndex"));

	bIgnoreHook = true;
	TE_Send(iClients, iNumClients, fDelay);
	return Plugin_Stop;
}