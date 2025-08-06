#if defined _dodgeball_core_included
  #endinput
#endif
#define _dodgeball_core_included

/**
 * Contains core gamemode logic: enabling/disabling the mod and the main game timer.
 */

bool IsDodgeBallMap()
{
	char strMap[64]; GetCurrentMap(strMap, sizeof(strMap));
	return StrContains(strMap, "tfdb_", false) == 0;
}

void EnableDodgeBall()
{
	if (g_bEnabled) return;

	char strMapName[64]; GetCurrentMap(strMapName, sizeof(strMapName));
	char strMapFile[PLATFORM_MAX_PATH]; FormatEx(strMapFile, sizeof(strMapFile), "%s.cfg", strMapName);

	ParseConfigurations();
	ParseConfigurations(strMapFile);

	if (g_iRocketClassCount == 0)   SetFailState("No rocket class defined.");
	if (g_iSpawnersCount == 0)      SetFailState("No spawner class defined.");
	if (g_iDefaultRedSpawner == -1) SetFailState("No spawner class definition for the Red spawners exists in the config file.");
	if (g_iDefaultBluSpawner == -1) SetFailState("No spawner class definition for the Blu spawners exists in the config file.");

	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", OnSetupFinished, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("post_inventory_application", OnPlayerInventory, EventHookMode_Post);
	HookEvent("teamplay_broadcast_audio", OnBroadcastAudio, EventHookMode_Pre);
	HookEvent("object_deflected", OnObjectDeflected);


	AddMultiTargetFilter("@stealer", MLTargetFilterStealer, "last stealer", false);
	AddMultiTargetFilter("@!stealer", MLTargetFilterStealer, "non last stealer", false);

	PrecacheSound(SOUND_DEFAULT_SPAWN, true);
	PrecacheSound(SOUND_DEFAULT_BEEP, true);
	PrecacheSound(SOUND_DEFAULT_ALERT, true);
	PrecacheSound(SOUND_DEFAULT_SPEEDUP, true);

	if (g_bMusicEnabled)
	{
		if (g_bMusic[Music_RoundStart]) PrecacheSoundEx(g_strMusic[Music_RoundStart], true, true);
		if (g_bMusic[Music_RoundWin])   PrecacheSoundEx(g_strMusic[Music_RoundWin], true, true);
		if (g_bMusic[Music_RoundLose])  PrecacheSoundEx(g_strMusic[Music_RoundLose], true, true);
		if (g_bMusic[Music_Gameplay])   PrecacheSoundEx(g_strMusic[Music_Gameplay], true, true);
	}

	PrecacheParticle(PARTICLE_NUKE_1);
	PrecacheParticle(PARTICLE_NUKE_2);
	PrecacheParticle(PARTICLE_NUKE_3);
	PrecacheParticle(PARTICLE_NUKE_4);
	PrecacheParticle(PARTICLE_NUKE_5);
	PrecacheParticle(PARTICLE_NUKE_COLLUMN);

	for (int i = 0; i < g_iRocketClassCount; i++)
	{
		RocketFlags iFlags = g_iRocketClassFlags[i];
		if (TestFlags(iFlags, RocketFlag_CustomModel))      PrecacheModelEx(g_strRocketClassModel[i], true, true);
		if (TestFlags(iFlags, RocketFlag_CustomSpawnSound)) PrecacheSoundEx(g_strRocketClassSpawnSound[i], true, true);
		if (TestFlags(iFlags, RocketFlag_CustomBeepSound))  PrecacheSoundEx(g_strRocketClassBeepSound[i], true, true);
		if (TestFlags(iFlags, RocketFlag_CustomAlertSound)) PrecacheSoundEx(g_strRocketClassAlertSound[i], true, true);
	}

	char strCfgFile[64];
	g_hCvarEnableCfgFile.GetString(strCfgFile, sizeof(strCfgFile));
	ServerCommand("exec \"%s\"", strCfgFile);

	g_bEnabled      = true;
	g_bRoundStarted = false;
	g_iRoundCount   = 0;
}

void DisableDodgeBall()
{
	if (!g_bEnabled) return;

	DestroyRockets();
	DestroyRocketClasses();
	DestroySpawners();

	if (g_hLogicTimer != null) KillTimer(g_hLogicTimer);
	g_hLogicTimer = null;

	g_bMusic[Music_RoundStart] =
	g_bMusic[Music_RoundWin]   =
	g_bMusic[Music_RoundLose]  =
	g_bMusic[Music_Gameplay]   = false;

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

	char strCfgFile[64]; g_hCvarDisableCfgFile.GetString(strCfgFile, sizeof(strCfgFile));
	ServerCommand("exec \"%s\"", strCfgFile);

	g_bEnabled      = false;
	g_bRoundStarted = false;
	g_iRoundCount   = 0;
}

/**
 * This is the main 20Hz timer for the gamemode.
 * It handles rocket spawning and the logic for "legacy homing" rockets.
 * It also calls shared logic functions like sound updates.
 */
public Action OnDodgeBallGameFrame(Handle hTimer, any Data)
{
	if (!BothTeamsPlaying()) return Plugin_Continue;

	// Rocket Spawning Logic
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

	// Rocket Think Logic
	int iIndex = -1;
	while ((iIndex = FindNextValidRocket(iIndex)) != -1)
	{
        // This timer handles legacy homing rockets and shared logic for all rockets.
		switch (g_iRocketClassBehaviour[g_iRocketClass[iIndex]])
		{
			case Behaviour_LegacyHoming:
			{
				RocketLegacyThink(iIndex);
			}
		}
        // Shared logic (sounds, delays) is called for all rockets from here.
        SharedRocketThink(iIndex);
	}

	return Plugin_Continue;
}
