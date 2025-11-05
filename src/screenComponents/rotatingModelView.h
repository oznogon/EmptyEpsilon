#pragma once

#include "gui/gui2_element.h"
#include "components/rendering.h"

class GuiRotatingModelView : public GuiElement
{
private:
    sp::ecs::Entity &entity;
    float zoom_factor;
    float height;
    float angle;
public:
    GuiRotatingModelView(GuiContainer* owner, string id, sp::ecs::Entity& entity);

    virtual void onDraw(sp::RenderTarget& target) override;

    void setCameraZoomFactor(float new_factor);
    float getCameraZoomFactor() { return zoom_factor; }
    bool is_rotating;
    void setCameraRotation(float new_angle);
    float getCameraRotation() { return angle; }
    void setCameraHeight(float new_height);
    float getCameraHeight() { return height; }
};
