#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_NAME        "[TFDB] Event fix"
#define PLUGIN_AUTHOR      "x07x08"
#define PLUGIN_DESCRIPTION "Fixes a very weird issue that happens when unhooking event callbacks..."
#define PLUGIN_VERSION     "1.0.2"
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
	
	// https://github.com/alliedmodders/sourcemod/blob/5addaffa5665f353c874f45505914ab692535c24/core/EventManager.cpp#L262
	//
	// If n plugins try to unhook the same event (at the same time, like inside OnMapEnd), the last one always fails and
	// throws an EventHookErr_NotActive error.
	//
	// Example :
	// Plugins 1, 2 and 3 hook the "player_team" event inside OnConfigsExecuted and unhook it inside OnMapEnd.
	// Plugin 3 will always throw (if it was the last one loaded).
	//
	// This might happen because the event manager wrongly removes the entire event structure while the
	// last plugin hasn't unloaded its events (throws on line 268) or there's an off-by-one error (line(s) 295 and / or 309)
	// that causes the former to occur.
	//
	// This issue will not happen if the event is hooked in another plugin and never unhooked.
	// The best way to observe it is on a clean install of SourceMod.
	
	HookEvent("teamplay_round_start", VoidCallback);
	HookEvent("arena_round_start", VoidCallback);
	HookEvent("teamplay_round_win", VoidCallback);
	HookEvent("player_spawn", VoidCallback);
	HookEvent("player_death", VoidCallback);
	HookEvent("post_inventory_application", VoidCallback);
	HookEvent("teamplay_broadcast_audio", VoidCallback);
	HookEvent("object_deflected", VoidCallback);
	
	HookEvent("player_team", VoidCallback);
}

public void VoidCallback(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	return;
}
