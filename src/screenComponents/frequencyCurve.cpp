#include "frequencyCurve.h"
#include "playerInfo.h"
#include "i18n.h"
#include "tween.h"

#include "components/beamweapon.h"
#include "components/shields.h"

#include "gui/theme.h"

GuiFrequencyCurve::GuiFrequencyCurve(GuiContainer* owner, string id, FrequencyType frequency_type, DamageEffect damage_effect)
: GuiPanel(owner, id), frequency_type(frequency_type), damage_effect(damage_effect)
{
}

void GuiFrequencyCurve::onDraw(sp::RenderTarget& renderer)
{
    GuiPanel::onDraw(renderer);

    if (frequency >= 0 && frequency <= BeamWeaponSys::max_frequency)
    {
        if (enemy_has_equipment)
        {
            float w = (rect.size.x - 40.0f) / (static_cast<float>(BeamWeaponSys::max_frequency) + 1.0f);
            int arrow_index = -1;

            if (frequency_type == FrequencyType::Beam)
            {
                if (auto shields = my_spaceship.getComponent<Shields>())
                    arrow_index = shields->frequency;
            }
            else if (my_spaceship)
            {
                if (auto beamsystem = my_spaceship.getComponent<BeamWeaponSys>())
                    arrow_index = beamsystem->frequency;
            }

            for (int n = 0; n <= BeamWeaponSys::max_frequency; n++)
            {
                float x = rect.position.x + 20.0f + w * n;
                float f;

                if (frequency_type == FrequencyType::Beam)
                    f = frequencyVsFrequencyDamageFactor(frequency, n);
                else
                    f = frequencyVsFrequencyDamageFactor(n, frequency);

                f = Tween<float>::linear(f, 0.5f, 1.5f, 0.1f, 1.0f);
                float h = (rect.size.y - 50.0f) * f;
                sp::Rect bar_rect(x, rect.position.y + rect.size.y - 10.0f - h, w * 0.8f, h);

                const int freq_damage_color = static_cast<int>(255.0f * (1.0f - f));

                if (damage_effect == DamageEffect::Positive)
                    renderer.fillRect(bar_rect, glm::u8vec4(freq_damage_color, static_cast<int>(255.0f * f), 0, 255));
                else
                    renderer.fillRect(bar_rect, glm::u8vec4(static_cast<int>(255.0f * f), freq_damage_color, 0, 255));

                if (n == arrow_index)
                    renderer.drawRotatedSprite(theme->getStyle("frequencycurve.indicator")->get(getState()).texture, glm::vec2(x + w * 0.5f, rect.position.y + rect.size.y - 20.0f - h), w, -90.0f);
            }

            int mouse_freq_nr = static_cast<int>((mouse_position.x - rect.position.x - 20.0f) / w);

            string text = "";
            if (rect.contains(mouse_position) && mouse_freq_nr >= 0 && mouse_freq_nr <= BeamWeaponSys::max_frequency)
            {
                if (frequency_type == FrequencyType::Beam)
                {
                    text = tr("{freq} {percent}% dmg").format({
                        {"freq", frequencyToString(mouse_freq_nr)},
                        {"percent", string(static_cast<int>(frequencyVsFrequencyDamageFactor(frequency, mouse_freq_nr) * 100.0f))}
                    });
                }
                else
                {
                    text = tr("{freq} {percent}% dmg").format({
                        {"freq", frequencyToString(mouse_freq_nr)},
                        {"percent", string(static_cast<int>(frequencyVsFrequencyDamageFactor(mouse_freq_nr, frequency) * 100.0f))}
                    });
                }
            }
            else
            {
                if (damage_effect == DamageEffect::Positive)
                    text = tr("scienceFrequencyGraph", "Damage with your beams");
                else
                    text = tr("scienceFrequencyGraph", "Damage to your shields");
            }

            renderer.drawText(sp::Rect(rect.position.x, rect.position.y, rect.size.x, 40.0f), text, sp::Alignment::Center, 20);
        } // end if enemy_has_equipment
        else
        {
            if (frequency_type == FrequencyType::Beam)
                renderer.drawText(rect, tr("scienceFrequencyGraph", "No target beam data"), sp::Alignment::Center, 30);
            else
                renderer.drawText(rect, tr("scienceFrequencyGraph", "No target shield data"), sp::Alignment::Center, 30);
        }
    }
    else
    {
        if (frequency_type == FrequencyType::Beam)
            renderer.drawText(rect, tr("scienceFrequencyGraph", "No target beam data"), sp::Alignment::Center, 30);
        else
            renderer.drawText(rect, tr("scienceFrequencyGraph", "No target shield data"), sp::Alignment::Center, 30);
    }
}

void GuiFrequencyCurve::drawElements(glm::vec2 mouse_position, GuiElement* hovered_element, sp::RenderTarget& window)
{
    this->mouse_position = mouse_position;
    GuiContainer::drawElements(mouse_position, hovered_element, window);
}
