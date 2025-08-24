# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build System

EmptyEpsilon uses CMake for building. Key commands:

```bash
# Configure and build
mkdir _build && cd _build
cmake .. -G Ninja -DCPACK_GENERATOR="RPM" -DSERIOUS_PROTON_DIR=$PWD/../../SeriousProton/ -DCMAKE_BUILD_TYPE=RelWithDebInfo
ninja

# Run the game
(cd .. && _build/EmptyEpsilon)
```

The project depends on SeriousProton engine (configured via `SERIOUS_PROTON_DIR` CMake variable, defaults to `../SeriousProton`).

Optional features can be enabled:
- `WITH_DISCORD=ON` for Discord integration (Windows default: ON)
- `APK_WITH_PACKS=ON` for Android builds with 3D assets

## Architecture Overview

EmptyEpsilon is a spaceship bridge simulator written in C++ using the SeriousProton engine. The codebase follows an Entity-Component-System (ECS) architecture.

### Core Architecture Components

- **ECS System**: Entity-Component-System architecture with components in `src/components/` and systems in `src/systems/`
- **Multiplayer**: Networking layer in `src/multiplayer/` handles client-server synchronization
- **Scripting**: Lua scripting engine for scenarios, ship behaviors, and game logic
- **GUI**: Custom GUI system in `src/gui/` using immediate-mode rendering
- **Screens**: Different crew station interfaces in `src/screens/`

### Key Directories

- `src/components/` - ECS components (shields, weapons, scanning, etc.)
- `src/systems/` - ECS systems that operate on components
- `src/multiplayer/` - Networking synchronization for components
- `src/screens/` - UI screens for different crew positions (helm, weapons, engineering, etc.)
- `src/screenComponents/` - Reusable UI components for screens
- `src/gui/` - Low-level GUI framework
- `src/ai/` - AI behaviors for NPCs
- `scripts/` - Lua scripts for scenarios, ship templates, and game content

### Scripting System

EmptyEpsilon uses Lua extensively:

- **Scenarios**: Game missions and situations in `scripts/scenario_*.lua`
- **Ship Templates**: Ship definitions in `scripts/shipTemplates.lua` and `scripts/shiptemplates/`
- **Communication**: Default ship/station comm scripts in `scripts/comms_*.lua`
- **Utilities**: Helper functions in `scripts/utils.lua`, `scripts/ee.lua`, etc.

Core script files loaded by the engine:
- `scripts/factionInfo.lua` - Faction definitions
- `scripts/model_data.lua` - 3D model data
- `scripts/science_db.lua` - Science database content
- `scripts/shipTemplates.lua` - Ship template definitions

### Code Conventions

- Member variables use underscores: `zoom_level`
- Classes use HighCamelCase: `GuiSlider`
- Functions use lowCamelCase: `getZoomLevel`
- C++17 features are used (minimum macOS 10.15+ requirement)

### Development Workflow

1. Scripts can be modified and reloaded without rebuilding
2. C++ changes require compilation
3. Use `update_locale` target to update translation files
4. Game supports headless server mode for dedicated hosting
5. Hardware integration supported via `src/hardware/` for DMX lighting, etc.

### Testing and Scenarios

- Tutorial system in `scripts/tutorial/` for teaching gameplay
- Scenarios range from basic training to complex missions
- Game Master (GM) mode allows real-time scenario modification
- HTTP API available for external tools integration

The codebase emphasizes modularity through the ECS architecture, allowing for easy extension of game mechanics and features.