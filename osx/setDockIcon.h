#pragma once

// Explicitly set the macOS dock icon from the app bundle's icon resource.
// Must be called after SDL_Init, which initializes NSApplication.
void setMacOSDockIcon();
