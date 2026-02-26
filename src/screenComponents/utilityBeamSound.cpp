#include "utilityBeamSound.h"

#include "soundManager.h"
#include "playerInfo.h"
#include "components/utilityBeam.h"
#include "gui/theme.h"
#include "gui/gui2_element.h"

#include <algorithm>


UtilityBeamSound::UtilityBeamSound()
{
    auto beam_style = GuiTheme::getCurrentTheme()->getStyle("utility_beam.active");
    if (beam_style)
        beam_sound_file = beam_style->get(GuiElement::State::Normal).sound;

    if (!beam_sound_file.empty())
        beam_sound_id = soundManager->playSound(beam_sound_file, 0.0f, 0.0f, true);
}

UtilityBeamSound::~UtilityBeamSound()
{
    if (soundManager && beam_sound_id != -1)
    {
        soundManager->stopSound(beam_sound_id);
        beam_sound_id = -1;
    }
}

void UtilityBeamSound::update(float delta)
{
    if (beam_sound_id == -1)
        return;

    if (!my_spaceship)
    {
        soundManager->setSoundVolume(beam_sound_id, 0.0f);
        beam_audible = false;
        beam_fading_out = false;
        return;
    }

    if (auto utility_beam = my_spaceship.getComponent<UtilityBeam>())
    {
        if (utility_beam->is_firing)
        {
            if (!beam_audible)
            {
                beam_audible = true;
                beam_fading_out = false;
                beam_fade_timer.start(FADE_IN_DURATION);
            }
            else if (beam_fading_out)
            {
                beam_fading_out = false;
                beam_fade_timer.start(FADE_IN_DURATION);
            }

            float effectiveness = utility_beam->getSystemEffectiveness();
            if (effectiveness <= 0.0f)
            {
                soundManager->setSoundVolume(beam_sound_id, 0.0f);
            }
            else
            {
                float target_volume = 100.0f * std::min(effectiveness, 1.0f);
                float target_pitch = std::max(1.0f, 1.0f + (effectiveness - 1.0f) * 0.15f);
                float t = std::min(beam_fade_timer.getProgress(), 1.0f);
                soundManager->setSoundVolume(beam_sound_id, t * target_volume);
                soundManager->setSoundPitch(beam_sound_id, 0.5f + t * (target_pitch - 0.5f));
            }
        }
        else
        {
            if (beam_audible && !beam_fading_out)
            {
                beam_fading_out = true;
                beam_fade_timer.start(FADE_OUT_DURATION);
            }

            if (beam_fading_out)
            {
                float progress = beam_fade_timer.getProgress();
                if (progress >= 1.0f)
                {
                    soundManager->setSoundVolume(beam_sound_id, 0.0f);
                    beam_audible = false;
                    beam_fading_out = false;
                }
                else
                {
                    float effectiveness = utility_beam->getSystemEffectiveness();
                    float target_volume = 100.0f * std::min(effectiveness, 1.0f);
                    float target_pitch = std::max(1.0f, 1.0f + (effectiveness - 1.0f) * 0.15f);
                    float t = 1.0f - progress;
                    soundManager->setSoundVolume(beam_sound_id, t * target_volume);
                    soundManager->setSoundPitch(beam_sound_id, 0.5f + t * (target_pitch - 0.5f));
                }
            }
            else
            {
                soundManager->setSoundVolume(beam_sound_id, 0.0f);
            }
        }
    }
    else
    {
        soundManager->setSoundVolume(beam_sound_id, 0.0f);
        beam_audible = false;
        beam_fading_out = false;
    }
}
