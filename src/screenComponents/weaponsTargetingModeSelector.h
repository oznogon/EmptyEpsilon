#ifndef WEAPONS_TARGETING_MODE_SELECTOR_H
#define WEAPONS_TARGETING_MODE_SELECTOR_H

#include "gui/gui2_toggleslider.h"

class GuiLabel;

class GuiWeaponsTargetingModeSelector : public GuiToggleSlider
{
private:
    GuiLabel* mode_label;

public:
    GuiWeaponsTargetingModeSelector(GuiContainer* owner, string id);

    virtual void onUpdate() override;
};

#endif//WEAPONS_TARGETING_MODE_SELECTOR_H
