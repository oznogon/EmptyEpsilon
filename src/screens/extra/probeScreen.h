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
    float mouse_turn_direction = 0.0f;
public:
    ProbeScreen(GuiContainer* owner);

    virtual void onUpdate() override;
    virtual void onDraw(sp::RenderTarget& target) override;
    virtual bool onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id) override;
    virtual void onMouseUp(glm::vec2 position, sp::io::Pointer::ID id) override;
};
