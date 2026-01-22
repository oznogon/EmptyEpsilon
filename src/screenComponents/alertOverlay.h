#pragma once

#include "gui/gui2_element.h"
#include "gui/theme.h"

class GuiOverlay;
class GuiLabel;


class AlertLevelOverlay : public GuiElement
{
private:
    GuiThemeStyle::StateStyle alert_style;
    string alert_sprite;
public:
    AlertLevelOverlay(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
};
