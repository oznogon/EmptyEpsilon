#include "gui2_canvas.h"
#include "gui2_element.h"
#include "theme.h"
#ifdef DEBUG
#include "engine.h"
#include "gui/mouseRenderer.h"
#include "hotkeyConfig.h"
#endif

GuiCanvas::GuiCanvas(RenderLayer* renderLayer)
: Renderable(renderLayer), click_element(nullptr), focus_element(nullptr)
{
    enable_debug_rendering = false;
    theme = GuiTheme::getCurrentTheme();
}

//due to a suspected compiler bug this deconstructor needs to be explicitly defined
GuiCanvas::~GuiCanvas()
{
}

void GuiCanvas::render(sp::RenderTarget& renderer)
{
    auto window_size = renderer.getVirtualSize();
    sp::Rect window_rect(0, 0, window_size.x, window_size.y);

    cleanTree();
    runUpdates(this);
    updateLayout(window_rect);
    GuiElement* hovered = getHoverElement(mouse_position);
    drawElements(mouse_position, hovered, renderer);

    if (enable_debug_rendering)
    {
        drawDebugElements(renderer);
    }

#ifdef DEBUG
    if (keys.debug_show_gui.getDown())
    {
        enable_debug_rendering = !enable_debug_rendering;
    }
#endif
}

bool GuiCanvas::onPointerMove(glm::vec2 position, sp::io::Pointer::ID id)
{
    mouse_position = position;
    return false;
}

void GuiCanvas::onPointerLeave(sp::io::Pointer::ID id)
{
}

bool GuiCanvas::onPointerDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    if (!click_element)
    {
        GuiElement* clicked = getClickElement(button, position, id);
        if (clicked)
        {
            click_element = clicked;
            if (button == sp::io::Pointer::Button::Touch)
                touch_pointer_count = 1;
            clicked->pressed = true;
            clicked->onMouseDown(button, position, id);
            focus(clicked);
            return true;
        }
    }
    else if (button == sp::io::Pointer::Button::Touch)
    {
        touch_pointer_count++;
        click_element->onMouseDown(button, position, id);
        return true;
    }
    return false;
}

void GuiCanvas::onPointerDrag(glm::vec2 position, sp::io::Pointer::ID id)
{
    if (click_element)
        click_element->onMouseDrag(position, id);
}

void GuiCanvas::onPointerUp(glm::vec2 position, sp::io::Pointer::ID id)
{
    if (click_element)
    {
        click_element->onMouseUp(position, id);
        if (id != sp::io::Pointer::mouse)
        {
            touch_pointer_count--;
            if (touch_pointer_count > 0)
                return;
        }
        click_element->pressed = false;
        click_element = nullptr;
        touch_pointer_count = 0;
    }
}

void GuiCanvas::onMouseWheelScroll(glm::vec2 position, float value)
{
    executeScrollOnElement(position, value);
}

void GuiCanvas::onTextInput(const string& text)
{
    if (focus_element)
        focus_element->onTextInput(text);
}

void GuiCanvas::onTextInput(sp::TextInputEvent e)
{
    if (focus_element)
        focus_element->onTextInput(e);
}

void GuiCanvas::focus(GuiElement* element)
{
    if (focus_element == element)
        return;
    if (focus_element)
    {
        focus_element->focus = false;
        focus_element->onFocusLost();
    }
    focus_element = element;
    if (focus_element)
    {
        focus_element->focus = true;
        focus_element->onFocusGained();
    }
}

void GuiCanvas::unfocusElementTree(GuiElement* element)
{
    if (focus_element == element)
        focus_element = nullptr;
    if (click_element == element)
        click_element = nullptr;
    for(auto& child_ptr : element->getChildren())
        unfocusElementTree(child_ptr.get());
}

void GuiCanvas::runUpdates(GuiContainer* parent)
{
    // Iterate over a copy because onUpdate() may modify the container
    // (e.g. moveToFront/moveToBack or reparenting).
    std::vector<GuiElement*> children_copy;
    for (const auto& ptr : parent->getChildren())
        children_copy.push_back(ptr.get());

    for (GuiElement* element : children_copy)
    {
        if (!element)
        {
            LOG(Warning, "[guicanvas] GuiElement in GuiCanvas::runUpdates is in the for loop but doesn't exist");
            continue;
        }

        // Verify the element is still owned by this parent.
        auto it = std::find_if(parent->getChildren().begin(), parent->getChildren().end(),
            [element](const std::unique_ptr<GuiElement>& ptr) { return ptr.get() == element; });
        if (it == parent->getChildren().end()) continue;

        element->onUpdate();
        runUpdates(element);
    }
}

#ifdef DEBUG
static void dumpGuiTree(FILE* f, GuiContainer* c)
{
    for (auto& child_ptr : c->getChildren())
    {
        GuiElement* child = child_ptr.get();
        auto r = child->getRect();

        fprintf(f, "<div style='position:fixed;left:%fpx;top:%fpx;width:%fpx;height:%fpx;background:rgba(0,0,0,0.1);'>ID:%s", double(r.position.x), double(r.position.y), double(r.size.x), double(r.size.y), child->getID().c_str());
        fprintf(f, "<br>%s", typeid(child).name());
        fprintf(f, "<br>size=%f,%f", double(child->getLayout().size.x), double(child->getLayout().size.y));

        if (child->getLayout().match_content_x)
            fprintf(f, "<br>match_content_x=true");

        if (child->getLayout().match_content_y)
            fprintf(f, "<br>match_content_y=true");

        if (child->getLayout().fill_width)
            fprintf(f, "<br>fill_width=true");

        if (child->getLayout().fill_height)
            fprintf(f, "<br>fill_height=true");

        dumpGuiTree(f, child);
        fprintf(f, "</div>");
    }
}

void GuiCanvas::renderDebugDumps()
{
    static float update_timer = 0.0f;
    update_timer += 1.0f / 60.0f;

    if (update_timer > 1.0f)
    {
        update_timer = 0.0f;
        auto f = fopen("gui.html", "wt");
        dumpGuiTree(f, this);
        fclose(f);
    }
}
#endif
