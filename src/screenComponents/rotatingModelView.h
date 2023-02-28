#ifndef ROTATING_MODEL_VIEW_H
#define ROTATING_MODEL_VIEW_H

#include "gui/gui2_element.h"
#include "modelData.h"

class GuiRotatingModelView : public GuiElement
{
private:
    P<ModelData> model;

    const float camera_fov;
    glm::vec3 translation;
    float rotation_rate;
    float x_rotation_angle;
    float y_rotation_angle;
    float z_rotation_angle;
public:
    GuiRotatingModelView(GuiContainer* owner, string id, P<ModelData> model);

    GuiRotatingModelView* setRotationRate(float rate);
    GuiRotatingModelView* translateTo(glm::vec3 coordinates);
    GuiRotatingModelView* rotateXTo(float angle);
    GuiRotatingModelView* rotateYTo(float angle);
    GuiRotatingModelView* rotateZTo(float angle);

    virtual void onDraw(sp::RenderTarget& target) override;
};

#endif//ROTATING_MODEL_VIEW_H
