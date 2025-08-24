// Simple test to verify SDL3 migration syntax
#include <SDL3/SDL.h>

int main() {
    // Test basic SDL3 initialization
    if (!SDL_Init(SDL_INIT_EVERYTHING)) {
        SDL_Log("Failed to initialize SDL: %s", SDL_GetError());
        return 1;
    }
    
    // Test SDL3 IOStream (replaces SDL_RWops)
    SDL_IOStream* stream = SDL_IOFromFile("test.txt", "w");
    if (stream) {
        const char* test_data = "Hello SDL3";
        SDL_WriteIO(stream, test_data, strlen(test_data));
        SDL_CloseIO(stream);
    }
    
    // Test SDL3 audio stream (replaces callbacks)
    SDL_AudioSpec spec;
    spec.freq = 44100;
    spec.format = SDL_AUDIO_S16SYS;
    spec.channels = 2;
    
    SDL_AudioStream* audio_stream = SDL_OpenAudioDeviceStream(
        SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, 
        &spec, 
        nullptr,
        nullptr
    );
    
    if (audio_stream) {
        SDL_DestroyAudioStream(audio_stream);
    }
    
    // Test SDL3 events
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        switch(event.type) {
            case SDL_EVENT_QUIT:
                return 0;
            case SDL_EVENT_KEY_DOWN:
                SDL_Log("Key pressed: %d", event.key.key);
                break;
            case SDL_EVENT_MOUSE_BUTTON_DOWN:
                SDL_Log("Mouse button pressed");
                break;
        }
    }
    
    SDL_Quit();
    return 0;
}