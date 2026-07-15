#include "gui2_scrollcontainer.h"
#include "gui2_scrollbar.h"
#include "gui2_canvas.h"
#include "gui/layout/layout.h"


GuiScrollContainer::GuiScrollContainer(GuiContainer* owner, const string& id, ScrollMode mode)
: GuiElement(owner, id), mode(mode)
{
    // Don't lock content size to element.
    // We need to manipulate content size when toggling scrollbar visibility.
    layout.match_content_x = false;
    layout.match_content_y = false;

    // Define the scrollbar and hide it.
    scrollbar_v = new GuiScrollbar(this, id + "_SCROLLBAR_V", 0, 100, 0,
        [this](int value)
        {
            scroll_offset = static_cast<float>(value) - scroll_offset_bias;
        }
    );
    scrollbar_v
        ->setClickChange(50)
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopRight)
        ->setSize(scrollbar_width, GuiSizeMax)
        ->hide();
}

GuiScrollContainer* GuiScrollContainer::setMode(ScrollMode new_mode)
{
    mode = new_mode;
    return this;
}

GuiScrollContainer* GuiScrollContainer::setScrollbarWidth(float width)
{
    scrollbar_width = width;
    return this;
}

GuiScrollContainer* GuiScrollContainer::setScrollStart(ScrollStart start)
{
    scroll_start = start;
    scroll_start_applied = false;
    return this;
}

void GuiScrollContainer::cleanTree()
{
    if (focused_element && focused_element->isDestroyed())
        focused_element = nullptr;

    if (pressed_element && pressed_element->isDestroyed())
        pressed_element = nullptr;

    GuiContainer::cleanTree();
}

void GuiScrollContainer::scrollToFraction(float fraction)
{
    const float min_scroll = -scroll_offset_bias;
    const float max_scroll = std::max(0.0f, content_height - visible_height - scroll_offset_bias);
    const float scroll_range = max_scroll - min_scroll;
    scroll_offset = std::clamp(min_scroll + fraction * scroll_range, min_scroll, max_scroll);
    scrollbar_v->setValue(static_cast<int>(scroll_offset + scroll_offset_bias));
}

void GuiScrollContainer::scrollToOffset(float pixel_offset)
{
    const float min_scroll = -scroll_offset_bias;
    const float max_scroll = std::max(0.0f, content_height - visible_height - scroll_offset_bias);
    scroll_offset = std::clamp(pixel_offset, min_scroll, max_scroll);
    scrollbar_v->setValue(static_cast<int>(scroll_offset + scroll_offset_bias));
}

void GuiScrollContainer::updateLayout(const sp::Rect& bounds)
{
    this->rect = bounds;
    visible_height = bounds.size.y - layout.padding.top - layout.padding.bottom;

    // Clamp scroll_offset using last frame's content_height to validate the
    // value passed to the layout manager. Allow negative offsets for layouts
    // where content extends above the content area (e.g. verticalbottom).
    scroll_offset = std::clamp(scroll_offset, -scroll_offset_bias, std::max(0.0f, content_height - visible_height));

    // Show the scrollbar only if we're clipping anything.
    bool has_overflow = (mode != ScrollMode::None) && (content_height > visible_height + 0.5f);
    scrollbar_v->setVisible(has_overflow);

    // Don't factor scrollbar width if it isn't visible.
    const float sb_width = scrollbar_v->isVisible() ? scrollbar_width : 0.0f;

    // Factor layout padding.
    glm::vec2 padding_offset{
        layout.padding.left,
        layout.padding.top
    };

    glm::vec2 padding_size{
        layout.padding.left + layout.padding.right,
        layout.padding.top + layout.padding.bottom
    };

    // Subtract scroll_offset from the layout rect so all children (and their
    // descendants) are offset.
    sp::Rect content_layout_rect{
        rect.position + padding_offset + glm::vec2{0.0f, -scroll_offset},
        rect.size - padding_size - glm::vec2{sb_width, 0.0f}
    };

    if (!layout_manager) layout_manager = std::make_unique<GuiLayout>();

    // Temporarily hide the scrollbar so the layout manager ignores it for
    // sizing, then restore it if enabled.
    scrollbar_v->setVisible(false);
    layout_manager->updateLoop(*this, content_layout_rect);
    scrollbar_v->setVisible(has_overflow);

    // Override the scrollbar rect.
    scrollbar_v->updateLayout({
        {rect.position.x + rect.size.x - scrollbar_width, rect.position.y},
        {scrollbar_width, rect.size.y}
    });

    // Compute content_height. Child elements are scrolled, so add
    // scroll_offset from extents.
    float min_top = std::numeric_limits<float>::max();
    float max_bottom = 0.0f;
    for (auto& child_ptr : children)
    {
        GuiElement* child = child_ptr.get();
        if (child == scrollbar_v) continue;
        if (!child->isVisible()) continue;

        const float top = child->getRect().position.y - rect.position.y + scroll_offset;
        if (top < min_top) min_top = top;
        const float bottom = child->getRect().position.y + child->getRect().size.y + child->getLayout().margin.bottom - rect.position.y + scroll_offset;
        if (bottom > max_bottom) max_bottom = bottom;
    }
    content_height = max_bottom - min_top;

    // Determine scroll range. At scroll_offset 0, content is at its default
    // layout position. Content can extend above the content area (negative
    // scroll_offset) or below (positive).
    const float content_area_top = layout.padding.top;
    const float content_area_bottom = visible_height + layout.padding.top;
    float overflow_above = std::max(0.0f, content_area_top - min_top);
    float overflow_below = std::max(0.0f, max_bottom - content_area_bottom);
    float min_scroll = -overflow_above;
    float max_scroll = overflow_below;

    // Apply the configured scroll start position on the first layout.
    if (!scroll_start_applied)
    {
        scroll_offset = (scroll_start == ScrollStart::Bottom) ? max_scroll : min_scroll;
        scroll_start_applied = true;

        scroll_offset_bias = overflow_above;

        // Re-run layout with the corrected scroll_offset.
        sp::Rect adjusted_rect{
            rect.position + padding_offset + glm::vec2{0.0f, -scroll_offset},
            rect.size - padding_size - glm::vec2{sb_width, 0.0f}
        };
        scrollbar_v->setVisible(false);
        layout_manager->updateLoop(*this, adjusted_rect);
        scrollbar_v->setVisible(has_overflow);

        // Recompute content extents with adjusted child positions.
        min_top = std::numeric_limits<float>::max();
        max_bottom = 0.0f;
        for (auto& child_ptr : children)
        {
            GuiElement* child = child_ptr.get();
            if (child == scrollbar_v) continue;
            if (!child->isVisible()) continue;

            const float top = child->getRect().position.y - rect.position.y + scroll_offset;
            if (top < min_top) min_top = top;
            const float bottom = child->getRect().position.y + child->getRect().size.y + child->getLayout().margin.bottom - rect.position.y + scroll_offset;
            if (bottom > max_bottom) max_bottom = bottom;
        }
        content_height = max_bottom - min_top;

        // Recompute overflow and scroll range.
        overflow_above = std::max(0.0f, content_area_top - min_top);
        overflow_below = std::max(0.0f, max_bottom - content_area_bottom);
        min_scroll = -overflow_above;
        max_scroll = overflow_below;
    }

    scroll_offset_bias = overflow_above;

    // Clamp again in case content shrank this frame.
    scroll_offset = std::clamp(scroll_offset, min_scroll, max_scroll);

    // Sync scrollbar properties to new layout. Shift the value so the
    // scrollbar always sees a non-negative range.
    scrollbar_v
        ->setRange(0, static_cast<int>(content_height))
        ->setValueSize(static_cast<int>(visible_height))
        ->setValue(static_cast<int>(scroll_offset + scroll_offset_bias));

    if (auto_scroll_down)
        scrollToFraction(1.0f);
}

void GuiScrollContainer::enableAutoScrollDown()
{
    auto_scroll_down = true;
}

void GuiScrollContainer::disableAutoScrollDown()
{
    auto_scroll_down = false;
}

void GuiScrollContainer::drawElements(glm::vec2 mouse_position, GuiElement* hovered_element, sp::RenderTarget& renderer)
{
    sp::Rect content_rect = getContentRect();

    // Clip child rendering to the visible content area.
    renderer.pushClipRegion(content_rect);

    // Draw each child element and pass mouse events, skipping this container's
    // scrollbar.
    for (auto& element_ptr : children)
    {
        GuiElement* element = element_ptr.get();
        if (element == scrollbar_v)
            continue;

        element->setHover(element == hovered_element);

        if (element->isVisible())
        {
            element->onDraw(renderer);
            element->drawElements(mouse_position, hovered_element, renderer);
        }
    }

    renderer.popClipRegion();

    // Draw the scrollbar if intended to be visible. Never clip nor scroll the
    // scrollbar itself.
    scrollbar_v->setVisible(scrollbar_v->isVisible() && mode != ScrollMode::None);
    if (scrollbar_v->isVisible())
    {
        scrollbar_v->setHover(scrollbar_v == hovered_element);
        scrollbar_v->onDraw(renderer);
        scrollbar_v->drawElements(mouse_position, hovered_element, renderer);
    }
}

GuiElement* GuiScrollContainer::getClickElement(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    // Pass the click to the scrollbar first, and don't translate its position.
    if (scrollbar_v->isVisible()
        && scrollbar_v->isEnabled()
        && scrollbar_v->getRect().contains(position)
    )
    {
        GuiElement* clicked = scrollbar_v->getClickElement(button, position, id);
        if (clicked) return clicked;
        if (scrollbar_v->onMouseDown(button, position, id)) return scrollbar_v;
    }

    // Don't pass clicks to elements outside of the content rect.
    if (!getContentRect().contains(position)) return nullptr;

    // Pass the click to each nested child, which should take priority if it can
    // use it.
    for (auto it = children.rbegin(); it != children.rend(); ++it)
    {
        GuiElement* element = it->get();

        // We already handled the scrollbar.
        if (element == scrollbar_v) continue;
        // We don't care about buttons that aren't visible or enabled.
        if (!element->isVisible() || !element->isEnabled()) continue;

        // Figure out if we can click the element. If so, focus it and click it.
        GuiElement* clicked = element->getClickElement(button, position, id);
        if (clicked)
        {
            switchFocusTo(clicked);
            pressed_element = clicked;
            return this;
        }

        // The click didn't fire, but we still recurse into children regardless.
        // This helps find children or child-like elements (like GuiSelector
        // popups) that can exist outside of their parent's rect.
        if (element->getRect().contains(position) && element->onMouseDown(button, position, id))
        {
            switchFocusTo(element);
            pressed_element = element;
            return this;
        }
    }

    // Otherwise, do nothing.
    return nullptr;
}

void GuiScrollContainer::switchFocusTo(GuiElement* new_element)
{
    // Apply focus change, if any.
    if (focused_element == new_element) return;

    if (focused_element)
    {
        focused_element->setFocus(false);
        focused_element->onFocusLost();
    }

    focused_element = new_element;

    // If this scroll container already has canvas focus, forward focus gained
    // to the new child now (GuiCanvas won't call our onFocusGained again).
    // If this scroll container is not yet focused, canvas will call our
    // onFocusGained after getClickElement returns, which will forward it.
    if (focus)
    {
        focused_element->setFocus(true);
        focused_element->onFocusGained();
    }
}

void GuiScrollContainer::onFocusGained()
{
    if (focused_element)
    {
        focused_element->setFocus(true);
        focused_element->onFocusGained();
    }
}

void GuiScrollContainer::onFocusLost()
{
    if (focused_element)
    {
        focused_element->setFocus(false);
        focused_element->onFocusLost();
        focused_element = nullptr;
    }
}

void GuiScrollContainer::onTextInput(const string& text)
{
    if (focused_element) focused_element->onTextInput(text);
}

void GuiScrollContainer::onTextInput(sp::TextInputEvent e)
{
    if (focused_element) focused_element->onTextInput(e);
}

bool GuiScrollContainer::onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    if (pressed_element)
    {
        pressed_element->onMouseDown(button, position, id);
        return true;
    }

    return false;
}

void GuiScrollContainer::onMouseDrag(glm::vec2 position, sp::io::Pointer::ID id)
{
    if (pressed_element) pressed_element->onMouseDrag(position, id);
}

void GuiScrollContainer::onMouseUp(glm::vec2 position, sp::io::Pointer::ID id)
{
    if (pressed_element)
    {
        pressed_element->onMouseUp(position, id);
        pressed_element = nullptr;
    }
}

GuiElement* GuiScrollContainer::executeScrollOnElement(glm::vec2 position, float value)
{
    // Pass the scroll to the scrollbar first, and don't translate its position.
    if (scrollbar_v->isVisible()
        && scrollbar_v->isEnabled()
        && scrollbar_v->getRect().contains(position))
    {
        GuiElement* scrolled = scrollbar_v->executeScrollOnElement(position, value);
        if (scrolled) return scrolled;
        // Handle mousewheel scroll, if any.
        if (scrollbar_v->onMouseWheelScroll(position, value)) return scrollbar_v;
    }

    // Return nothing if the scroll isn't within the container.
    if (!getContentRect().contains(position)) return nullptr;

    // Execute the scroll on each nested child. If a child can use the mousewheel
    // scroll event, give it to them.
    for (auto it = children.rbegin(); it != children.rend(); ++it)
    {
        GuiElement* element = it->get();
        if (element == scrollbar_v) continue;

        if (element
            && element->isVisible()
            && element->isEnabled()
            && element->getRect().contains(position)
        )
        {
            GuiElement* scrolled = element->executeScrollOnElement(position, value);
            if (scrolled) return scrolled;
            if (element->onMouseWheelScroll(position, value)) return element;
        }
    }

    // No child used the mousewheel scroll event, so use it to scroll the
    // container.
    if (onMouseWheelScroll(position, value)) return this;

    // Otherwise, nothing happens.
    return nullptr;
}

bool GuiScrollContainer::onMouseWheelScroll(glm::vec2 /* position */, float value)
{
    // Don't scroll if used only to clip.
    if (mode == ScrollMode::None) return false;

    // Scroll by a default interval of 50, or by the container height if set to
    // paged mode.
    const float step = (mode == ScrollMode::Page) ? visible_height : 50.0f;
    const float min_scroll = -scroll_offset_bias;
    const float max_scroll = std::max(0.0f, content_height - visible_height - scroll_offset_bias);

    // If there's no overflow, let mousewheel pass through.
    if (max_scroll - min_scroll < 0.5f) return false;

    scroll_offset = std::clamp(scroll_offset - value * step, min_scroll, max_scroll);

    // Update the scrollbar.
    scrollbar_v->setValue(static_cast<int>(scroll_offset + scroll_offset_bias));

    return true;
}

sp::Rect GuiScrollContainer::getContentRect() const
{
    // Return the rect, inset by padding and minus room for the scrollbar if
    // it's visible.
    return sp::Rect{
        rect.position + glm::vec2{layout.padding.left, layout.padding.top},
        {
            rect.size.x - layout.padding.left - layout.padding.right - getEffectiveScrollbarWidth(),
            rect.size.y - layout.padding.top - layout.padding.bottom
        }
    };
}

float GuiScrollContainer::getEffectiveScrollbarWidth() const
{
    // Save room for the scrollbar only if it's visible.
    return scrollbar_v->isVisible() ? scrollbar_width : 0.0f;
}
