#pragma once

#include "gui2_button.h"

class GuiArrowButton : public GuiButton
{
protected:
    float angle;
public:
    GuiArrowButton(GuiContainer* owner, string id, float angle, func_t func);

    virtual void onDraw(sp::RenderTarget& renderer) override;
};
