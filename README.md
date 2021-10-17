# TF2_Dodgeball_Modified
A modified version of the original YADB (Yet Another Dodgeball) plugin.

# Convars
```c
    tf_dodgeball_enablecfg        "sourcemod/dodgeball_enable.cfg"  - Config file to execute when enabling the Dodgeball game mode.
    tf_dodgeball_disablecfg       "sourcemod/dodgeball_disable.cfg" - Config file to execute when disabling the Dodgeball game mode.
    tf_dodgeball_steal_prevention "0"     - Enable steal prevention?
    tf_dodgeball_sp_number        "3"     - How many steals before you get slayed?
    tf_dodgeball_sp_damage        "0"     - Reduce all damage on stolen rockets?
    tf_dodgeball_sp_distance      "48.0"  - The distance between players for a steal to register.
    tf_dodgeball_delay_prevention "1"     - Enable delay prevention?
    tf_dodgeball_dp_time          "5"     - How much time [in seconds] before delay prevention activates?
    tf_dodgeball_dp_speedup       "100"   - How much speed [in hammer units per second] should the rocket gain when delayed? 
```

# Commands
For a list of commands, check the configuration file located in [`addons/sourcemod/configs/dodgeball`](https://github.com/x07x08/TF2_Dodgeball_Modified/tree/main/TF2_Dodgeball_Modified/addons/sourcemod/configs/dodgeball).

# Nuke model
By default, the plugin uses a custom model for the `"nuke"` rocket class. It can be found here : [AlliedMods Link](https://forums.alliedmods.net/showpost.php?s=8fa72450fa0c4941c927d01d2d6245c9&p=2180141&postcount=350)

# Versions
There are 2 versions : 
* The normal one : `TF2_Dodgeball_Modified`
* The "OGF" version : `TF2_Dodgeball_Modified_OGF`

The main difference between them is how the rocket moves :

- The OGF version uses [`OnGameFrame()`](https://sm.alliedmods.net/new-api/sourcemod/OnGameFrame) which is called on every single frame of the server logic (or simply put, every tick of the server's tickrate), making the rocket turn more precisely.

- The normal one uses the original method : a timer with an 0.1 seconds interval, it's less resource intensive but results in worse movement.

The OGF version also includes a few more rocket settings that are **not** present in the normal version.

**Use only one version!**

# Features
- Steal and delay prevention from updated YADBP.
- "Keep direction" feature from Redux.
- Steal distance CVar.
- Additional parameters for internal commands.
- Limits for speed and turnrate parameters.
- No damage on rockets if the target suicides / disconnects.
- No damage on stolen rockets (toggleable with a CVar).
- Commands to modify the movement parameters of a rocket.

# Fixes
- Fixed some errors caused by invalid client indexes in timers.
- Fixed the wrong rocket class being rarely chosen.
- Fixed neutral rockets.

# Known bugs
- The `"refresh"` command throws a `"Divide by zero"` exception.

# Credits
1. The original YADB plugin by Damizean : [AlliedMods Link](https://forums.alliedmods.net/showthread.php?t=134503)
2. The updated YADB plugin by bloody & lizzy : [AlliedMods Link](https://forums.alliedmods.net/showthread.php?p=2534328) or [GitHub Link](https://github.com/bloodgit/TF2-Dodgeball)
3. Dodgeball Redux by ClassicGuzzi : [AlliedMods Link](https://forums.alliedmods.net/showthread.php?p=2226728) or [GitHub Link](https://github.com/ClassicSpeed/dodgeball)
4. friagram for his flag airblast prevention : [AlliedMods Link](https://forums.alliedmods.net/showthread.php?t=219056)
5. BloodyNightmare and Mitchell for the original airblast prevention plugin : [AlliedMods Link](https://forums.alliedmods.net/showthread.php?t=233475)
6. Syntax converter batch by Dragokas : [AlliedMods Link](https://forums.alliedmods.net/showpost.php?p=2593268&postcount=54)
