#pragma once

#include "gui/gui2_element.h"

class GuiOverlay;

class AlertLevelOverlay : public GuiElement
{
private:
    const float PULSE_PERIOD = 2.0f;

    string alert_sprite;
public:
    AlertLevelOverlay(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
};
