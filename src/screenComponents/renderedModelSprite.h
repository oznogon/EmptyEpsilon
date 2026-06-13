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
    float zoom_factor = 1.0f;
    float height = -1.0f;
    float angle = 90.0f;
    bool needs_rerender = true;
    glm::ivec2 last_render_size{0, 0};
public:
    GuiRenderedModelSprite(GuiContainer* owner, string id, sp::ecs::Entity& entity);

    virtual void onDraw(sp::RenderTarget& target) override;

    void setCameraZoomFactor(float new_factor);
    float getCameraZoomFactor() { return zoom_factor; }
    void setCameraRotation(float new_angle);
    float getCameraRotation() { return angle; }
    void setCameraHeight(float new_height);
    float getCameraHeight() { return height; }
private:
    bool renderToTexture(glm::ivec2 size);
};
