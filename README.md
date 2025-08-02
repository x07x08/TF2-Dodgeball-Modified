# TF2 Dodgeball Modified

This project is a modified and updated version of the classic TF2 Dodgeball gamemode for SourceMod. It builds upon the work of several developers in the community to provide a stable, configurable, and extensible Dodgeball experience.

For a more sophisticated rewrite of this gamemode, consider checking out [TF2 Dodgeball Unified by Mikah31](https://github.com/Mikah31/TF2-Dodgeball-Unified).

---
## ✨ Features

- Steal and delay prevention from updated YADBP.
- "Keep direction" feature from Redux.
- Steal distance CVar.
- Additional parameters for internal commands.
- Limits for speed and turnrate parameters.
- No damage on rockets if the target suicides / disconnects (toggleable via a CVar).
- No damage on stolen rockets (toggleable via a CVar).
- Custom trails toggleable client-side.

## 🔧 Fixes
- Fixed looping explosion sounds.
- Fixed 0% chance rocket classes being rarely chosen.
- Fixed neutral rockets.

---
## 🚀 Installation

<!-- https://ibb.co/qJRg3fV - Weren't the instructions clear already... -->
1. **`TF2Dodgeball`**: Place its contents inside your server's `tf` directory.
2. **`Subplugins`**: Copy the contents of a subplugin folder (e.g., `Menu`) inside `tf/addons`.
- The `README.md` files can be omitted.
- It's recommended to install the [`EventFix`](https://github.com/x07x08/TF2-Dodgeball-Modified/tree/main/Subplugins/EventFix) subplugin.

---
## ⚙️ Requirements

- [Multi-Colors](https://github.com/Bara/Multi-Colors) (compile only).
- <sup>Optional</sup> [CollisionHook](https://forums.alliedmods.net/showthread.php?t=197815) (for the [Anti snipe](https://github.com/x07x08/TF2-Dodgeball-Modified/tree/main/Subplugins/AntiSnipe) plugin)
    * Download it from [here](https://github.com/Adrianilloo/Collisionhook)

---
## 🎮 Commands
For a list of commands, check the configuration file located in [`addons/sourcemod/configs/dodgeball`](https://github.com/x07x08/TF2-Dodgeball-Modified/tree/main/TF2Dodgeball/addons/sourcemod/configs/dodgeball).

## Console Variables (ConVars)
```ini
    tf_dodgeball_enablecfg        "sourcemod/dodgeball_enable.cfg"  - Config file to execute when enabling the Dodgeball game mode.
    tf_dodgeball_disablecfg       "sourcemod/dodgeball_disable.cfg" - Config file to execute when disabling the Dodgeball game mode.
    tf_dodgeball_sp_number        "3"     - How many steals before you get slayed?
    tf_dodgeball_sp_damage        "0"     - Reduce all damage on stolen rockets?
    tf_dodgeball_sp_distance      "48.0"  - The distance between players for a steal to register.
    tf_dodgeball_delay_prevention "1"     - Enable delay prevention?
    tf_dodgeball_dp_time          "5"     - How much time [in seconds] before delay prevention activates?
    tf_dodgeball_dp_speedup       "100"   - How much speed [in hammer units per second] should the rocket gain when delayed?
    tf_dodgeball_redirect_damage  "1"     - Reduce all damage when a rocket has an invalid target?
    tf_dodgeball_sp_message       "1"     - Display the steal message(s)?
    tf_dodgeball_dp_message       "1"     - Display the delay message(s)?
```

---
## ☢️ Nuke model
By default, the plugin uses a custom model for the `"nuke"` rocket class. It can be found here : [AlliedMods Link](https://forums.alliedmods.net/showpost.php?s=8fa72450fa0c4941c927d01d2d6245c9&p=2180141&postcount=350)

---
## 🐞 Reporting Bugs
Report bugs using the [Issues](https://github.com/x07x08/TF2-Dodgeball-Modified/issues) tab.

---
## ❤️ Credits
1. The original YADB plugin by Damizean : [AlliedMods Link](https://forums.alliedmods.net/showthread.php?t=134503)
2. The updated YADB plugin by bloody & lizzy : [AlliedMods Link](https://forums.alliedmods.net/showthread.php?p=2534328) | [GitHub Account](https://github.com/keybangz)
3. Dodgeball Redux by ClassicGuzzi : [AlliedMods Link](https://forums.alliedmods.net/showthread.php?p=2226728) | [GitHub Link](https://github.com/ClassicSpeed/dodgeball)
4. BloodyNightmare and Mitchell for the original airblast prevention plugin : [AlliedMods Link](https://forums.alliedmods.net/showthread.php?t=233475)
5. Syntax converter batch by Dragokas : [AlliedMods Link](https://forums.alliedmods.net/showpost.php?p=2593268&postcount=54)
6. To updater of DB plugin named x07x08
