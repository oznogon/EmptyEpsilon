# SDL3 Migration Plan for EmptyEpsilon and SeriousProton

## Overview
Porting from SDL2 to SDL3 with breaking changes. SeriousProton is the engine layer that EmptyEpsilon depends on, so we'll port SeriousProton first.

## Key Changes Required

### Header Changes
- `#include <SDL.h>` → `#include <SDL3/SDL.h>`
- `#include <SDL_*.h>` → `#include <SDL3/SDL_*.h>`

### Function Return Values
- Many functions changed from returning negative error codes to returning `bool`
- Error checking: `if (SDL_Function() < 0)` → `if (!SDL_Function())`

### Major API Changes
1. **Audio System**: Complete redesign using SDL_AudioStream
2. **Event System**: 
   - Timestamps now in nanoseconds
   - Event constants renamed (SDL_KEYDOWN → SDL_EVENT_KEY_DOWN)
   - Mouse events use floating-point coordinates
3. **I/O System**: SDL_RWops → SDL_IOStream
4. **Controllers**: SDL_gamecontroller → SDL_gamepad APIs

### Build System Changes
- CMake: Use `find_package(SDL3 REQUIRED CONFIG)`
- Update SDL dependency versions

## Migration Strategy

### Phase 1: SeriousProton Engine
Priority files (high SDL usage):
- src/engine.cpp/h - Main engine initialization
- src/windowManager.cpp/h - Window and context management  
- src/io/keybinding.cpp/h - Input handling
- src/graphics/opengl.cpp/h - Graphics context
- src/audio/source.cpp/h - Audio system
- src/P.cpp/h - Platform layer

### Phase 2: EmptyEpsilon Application
Priority files:
- src/main.cpp - Application entry point
- src/gui/hotkeyConfig.h - Input configuration
- CMakeLists.txt - Build configuration

### Phase 3: Testing and Validation
- Create basic functionality tests
- Test audio, input, rendering subsystems
- Validate multiplayer networking still works

## File Analysis Summary

### SeriousProton Files with SDL (27 files)
Most critical for porting:
- Engine core: engine.cpp/h, P.cpp/h, windowManager.cpp/h
- Graphics: opengl.cpp/h, renderTarget.cpp, texture.cpp, shader.cpp
- Audio: audio/source.cpp/h
- Input: io/keybinding.cpp/h
- Resources: resources.cpp, image.cpp

### EmptyEpsilon Files with SDL (15 files)  
- main.cpp, init/displaywindows.cpp - initialization
- gui/hotkeyConfig.h, gui/gui2_textentry.cpp - input
- Various game logic files with minimal SDL usage

## Next Steps
1. Research specific SDL3 API replacements
2. Start with SeriousProton engine core files
3. Update build system configuration
4. Port EmptyEpsilon application layer
5. Create minimal test suite