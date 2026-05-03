#pragma once

#include "gui/gui2_overlay.h"

class GuiImage;
class GuiLabel;
class GuiViewport3D;

class ProbeScreen : public GuiOverlay
{
private:
    GuiImage* background_gradient;
    GuiViewport3D* viewport;
    GuiLabel* no_probe_label;
public:
    ProbeScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
};
