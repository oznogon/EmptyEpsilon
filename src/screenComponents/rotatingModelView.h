#pragma once

#include "gui/gui2_element.h"
#include "components/rendering.h"

class GuiRotatingModelView : public GuiElement
{
private:
    sp::ecs::Entity &entity;
    float zoom_factor;
    float angle;
public:
    GuiRotatingModelView(GuiContainer* owner, string id, sp::ecs::Entity& entity);

    virtual void onDraw(sp::RenderTarget& target) override;

    void setZoomFactor(float new_factor) { zoom_factor = std::max(0.1f, new_factor); }
    float getZoomFactor() { return zoom_factor; }
    bool is_rotating;
    void setAngle(float new_angle);
    float getAngle() { return angle; }
};
