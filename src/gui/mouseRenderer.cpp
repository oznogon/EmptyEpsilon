#include "mouseRenderer.h"
#include "main.h"

MouseRenderer::MouseRenderer(RenderLayer* render_layer)
: Renderable(render_layer)
{
    visible = true;
}

void MouseRenderer::render(sp::RenderTarget& renderer)
{
    if (!visible) return;

    renderer.drawSprite(sprite, position, 32.0f);
}

bool MouseRenderer::onPointerMove(glm::vec2 position, sp::io::Pointer::ID id)
{
    if (id == -1) {
        this->position = position;
        visible = true;
    }
    return false;
}

void MouseRenderer::onPointerLeave(sp::io::Pointer::ID id)
{
    if (id == -1)
        visible = false;
}

void MouseRenderer::onPointerDrag(glm::vec2 position, sp::io::Pointer::ID id)
{
    if (id == -1) {
        this->position = position;
        visible = true;
    }
}

void MouseRenderer::onRelativeDrag(glm::vec2 raw_delta, sp::io::Pointer::ID id)
{
    if (id == -1) {
        this->raw_delta = raw_delta;
        visible = false;
    }
}

bool MouseRenderer::onRelativeMove(glm::vec2 raw_delta, sp::io::Pointer::ID id)
{
    if (id == -1) {
        this->raw_delta = raw_delta;
        visible = false;
    }
    return false;
}
