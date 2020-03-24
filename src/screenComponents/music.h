#ifndef MUSIC_H
#define MUSIC_H

#include "stringImproved.h"
#include "threatLevelEstimate.h"

class Music
{
private:
    P<ThreatLevelEstimate> threat_estimate;
    string music_file;
public:
    Music(bool enabled);
    bool is_enabled;

    virtual void play(string music_file);
    virtual void playSet(string music_files);
    virtual void stop();
    virtual void playThreatSet();
};

#endif//MUSIC_H
