#include "music.h"
// #include "playerInfo.h"
// #include "spaceObjects/playerSpaceship.h"
// #include "preferenceManager.h"

Music::Music(bool enabled)
{
    is_enabled = enabled;
}

void Music::play(string music_file)
{
    // Play the new song.
    if (is_enabled)
        soundManager->playMusic(music_file);
}

void Music::playSet(string music_files)
{
    // Play the new set of songs.
    if (is_enabled)
        soundManager->playMusicSet(findResources(music_files));
}

void Music::stop()
{
    soundManager->stopMusic();
}

void Music::playThreatSet()
{
    threat_estimate = new ThreatLevelEstimate();

    // Handle threat level change events.
    threat_estimate->setCallbacks([this](){
        // Low threat function
        LOG(INFO) << "Switching to ambient music";
        this->playSet("music/ambient/*.ogg");
    }, [this]() {
        // High threat function
        LOG(INFO) << "Switching to combat music";
        this->playSet("music/combat/*.ogg");
    });
}
