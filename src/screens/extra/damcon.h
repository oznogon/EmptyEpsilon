#pragma once

#include "gui/gui2_overlay.h"
#include "components/shipsystem.h"

class GuiKeyValueDisplay;
class GuiShipInternalView;
class GuiProgressbar;

class DamageControlScreen : public GuiOverlay
{
private:
    // Connective line properties
    struct LineInfo
    {
        unsigned int system_idx;
        glm::vec2 room_center;
        glm::vec2 start;
        glm::u8vec4 color;
        float y_offset = 0.0f;
    };

    GuiShipInternalView* internal_view;
    float room_size = 72.0f; // 48.0f * 1.5f
    GuiKeyValueDisplay* hull_display;
    GuiKeyValueDisplay* shield_display;
    GuiKeyValueDisplay* energy_display;
    GuiElement* system_group[ShipSystem::COUNT];
    GuiKeyValueDisplay* system_health[ShipSystem::COUNT];
    GuiProgressbar* power_bar[ShipSystem::COUNT];
    GuiProgressbar* health_bar[ShipSystem::COUNT];
    GuiProgressbar* heat_bar[ShipSystem::COUNT];
    GuiProgressbar* coolant_bar[ShipSystem::COUNT];
    int line_mode = 0; // 0 = 5px only, 1 = all lines, 2 = no lines
public:
    DamageControlScreen(GuiContainer* owner);

    void onDraw(sp::RenderTarget& target) override;
protected:
    void drawElements(glm::vec2 mouse_position, sp::Rect parent_rect, sp::RenderTarget& renderer) override;
};
