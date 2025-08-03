# TF2 Dodgeball Modified

This project is a modified and updated version of the classic TF2 Dodgeball gamemode for SourceMod. It builds upon the work of several developers in the community to provide a stable, configurable, and extensible Dodgeball experience.

---
## ✨ Key Features

* **Advanced Gameplay Mechanics**: Incorporates essential features like **steal and delay prevention**, plus the popular **"keep direction"** feature from Dodgeball Redux.
* **Dual Homing Modes**: Choose between two distinct rocket behaviors: a modern, smooth `"homing"` and a classic, more direct `"legacy homing"`.
* **Extensive Rocket Customization**: Define rocket classes with unique models, sounds, speeds, turn rates, and damage properties via configuration files.
* **Rich Event System**: Use parameters like `@rocket`, `@owner`, and `@target` to trigger custom server commands on in-game events (`on spawn`, `on deflect`, `on kill`, `on explode`).
* **Performance Controls**: Set server-wide limits for rocket speed and turn rates to maintain balance and prevent extreme values.
* **Critical Bug Fixes**: Corrects long-standing issues, including looping explosion sounds, neutral rocket behavior, and incorrect spawn chances for 0% probability rocket classes.
* **Developer API**: A robust set of natives and forwards allows other developers to easily create addons that interact with the gamemode.

---
## 🚀 Installation

1.  **Download the Release**: Grab the latest release package from the repository.
2.  **Install the Main Plugin**:
    * Open the `TF2Dodgeball` folder from the download.
    * Copy the `addons` folder from within `TF2Dodgeball` and merge it into your server's `tf/` directory. This will correctly place the plugin, configurations, and translation files.
3.  **Install Subplugins (Optional)**:
    * Navigate to the `Subplugins` folder in the release package.
    * Choose a subplugin (e.g., `Menu`, `Trails`) and copy its contents into your server's `tf/addons/` directory if you need them.
4.  **Install Requirements**: Ensure the required dependencies (see below) are installed on your server.
5.  **Restart Your Server**: Either restart your server or change maps for the changes to take effect.

---
## 🔧 Requirements

* **Multi-Colors**: Only required if you are compiling the plugin from source. It is **not** needed on the server to run the pre-compiled `.smx` file. [Link](https://github.com/Bara/Multi-Colors).
* **CollisionHook** (Optional): Only required for the **Anti-Snipe** subplugin.
    * Download from [here](https://github.com/Adrianilloo/Collisionhook) or the original [AlliedModders thread](https://forums.alliedmods.net/showthread.php?t=197815).

---
## ⚙️ Configuration

* The core configuration is located in `addons/sourcemod/configs/dodgeball/general.cfg`. This is where you define rocket classes and spawners.
* **Map Naming**: The plugin automatically activates on maps with the `tfdb_` prefix. It will **not** activate on maps named `db_` or `dbs_` unless the source code is modified.
* You can create map-specific configs (e.g., `tfdb_mapname.cfg`) in the same directory to override the general settings for that map.

---
## 🎮 Commands & ConVars

### Server Commands
These commands can be used in your configuration files for event scripting.

| Command | Parameters | Description |
| :--- | :--- | :--- |
| `tf_dodgeball_explosion` | `<client_index>` | Creates a large visual explosion at the target client's location. |
| `tf_dodgeball_shockwave` | `<client> <damage> <force> <radius> <falloff>` | Applies a physics-based shockwave originating from the client. |

### Console Variables (ConVars)
```ini
// Gameplay
tf_dodgeball_sp_number        "3"     // How many steals before a player is slain.
tf_dodgeball_sp_damage        "0"     // If 1, reduces all damage on stolen rockets.
tf_dodgeball_sp_distance      "48.0"  // The minimum distance between players for a steal to register.
tf_dodgeball_delay_prevention "1"     // Enables the system to prevent players from delaying the round.
tf_dodgeball_dp_time          "5"     // Seconds before a rocket is considered "delayed" and starts speeding up.
tf_dodgeball_dp_speedup       "100"   // How many Hammer Units/sec are added to a delayed rocket's speed.
tf_dodgeball_redirect_damage  "1"     // If 1, reduces damage when a rocket's target is invalid (e.g., disconnects).

// Messaging
tf_dodgeball_sp_message       "1"     // Toggles the display of rocket steal messages in chat.
tf_dodgeball_dp_message       "1"     // Toggles the display of round delay messages in chat.

// Config Files
tf_dodgeball_enablecfg        "sourcemod/dodgeball_enable.cfg"  // Config file to execute when Dodgeball mode enables.
tf_dodgeball_disablecfg       "sourcemod/dodgeball_disable.cfg" // Config file to execute when Dodgeball mode disables.
```

---
## 👨‍💻 For Developers: API

The plugin exposes a full API via the `tfdb.inc` library, allowing for deep integration with other plugins.

**Key Forwards:**
* `TFDB_OnRocketCreated(int iIndex, int iEntity)`
* `TFDB_OnRocketDeflect(int iIndex, int iEntity, int iOwner)`
* `TFDB_OnRocketSteal(int iIndex, int iOwner, int iTarget, int iStealCount)`
* `TFDB_OnRocketNoTarget(int iIndex, int iTarget, int iOwner)`
* `TFDB_OnRocketBounce(int iIndex, int iEntity)`
* `TFDB_OnRocketStateChanged(int iIndex, RocketState iState, RocketState iNewState)`

Include `tfdb.inc` in your project to access these and the full list of natives for getting/setting rocket properties.

---
## ☢️ Optional: Nuke Model
The default configuration includes a `"nuke"` rocket class that uses a custom model. For the full experience, download and add it to your server's FastDL.
* **Download Link**: [AlliedModders Post](https://forums.alliedmods.net/showpost.php?s=8fa72450fa0c4941c927d01d2d6245c9&p=2180141&postcount=350)

---
## 🐞 Reporting Bugs
Please report any bugs or issues you encounter using the [**Issues**](https://github.com/x07x08/TF2-Dodgeball-Modified/issues) tab on GitHub.

---
## ❤️ Credits
* **The original YADB plugin by Damizean**: [AlliedMods Link](https://forums.alliedmods.net/showthread.php?t=134503)
* **The updated YADB plugin by bloody & lizzy**: [AlliedMods Link](https://forums.alliedmods.net/showthread.php?p=2534328) | [GitHub Account](https://github.com/keybangz)
* **Dodgeball Redux by ClassicGuzzi**: [AlliedMods Link](https://forums.alliedmods.net/showthread.php?p=2226728) | [GitHub Link](https://github.com/ClassicSpeed/dodgeball)
* **BloodyNightmare and Mitchell for the original airblast prevention plugin**: [AlliedMods Link](https://forums.alliedmods.net/showthread.php?t=233475)
* **Syntax converter batch by Dragokas**: [AlliedMods Link](https://forums.alliedmods.net/showpost.php?p=2593268&postcount=54)
