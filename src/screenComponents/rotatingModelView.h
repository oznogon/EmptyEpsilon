#ifndef ROTATING_MODEL_VIEW_H
#define ROTATING_MODEL_VIEW_H

#include "gui/gui2_element.h"
#include "modelData.h"

class GuiRotatingModelView : public GuiElement
{
private:
    P<ModelData> model;
    float rotation_rate = 10.0f;
    float rotation_angle = 0.0f;
public:
    GuiRotatingModelView(GuiContainer* owner, string id, P<ModelData> model);
    GuiRotatingModelView* setRotationRate(float rate);
    GuiRotatingModelView* rotateTo(float angle);

    virtual void onDraw(sp::RenderTarget& target) override;
};

#endif//ROTATING_MODEL_VIEW_H
