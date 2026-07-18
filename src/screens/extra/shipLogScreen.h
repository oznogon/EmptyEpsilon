#pragma once

#include "gui/gui2_overlay.h"

class GuiAdvancedScrollText;
class GuiCustomShipFunctions;

class ShipLogScreen : public GuiOverlay
{
private:
    GuiAdvancedScrollText* log_text;
    GuiCustomShipFunctions* custom_function_sidebar;
public:
    ShipLogScreen(GuiContainer* owner);

    void onDraw(sp::RenderTarget& target) override;
};
