#pragma once

#include "gui/gui2_overlay.h"

class GuiLabel;

class CommsScreen : public GuiOverlay
{
public:
    CommsScreen(GuiContainer* owner);

    void onUpdate() override;
private:
    GuiLabel* no_comms_label;
};
