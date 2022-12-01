#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <multicolors>

#include <tfdb>

#define PLUGIN_NAME        "[TFDB] Votes"
#define PLUGIN_AUTHOR      "x07x08"
#define PLUGIN_DESCRIPTION "Various rocket votes."
#define PLUGIN_VERSION     "1.0.0"
#define PLUGIN_URL         "https://github.com/x07x08/TF2-Dodgeball-Modified"

int g_iSpawnersCount;

ConVar g_hCvarVoteBounceDuration;
ConVar g_hCvarVoteClassDuration;
ConVar g_hCvarVoteCountDuration;
ConVar g_hCvarVoteBounceTimeout;
ConVar g_hCvarVoteClassTimeout;
ConVar g_hCvarVoteCountTimeout;

bool g_bVoteBounceAllowed;
bool g_bVoteClassAllowed;
bool g_bVoteCountAllowed;

float g_fLastVoteBounceTime;
float g_fLastVoteClassTime;
float g_fLastVoteCountTime;

bool g_bBounceEnabled;
int g_iMainRocketClass = -1;
int g_iRocketsCount = -1;

int g_iSavedMaxRockets[MAX_SPAWNER_CLASSES];

bool g_bLoaded;

public Plugin myinfo =
{
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version     = PLUGIN_VERSION,
	url         = PLUGIN_URL
};

public void OnPluginStart()
{
	LoadTranslations("tfdb.phrases.txt");
	
	g_hCvarVoteBounceDuration = CreateConVar("tf_dodgeball_votes_bounce_duration", "20", _, _, true, 0.0);
	g_hCvarVoteClassDuration  = CreateConVar("tf_dodgeball_votes_class_duration", "20", _, _, true, 0.0);
	g_hCvarVoteCountDuration  = CreateConVar("tf_dodgeball_votes_count_duration", "20", _, _, true, 0.0);
	g_hCvarVoteBounceTimeout  = CreateConVar("tf_dodgeball_votes_bounce_timeout", "150", _, _, true, 0.0);
	g_hCvarVoteClassTimeout   = CreateConVar("tf_dodgeball_votes_class_timeout", "150", _, _, true, 0.0);
	g_hCvarVoteCountTimeout   = CreateConVar("tf_dodgeball_votes_count_timeout", "150", _, _, true, 0.0);
	
	RegConsoleCmd("sm_vrb", CmdVoteBounce, "Start a rocket bounce vote");
	RegConsoleCmd("sm_vrc", CmdVoteClass, "Start a rocket class vote");
	RegConsoleCmd("sm_vrcount", CmdVoteCount, "Start a rocket count vote");
	RegConsoleCmd("sm_votebounce", CmdVoteBounce, "Start a rocket bounce vote");
	RegConsoleCmd("sm_voteclass", CmdVoteClass, "Start a rocket class vote");
	RegConsoleCmd("sm_votecount", CmdVoteCount, "Start a rocket count vote");
	RegConsoleCmd("sm_voterocketbounce", CmdVoteBounce, "Start a rocket bounce vote");
	RegConsoleCmd("sm_voterocketclass", CmdVoteClass, "Start a rocket class vote");
	RegConsoleCmd("sm_voterocketcount", CmdVoteCount, "Start a rocket count vote");
	
	if (TFDB_IsDodgeballEnabled())
	{
		char strMapName[64]; GetCurrentMap(strMapName, sizeof(strMapName));
		char strMapFile[PLATFORM_MAX_PATH]; FormatEx(strMapFile, sizeof(strMapFile), "%s.cfg", strMapName);
		
		TFDB_OnRocketsConfigExecuted("general.cfg");
		TFDB_OnRocketsConfigExecuted(strMapFile);
	}
}

public void OnMapEnd()
{
	if (g_bLoaded)
	{
		g_bVoteBounceAllowed =
		g_bVoteClassAllowed  =
		g_bVoteCountAllowed  = false;
		
		g_fLastVoteBounceTime =
		g_fLastVoteClassTime  =
		g_fLastVoteCountTime  = 0.0;
		
		g_bBounceEnabled = false;
		g_iMainRocketClass = -1;
		g_iRocketsCount = -1;
		
		g_bLoaded = false;
	}
	
	g_iSpawnersCount = 0;
}

public void TFDB_OnRocketsConfigExecuted(const char[] strConfigFile)
{
	if (!g_bLoaded)
	{
		g_bVoteBounceAllowed =
		g_bVoteClassAllowed  =
		g_bVoteCountAllowed  = true;
		
		g_fLastVoteBounceTime =
		g_fLastVoteClassTime  =
		g_fLastVoteCountTime  = 0.0;
		
		g_bBounceEnabled = false;
		g_iMainRocketClass = -1;
		g_iRocketsCount = -1;
		
		g_bLoaded = true;
	}
	
	if (strcmp(strConfigFile, "general.cfg") == 0)
	{
		g_iSpawnersCount = 0;
	}
	
	ParseConfigurations(strConfigFile);
}

public Action CmdVoteBounce(int iClient, int iArgs)
{
	if (iClient == 0)
	{
		ReplyToCommand(iClient, "Command is in-game only.");
		
		return Plugin_Handled;
	}
	
	if (!TFDB_IsDodgeballEnabled())
	{
		CReplyToCommand(iClient, "%t", "Command_Disabled");
		
		return Plugin_Handled;
	}
	
	if (IsVoteInProgress())
	{
		CReplyToCommand(iClient, "%t", "Dodgeball_FFAVote_Conflict");
		
		return Plugin_Handled;
	}
	
	if (g_bVoteBounceAllowed)
	{
		g_bVoteBounceAllowed  = false;
		g_fLastVoteBounceTime = GetGameTime();
		
		StartBounceVote();
		CreateTimer(g_hCvarVoteBounceTimeout.FloatValue, VoteBounceTimeoutCallback, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		CReplyToCommand(iClient, "%t", "Dodgeball_BounceVote_Cooldown",
		                RoundToCeil((g_fLastVoteBounceTime + g_hCvarVoteBounceTimeout.FloatValue) - GetGameTime()));
	}
	
	return Plugin_Handled;
}

void StartBounceVote()
{
	char strMode[16];
	strMode = !g_bBounceEnabled ? "Enable" : "Disable";
	
	Menu hMenu = new Menu(VoteMenuHandler);
	hMenu.VoteResultCallback = VoteBounceResultHandler;
	
	hMenu.SetTitle("%s no rocket bounce mode?", strMode);
	
	hMenu.AddItem("0", "Yes");
	hMenu.AddItem("1", "No");
	
	int iTotal;
	int[] iClients = new int[MaxClients];
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient) || IsFakeClient(iClient) || GetClientTeam(iClient) <= 1)
		{
			continue;
		}
		
		iClients[iTotal++] = iClient;
	}
	
	hMenu.DisplayVote(iClients, iTotal, g_hCvarVoteBounceDuration.IntValue);
}

public int VoteMenuHandler(Menu hMenu, MenuAction iMenuActions, int iParam1, int iParam2)
{
	switch (iMenuActions)
	{
		case MenuAction_End :
		{
			delete hMenu;
		}
	}
	
	return 0;
}

public void VoteBounceResultHandler(Menu hMenu,
                                    int iNumVotes,
                                    int iNumClients,
                                    const int[][] iClientInfo,
                                    int iNumItems,
                                    const int[][] iItemInfo)
{
	int iWinnerIndex = 0;
	
	if (iNumItems > 1 &&
	    (iItemInfo[0][VOTEINFO_ITEM_VOTES] == iItemInfo[1][VOTEINFO_ITEM_VOTES]))
	{
		iWinnerIndex = GetRandomInt(0, 1);
	}
	
	char strWinner[8]; hMenu.GetItem(iItemInfo[iWinnerIndex][VOTEINFO_ITEM_INDEX], strWinner, sizeof(strWinner));
	
	if (StrEqual(strWinner, "0"))
	{
		ToggleBounce();
	}
	else
	{
		CPrintToChatAll("%t", "Dodgeball_BounceVote_Failed");
	}
}

void ToggleBounce()
{
	if (!g_bBounceEnabled)
	{
		EnableBounce();
	}
	else
	{
		DisableBounce();
	}
}

void EnableBounce()
{
	g_bBounceEnabled = true;
	
	for (int iIndex = 0; iIndex < MAX_ROCKETS; iIndex++)
	{
		if (!TFDB_IsValidRocket(iIndex)) continue;
		
		TFDB_SetRocketBounces(iIndex, TFDB_GetRocketClassMaxBounces(TFDB_GetRocketClass(iIndex)));
	}
	
	CPrintToChatAll("%t", "Dodgeball_BounceVote_Enabled");
}

void DisableBounce()
{
	g_bBounceEnabled = false;
	
	for (int iIndex = 0; iIndex < MAX_ROCKETS; iIndex++)
	{
		if (!TFDB_IsValidRocket(iIndex)) continue;
		
		TFDB_SetRocketBounces(iIndex, 0);
	}
	
	CPrintToChatAll("%t", "Dodgeball_BounceVote_Disabled");
}

public Action CmdVoteClass(int iClient, int iArgs)
{
	if (iClient == 0)
	{
		ReplyToCommand(iClient, "Command is in-game only.");
		
		return Plugin_Handled;
	}
	
	if (!TFDB_IsDodgeballEnabled())
	{
		CReplyToCommand(iClient, "%t", "Command_Disabled");
		
		return Plugin_Handled;
	}
	
	if (IsVoteInProgress())
	{
		CReplyToCommand(iClient, "%t", "Dodgeball_FFAVote_Conflict");
		
		return Plugin_Handled;
	}
	
	if (g_bVoteClassAllowed)
	{
		g_bVoteClassAllowed  = false;
		g_fLastVoteClassTime = GetGameTime();
		
		StartClassVote();
		CreateTimer(g_hCvarVoteClassTimeout.FloatValue, VoteClassTimeoutCallback, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		CReplyToCommand(iClient, "%t", "Dodgeball_ClassVote_Cooldown",
		                RoundToCeil((g_fLastVoteClassTime + g_hCvarVoteClassTimeout.FloatValue) - GetGameTime()));
	}
	
	return Plugin_Handled;
}

void StartClassVote()
{
	Menu hMenu = new Menu(VoteMenuHandler);
	hMenu.VoteResultCallback = VoteClassResultHandler;
	
	hMenu.SetTitle("Change main rocket class?");
	
	if (g_iMainRocketClass != -1)
	{
		hMenu.AddItem("-1", "Reset the spawn chances");
	}
	
	char strClass[8], strRocketClassLongName[32];
	
	for (int iClass = 0; iClass < TFDB_GetRocketClassCount(); iClass++)
	{
		IntToString(iClass, strClass, sizeof(strClass));
		TFDB_GetRocketClassLongName(iClass, strRocketClassLongName, sizeof(strRocketClassLongName));
		
		hMenu.AddItem(strClass, strRocketClassLongName, ITEMDRAW_DEFAULT);
	}
	
	int iTotal;
	int[] iClients = new int[MaxClients];
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient) || IsFakeClient(iClient) || GetClientTeam(iClient) <= 1)
		{
			continue;
		}
		
		iClients[iTotal++] = iClient;
	}
	
	hMenu.DisplayVote(iClients, iTotal, g_hCvarVoteClassDuration.IntValue);
}

public void VoteClassResultHandler(Menu hMenu,
                                   int iNumVotes,
                                   int iNumClients,
                                   const int[][] iClientInfo,
                                   int iNumItems,
                                   const int[][] iItemInfo)
{
	int iWinnerIndex = 0;
	int iClassCount = TFDB_GetRocketClassCount();
	
	if (g_iMainRocketClass != -1) iClassCount++;
	
	bool bEqual = AreVotesEqual(iItemInfo, iClassCount);
	
	if (bEqual) iWinnerIndex = GetRandomInt(0, (iClassCount - 1));
	
	char strWinner[8], strClassLongName[32];
	
	hMenu.GetItem(iItemInfo[iWinnerIndex][VOTEINFO_ITEM_INDEX], strWinner, sizeof(strWinner), _, strClassLongName, sizeof(strClassLongName));
	
	g_iMainRocketClass = StringToInt(strWinner);
	
	if (g_iMainRocketClass == -1)
	{
		CPrintToChatAll("%t", "Dodgeball_ClassVote_Reset");
	}
	else
	{
		CPrintToChatAll("%t", "Dodgeball_ClassVote_Changed", strClassLongName);
	}
	
	TFDB_DestroyRockets();
}

public Action CmdVoteCount(int iClient, int iArgs)
{
	if (iClient == 0)
	{
		ReplyToCommand(iClient, "Command is in-game only.");
		
		return Plugin_Handled;
	}
	
	if (!TFDB_IsDodgeballEnabled())
	{
		CReplyToCommand(iClient, "%t", "Command_Disabled");
		
		return Plugin_Handled;
	}
	
	if (IsVoteInProgress())
	{
		CReplyToCommand(iClient, "%t", "Dodgeball_FFAVote_Conflict");
		
		return Plugin_Handled;
	}
	
	if (g_bVoteCountAllowed)
	{
		g_bVoteCountAllowed  = false;
		g_fLastVoteCountTime = GetGameTime();
		
		StartCountVote();
		CreateTimer(g_hCvarVoteCountTimeout.FloatValue, VoteCountTimeoutCallback, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		CReplyToCommand(iClient, "%t", "Dodgeball_CountVote_Cooldown",
		                RoundToCeil((g_fLastVoteCountTime + g_hCvarVoteCountTimeout.FloatValue) - GetGameTime()));
	}
	
	return Plugin_Handled;
}

void StartCountVote()
{
	Menu hMenu = new Menu(VoteMenuHandler);
	hMenu.VoteResultCallback = VoteCountResultHandler;
	
	hMenu.SetTitle("Change rockets count?");
	
	if (g_iRocketsCount != -1)
	{
		hMenu.AddItem("-1", "Reset rockets count");
	}
	
	hMenu.AddItem("0", "One rocket");
	hMenu.AddItem("1", "Two rockets");
	hMenu.AddItem("2", "Three rockets");
	hMenu.AddItem("3", "Four rockets");
	hMenu.AddItem("4", "Five rockets");
	
	int iTotal;
	int[] iClients = new int[MaxClients];
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient) || IsFakeClient(iClient) || GetClientTeam(iClient) <= 1)
		{
			continue;
		}
		
		iClients[iTotal++] = iClient;
	}
	
	hMenu.DisplayVote(iClients, iTotal, g_hCvarVoteCountDuration.IntValue);
}

public void VoteCountResultHandler(Menu hMenu,
                                   int iNumVotes,
                                   int iNumClients,
                                   const int[][] iClientInfo,
                                   int iNumItems,
                                   const int[][] iItemInfo)
{
	int iWinnerIndex = 0;
	int iVotesCount = 5;
	
	if (g_iRocketsCount != -1) iVotesCount++;
	
	bool bEqual = AreVotesEqual(iItemInfo, iVotesCount);
	
	if (bEqual) iWinnerIndex = GetRandomInt(0, (iVotesCount - 1));
	
	char strWinner[8]; hMenu.GetItem(iItemInfo[iWinnerIndex][VOTEINFO_ITEM_INDEX], strWinner, sizeof(strWinner));
	
	g_iRocketsCount = StringToInt(strWinner);
	
	for (int iIndex = 0; iIndex < TFDB_GetSpawnersCount(); iIndex++)
	{
		TFDB_SetSpawnersMaxRockets(iIndex, g_iRocketsCount == -1 ? g_iSavedMaxRockets[iIndex] : (g_iRocketsCount + 1));
	}
	
	if (g_iRocketsCount == -1)
	{
		CPrintToChatAll("%t", "Dodgeball_CountVote_Reset");
	}
	else
	{
		CPrintToChatAll("%t", "Dodgeball_CountVote_Changed", (g_iRocketsCount + 1));
	}
}

public Action VoteBounceTimeoutCallback(Handle hTimer)
{
	g_bVoteBounceAllowed = true;
	
	return Plugin_Continue;
}

public Action VoteClassTimeoutCallback(Handle hTimer)
{
	g_bVoteClassAllowed = true;
	
	return Plugin_Continue;
}

public Action VoteCountTimeoutCallback(Handle hTimer)
{
	g_bVoteCountAllowed = true;
	
	return Plugin_Continue;
}

public Action TFDB_OnRocketCreatedPre(int iIndex, int &iClass, RocketFlags &iFlags)
{
	if (g_iMainRocketClass != -1)
	{
		iClass = g_iMainRocketClass;
		iFlags = TFDB_GetRocketClassFlags(g_iMainRocketClass);
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public void TFDB_OnRocketCreated(int iIndex)
{
	if (g_bBounceEnabled) TFDB_SetRocketBounces(iIndex, TFDB_GetRocketClassMaxBounces(TFDB_GetRocketClass(iIndex)));
}

void ParseConfigurations(const char[] strConfigFile)
{
	char strPath[PLATFORM_MAX_PATH];
	char strFileName[PLATFORM_MAX_PATH];
	FormatEx(strFileName, sizeof(strFileName), "configs/dodgeball/%s", strConfigFile);
	BuildPath(Path_SM, strPath, sizeof(strPath), strFileName);
	
	if (FileExists(strPath, true))
	{
		KeyValues kvConfig = new KeyValues("TF2_Dodgeball");
		if (kvConfig.ImportFromFile(strPath) == false) SetFailState("Error while parsing the configuration file.");
		kvConfig.GotoFirstSubKey();
		
		do
		{
			char strSection[64]; kvConfig.GetSectionName(strSection, sizeof(strSection));
			
			if (StrEqual(strSection, "spawners")) ParseSpawners(kvConfig);
		}
		while (kvConfig.GotoNextKey());
		
		delete kvConfig;
	}
}

void ParseSpawners(KeyValues kvConfig)
{
	kvConfig.GotoFirstSubKey();
	
	do
	{
		int iIndex = g_iSpawnersCount;
		
		g_iSavedMaxRockets[iIndex] = kvConfig.GetNum("max rockets", 1);
		
		g_iSpawnersCount++;
	}
	while (kvConfig.GotoNextKey());
	kvConfig.GoBack();
}

bool AreVotesEqual(const int[][] iVoteItems, int iSize)
{
	int iFirst = iVoteItems[0][VOTEINFO_ITEM_VOTES];
	
	for (int iIndex = 1; iIndex < iSize; iIndex++)
	{
		if (iVoteItems[iIndex][VOTEINFO_ITEM_VOTES] != iFirst) return false;
	}
	
	return true;
}
