#pragma once

#include "gui/gui2_panel.h"

class GuiFrequencyCurve : public GuiPanel
{
public:
    enum class FrequencyType
    {
        Beam,
        Other
    };

    enum class DamageEffect
    {
        Positive,
        Negative
    };

private:
    FrequencyType frequency_type;
    DamageEffect damage_effect;
    bool enemy_has_equipment; // True if target ship has beams/shields (which of those depends on frequency_type)

    int frequency = -1;
    glm::vec2 mouse_position;
public:
    GuiFrequencyCurve(GuiContainer* owner, string id, FrequencyType frequency_type, DamageEffect damage_effect);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void drawElements(glm::vec2 mouse_position, GuiElement* hovered_element, sp::RenderTarget& window) override;

    GuiFrequencyCurve* setFrequency(int frequency) { this->frequency = frequency; return this; }

    void setEnemyHasEquipment(bool state) { this->enemy_has_equipment = state; }
};
