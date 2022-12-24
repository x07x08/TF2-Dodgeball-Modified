#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_NAME        "[TFDB] Event fix"
#define PLUGIN_AUTHOR      "x07x08"
#define PLUGIN_DESCRIPTION "Fixes a very weird issue that happens when unhooking event callbacks..."
#define PLUGIN_VERSION     "1.0.1"
#define PLUGIN_URL         "https://github.com/x07x08/TF2-Dodgeball-Modified"

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
	// https://forums.alliedmods.net/showthread.php?p=2050730
	//
	// This plugin somehow made it so I didn't get any UnhookEvent errors when changing maps.
	// Keep in mind, those event callbacks shouldn't be related in any way with the ones from the dodgeball plugin.
	// That doesn't seem to be the case...
	// Oh well... wasted a bunch of time on this.
	//
	// Refer to : https://github.com/x07x08/TF2-Dodgeball-Modified/issues/7
	
	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("arena_round_start", OnSetupFinished);
	HookEvent("teamplay_round_win", OnRoundEnd);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("post_inventory_application", OnPlayerInventory);
	HookEvent("teamplay_broadcast_audio", OnBroadcastAudio);
	HookEvent("object_deflected", OnObjectDeflected);
	
	HookEvent("player_team", OnPlayerTeam);
}

public void OnRoundStart(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	return;
}

public void OnSetupFinished(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	return;
}

public void OnRoundEnd(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	return;
}

public void OnPlayerSpawn(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	return;
}

public void OnPlayerDeath(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	return;
}

public void OnPlayerInventory(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	return;
}

public void OnBroadcastAudio(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	return;
}

public void OnObjectDeflected(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	return;
}

public void OnPlayerTeam(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	return;
}
