# SDL Usage Analysis

## SeriousProton Files Using SDL2 (27 files)

### Core Engine Files
- **src/engine.h/cpp**: SDL_Event handling, main event loop
- **src/windowManager.h/cpp**: SDL window creation, OpenGL context, fullscreen handling
- **src/P.h**: SDL_assert for debugging

### Graphics System  
- **src/graphics/opengl.h/cpp**: OpenGL context management
- **src/graphics/renderTarget.cpp**: Rendering operations
- **src/graphics/texture.cpp**: Texture loading
- **src/graphics/shader.cpp**: Shader compilation
- **src/graphics/image.cpp**: Image loading
- **src/graphics/freetypefont.cpp**: Font rendering

### Audio System
- **src/audio/source.h/cpp**: Audio playback (major changes needed for SDL3)

### Input/IO System
- **src/io/keybinding.h/cpp**: Keyboard/gamepad input handling
- **src/clipboard.cpp**: Clipboard operations
- **src/resources.cpp**: Resource loading

### Network/Misc
- **src/multiplayer.h**: Network events
- **src/multiplayer_client.cpp**: Client networking
- **src/multiplayer_server.cpp**: Server networking 
- **src/networkRecorder.h/cpp**: Network recording
- **src/dynamicLibrary.cpp**: Dynamic loading
- **src/i18n.cpp**: Internationalization
- **src/logging.cpp**: Logging system

## EmptyEpsilon Files Using SDL2 (15 files)

### Application Layer
- **src/main.cpp**: Application initialization, event loop
- **src/init/displaywindows.cpp**: Display initialization

### GUI System
- **src/gui/hotkeyConfig.h**: Hotkey configuration
- **src/gui/gui2_textentry.cpp**: Text input

### Game Logic (minimal SDL usage)
- **src/screens/gm/gameMasterScreen.cpp**: GM interface
- **src/spaceObjects/spaceship.cpp**: Game objects
- **src/gameGlobalInfo.cpp**: Game state
- **src/GMActions.cpp**: GM actions
- **src/script.cpp**: Scripting
- **src/menus/optionsMenu.cpp**: Options menu
- **src/mesh.cpp**: 3D meshes
- **src/packResourceProvider.h/cpp**: Resource packs
- **src/particleEffect.cpp**: Particle effects
- **src/preferenceManager.cpp**: Settings

## SDL2 API Usage Patterns Found

### Headers
- `#include <SDL.h>` - Main SDL header
- `#include <SDL_assert.h>` - Assertions

### SDL Functions Used
- `SDL_Init()`, `SDL_Quit()` - Initialization
- `SDL_CreateWindow()`, `SDL_DestroyWindow()` - Window management
- `SDL_GL_CreateContext()`, `SDL_GL_DeleteContext()` - OpenGL context
- `SDL_GL_MakeCurrent()`, `SDL_GL_SwapWindow()` - OpenGL operations
- `SDL_GL_GetDrawableSize()` - Window size (removed in SDL3!)
- `SDL_SetWindowSize()`, `SDL_SetWindowFullscreen()` - Window operations
- `SDL_PollEvent()`, `SDL_WaitEvent()` - Event handling
- `SDL_GetTicks()` - Timing
- Various SDL_Event types for input

### SDL Types Used
- `SDL_Event` - Event structure
- `SDL_Window*` - Window handles
- `SDL_GLContext` - OpenGL context
- Various event-specific types

## Migration Priority

### Phase 1: Core Engine (SeriousProton)
1. Update build system (CMakeLists.txt)
2. Update headers (`#include <SDL3/SDL.h>`)
3. Fix function return value checks (error handling)
4. Port engine.cpp - event loop and initialization
5. Port windowManager.cpp - window and context management
6. Port P.h - replace SDL_assert
7. Port audio system (major changes required)
8. Port input/keybinding system

### Phase 2: EmptyEpsilon Application  
1. Update build dependency on SeriousProton
2. Port main.cpp initialization
3. Port GUI components
4. Fix remaining SDL references

## Key Challenges

1. **Audio System**: Complete redesign from callback-based to stream-based
2. **Event System**: Event constants renamed, different handling
3. **Function Return Values**: Many now return bool instead of int
4. **Removed Functions**: `SDL_GL_GetDrawableSize()` needs replacement
5. **Build System**: SDL3 uses different CMake configuration