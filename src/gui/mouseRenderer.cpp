#include "mouseRenderer.h"
#include "main.h"

MouseRenderer::MouseRenderer(RenderLayer* render_layer)
: Renderable(render_layer)
{
}

void MouseRenderer::render(sp::RenderTarget& renderer)
{
    if (!is_visible || !should_be_visible) return;

    renderer.drawSprite(sprite, position, 32.0f);
}

bool MouseRenderer::onPointerMove(glm::vec2 position, sp::io::Pointer::ID id)
{
    if (id == -1)
    {
        this->position = position;
        is_visible = should_be_visible;
    }

    return false;
}

void MouseRenderer::onPointerLeave(sp::io::Pointer::ID id)
{
    // Override should_be_visible when the mouse leaves the window.
    if (id == -1) is_visible = false;
}

void MouseRenderer::onPointerDrag(glm::vec2 position, sp::io::Pointer::ID id)
{
    if (id == -1)
    {
        this->position = position;
        is_visible = should_be_visible;
    }
}
