#pragma once

#include "gui/gui2_selector.h"

class GuiBeamFrequencySelector : public GuiSelector
{
public:
    GuiBeamFrequencySelector(GuiContainer* owner, string id);

    virtual void onUpdate() override;
};
