#pragma once

#include "Renderable.h"

class MouseRenderer : public Renderable
{
public:
    bool visible;

    MouseRenderer(RenderLayer* render_layer);

    virtual void render(sp::RenderTarget& window) override;
    virtual bool onPointerMove(glm::vec2 position, sp::io::Pointer::ID id) override;
    virtual void onPointerLeave(sp::io::Pointer::ID id) override;
    virtual void onPointerDrag(glm::vec2 position, sp::io::Pointer::ID id) override;
    virtual bool onRelativeMove(glm::vec2 raw_delta, sp::io::Pointer::ID id) override;
    virtual void onRelativeDrag(glm::vec2 raw_delta, sp::io::Pointer::ID id) override;

    void setSpriteImage(string sprite_image) { sprite = sprite_image; }
private:
    glm::vec2 position;
    glm::vec2 raw_delta;
    string sprite = "mouse.png";
};

