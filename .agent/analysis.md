# SDL2 to SDL3 Port Analysis

## Current State

### SeriousProton
- CMakeLists.txt already configured for SDL3 (line 31: `find_package(SDL3 REQUIRED CONFIG)`)
- Still has some SDL2 references in install logic (line 442)
- 27 C++ files contain SDL references

### EmptyEpsilon
- CMakeLists.txt still references SDL2 in comments and macOS packaging
- 17 C++ files contain SDL references
- Depends on SeriousProton for SDL functionality

## Key Areas to Port

### SeriousProton Files with SDL Usage:
- Window management: `src/windowManager.cpp`, `src/windowManager.h`
- Graphics/OpenGL: `src/graphics/opengl.cpp`, `src/graphics/opengl.h`
- Input handling: `src/io/keybinding.cpp`, `src/io/keybinding.h`
- Audio: `src/audio/source.cpp`, `src/audio/source.h`
- Engine core: `src/engine.cpp`, `src/engine.h`
- Platform integration: `src/P.cpp`, `src/P.h`

### EmptyEpsilon Files with SDL Usage:
- Main entry point: `src/main.cpp`
- Display initialization: `src/init/displaywindows.cpp`
- Options/preferences: `src/menus/optionsMenu.cpp`, `src/preferenceManager.cpp`
- GUI components: `src/gui/gui2_textentry.cpp`, `src/gui/hotkeyConfig.h`

## SDL2 to SDL3 Major Changes to Handle:
1. Header restructuring (`SDL.h` → separate headers)
2. Event handling API changes
3. Window creation API changes
4. Audio API changes
5. Input handling API changes
6. Surface/texture API changes

## Strategy:
1. Start with SeriousProton (core engine)
2. Port EmptyEpsilon after SeriousProton is stable
3. Focus on compilation first, then runtime testing
4. Write validation tests for critical functionality