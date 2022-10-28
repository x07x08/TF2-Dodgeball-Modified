#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <multicolors>

#include <tfdb>

#define PLUGIN_NAME        "[TFDB] Free-for-All"
#define PLUGIN_AUTHOR      "x07x08"
#define PLUGIN_DESCRIPTION "Makes all rockets neutral"
#define PLUGIN_VERSION     "1.0.0"
#define PLUGIN_URL         "https://github.com/x07x08/TF2-Dodgeball-Modified"

bool   g_bFFAEnabled;
bool   g_bBotJoined;
bool   g_bVoteAllowed;
float  g_fLastVoteTime;

ConVar g_hDisableOnBot;
ConVar g_hVoteTimeout;
ConVar g_hVoteDuration;
ConVar g_hToggleMode;
ConVar g_hAllowStealing;
ConVar g_hFriendlyFire;

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
	
	g_hDisableOnBot  = CreateConVar("tf_dodgeball_ffa_bot", "1", "Disable FFA when a bot joins?", _, true, 0.0, true, 1.0);
	g_hVoteTimeout   = CreateConVar("tf_dodgeball_ffa_timeout", "150", "Vote timeout (in seconds)", _, true, 0.0);
	g_hVoteDuration  = CreateConVar("tf_dodgeball_ffa_duration", "20", "Vote duration (in seconds)", _, true, 0.0);
	g_hToggleMode    = CreateConVar("tf_dodgeball_ffa_mode", "1", "How does changing FFA affect the rockets?\n 0 - No effect, wait for the next spawn\n 1 - Destroy all active rockets\n 2 - Immediately change the rockets to be neutral", _, true, 0.0);
	g_hAllowStealing = CreateConVar("tf_dodgeball_ffa_stealing", "1", "Allow stealing in FFA mode?", _, true, 0.0, true, 1.0);
	g_hFriendlyFire  = FindConVar("mp_friendlyfire");
	
	RegAdminCmd("sm_ffa", CmdToggleFFA, ADMFLAG_CONFIG, "Forcefully toggle FFA");
	RegConsoleCmd("sm_voteffa", CMDVoteFFA, "Start a vote to toggle FFA");
}

public void OnMapStart()
{
	g_bVoteAllowed  = true;
	g_bFFAEnabled   = false;
	g_bBotJoined    = false;
	g_fLastVoteTime = 0.0;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient) && IsFakeClient(iClient))
		{
			g_bBotJoined = true;
			break;
		}
	}
}

public void OnMapEnd()
{
	g_bVoteAllowed  = false;
	g_bFFAEnabled   = false;
	g_bBotJoined    = false;
	g_fLastVoteTime = 0.0;
}

// I am assuming the bot's plugin will restart the round.
// If that doesn't happen, the rockets will stay the same.

public void OnClientPutInServer(int iClient)
{
	if (TFDB_IsDodgeballEnabled() && IsFakeClient(iClient) && g_hDisableOnBot.BoolValue)
	{
		g_bBotJoined = true;
		
		if (g_bFFAEnabled)
		{
			CPrintToChatAll("%t", "Dodgeball_FFABot_Joined");
			g_hFriendlyFire.RestoreDefault();
		}
	}
}

public void OnClientDisconnect(int iClient)
{
	if (TFDB_IsDodgeballEnabled() && IsFakeClient(iClient) && g_hDisableOnBot.BoolValue)
	{
		g_bBotJoined = false;
		
		if (g_bFFAEnabled)
		{
			CPrintToChatAll("%t", "Dodgeball_FFABot_Left");
			g_hFriendlyFire.SetBool(true);
		}
	}
}

public Action CmdToggleFFA(int iClient, int iArgs)
{
	if (!TFDB_IsDodgeballEnabled())
	{
		CReplyToCommand(iClient, "%t", "Command_Disabled");
		
		return Plugin_Handled;
	}
	
	ToggleFFA();
	
	return Plugin_Handled;
}

public Action CMDVoteFFA(int iClient, int iArgs)
{
	if (iClient == 0)
	{
		// CReplyToCommand prints the message twice...
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
	
	if (g_bVoteAllowed)
	{
		g_bVoteAllowed  = false;
		g_fLastVoteTime = GetGameTime();
		
		StartFFAVote();
		CreateTimer(g_hVoteTimeout.FloatValue, VoteTimeoutCallback, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		CReplyToCommand(iClient, "%t", "Dodgeball_FFAVote_Cooldown",
		                RoundToCeil((g_fLastVoteTime + g_hVoteTimeout.FloatValue) - GetGameTime()));
	}
	
	return Plugin_Handled;
}

void StartFFAVote()
{
	char strMode[16];
	strMode = !g_bFFAEnabled ? "Enable" : "Disable";
	
	Menu hMenu = new Menu(VoteMenuHandler);
	hMenu.VoteResultCallback = VoteResultHandler;
	
	hMenu.SetTitle("%s FFA mode?", strMode);
	
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
	
	hMenu.DisplayVote(iClients, iTotal, g_hVoteDuration.IntValue);
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

public void VoteResultHandler(Menu hMenu,
                              int iNumVotes,
                              int iNumClients,
                              const int[][] iClientInfo,
                              int iNumItems,
                              const int[][] iItemInfo)
{
	int iWinnerIndex = 0;
	
	if (iNumItems > 1
	    && (iItemInfo[0][VOTEINFO_ITEM_VOTES] == iItemInfo[1][VOTEINFO_ITEM_VOTES]))
	{
		iWinnerIndex = GetRandomInt(0, 1);
	}
	
	char strWinner[8]; hMenu.GetItem(iItemInfo[iWinnerIndex][VOTEINFO_ITEM_INDEX], strWinner, sizeof(strWinner));
	
	if (StrEqual(strWinner, "0"))
	{
		ToggleFFA();
	}
	else
	{
		CPrintToChatAll("%t", "Dodgeball_FFAVote_Failed");
	}
}

void EnableFFA()
{
	g_bFFAEnabled = true;
	
	if (g_hDisableOnBot.BoolValue && g_bBotJoined)
	{
		CPrintToChatAll("%t", "Dodgeball_FFAVote_LateEnabled");
	}
	else
	{
		g_hFriendlyFire.SetBool(true);
		
		switch (g_hToggleMode.IntValue)
		{
			case 1 :
			{
				TFDB_DestroyRockets();
			}
			
			case 2 :
			{
				ChangeRockets();
			}
		}
		
		CPrintToChatAll("%t", "Dodgeball_FFAVote_Enabled");
	}
}

void DisableFFA()
{
	g_bFFAEnabled = false;
	g_hFriendlyFire.RestoreDefault();
	
	switch (g_hToggleMode.IntValue)
	{
		case 1 :
		{
			TFDB_DestroyRockets();
		}
		
		case 2 :
		{
			ChangeRockets();
		}
	}
	
	CPrintToChatAll("%t", "Dodgeball_FFAVote_Disabled");
}

void ToggleFFA()
{
	if (!g_bFFAEnabled)
	{
		EnableFFA();
	}
	else
	{
		DisableFFA();
	}
}

void ChangeRockets()
{
	RocketFlags iFlags, iClassFlags;
	int iEntity;
	
	for (int iIndex = 0; iIndex < MAX_ROCKETS; iIndex++)
	{
		if (!TFDB_IsValidRocket(iIndex)) continue;
		
		iFlags = TFDB_GetRocketFlags(iIndex);
		iClassFlags = TFDB_GetRocketClassFlags(TFDB_GetRocketClass(iIndex));
		iEntity = EntRefToEntIndex(TFDB_GetRocketEntity(iIndex));
		
		if (g_bFFAEnabled)
		{
			iFlags |= RocketFlag_IsNeutral;
			
			if (g_hAllowStealing.BoolValue) iFlags |= RocketFlag_CanBeStolen;
			
			SetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1, 1);
			
			TFDB_SetRocketFlags(iIndex, iFlags);
		}
		else
		{
			if (!(iClassFlags & RocketFlag_IsNeutral)) iFlags &= ~RocketFlag_IsNeutral;
			
			if (g_hAllowStealing.BoolValue && !(iClassFlags & RocketFlag_CanBeStolen)) iFlags &= ~RocketFlag_CanBeStolen;
			
			int iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
			SetEntProp(iEntity, Prop_Send, "m_iTeamNum", GetClientTeam(iOwner), 1);
			
			TFDB_SetRocketFlags(iIndex, iFlags);
		}
	}
}

public Action VoteTimeoutCallback(Handle hTimer)
{
	g_bVoteAllowed = true;
	
	return Plugin_Continue;
}

public Action TFDB_OnRocketCreatedPre(int iIndex, int &iClass, RocketFlags &iFlags)
{
	if (g_bFFAEnabled && (!g_hDisableOnBot.BoolValue || !g_bBotJoined))
	{
		iFlags |= RocketFlag_IsNeutral;
		
		if (g_hAllowStealing.BoolValue) iFlags |= RocketFlag_CanBeStolen;
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}
