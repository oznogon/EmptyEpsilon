#pragma once

#include "gui/gui2_overlay.h"

class GuiViewport3D;
class GuiLabel;

class ProbeScreen : public GuiOverlay
{
private:
    GuiViewport3D* viewport;
    GuiLabel* no_probe_label;
public:
    ProbeScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
};
