#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <multicolors>

#define PLUGIN_NAME        "[TFDB] Print & replace client indexes"
#define PLUGIN_AUTHOR      "x07x08"
#define PLUGIN_DESCRIPTION "Does what it says"
#define PLUGIN_VERSION     "1.1.2"
#define PLUGIN_URL         "https://github.com/x07x08/TF2-Dodgeball-Modified"

char g_strCmdBuffer[255];
char g_strExplodeBuffer[32][255];

Regex g_hBracketsPattern;

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
	
	g_hBracketsPattern = new Regex("(?<=\\[)(.*?)(?=\\])");
	
	RegAdminCmd("tf_dodgeball_print", CmdPrintMessage, ADMFLAG_CHAT, "Prints a message to chat and replaces client indexes inside a pair of '##'");
	RegAdminCmd("tf_dodgeball_print_c", CmdPrintMessageClient, ADMFLAG_CHAT, "Prints a message to a client and replaces client indexes inside a pair of '##'");
	RegAdminCmd("tf_dodgeball_phrase", CmdPrintPhrase, ADMFLAG_CHAT, "Prints a translation phrase to chat");
	RegAdminCmd("tf_dodgeball_phrase_c", CmdPrintPhraseClient, ADMFLAG_CHAT, "Prints a translation phrase to a client");
}

public Action CmdPrintMessage(int iClient, int iArgs)
{
	if (!(iArgs >= 1))
	{
		ReplyToCommand(iClient, "Usage : tf_dodgeball_print <text>");
		
		return Plugin_Handled;
	}
	
	GetCmdArgString(g_strCmdBuffer, sizeof(g_strCmdBuffer));
	TrimString(g_strCmdBuffer);
	
	int iNumStrings = ExplodeString(g_strCmdBuffer, "##", g_strExplodeBuffer, sizeof(g_strExplodeBuffer), sizeof(g_strExplodeBuffer[]));
	int iIndex;
	
	for (int iPos = 0; iPos < iNumStrings; iPos++)
	{
		if (!g_strExplodeBuffer[iPos][0]) continue;
		
		if ((StringToIntEx(g_strExplodeBuffer[iPos], iIndex) == strlen(g_strExplodeBuffer[iPos])) &&
		    ((iIndex >= 1) && (iIndex <= MaxClients) && IsClientInGame(iIndex)))
		{
			FormatEx(g_strExplodeBuffer[iPos], sizeof(g_strExplodeBuffer[]), "%N", iIndex);
		}
	}
	
	ImplodeStrings(g_strExplodeBuffer, iNumStrings, "", g_strCmdBuffer, sizeof(g_strCmdBuffer));
	
	CPrintToChatAll(g_strCmdBuffer);
	
	return Plugin_Handled;
}

public Action CmdPrintMessageClient(int iClient, int iArgs)
{
	if (!(iArgs >= 2))
	{
		ReplyToCommand(iClient, "Usage : tf_dodgeball_print_c <client> <text>");
		
		return Plugin_Handled;
	}
	
	char strBuffer[8];
	
	GetCmdArgString(g_strCmdBuffer, sizeof(g_strCmdBuffer));
	
	int iLength = BreakString(g_strCmdBuffer, strBuffer, sizeof(strBuffer));
	int iTarget = StringToInt(strBuffer);
	
	TrimString(g_strCmdBuffer[iLength]);
	
	int iNumStrings = ExplodeString(g_strCmdBuffer[iLength], "##", g_strExplodeBuffer, sizeof(g_strExplodeBuffer), sizeof(g_strExplodeBuffer[]));
	int iIndex;
	
	for (int iPos = 0; iPos < iNumStrings; iPos++)
	{
		if (!g_strExplodeBuffer[iPos][0]) continue;
		
		if ((StringToIntEx(g_strExplodeBuffer[iPos], iIndex) == strlen(g_strExplodeBuffer[iPos])) &&
		    ((iIndex >= 1) && (iIndex <= MaxClients) && IsClientInGame(iIndex)))
		{
			FormatEx(g_strExplodeBuffer[iPos], sizeof(g_strExplodeBuffer[]), "%N", iIndex);
		}
	}
	
	ImplodeStrings(g_strExplodeBuffer, iNumStrings, "", g_strCmdBuffer[iLength], sizeof(g_strCmdBuffer));
	
	if ((iTarget >= 1) && (iTarget <= MaxClients) && IsClientInGame(iTarget))
	{
		CPrintToChat(iTarget, g_strCmdBuffer[iLength]);
	}
	
	return Plugin_Handled;
}

public Action CmdPrintPhrase(int iClient, int iArgs)
{
	char strPhrase[48];
	
	GetCmdArgString(g_strCmdBuffer, sizeof(g_strCmdBuffer)); TrimString(g_strCmdBuffer);
	
	int iMatches = g_hBracketsPattern.MatchAll(g_strCmdBuffer);
	
	if (!(iMatches >= 1))
	{
		ReplyToCommand(iClient, "Usage : tf_dodgeball_phrase <phrase> <args> (phrase and args must be surrounded by []) (phrase arguments must be separated by a comma [,])");
		
		return Plugin_Handled;
	}
	
	any aArgs[32];
	
	g_hBracketsPattern.GetSubString(0, strPhrase, sizeof(strPhrase), 0); TrimString(strPhrase);
	
	if (iMatches == 2)
	{
		g_hBracketsPattern.GetSubString(0, g_strCmdBuffer, sizeof(g_strCmdBuffer), 1);
		
		int iStrings = ExplodeString(g_strCmdBuffer, ",", g_strExplodeBuffer, sizeof(g_strExplodeBuffer), sizeof(g_strExplodeBuffer[]));
		
		for (int iIndex = 0; iIndex < iStrings; iIndex++)
		{
			TrimString(g_strExplodeBuffer[iIndex]);
			
			if ((StringToIntEx(g_strExplodeBuffer[iIndex], aArgs[iIndex]) == strlen(g_strExplodeBuffer[iIndex])) ||
			    (StringToFloatEx(g_strExplodeBuffer[iIndex], aArgs[iIndex]) == strlen(g_strExplodeBuffer[iIndex])))
			{
				g_strExplodeBuffer[iIndex] = "\0";
			}
		}
	}
	
	PrintPhrase(strPhrase, g_strExplodeBuffer, aArgs, true);
	
	return Plugin_Handled;
}

public Action CmdPrintPhraseClient(int iClient, int iArgs)
{
	char strPhrase[48], strTarget[8];
	
	GetCmdArgString(g_strCmdBuffer, sizeof(g_strCmdBuffer)); TrimString(g_strCmdBuffer);
	
	int iMatches = g_hBracketsPattern.MatchAll(g_strCmdBuffer);
	
	if (!(iMatches >= 2))
	{
		ReplyToCommand(iClient, "Usage : tf_dodgeball_phrase_c <client> <phrase> <args> (client, phrase and args must be surrounded by []) (phrase arguments must be separated by a comma [,])");
		
		return Plugin_Handled;
	}
	
	any aArgs[32];
	
	g_hBracketsPattern.GetSubString(0, strTarget, sizeof(strTarget), 0); TrimString(strTarget);
	g_hBracketsPattern.GetSubString(0, strPhrase, sizeof(strPhrase), 1); TrimString(strPhrase);
	
	int iTarget = StringToInt(strTarget);
	
	if (iMatches == 3)
	{
		g_hBracketsPattern.GetSubString(0, g_strCmdBuffer, sizeof(g_strCmdBuffer), 2);
		
		int iStrings = ExplodeString(g_strCmdBuffer, ",", g_strExplodeBuffer, sizeof(g_strExplodeBuffer), sizeof(g_strExplodeBuffer[]));
		
		for (int iIndex = 0; iIndex < iStrings; iIndex++)
		{
			TrimString(g_strExplodeBuffer[iIndex]);
			
			if ((StringToIntEx(g_strExplodeBuffer[iIndex], aArgs[iIndex]) == strlen(g_strExplodeBuffer[iIndex])) ||
			    (StringToFloatEx(g_strExplodeBuffer[iIndex], aArgs[iIndex]) == strlen(g_strExplodeBuffer[iIndex])))
			{
				g_strExplodeBuffer[iIndex] = "\0";
			}
		}
	}
	
	if ((iTarget >= 1) && (iTarget <= MaxClients) && IsClientInGame(iTarget))
	{
		PrintPhrase(strPhrase, g_strExplodeBuffer, aArgs, false, iTarget);
	}
	
	return Plugin_Handled;
}

void PrintPhrase(const char[] strPhrase, const char strArgs[32][255], const any aArgs[32], bool bAll, int iClient = -1)
{
	if (bAll)
	{
		// There are a maximum of 32 arguments for the translation format function.
		// Three of them seem to be reserved :
		//
		//     - One for the phrase name
		//     - One for the client or the language ID (no idea which)
		//     - One that is unknown to me (most likely one of the above)
		//
		// Found the optimal number through plenty of crashes.
		
		// Ok so this has 29 arguments, which contradicts everything above...
		// I have no clue why this works with 29 instead of 28...
		
		CPrintToChatAll("%t", strPhrase, HandleBadConversion(strArgs, aArgs, 0),
		                                 HandleBadConversion(strArgs, aArgs, 1),
		                                 HandleBadConversion(strArgs, aArgs, 2),
		                                 HandleBadConversion(strArgs, aArgs, 3),
		                                 HandleBadConversion(strArgs, aArgs, 4),
		                                 HandleBadConversion(strArgs, aArgs, 5),
		                                 HandleBadConversion(strArgs, aArgs, 6),
		                                 HandleBadConversion(strArgs, aArgs, 7),
		                                 HandleBadConversion(strArgs, aArgs, 8),
		                                 HandleBadConversion(strArgs, aArgs, 9),
		                                 HandleBadConversion(strArgs, aArgs, 10),
		                                 HandleBadConversion(strArgs, aArgs, 11),
		                                 HandleBadConversion(strArgs, aArgs, 12),
		                                 HandleBadConversion(strArgs, aArgs, 13),
		                                 HandleBadConversion(strArgs, aArgs, 14),
		                                 HandleBadConversion(strArgs, aArgs, 15),
		                                 HandleBadConversion(strArgs, aArgs, 16),
		                                 HandleBadConversion(strArgs, aArgs, 17),
		                                 HandleBadConversion(strArgs, aArgs, 18),
		                                 HandleBadConversion(strArgs, aArgs, 19),
		                                 HandleBadConversion(strArgs, aArgs, 20),
		                                 HandleBadConversion(strArgs, aArgs, 21),
		                                 HandleBadConversion(strArgs, aArgs, 22),
		                                 HandleBadConversion(strArgs, aArgs, 23),
		                                 HandleBadConversion(strArgs, aArgs, 24),
		                                 HandleBadConversion(strArgs, aArgs, 25),
		                                 HandleBadConversion(strArgs, aArgs, 26),
		                                 HandleBadConversion(strArgs, aArgs, 27),
		                                 HandleBadConversion(strArgs, aArgs, 28));
	}
	else
	{
		CPrintToChat(iClient, "%t", strPhrase, HandleBadConversion(strArgs, aArgs, 0),
		                                       HandleBadConversion(strArgs, aArgs, 1),
		                                       HandleBadConversion(strArgs, aArgs, 2),
		                                       HandleBadConversion(strArgs, aArgs, 3),
		                                       HandleBadConversion(strArgs, aArgs, 4),
		                                       HandleBadConversion(strArgs, aArgs, 5),
		                                       HandleBadConversion(strArgs, aArgs, 6),
		                                       HandleBadConversion(strArgs, aArgs, 7),
		                                       HandleBadConversion(strArgs, aArgs, 8),
		                                       HandleBadConversion(strArgs, aArgs, 9),
		                                       HandleBadConversion(strArgs, aArgs, 10),
		                                       HandleBadConversion(strArgs, aArgs, 11),
		                                       HandleBadConversion(strArgs, aArgs, 12),
		                                       HandleBadConversion(strArgs, aArgs, 13),
		                                       HandleBadConversion(strArgs, aArgs, 14),
		                                       HandleBadConversion(strArgs, aArgs, 15),
		                                       HandleBadConversion(strArgs, aArgs, 16),
		                                       HandleBadConversion(strArgs, aArgs, 17),
		                                       HandleBadConversion(strArgs, aArgs, 18),
		                                       HandleBadConversion(strArgs, aArgs, 19),
		                                       HandleBadConversion(strArgs, aArgs, 20),
		                                       HandleBadConversion(strArgs, aArgs, 21),
		                                       HandleBadConversion(strArgs, aArgs, 22),
		                                       HandleBadConversion(strArgs, aArgs, 23),
		                                       HandleBadConversion(strArgs, aArgs, 24),
		                                       HandleBadConversion(strArgs, aArgs, 25),
		                                       HandleBadConversion(strArgs, aArgs, 26),
		                                       HandleBadConversion(strArgs, aArgs, 27));
	}
}

// If I do "!strArgs[iIndex][0] ? aArgs[iIndex] : strArgs[iIndex]", it will print random stuff.
// Found out it's because it returns a value on one side of the conditional operator and an array on the other.
// I wasted 2 hours on this issue.

any[] HandleBadConversion(const char[][] strArgs, const any[] aArgs, int iIndex)
{
	any aTemp[1][1]; aTemp[0][0] = aArgs[iIndex];
	
	return !strArgs[iIndex][0] ? aTemp[0] : strArgs[iIndex];
}
