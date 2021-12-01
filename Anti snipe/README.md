This subplugin can be used to toggle collision and / or damage on clients if they are a rocket's target.

Due to the way this subplugin works, it will cause issues on versions pre 1.5 (the `on no target` event is not present).

# Commands
```c
    tf_dodgeball_nosnipe - Changes collision and / or damage on the target and other players accordingly.
```

# Convars
```c
    tf_dodgeball_antisnipe    "1" - Enable anti-sniping?
    tf_dodgeball_as_damage    "1" - Hook damage for anti-sniping?
    tf_dodgeball_as_collision "1" - Change player collisions for anti-sniping?
```

# Notes
When using multi rocket configs, make sure all rockets that spawn use anti-snipe in their configuration.

Doing otherwise may lead to unexpected results (rockets going through people, not damaging the target etc.).

# Usage
The `tf_dodgeball_nosnipe` requires 2 arguments : the rocket's target (`@target`) and the rocket entity (`@rocket`), in this ***exact*** order.

The command along the necessary arguments must be placed in all the events that update a rocket's target.

Those events are : `on spawn`, `on deflect` and `on no target`.

Example (in the dodgeball config):

```c
   // >>> Events <<<
   "on spawn"     "tf_dodgeball_nosnipe @target @rocket"
   "on deflect"   "tf_dodgeball_nosnipe @target @rocket"
   "on kill"      "..."
   "on explode"   "..."
   "on no target" "tf_dodgeball_nosnipe @target @rocket"
```
