#pragma once

#include "gui/gui2_element.h"
#include "components/rendering.h"
#include <graphics/renderTexture.h>
#include <memory>

class GuiRenderedModelSprite : public GuiElement
{
private:
    sp::ecs::Entity &entity;
    std::unique_ptr<sp::RenderTexture> render_texture;
    float zoom_factor;
    float height;
    float angle;
    bool needs_rerender;
    glm::ivec2 last_render_size;

public:
    GuiRenderedModelSprite(GuiContainer* owner, string id, sp::ecs::Entity& entity);

    virtual void onDraw(sp::RenderTarget& target) override;

    void setCameraZoomFactor(float new_factor);
    float getCameraZoomFactor() { return zoom_factor; }
    bool is_rotating;
    void setCameraRotation(float new_angle);
    float getCameraRotation() { return angle; }
    void setCameraHeight(float new_height);
    float getCameraHeight() { return height; }

private:
    bool renderToTexture(glm::ivec2 size);
};
