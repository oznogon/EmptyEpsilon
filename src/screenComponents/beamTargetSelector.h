#pragma once

#include "gui/gui2_selector.h"

class GuiBeamTargetSelector : public GuiSelector
{
public:
    GuiBeamTargetSelector(GuiContainer* owner, string id);

    virtual void onUpdate() override;
};
