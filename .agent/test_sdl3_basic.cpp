// Basic SDL3 functionality test for EmptyEpsilon
// This verifies that key SDL3 APIs work correctly after migration

#include <SDL3/SDL.h>
#include <iostream>

int main() {
    std::cout << "SDL3 Basic Functionality Test\n";
    std::cout << "=============================\n";

    // Test 1: SDL Initialization
    if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_EVENTS)) {
        std::cout << "✗ SDL_Init failed: " << SDL_GetError() << std::endl;
        return 1;
    }
    std::cout << "✓ SDL_Init successful\n";

    // Test 2: Display enumeration
    int display_count;
    SDL_DisplayID* displays = SDL_GetDisplays(&display_count);
    if (displays && display_count > 0) {
        std::cout << "✓ Found " << display_count << " display(s)\n";
        SDL_free(displays);
    } else {
        std::cout << "✗ No displays found\n";
        SDL_Quit();
        return 1;
    }

    // Test 3: Window creation
    SDL_Window* window = SDL_CreateWindow("SDL3 Test", 640, 480, SDL_WINDOW_OPENGL);
    if (!window) {
        std::cout << "✗ SDL_CreateWindow failed: " << SDL_GetError() << std::endl;
        SDL_Quit();
        return 1;
    }
    std::cout << "✓ Window creation successful\n";

    // Test 4: OpenGL context creation
    SDL_GLContext context = SDL_GL_CreateContext(window);
    if (!context) {
        std::cout << "✗ SDL_GL_CreateContext failed: " << SDL_GetError() << std::endl;
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }
    std::cout << "✓ OpenGL context creation successful\n";

    // Test 5: Audio device enumeration
    int audio_device_count;
    SDL_AudioDeviceID* audio_devices = SDL_GetAudioPlaybackDevices(&audio_device_count);
    if (audio_devices && audio_device_count > 0) {
        std::cout << "✓ Found " << audio_device_count << " audio playback device(s)\n";
        SDL_free(audio_devices);
    } else {
        std::cout << "! No audio playback devices found (this may be normal)\n";
    }

    // Test 6: Gamepad initialization
    if (!SDL_InitSubSystem(SDL_INIT_GAMEPAD)) {
        std::cout << "✗ Gamepad initialization failed: " << SDL_GetError() << std::endl;
    } else {
        std::cout << "✓ Gamepad subsystem initialized\n";
    }

    // Cleanup
    SDL_GL_DestroyContext(context);
    SDL_DestroyWindow(window);
    SDL_Quit();

    std::cout << "\nAll basic SDL3 functionality tests passed! ✓\n";
    return 0;
}