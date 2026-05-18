#pragma once

#include "gui/gui2_overlay.h"
#include "gui/joystickConfig.h"
#include "screenComponents/targetsContainer.h"

class AimLock;
class AimLockButton;
class GuiImage;
class GuiKeyValueDisplay;
class GuiLabel;
class GuiMissileTubeControls;
class GuiRadarView;

class MissileWeaponsScreen : public GuiOverlay
{
private:
    GuiImage* background_gradient;
    GuiOverlay* background_crosses;
    GuiElement* missile_controls;
    GuiLabel* no_weapons_label;

    GuiRadarView* radar;
    TargetsContainer targets;
    GuiKeyValueDisplay* energy_display;
    GuiMissileTubeControls* tube_controls;
    AimLock* missile_aim;
    AimLockButton* lock_aim;
public:
    MissileWeaponsScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};
