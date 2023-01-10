#include <sys/stat.h>
#include "shipSound.h"
#include "playerInfo.h"
#include "spaceObjects/playerSpaceship.h"
#include "preferenceManager.h"
#include "soundManager.h"

ShipSound::ShipSound()
{
    // An ID of -1 won't play.
    id = -1;
    enabled = false;
    played = false;
    looping = false;
    volume = 0.0f;
    pitch = 0.0f;
    filename = "";
}

ShipSound::~ShipSound()
{
    if (soundManager) {
        soundManager->stopSound(id);
    }
}

void ShipSound::play()
{
    // As a player, play ship sounds only on my ship.
    if (!my_spaceship) {
        return;
    }

    // If there's already a sound playing on this ID, stop it.
    if (id > -1) {
        soundManager->stopSound(id);
    }

    // Play the new sound and store its integer ID in the class.
    id = soundManager->playSound(filename, volume, pitch, looping);
    LOG(INFO) << "ShipSound::play(): Playing ship sound " << filename << " on sound id " << id;

    if (id > -1) {
        played = true;
    } else {
        played = false;
    }
}

void ShipSound::stop()
{
    soundManager->stopSound(id);
    id = -1;
}

void ShipSound::setFilename(string name)
{
    filename = name;
}

void ShipSound::update(float delta)
{
    // Update only if this sound has a defined ID.
    if (id > -1) {
        // If so, update the pitch and volume.
        soundManager->setSoundPitch(id, pitch);
        soundManager->setSoundVolume(id, volume);
    }
}
