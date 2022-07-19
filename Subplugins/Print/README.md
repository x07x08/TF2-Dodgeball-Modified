This subplugin can be used to print messages and replace the client indexes given by the main dodgeball plugin.

To replace an index, surround it in a pair of `"##"` (without quotes). 

[Example : `##@dead##`]

Colors are supported as well (uses [`multicolors.inc`](https://github.com/Bara/Multi-Colors/blob/master/addons/sourcemod/scripting/include/multicolors.inc) to compile).

[Example : `{steelblue}##@dead##{default}`]

# Commands
```c
    tf_dodgeball_print <text>            - Prints a message to chat and replaces client indexes inside a pair of '##'
    tf_dodgeball_print_c <client> <text> - Prints a message to a client and replaces client indexes inside a pair of '##'
```

# Credits
1. Smlib : [GitHub Link](https://github.com/bcserv/smlib)
2. Print by Matheus28 : [AlliedMods Link](https://forums.alliedmods.net/showthread.php?p=1363600)
