This subplugin can be used to toggle collision and / or damage on clients if they are a rocket's target.

Due to the way this subplugin works, it will cause issues on versions pre 1.5 (the `on no target` event is not present, nor is the `TFDB_OnRocketNoTarget` forward present).

# Convars
```c
    tf_dodgeball_antisnipe    "1" - Enable anti-sniping?
    tf_dodgeball_as_damage    "1" - Hook damage for anti-sniping?
    tf_dodgeball_as_collision "1" - Change player collisions for anti-sniping?
```
