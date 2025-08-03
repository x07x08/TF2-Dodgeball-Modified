#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <clientprefs>
#include <tf2>
#include <tfdb> // Ensures we can use the TFDB natives and forwards

#define PLUGIN_NAME        "[TFDB] Rocket Speedometer (Event-Driven)"
#define PLUGIN_AUTHOR      "x07x08 (Rewrite by Silorak)"
#define PLUGIN_DESCRIPTION "Shows the speed of dodgeball rockets, updated via game events."
#define PLUGIN_VERSION     "2.0.0"
#define PLUGIN_URL         "https://github.com/Silorak/TF2-Dodgeball-Modified"

// --- Global Variables ---
bool   g_bShowHud[MAXPLAYERS + 1];
Cookie g_hCookieShowHud;
Handle g_hMainHudSync;
Handle g_hMultiHudSync;
bool   g_bLoaded;
int    g_iLastDeflectedRocket = -1;

// --- Plugin Info ---
public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
};

// --- Plugin Lifecycle Functions ---

public void OnPluginStart()
{
    LoadTranslations("common.phrases.txt");
    LoadTranslations("tfdb.phrases.txt");

    RegConsoleCmd("sm_rockethud", CmdToggleSpeedometer);
    RegConsoleCmd("sm_rocketspeedo", CmdToggleSpeedometer);

    g_hCookieShowHud = new Cookie("tfdb_rockethud", "Show rocket speedometer", CookieAccess_Protected);

    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        if (IsClientConnected(iClient) && AreClientCookiesCached(iClient))
        {
            OnClientCookiesCached(iClient);
        }
    }
}

public void OnMapEnd()
{
    if (!g_bLoaded) return;

    delete g_hMainHudSync;
    g_hMainHudSync = null;
    delete g_hMultiHudSync;
    g_hMultiHudSync = null;

    g_bLoaded = false;
}

// --- Dodgeball & Game Event Hooks ---

public void TFDB_OnRocketsConfigExecuted(const char[] strConfigFile)
{
    if (g_bLoaded) return;

    g_hMainHudSync  = CreateHudSynchronizer();
    g_hMultiHudSync = CreateHudSynchronizer();

    HookEvent("teamplay_round_win", OnEvent);
    HookEvent("arena_win_panel", OnEvent);
    HookEvent("arena_round_start", OnEvent);

    g_bLoaded = true;
}

public void TFDB_OnRocketCreated(int iIndex, int iEntity)
{
    if (!g_bLoaded) return;

    if (g_iLastDeflectedRocket == -1)
    {
        g_iLastDeflectedRocket = iIndex;
    }
    UpdateAllHuds();
}

public Action TFDB_OnRocketDeflectPre(int iIndex, int iEntity, int iOwner, int &iTarget)
{
    // FIX: This now correctly returns a value in all code paths.
    if (!g_bLoaded) return Plugin_Continue;

    g_iLastDeflectedRocket = iIndex;
    UpdateAllHuds();

    return Plugin_Continue;
}

public void OnEvent(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bLoaded) return;

    if (StrEqual(name, "teamplay_round_win") || StrEqual(name, "arena_win_panel"))
    {
        g_iLastDeflectedRocket = -1;
        for (int iClient = 1; iClient <= MaxClients; iClient++)
        {
            if (IsValidClient(iClient))
            {
                ClearSyncHud(iClient, g_hMainHudSync);
                ClearSyncHud(iClient, g_hMultiHudSync);
            }
        }
    }
    else if (StrEqual(name, "arena_round_start"))
    {
        g_iLastDeflectedRocket = -1;
        UpdateAllHuds();
    }
}

// --- Client Handling ---

public void OnClientDisconnect(int iClient)
{
    g_bShowHud[iClient] = false;
}

public void OnClientPutInServer(int iClient)
{
    g_bShowHud[iClient] = true;
    if (AreClientCookiesCached(iClient))
    {
        OnClientCookiesCached(iClient);
    }
}

public void OnClientCookiesCached(int iClient)
{
    char strValue[4];
    g_hCookieShowHud.Get(iClient, strValue, sizeof(strValue));
    if (!strValue[0])
    {
        g_hCookieShowHud.Set(iClient, "1");
        strValue = "1";
    }
    g_bShowHud[iClient] = !!StringToInt(strValue);
    if(g_bLoaded)
    {
        UpdatePlayerHud(iClient);
    }
}

// --- HUD Logic ---

void UpdateAllHuds()
{
    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
        if (IsValidClient(iClient))
        {
            UpdatePlayerHud(iClient);
        }
    }
}

void UpdatePlayerHud(int iClient)
{
    if (!g_bShowHud[iClient])
    {
        ClearSyncHud(iClient, g_hMainHudSync);
        ClearSyncHud(iClient, g_hMultiHudSync);
        return;
    }

    char strMultiHudText[1024] = "";

    for (int iIndex = 0; iIndex < MAX_ROCKETS; iIndex++)
    {
        if (!TFDB_IsValidRocket(iIndex))
        {
            continue;
        }

        if (iIndex == g_iLastDeflectedRocket)
        {
            ShowMainRocketHud(iClient, iIndex);
        }
        else
        {
            FormatMultiRocketHud(iClient, iIndex, strMultiHudText, sizeof(strMultiHudText));
        }
    }

    if (strMultiHudText[0])
    {
        SetHudTextParams(0.05, 0.05, 0.1, 255, 255, 255, 255, 0, 0.0, 0.12, 0.12);
        ShowSyncHudText(iClient, g_hMultiHudSync, strMultiHudText);
    }
    else
    {
        ClearSyncHud(iClient, g_hMultiHudSync);
    }

    if (!TFDB_IsValidRocket(g_iLastDeflectedRocket))
    {
        g_iLastDeflectedRocket = -1;
        ClearSyncHud(iClient, g_hMainHudSync);
    }
}

void ShowMainRocketHud(int iClient, int iIndex)
{
    SetHudTextParams(-1.0, 0.9, 0.1, 255, 255, 255, 255, 0, 0.0, 0.12, 0.12);

    char strRocketName[32];
    TFDB_GetRocketClassLongName(TFDB_GetRocketClass(iIndex), strRocketName, sizeof(strRocketName));

    ShowSyncHudText(iClient, g_hMainHudSync, "%t", "Hud_Speedometer",
        RoundToNearest(TFDB_GetRocketMphSpeed(iIndex)),
        RoundToNearest(TFDB_GetRocketSpeed(iIndex)),
        TFDB_GetRocketDeflections(iIndex),
        iIndex,
        strRocketName
    );
}

void FormatMultiRocketHud(int iClient, int iIndex, char[] strBuffer, int iMaxLen)
{
    char strTemp[256];
    char strRocketName[32];
    TFDB_GetRocketClassLongName(TFDB_GetRocketClass(iIndex), strRocketName, sizeof(strRocketName));

    Format(strTemp, sizeof(strTemp), "%T\n", "Hud_SpeedometerEx", iClient,
        RoundToNearest(TFDB_GetRocketMphSpeed(iIndex)),
        RoundToNearest(TFDB_GetRocketSpeed(iIndex)),
        TFDB_GetRocketDeflections(iIndex),
        iIndex,
        strRocketName
    );

    if (strlen(strBuffer) + strlen(strTemp) < iMaxLen)
    {
        StrCat(strBuffer, iMaxLen, strTemp);
    }
}


public Action CmdToggleSpeedometer(int iClient, int iArgs)
{
    if (iClient == 0) return Plugin_Handled;

    if (!g_bLoaded)
    {
        ReplyToCommand(iClient, "Dodgeball is not currently active.");
        return Plugin_Handled;
    }

    g_bShowHud[iClient] = !g_bShowHud[iClient];

    char strValue[2];
    IntToString(g_bShowHud[iClient] ? 1 : 0, strValue, sizeof(strValue));
    g_hCookieShowHud.Set(iClient, strValue);

    UpdatePlayerHud(iClient);

    ReplyToCommand(iClient, "Rocket HUD %s", g_bShowHud[iClient] ? "{green}Enabled" : "{red}Disabled");
    return Plugin_Handled;
}

stock bool IsValidClient(int iClient)
{
    return (iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient));
}
