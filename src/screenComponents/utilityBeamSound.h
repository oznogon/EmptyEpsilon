#pragma once

#include "stringImproved.h"
#include "timer.h"

class UtilityBeamSound
{
private:
    int beam_sound_id = -1;
    string beam_sound_file;
    sp::SystemTimer beam_fade_timer;
    bool beam_audible = false;
    bool beam_fading_out = false;
    static constexpr float FADE_IN_DURATION = 0.3f;
    static constexpr float FADE_OUT_DURATION = 0.8f;
public:
    UtilityBeamSound();
    ~UtilityBeamSound();

    void update(float delta);
};
