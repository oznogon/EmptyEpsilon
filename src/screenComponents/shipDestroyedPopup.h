#pragma once

#include "gui/gui2_element.h"
#include "timer.h"

class GuiCanvas;
class GuiOverlay;

class GuiShipDestroyedPopup : public GuiElement
{
private:
    GuiOverlay* ship_destroyed_overlay;
    GuiCanvas* owner;
    sp::SystemTimer show_timeout;
public:
    GuiShipDestroyedPopup(GuiCanvas* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
};
