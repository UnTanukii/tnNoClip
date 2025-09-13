# NoClip FiveM (Lua)

A simple freecam/no-clip script for FiveM, inspired by txAdmin

## Features

* Toggle noclip mode on/off for the player
* Smooth camera movement with configurable FOV and easing
* Configurable movement speed multipliers for normal, fast, and slow movement
* Optional particle effect when activating noclip
* Works with vehicles or mounts if the player is in one
* Prevents fall damage on deactivation
* Configurable keybinding to toggle noclip

## Installation

1. Place the `noclip` folder in your server resources
2. Add `start noclip` to your `server.cfg`

## Configuration

Example configuration:

```lua
NOCLIP_SETTINGS = {
    KEYBIND = 'F5', -- Keyboard key to toggle noclip

    COOLDOWN = 1000,
    LOOK_SENSITIVITY_X   = 5,
    LOOK_SENSITIVITY_Y   = 5,
    BASE_MOVE_MULTIPLIER = 0.85,
    FAST_MOVE_MULTIPLIER = 6,
    SLOW_MOVE_MULTIPLIER = 6,

    CONTROLS = {
        LOOK_X      = 1,           -- INPUT_LOOK_LR
        LOOK_Y      = 2,           -- INPUT_LOOK_UD
        MOVE_X      = 30,          -- INPUT_MOVE_LR
        MOVE_Y      = 31,          -- INPUT_MOVE_UD
        MOVE_Z      = {152, 153},  -- INPUT_PARACHUTE_BRAKE_LEFT / RIGHT
        MOVE_FAST   = 21,          -- INPUT_SPRINT
        MOVE_SLOW   = 19           -- INPUT_CHARACTER_WHEEL
        --Controls from: https://docs.fivem.net/docs/game-references/controls/
    },

    CAMERA = {
        FOV = 50.0,
        ENABLE_EASING = true,
        EASING_DURATION = 250,
        KEEP_POSITION = false,
        KEEP_ROTATION = false
    },

    PTFX = {
        DICT = 'core',
        ASSET = 'ent_dst_elec_fire_sp',
        SCALE = 1.75,
        DURATION = 1500,
        AUDIO = {
            NAME = 'ent_amb_elec_crackle',
            REF = 0,
        },
        LOOP = {
            AMOUNT = 7,
            DELAY = 75,
        },
    }
}
```

## Usage

* Press the configured key (default `F5`) to toggle noclip
* If the player is in a vehicle or on a mount, it will move with the player
* Particle effects play when activating noclip if enabled in the settings

## Keybinding

You can change the toggle key by updating the `KEYBIND` value in the configuration

## Dependencies

* **None** – works out of the box with FiveM

## License

MIT License. Free to use and modify