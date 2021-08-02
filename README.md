# TF2_Dodgeball_Modified
A modified version of the original YADB (Yet Another Dodgeball) plugin.

# Convars
```c
    tf_dodgeball_enablecfg        "sourcemod/dodgeball_enable.cfg"  - Config file to execute when enabling the Dodgeball game mode.
    tf_dodgeball_disablecfg       "sourcemod/dodgeball_disable.cfg" - Config file to execute when disabling the Dodgeball game mode.
    tf_dodgeball_steal_prevention "0"    - Enable steal prevention?
    tf_dodgeball_sp_number        "3"    - How many steals before you get slayed?
    tf_dodgeball_sp_damage        "0"    - Reduce all damage on stolen rockets?
    tf_dodgeball_rbmax            "2"    - Max number of times a rocket will bounce.
    tf_dodgeball_sp_distance      "48.0" - The distance between players for a steal to register.
    tf_dodgeball_delay_prevention "1"    - Enable delay prevention?
    tf_dodgeball_dp_time          "5"    - How much time [in seconds] before delay prevention activates?
    tf_dodgeball_dp_speedup       "100"  - How much speed [in hammer units per second] should the rocket gain when delayed? 
```

# Commands
For a list of commands, check the configuration file located in `addons/sourcemod/configs/dodgeball`.

# Versions
There are 2 versions : 
* The normal one : `TF2_Dodgeball_Modified`
* The "OGF" version : `TF2_Dodgeball_Modified_OGF`

The only difference between them is how the rocket moves :

- The OGF version uses `OnGameFrame()` which is called on every single frame of the server logic (or simply put, every tick of the server's tickrate), making the rocket turn more precisely.

- The normal one uses the original method : a timer with an 0.1 seconds interval, it's less resource intensive but results in worse movement.

### Use only one version!

# Fixes
1. Fixed some errors cause by invalid client indexes in timers.
2. Fixed the wrong rocket class being rarely chosen.

# Known bugs
1. Despite what the configuration file says, the `"on explode"` event is always triggered.

# Credits
1. The original YADB plugin by Damizean : https://forums.alliedmods.net/showthread.php?t=134503
2. The updated YADB plugin by bloody & lizzy : https://forums.alliedmods.net/showthread.php?p=2534328 or https://github.com/bloodgit/TF2-Dodgeball
3. Dodgeball Redux by ClassicGuzzi : https://forums.alliedmods.net/showthread.php?p=2226728 or https://github.com/ClassicSpeed/dodgeball
4. friagram for his flag airblast prevention : https://forums.alliedmods.net/showthread.php?t=219056
5. BloodyNightmare and Mitchell for the original airblast prevention plugin : https://forums.alliedmods.net/showthread.php?t=233475
