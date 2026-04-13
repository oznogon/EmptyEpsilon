#pragma once

#include "gui/gui2_overlay.h"
#include "gui/joystickConfig.h"

class GuiKeyValueDisplay;
class GuiLabel;
class GuiTooltip;
class GuiRadarView;
class GuiDockingButton;
class GuiCombatManeuver;

class HelmsScreen : public GuiOverlay
{
private:
    GuiOverlay* background_crosses;
    GuiRadarView* radar;

    GuiTooltip* heading_hint;
    GuiLabel* heading_label;
    GuiCombatManeuver* combat_maneuver;
    GuiDockingButton* docking_button;
public:
    HelmsScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};
