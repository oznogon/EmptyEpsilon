#include "gui2_scrollcontainer.h"
#include "gui2_scrollbar.h"
#include "gui2_canvas.h"
#include "gui/layout/layout.h"


GuiScrollContainer::GuiScrollContainer(GuiContainer* owner, const string& id, OverflowMode mode)
: GuiElement(owner, id), mode(mode)
{
    layout.match_content_size = false;

    if (mode == OverflowMode::Scroll || mode == OverflowMode::Page)
    {
        scrollbar_v = new GuiScrollbar(this, id + "_SCROLLBAR_V", 0, 100, 0, [this](int value) {
            scroll_offset = float(value);
        });
        scrollbar_v->setPosition(0, 0, sp::Alignment::TopRight)->setSize(scrollbar_width, GuiSizeMax);
    }
}

GuiScrollContainer* GuiScrollContainer::setMode(OverflowMode new_mode)
{
    mode = new_mode;
    return this;
}

GuiScrollContainer* GuiScrollContainer::setScrollbarWidth(float width)
{
    scrollbar_width = width;
    return this;
}

void GuiScrollContainer::scrollToFraction(float fraction)
{
    float max_scroll = std::max(0.0f, content_height - visible_height);
    scroll_offset = std::clamp(fraction * max_scroll, 0.0f, max_scroll);
    if (scrollbar_v)
        scrollbar_v->setValue(int(scroll_offset));
}

void GuiScrollContainer::onDraw(sp::RenderTarget& /*renderer*/)
{
    // No background by default; users provide their own if needed.
}

void GuiScrollContainer::updateLayout(const sp::Rect& rect)
{
    this->rect = rect;
    visible_height = rect.size.y;

    scrollbar_visible = (scrollbar_v != nullptr) && (content_height > visible_height + 0.5f);
    float sb_width = scrollbar_visible ? scrollbar_width : 0.0f;

    glm::vec2 padding_offset{layout.padding.left, layout.padding.top};
    glm::vec2 padding_size{layout.padding.left + layout.padding.right,
                           layout.padding.top + layout.padding.bottom};

    sp::Rect content_layout_rect{
        rect.position + padding_offset,
        rect.size - padding_size - glm::vec2{sb_width, 0.0f}
    };

    if (!layout_manager)
        layout_manager = std::make_unique<GuiLayout>();

    // Temporarily hide the scrollbar so the layout manager ignores it.
    if (scrollbar_v)
        scrollbar_v->setVisible(false);

    layout_manager->updateLoop(*this, content_layout_rect);

    if (scrollbar_v)
        scrollbar_v->setVisible(scrollbar_visible);

    // Override the scrollbar rect manually.
    if (scrollbar_v)
    {
        scrollbar_v->updateLayout({
            {rect.position.x + rect.size.x - scrollbar_width, rect.position.y},
            {scrollbar_width, rect.size.y}
        });
    }

    // Compute content_height from non-scrollbar visible children.
    float max_bottom = 0.0f;
    for (GuiElement* child : children)
    {
        if (child == scrollbar_v)
            continue;
        if (!child->isVisible())
            continue;
        float bottom = child->getRect().position.y + child->getRect().size.y
                       + child->layout.margin.bottom
                       - rect.position.y;
        if (bottom > max_bottom)
            max_bottom = bottom;
    }
    content_height = max_bottom;

    // Clamp scroll offset.
    float max_scroll = std::max(0.0f, content_height - visible_height);
    scroll_offset = std::clamp(scroll_offset, 0.0f, max_scroll);

    // Sync scrollbar.
    if (scrollbar_v)
    {
        scrollbar_v->setRange(0, int(content_height));
        scrollbar_v->setValueSize(int(visible_height));
        scrollbar_v->setValue(int(scroll_offset));
    }
}

void GuiScrollContainer::drawElements(glm::vec2 mouse_position, sp::Rect /*parent_rect*/, sp::RenderTarget& renderer)
{
    sp::Rect content_rect = getContentRect();

    renderer.pushScissorRect(content_rect);
    renderer.pushTranslation({0.0f, -scroll_offset});

    glm::vec2 layout_mouse = mouse_position + glm::vec2{0.0f, scroll_offset};

    for (auto it = children.begin(); it != children.end(); )
    {
        GuiElement* element = *it;

        if (element == scrollbar_v)
        {
            ++it;
            continue;
        }

        if (element->isDestroyed())
        {
            GuiCanvas* canvas = dynamic_cast<GuiCanvas*>(element->getTopLevelContainer());
            if (canvas)
                canvas->unfocusElementTree(element);
            it = children.erase(it);
            clearElementOwner(element);
            delete element;
            continue;
        }

        setElementHover(element, element->getRect().contains(layout_mouse));

        if (element->isVisible())
        {
            element->onDraw(renderer);
            callDrawElements(element, layout_mouse, element->getRect(), renderer);
        }

        ++it;
    }

    renderer.popTranslation();
    renderer.popScissorRect();

    // Draw the scrollbar without the content translation/scissor.
    if (scrollbar_v && !scrollbar_v->isDestroyed() && scrollbar_v->isVisible())
    {
        setElementHover(scrollbar_v, scrollbar_v->getRect().contains(mouse_position));
        scrollbar_v->onDraw(renderer);
        callDrawElements(scrollbar_v, mouse_position, scrollbar_v->getRect(), renderer);
    }
}

GuiElement* GuiScrollContainer::getClickElement(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    // Test scrollbar first at raw (unscrolled) position.
    if (scrollbar_v && scrollbar_v->isVisible() && scrollbar_v->isEnabled()
        && scrollbar_v->getRect().contains(position))
    {
        GuiElement* clicked = callGetClickElement(scrollbar_v, button, position, id);
        if (clicked)
            return clicked;
        if (scrollbar_v->onMouseDown(button, position, id))
            return scrollbar_v;
    }

    // Outside the content viewport → no hit.
    if (!getContentRect().contains(position))
        return nullptr;

    glm::vec2 layout_pos = position + glm::vec2{0.0f, scroll_offset};

    for (auto it = children.rbegin(); it != children.rend(); ++it)
    {
        GuiElement* element = *it;
        if (element == scrollbar_v)
            continue;
        if (!element->isVisible() || !element->isEnabled())
            continue;

        // Always recurse into children regardless of the parent element's own
        // rect — this lets us find children that extend outside their parent
        // (e.g. GuiSelector popup menus that sit below the selector row).
        GuiElement* clicked = callGetClickElement(element, button, layout_pos, id);
        if (clicked)
        {
            switchFocusTo(clicked);
            pressed_element = clicked;
            pressed_scroll = scroll_offset;
            return this;
        }

        // Direct hit on the element itself still requires rect containment.
        if (element->getRect().contains(layout_pos) && element->onMouseDown(button, layout_pos, id))
        {
            switchFocusTo(element);
            pressed_element = element;
            pressed_scroll = scroll_offset;
            return this;
        }
    }
    return nullptr;
}

void GuiScrollContainer::switchFocusTo(GuiElement* new_element)
{
    if (focused_element == new_element)
        return;
    if (focused_element)
    {
        setElementFocus(focused_element, false);
        focused_element->onFocusLost();
    }
    focused_element = new_element;
    // If this scroll container already has canvas focus, forward focus gained
    // to the new child now (canvas won't call our onFocusGained again).
    if (focus)
    {
        setElementFocus(focused_element, true);
        focused_element->onFocusGained();
    }
    // If this scroll container is not yet focused, canvas will call our
    // onFocusGained after getClickElement returns, which will forward it.
}

void GuiScrollContainer::onFocusGained()
{
    if (focused_element)
    {
        setElementFocus(focused_element, true);
        focused_element->onFocusGained();
    }
}

void GuiScrollContainer::onFocusLost()
{
    if (focused_element)
    {
        setElementFocus(focused_element, false);
        focused_element->onFocusLost();
        focused_element = nullptr;
    }
}

void GuiScrollContainer::onTextInput(const string& text)
{
    if (focused_element)
        focused_element->onTextInput(text);
}

void GuiScrollContainer::onTextInput(sp::TextInputEvent e)
{
    if (focused_element)
        focused_element->onTextInput(e);
}

void GuiScrollContainer::onMouseDrag(glm::vec2 position, sp::io::Pointer::ID id)
{
    if (pressed_element)
        pressed_element->onMouseDrag(position + glm::vec2{0.0f, pressed_scroll}, id);
}

void GuiScrollContainer::onMouseUp(glm::vec2 position, sp::io::Pointer::ID id)
{
    if (pressed_element)
    {
        pressed_element->onMouseUp(position + glm::vec2{0.0f, pressed_scroll}, id);
        pressed_element = nullptr;
    }
}

GuiElement* GuiScrollContainer::executeScrollOnElement(glm::vec2 position, float value)
{
    // Test scrollbar at raw position.
    if (scrollbar_v && scrollbar_v->isVisible() && scrollbar_v->isEnabled()
        && scrollbar_v->getRect().contains(position))
    {
        GuiElement* scrolled = callExecuteScrollOnElement(scrollbar_v, position, value);
        if (scrolled)
            return scrolled;
        if (scrollbar_v->onMouseWheelScroll(position, value))
            return scrollbar_v;
    }

    if (!getContentRect().contains(position))
        return nullptr;

    glm::vec2 layout_pos = position + glm::vec2{0.0f, scroll_offset};

    for (auto it = children.rbegin(); it != children.rend(); ++it)
    {
        GuiElement* element = *it;
        if (element == scrollbar_v)
            continue;
        if (element->isVisible() && element->isEnabled() && element->getRect().contains(layout_pos))
        {
            GuiElement* scrolled = callExecuteScrollOnElement(element, layout_pos, value);
            if (scrolled)
                return scrolled;
            if (element->onMouseWheelScroll(layout_pos, value))
                return element;
        }
    }

    // Nothing consumed — let the container itself scroll.
    if (onMouseWheelScroll(position, value))
        return this;
    return nullptr;
}

bool GuiScrollContainer::onMouseWheelScroll(glm::vec2 /*position*/, float value)
{
    if (mode == OverflowMode::Clip)
        return false;

    float step = (mode == OverflowMode::Page) ? visible_height : 50.0f;
    float max_scroll = std::max(0.0f, content_height - visible_height);
    scroll_offset = std::clamp(scroll_offset - value * step, 0.0f, max_scroll);

    if (scrollbar_v)
        scrollbar_v->setValue(int(scroll_offset));

    return true;
}

sp::Rect GuiScrollContainer::getContentRect() const
{
    return sp::Rect{rect.position, {rect.size.x - getEffectiveScrollbarWidth(), rect.size.y}};
}

float GuiScrollContainer::getEffectiveScrollbarWidth() const
{
    return (scrollbar_v && scrollbar_visible) ? scrollbar_width : 0.0f;
}
