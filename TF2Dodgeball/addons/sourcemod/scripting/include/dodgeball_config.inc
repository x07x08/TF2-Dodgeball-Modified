#if defined _dodgeball_config_included
  #endinput
#endif
#define _dodgeball_config_included

/**
 * Handles parsing of configuration files and server commands.
 */

void DestroyRocketClasses()
{
	for (int iIndex = 0; iIndex < g_iRocketClassCount; iIndex++)
	{
		DataPack hCmdOnSpawn    = g_hRocketClassCmdsOnSpawn[iIndex];
		DataPack hCmdOnKill     = g_hRocketClassCmdsOnKill[iIndex];
		DataPack hCmdOnExplode  = g_hRocketClassCmdsOnExplode[iIndex];
		DataPack hCmdOnDeflect  = g_hRocketClassCmdsOnDeflect[iIndex];
		DataPack hCmdOnNoTarget = g_hRocketClassCmdsOnNoTarget[iIndex];

		if (hCmdOnSpawn   != null)  delete hCmdOnSpawn;
		if (hCmdOnKill    != null)  delete hCmdOnKill;
		if (hCmdOnExplode != null)  delete hCmdOnExplode;
		if (hCmdOnDeflect != null)  delete hCmdOnDeflect;
		if (hCmdOnNoTarget != null) delete hCmdOnNoTarget;

		g_hRocketClassCmdsOnSpawn[iIndex]    = null;
		g_hRocketClassCmdsOnKill[iIndex]     = null;
		g_hRocketClassCmdsOnExplode[iIndex]  = null;
		g_hRocketClassCmdsOnDeflect[iIndex]  = null;
		g_hRocketClassCmdsOnNoTarget[iIndex] = null;
	}
	g_iRocketClassCount = 0;
}

void DestroySpawners()
{
	for (int iIndex = 0; iIndex < g_iSpawnersCount; iIndex++)
	{
		delete g_hSpawnersChancesTable[iIndex];
	}

	g_iSpawnersCount  = 0;
	g_iSpawnPointsRedCount = 0;
	g_iSpawnPointsBluCount = 0;
	g_iDefaultRedSpawner = -1;
	g_iDefaultBluSpawner = -1;
	g_hSpawnersTrie.Clear();
}

void PopulateSpawnPoints()
{
	g_iSpawnPointsRedCount = 0;
	g_iSpawnPointsBluCount = 0;
	int iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "info_target")) != -1)
	{
		char strName[32]; GetEntPropString(iEntity, Prop_Data, "m_iName", strName, sizeof(strName));
		if ((StrContains(strName, "rocket_spawn_red") != -1) || (StrContains(strName, "tf_dodgeball_red") != -1))
		{
			int iIndex = FindSpawnerByName(strName);
			if (iIndex == -1) iIndex = g_iDefaultRedSpawner;
			g_iSpawnPointsRedClass [g_iSpawnPointsRedCount] = iIndex;
			g_iSpawnPointsRedEntity[g_iSpawnPointsRedCount] = iEntity;
			g_iSpawnPointsRedCount++;
		}

		if ((StrContains(strName, "rocket_spawn_blu") != -1) || (StrContains(strName, "tf_dodgeball_blu") != -1))
		{
			int iIndex = FindSpawnerByName(strName);
			if (iIndex == -1) iIndex = g_iDefaultBluSpawner;

			g_iSpawnPointsBluClass [g_iSpawnPointsBluCount] = iIndex;
			g_iSpawnPointsBluEntity[g_iSpawnPointsBluCount] = iEntity;
			g_iSpawnPointsBluCount++;
		}
	}

	// New code block starts here
	if (g_iSpawnPointsRedCount == 0 && g_iSpawnPointsBluCount == 0)
	{
		SetFailState("No 'info_target' entities found on this map.");
		return;
	}
	// New code block ends here

	if (g_iSpawnPointsRedCount == 0) SetFailState("No RED spawn points found on this map.");
	if (g_iSpawnPointsBluCount == 0) SetFailState("No BLU spawn points found on this map.");
}

int FindSpawnerByName(char strName[32])
{
	int iIndex = -1;
	g_hSpawnersTrie.GetValue(strName, iIndex);
	return iIndex;
}

void RegisterCommands()
{
	RegServerCmd("tf_dodgeball_explosion", CmdExplosion);
	RegServerCmd("tf_dodgeball_shockwave", CmdShockwave);
}

public Action CmdExplosion(int iArgs)
{
	if (!g_bEnabled)
	{
		CPrintToServer("%t", "Command_Disabled");
		return Plugin_Handled;
	}

	if (iArgs != 1)
	{
		CPrintToServer("%t", "Command_DBShockwave_Usage");
		return Plugin_Handled;
	}

	char strBuffer[8];
	int iClient;
	GetCmdArg(1, strBuffer, sizeof(strBuffer));
	iClient = StringToInt(strBuffer);

	if (!IsValidEntity(iClient)) return Plugin_Handled;

	static float fPosition[3]; GetClientAbsOrigin(iClient, fPosition);
	switch (GetURandomIntRange(0, 4))
	{
		case 0: PlayParticle(fPosition, PARTICLE_NUKE_1_ANGLES, PARTICLE_NUKE_1);
		case 1: PlayParticle(fPosition, PARTICLE_NUKE_2_ANGLES, PARTICLE_NUKE_2);
		case 2: PlayParticle(fPosition, PARTICLE_NUKE_3_ANGLES, PARTICLE_NUKE_3);
		case 3: PlayParticle(fPosition, PARTICLE_NUKE_4_ANGLES, PARTICLE_NUKE_4);
		case 4: PlayParticle(fPosition, PARTICLE_NUKE_5_ANGLES, PARTICLE_NUKE_5);
	}
	PlayParticle(fPosition, PARTICLE_NUKE_COLLUMN_ANGLES, PARTICLE_NUKE_COLLUMN);

	return Plugin_Handled;
}

public Action CmdShockwave(int iArgs)
{
	if (!g_bEnabled)
	{
		CPrintToServer("%t", "Command_Disabled");
		return Plugin_Handled;
	}

	if (iArgs != 5)
	{
		CPrintToServer("%t", "Command_DBShockwave_Usage");
		return Plugin_Handled;
	}

	static char strBuffer[8];
	int iClient, iTeam; static float fPosition[3]; int iDamage; float fPushStrength, fRadius, fFalloffRadius;
	
	GetCmdArg(1, strBuffer, sizeof(strBuffer)); iClient        = StringToInt(strBuffer);
	GetCmdArg(2, strBuffer, sizeof(strBuffer)); iDamage        = StringToInt(strBuffer);
	GetCmdArg(3, strBuffer, sizeof(strBuffer)); fPushStrength  = StringToFloat(strBuffer);
	GetCmdArg(4, strBuffer, sizeof(strBuffer)); fRadius        = StringToFloat(strBuffer);
	GetCmdArg(5, strBuffer, sizeof(strBuffer)); fFalloffRadius = StringToFloat(strBuffer);

	if (!IsValidClient(iClient)) return Plugin_Handled;
	
	iTeam = GetClientTeam(iClient);
	GetClientAbsOrigin(iClient, fPosition);

	for (iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!(IsValidClientEx(iClient, true) && (GetClientTeam(iClient) == iTeam))) continue;
		
		static float fPlayerPosition[3]; GetClientEyePosition(iClient, fPlayerPosition);
		float fDistanceToShockwave = GetVectorDistance(fPosition, fPlayerPosition);

		if (!(fDistanceToShockwave < fRadius)) continue;

		static float fImpulse[3], fFinalPush;
		int iFinalDamage;
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

	return Plugin_Handled;
}

void ExecuteCommands(DataPack hDataPack, int iClass, int iRocket, int iOwner, int iTarget, int iLastDead, float fSpeed, int iNumDeflections, float fMphSpeed)
{
	hDataPack.Reset(false);
	int iNumCommands = hDataPack.ReadCell();

	while (iNumCommands-- > 0)
	{
		char strCmd[256], strBuffer[32];

		hDataPack.ReadString(strCmd, sizeof(strCmd));
		ReplaceString(strCmd, sizeof(strCmd), "@name", g_strRocketClassLongName[iClass]);
		FormatEx(strBuffer, sizeof(strBuffer), "%i", iRocket);                           ReplaceString(strCmd, sizeof(strCmd), "@rocket", strBuffer);
		FormatEx(strBuffer, sizeof(strBuffer), "%i", iOwner);                            ReplaceString(strCmd, sizeof(strCmd), "@owner", strBuffer);
		FormatEx(strBuffer, sizeof(strBuffer), "%i", iTarget);                           ReplaceString(strCmd, sizeof(strCmd), "@target", strBuffer);
		FormatEx(strBuffer, sizeof(strBuffer), "%i", iLastDead);                         ReplaceString(strCmd, sizeof(strCmd), "@dead", strBuffer);
		FormatEx(strBuffer, sizeof(strBuffer), "%i", iNumDeflections);                   ReplaceString(strCmd, sizeof(strCmd), "@deflections", strBuffer);
		FormatEx(strBuffer, sizeof(strBuffer), "%f", fSpeed);                            ReplaceString(strCmd, sizeof(strCmd), "@speed", strBuffer);
		FormatEx(strBuffer, sizeof(strBuffer), "%i", RoundToNearest(fMphSpeed));         ReplaceString(strCmd, sizeof(strCmd), "@mphspeed", strBuffer);
		FormatEx(strBuffer, sizeof(strBuffer), "%i", RoundToNearest(fSpeed * 0.042614)); ReplaceString(strCmd, sizeof(strCmd), "@capmphspeed", strBuffer);
		FormatEx(strBuffer, sizeof(strBuffer), "%f", fMphSpeed / 0.042614);              ReplaceString(strCmd, sizeof(strCmd), "@nocapspeed", strBuffer);
		FormatEx(strBuffer, sizeof(strBuffer), "%.2f", fSpeed);                          ReplaceString(strCmd, sizeof(strCmd), "@2dspeed", strBuffer);
		FormatEx(strBuffer, sizeof(strBuffer), "%.2f", fMphSpeed / 0.042614);            ReplaceString(strCmd, sizeof(strCmd), "@2dnocapspeed", strBuffer);

		ServerCommand(strCmd);
	}
}

void ParseConfigurations(char[] strConfigFile = "general.cfg")
{
	char strPath[PLATFORM_MAX_PATH];
	char strFileName[PLATFORM_MAX_PATH];
	FormatEx(strFileName, sizeof(strFileName), "configs/dodgeball/%s", strConfigFile);
	BuildPath(Path_SM, strPath, sizeof(strPath), strFileName);
	LogMessage("Executing configuration file %s", strPath);

	if (!FileExists(strPath, true)) return;

	KeyValues kvConfig = new KeyValues("TF2_Dodgeball");
	if (!kvConfig.ImportFromFile(strPath)) SetFailState("Error while parsing the configuration file.");

	kvConfig.GotoFirstSubKey();
	do
	{
		char strSection[64]; kvConfig.GetSectionName(strSection, sizeof(strSection));
		if (StrEqual(strSection, "general"))       ParseGeneral(kvConfig);
		else if (StrEqual(strSection, "classes"))  ParseClasses(kvConfig);
		else if (StrEqual(strSection, "spawners")) ParseSpawners(kvConfig);
	}
	while (kvConfig.GotoNextKey());

	delete kvConfig;
	Forward_OnRocketsConfigExecuted(strConfigFile);
}

void ParseGeneral(KeyValues kvConfig)
{
	g_bMusicEnabled = view_as<bool>(kvConfig.GetNum("music", 0));
	if (!g_bMusicEnabled) return;

	g_bUseWebPlayer = view_as<bool>(kvConfig.GetNum("use web player", 0));
	kvConfig.GetString("web player url", g_strWebPlayerUrl, sizeof(g_strWebPlayerUrl));
	g_bMusic[Music_RoundStart] = kvConfig.GetString("round start",      g_strMusic[Music_RoundStart], PLATFORM_MAX_PATH) && g_strMusic[Music_RoundStart][0];
	g_bMusic[Music_RoundWin]   = kvConfig.GetString("round end (win)",  g_strMusic[Music_RoundWin],   PLATFORM_MAX_PATH) && g_strMusic[Music_RoundWin][0];
	g_bMusic[Music_RoundLose]  = kvConfig.GetString("round end (lose)", g_strMusic[Music_RoundLose],  PLATFORM_MAX_PATH) && g_strMusic[Music_RoundLose][0];
	g_bMusic[Music_Gameplay]   = kvConfig.GetString("gameplay",         g_strMusic[Music_Gameplay],   PLATFORM_MAX_PATH) && g_strMusic[Music_Gameplay][0];
}

void ParseClasses(KeyValues kvConfig)
{
	char strName[64];
	char strBuffer[256];
	kvConfig.GotoFirstSubKey();
	do
	{
		int iIndex = g_iRocketClassCount;
		RocketFlags iFlags;

		kvConfig.GetSectionName(strName, sizeof(strName));        strcopy(g_strRocketClassName[iIndex], 16, strName);
		kvConfig.GetString("name", strBuffer, sizeof(strBuffer)); strcopy(g_strRocketClassLongName[iIndex], 32, strBuffer);
		
		if (kvConfig.GetString("model", strBuffer, sizeof(strBuffer)))
		{
			strcopy(g_strRocketClassModel[iIndex], PLATFORM_MAX_PATH, strBuffer);
			if (g_strRocketClassModel[iIndex][0])
			{
				iFlags |= RocketFlag_CustomModel;
				if (kvConfig.GetNum("is animated", 0)) iFlags |= RocketFlag_IsAnimated;
			}
		}

		kvConfig.GetString("behaviour", strBuffer, sizeof(strBuffer), "homing");
		if (StrEqual(strBuffer, "homing")) g_iRocketClassBehaviour[iIndex] = Behaviour_Homing;
		else if (StrEqual(strBuffer, "legacy homing")) g_iRocketClassBehaviour[iIndex] = Behaviour_LegacyHoming;
		else g_iRocketClassBehaviour[iIndex] = Behaviour_Unknown;

		if (kvConfig.GetNum("play spawn sound", 0) == 1)
		{
			iFlags |= RocketFlag_PlaySpawnSound;
			if (kvConfig.GetString("spawn sound", g_strRocketClassSpawnSound[iIndex], PLATFORM_MAX_PATH) && g_strRocketClassSpawnSound[iIndex][0])
			{
				iFlags |= RocketFlag_CustomSpawnSound;
			}
		}

		if (kvConfig.GetNum("play beep sound", 0) == 1)
		{
			iFlags |= RocketFlag_PlayBeepSound;
			g_fRocketClassBeepInterval[iIndex] = kvConfig.GetFloat("beep interval", 0.5);
			if (kvConfig.GetString("beep sound", g_strRocketClassBeepSound[iIndex], PLATFORM_MAX_PATH) && g_strRocketClassBeepSound[iIndex][0])
			{
				iFlags |= RocketFlag_CustomBeepSound;
			}
		}

		if (kvConfig.GetNum("play alert sound", 0) == 1)
		{
			iFlags |= RocketFlag_PlayAlertSound;
			if (kvConfig.GetString("alert sound", g_strRocketClassAlertSound[iIndex], PLATFORM_MAX_PATH) && g_strRocketClassAlertSound[iIndex][0])
			{
				iFlags |= RocketFlag_CustomAlertSound;
			}
		}

		if (kvConfig.GetNum("elevate on deflect", 1) == 1) iFlags |= RocketFlag_ElevateOnDeflect;
		if (kvConfig.GetNum("neutral rocket", 0) == 1)     iFlags |= RocketFlag_IsNeutral;
		if (kvConfig.GetNum("keep direction", 0) == 1)     iFlags |= RocketFlag_KeepDirection;
		if (kvConfig.GetNum("teamless deflects", 0) == 1)  iFlags |= RocketFlag_TeamlessHits;
		if (kvConfig.GetNum("reset bounces", 0) == 1)      iFlags |= RocketFlag_ResetBounces;
		if (kvConfig.GetNum("no bounce drags", 0) == 1)    iFlags |= RocketFlag_NoBounceDrags;
		if (kvConfig.GetNum("can be stolen", 0) == 1)      iFlags |= RocketFlag_CanBeStolen;
		if (kvConfig.GetNum("steal team check", 0) == 1)   iFlags |= RocketFlag_StealTeamCheck;

		g_fRocketClassDamage[iIndex]            = kvConfig.GetFloat("damage");
		g_fRocketClassDamageIncrement[iIndex]   = kvConfig.GetFloat("damage increment");
		g_fRocketClassCritChance[iIndex]        = kvConfig.GetFloat("critical chance");
		g_fRocketClassSpeed[iIndex]             = kvConfig.GetFloat("speed");
		g_fRocketClassSpeedIncrement[iIndex]    = kvConfig.GetFloat("speed increment");
		if ((g_fRocketClassSpeedLimit[iIndex] = kvConfig.GetFloat("speed limit")) != 0.0)
		{
			iFlags |= RocketFlag_IsSpeedLimited;
		}

		g_fRocketClassTurnRate[iIndex]          = kvConfig.GetFloat("turn rate");
		g_fRocketClassTurnRateIncrement[iIndex] = kvConfig.GetFloat("turn rate increment");
		if ((g_fRocketClassTurnRateLimit[iIndex] = kvConfig.GetFloat("turn rate limit")) != 0.0)
		{
			iFlags |= RocketFlag_IsTRLimited;
		}

		g_fRocketClassElevationRate[iIndex]     = kvConfig.GetFloat("elevation rate");
		g_fRocketClassElevationLimit[iIndex]    = kvConfig.GetFloat("elevation limit");
		g_fRocketClassControlDelay[iIndex]      = kvConfig.GetFloat("control delay");
		g_fRocketClassDragTimeMin[iIndex]       = kvConfig.GetFloat("drag time min");
		g_fRocketClassDragTimeMax[iIndex]       = kvConfig.GetFloat("drag time max");
		g_iRocketClassMaxBounces[iIndex]        = kvConfig.GetNum("max bounces");
		g_fRocketClassBounceScale[iIndex]       = kvConfig.GetFloat("bounce scale", 1.0);
		g_fRocketClassPlayerModifier[iIndex]    = kvConfig.GetFloat("no. players modifier");
		g_fRocketClassRocketsModifier[iIndex]   = kvConfig.GetFloat("no. rockets modifier");
		g_fRocketClassTargetWeight[iIndex]      = kvConfig.GetFloat("direction to target weight");
		
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

		g_iRocketClassFlags[iIndex] = iFlags;
		g_iRocketClassCount++;
	}
	while (kvConfig.GotoNextKey());
	kvConfig.GoBack();
}

void ParseSpawners(KeyValues kvConfig)
{
	char strBuffer[256];
	kvConfig.GotoFirstSubKey();
	do
	{
		int iIndex = g_iSpawnersCount;

		kvConfig.GetSectionName(strBuffer, sizeof(strBuffer)); strcopy(g_strSpawnersName[iIndex], 32, strBuffer);
		g_iSpawnersMaxRockets[iIndex] = kvConfig.GetNum("max rockets", 1);
		g_fSpawnersInterval[iIndex]   = kvConfig.GetFloat("interval", 1.0);

		g_hSpawnersChancesTable[iIndex] = new ArrayList();
		for (int iClassIndex = 0; iClassIndex < g_iRocketClassCount; iClassIndex++)
		{
			FormatEx(strBuffer, sizeof(strBuffer), "%s%%", g_strRocketClassName[iClassIndex]);
			g_hSpawnersChancesTable[iIndex].Push(kvConfig.GetNum(strBuffer, 0));
		}

		g_hSpawnersTrie.SetValue(g_strSpawnersName[iIndex], iIndex);
		g_iSpawnersCount++;
	}
	while (kvConfig.GotoNextKey());

	kvConfig.GoBack();
	g_hSpawnersTrie.GetValue("red", g_iDefaultRedSpawner);
	g_hSpawnersTrie.GetValue("blu", g_iDefaultBluSpawner);
}

DataPack ParseCommands(char[] strLine)
{
    TrimString(strLine);
    if (!strLine[0]) return null;

    ArrayList hCommands = new ArrayList(ByteCountToCells(256));
    char strBuffer[256];
    char[][] strParts = new char[32][256];
    int iNumParts = ExplodeString(strLine, ";", strParts, 32, 256);

    for (int i = 0; i < iNumParts; i++)
    {
        TrimString(strParts[i]);
        if (strParts[i][0]) hCommands.PushString(strParts[i]);
    }
    
    int iNumCommands = hCommands.Length;
    if (iNumCommands == 0)
    {
        delete hCommands;
        return null;
    }

    DataPack hDataPack = new DataPack();
    hDataPack.WriteCell(iNumCommands);
    for (int i = 0; i < iNumCommands; i++)
    {
        hCommands.GetString(i, strBuffer, sizeof(strBuffer));
        hDataPack.WriteString(strBuffer);
    }

    delete hCommands;
    return hDataPack;
}