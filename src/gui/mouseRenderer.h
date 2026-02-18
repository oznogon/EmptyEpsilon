#pragma once

#include "Renderable.h"

class MouseRenderer : public Renderable
{
public:
    // Override default visibility
    bool should_be_visible = true;

    MouseRenderer(RenderLayer* render_layer);

    virtual void render(sp::RenderTarget& window) override;
    virtual bool onPointerMove(glm::vec2 position, sp::io::Pointer::ID id) override;
    virtual void onPointerLeave(sp::io::Pointer::ID id) override;
    virtual void onPointerDrag(glm::vec2 position, sp::io::Pointer::ID id) override;

    bool isVisible() { return is_visible; }
    void setSpriteImage(string sprite_image) { sprite = sprite_image; }
private:
    glm::vec2 position;
    glm::vec2 raw_delta;
    string sprite = "mouse.png";
    bool is_visible = true;
};
