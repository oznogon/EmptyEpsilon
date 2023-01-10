#ifndef SHIP_SOUND_H
#define SHIP_SOUND_H

#include "stringImproved.h"

class ShipSound
{
private:
    int id;
    bool enabled;
    bool played;
    bool looping;
    float volume;
    float pitch;
    string filename;
public:
    ShipSound();
    ~ShipSound();

    int getID() { return id; }
    bool isEnabled() { return enabled; }
    void setEnabled(bool e) { enabled = e; }
    bool hasPlayed() { return played; }
    void setPlayed(bool p) { played = p; }
    bool isLooping() { return looping; }
    void setLooping(bool e) { looping = e; }
    float getVolume() { return volume; }
    void setVolume(float v) { if (v >= 0.0f && v <= 100.0f) volume = v; }
    float getPitch() { return pitch; }
    void setPitch(float p) { if (p >= 0.0f && p <= 10.0f) pitch = p; }
    string getFilename() { return filename; }
    void setFilename(string name);

    void play();
    void stop();
    void update(float delta);
};

#endif//SHIP_SOUND_H
