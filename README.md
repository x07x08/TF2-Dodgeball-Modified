# Convars
```c
    tf_dodgeball_enablecfg        "sourcemod/dodgeball_enable.cfg"  - Config file to execute when enabling the Dodgeball game mode.
    tf_dodgeball_disablecfg       "sourcemod/dodgeball_disable.cfg" - Config file to execute when disabling the Dodgeball game mode.
    tf_dodgeball_sp_number        "3"     - How many steals before you get slayed?
    tf_dodgeball_sp_damage        "0"     - Reduce all damage on stolen rockets?
    tf_dodgeball_sp_distance      "48.0"  - The distance between players for a steal to register.
    tf_dodgeball_delay_prevention "1"     - Enable delay prevention?
    tf_dodgeball_dp_time          "5"     - How much time [in seconds] before delay prevention activates?
    tf_dodgeball_dp_speedup       "100"   - How much speed [in hammer units per second] should the rocket gain when delayed?
    tf_dodgeball_redirect_damage  "1"     - Reduce all damage when a rocket has an invalid target?
```

# Commands
For a list of commands, check the configuration file located in [`addons/sourcemod/configs/dodgeball`](https://github.com/x07x08/TF2-Dodgeball-Modified/tree/main/TF2Dodgeball/addons/sourcemod/configs/dodgeball).

# Installation
Drag and drop the contents of a folder inside the `tf` folder.

If you plan on using airblast prevention, make sure to also add the contents of [`cfg/sourcemod`](https://github.com/x07x08/TF2-Dodgeball-Modified/tree/main/TF2Dodgeball/cfg/sourcemod).

# Requirements
- [Multi-Colors](https://github.com/Bara/Multi-Colors) (compile only).

# Nuke model
By default, the plugin uses a custom model for the `"nuke"` rocket class. It can be found here : [AlliedMods Link](https://forums.alliedmods.net/showpost.php?s=8fa72450fa0c4941c927d01d2d6245c9&p=2180141&postcount=350)

# Features
- Steal and delay prevention from updated YADBP.
- "Keep direction" feature from Redux.
- Steal distance CVar.
- Additional parameters for internal commands.
- Limits for speed and turnrate parameters.
- No damage on rockets if the target suicides / disconnects (toggleable via a CVar).
- No damage on stolen rockets (toggleable via a CVar).
- Custom trails toggleable client-side.

# Fixes
- Fixed looping explosion sounds.
- Fixed 0% chance rocket classes being rarely chosen.
- Fixed neutral rockets.

Report bugs using the [Issues](https://github.com/x07x08/TF2-Dodgeball-Modified/issues) tab.

# Credits
1. The original YADB plugin by Damizean : [AlliedMods Link](https://forums.alliedmods.net/showthread.php?t=134503)
2. The updated YADB plugin by bloody & lizzy : [AlliedMods Link](https://forums.alliedmods.net/showthread.php?p=2534328) | [GitHub Link](https://github.com/bloodgit/TF2-Dodgeball)
3. Dodgeball Redux by ClassicGuzzi : [AlliedMods Link](https://forums.alliedmods.net/showthread.php?p=2226728) | [GitHub Link](https://github.com/ClassicSpeed/dodgeball)
4. BloodyNightmare and Mitchell for the original airblast prevention plugin : [AlliedMods Link](https://forums.alliedmods.net/showthread.php?t=233475)
5. Syntax converter batch by Dragokas : [AlliedMods Link](https://forums.alliedmods.net/showpost.php?p=2593268&postcount=54)
