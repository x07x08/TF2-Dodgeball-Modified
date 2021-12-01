#pragma semicolon 1

#define PLUGIN_AUTHOR "x07x08"
#define PLUGIN_VERSION "1.02"

#include <sourcemod>
#include <morecolors>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[YADBP] Print & replace client indexes",
	author = PLUGIN_AUTHOR,
	description = "Does what it says",
	version = PLUGIN_VERSION,
	url = "https://github.com/x07x08/TF2_Dodgeball_Modified"
};

public void OnPluginStart()
{
	RegAdminCmd("tf_dodgeball_print", CmdPrintMessage, ADMFLAG_CHAT, "Prints a message to chat and replaces client indexes inside a pair of '##'");
	RegAdminCmd("tf_dodgeball_print_c", CmdPrintMessageClient, ADMFLAG_CHAT, "Prints a message to a client and replaces client indexes inside a pair of '##'");
}

public Action CmdPrintMessage(int iClient, int iArgs)
{
	if (iArgs >= 1)
	{
		char strText[255];
		char strStrings[16][255];
		
		GetCmdArgString(strText, sizeof(strText));
		TrimString(strText);
		
		int iNumStrings = ExplodeString(strText, "##", strStrings, sizeof(strStrings), sizeof(strStrings[]));
		
		for (int i = 0; i < iNumStrings; i++)
		{
			if (strlen(strStrings[i]) == 0)
			{
				continue;
			}
			
			if (String_IsNumeric(strStrings[i]))
			{
				int iIndex = StringToInt(strStrings[i]);
				
				if ((iIndex >= 1) && (iIndex <= MaxClients))
				{
					if (IsClientInGame(iIndex))
					{
						FormatEx(strStrings[i], sizeof(strStrings[]), "%N", iIndex);
					}
				}
			}
		}
		
		ImplodeStrings(strStrings, sizeof(strStrings), "##", strText, sizeof(strStrings[]));
		ReplaceString(strText, strlen(strText), "##", "");
		
		CPrintToChatAll(strText);
	}
	else
	{
		ReplyToCommand(iClient, "Usage : tf_dodgeball_print <text>");
	}
	
	return Plugin_Handled;
}

public Action CmdPrintMessageClient(int iClient, int iArgs)
{
	if (iArgs >= 2)
	{
		char strText[255];
		char strStrings[16][255];
		char strBuffer[8];
		
		GetCmdArgString(strText, sizeof(strText));
		
		int iLength = BreakString(strText, strBuffer, sizeof(strBuffer)); // From basechat
		int iTarget = StringToInt(strBuffer);
		
		TrimString(strText[iLength]);
		
		int iNumStrings = ExplodeString(strText[iLength], "##", strStrings, sizeof(strStrings), sizeof(strStrings[]));
		
		for (int i = 0; i < iNumStrings; i++)
		{
			if (strlen(strStrings[i]) == 0)
			{
				continue;
			}
			
			if (String_IsNumeric(strStrings[i]))
			{
				int iIndex = StringToInt(strStrings[i]);
				
				if ((iIndex >= 1) && (iIndex <= MaxClients))
				{
					if (IsClientInGame(iIndex))
					{
						FormatEx(strStrings[i], sizeof(strStrings[]), "%N", iIndex);
					}
				}
			}
		}
		
		ImplodeStrings(strStrings, sizeof(strStrings), "##", strText[iLength], sizeof(strStrings[]));
		ReplaceString(strText[iLength], strlen(strText[iLength]), "##", "");
		
		if ((iTarget >= 1) && (iTarget <= MaxClients))
		{
			if (IsClientInGame(iTarget))
			{
				CPrintToChat(iTarget, strText[iLength]);
			}
		}
	}
	else
	{
		ReplyToCommand(iClient, "Usage : tf_dodgeball_print_c <client> <text>");
	}
	
	return Plugin_Handled;
}

// Smlib stock
stock bool String_IsNumeric(const char[] str)
{
	int x=0;
	int dotsFound=0;
	int numbersFound=0;

	if (str[x] == '+' || str[x] == '-') {
		x++;
	}

	while (str[x] != '\0') {

		if (IsCharNumeric(str[x])) {
			numbersFound++;
		}
		else if (str[x] == '.') {
			dotsFound++;

			if (dotsFound > 1) {
				return false;
			}
		}
		else {
			return false;
		}

		x++;
	}

	if (!numbersFound) {
		return false;
	}

	return true;
}