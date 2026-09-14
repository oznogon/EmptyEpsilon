#include "gui2_tooltip.h"
#include "gui2_canvas.h"
#include "gui2_label.h"
#include "preferenceManager.h"
#include "theme.h"
#include <algorithm>

namespace
{
// Track open tooltip state.
int tooltip_open_count = 0;
// Timer that ends the warm window after the last tooltip closes.
sp::SystemTimer tooltip_warm_timer;

// Returns true while a tooltip is open or the cooldown timer is still running.
// Lapses the warm timer when it expires so the page goes cold again.
bool isTooltipPageWarm()
{
    if (tooltip_open_count > 0) return true;

    if (tooltip_warm_timer.isRunning())
    {
        if (tooltip_warm_timer.getTimeLeft() <= 0.0f)
        {
            tooltip_warm_timer.stop();
            return false;
        }

        return true;
    }

    return false;
}

// When a tooltip opens, tick the open counter and pause the tooltip visibility cooldown clock.
void tooltipOpened()
{
    tooltip_open_count++;
    tooltip_warm_timer.stop();
}

// When a tooltip closes, decrement the open tooltip counter. If all tooltips
// are closed, reset the cooldown timer.
void tooltipClosed()
{
    if (tooltip_open_count > 0) tooltip_open_count--;
    if (tooltip_open_count == 0) tooltip_warm_timer.start(GuiTooltip::WARM_WINDOW_DURATION);
}
}

static bool isTreeHoveredOrPressed(GuiElement* element)
{
    if (element->isHovered() || element->isPressed()) return true;

    for (auto& child_ptr : element->getChildren())
        if (isTreeHoveredOrPressed(child_ptr.get())) return true;

    return false;
}

GuiTooltip::Anchor::Anchor(GuiElement* watched, GuiTooltip* tooltip)
: GuiElement(watched, ""), tooltip(tooltip)
{
    // Anchors are invisible, take no layout space, and don't intercept input.
    hide();
    setSize(0.0f, 0.0f);
}

GuiTooltip::Anchor::~Anchor()
{
    if (tooltip) tooltip->anchorDestroyed();
}

// Attach to the top-level canvas so this element renders above all screen
// content. The watched element is stored separately.
GuiTooltip::GuiTooltip(GuiElement* watched, string id)
: GuiElement(watched->getTopLevelContainer(), id), watched(watched)
{
    anchor = new Anchor(watched, this);
    layout.alignment = sp::Alignment::TopLeft;
    setVisible(false);
}

GuiTooltip::~GuiTooltip()
{
    // Break the back-reference so Anchor::~Anchor() is a no-op if the tooltip
    // is destroyed before the Anchor.
    if (anchor) anchor->tooltip = nullptr;

    // If the tooltip is still open when destroyed, close it so the shared page
    // warmth state isn't left with a dangling open count.
    if (showing)
    {
        showing = false;
        tooltipClosed();
    }
}

void GuiTooltip::anchorDestroyed()
{
    // If the watched element's subtree is being torn down, null the pointer so
    // onUpdate() can't reach freed memory, then schedule self-deletion.
    watched = nullptr;
    anchor = nullptr;
    destroy();
}

void GuiTooltip::onUpdate()
{
    if (!watched) return;
    if (PreferencesManager::get("tooltips", "1") != "1") return;

    // If the tooltip parent isn't or can't be triggered, hide/skip the tooltip.
    // isVisible() checks only the element's own flag, and hidden ancestors
    // don't propagate to descendants, so isEffectivelyVisible() walks the full
    // ownership chain.
    bool active = watched->isEffectivelyVisible() && isTreeHoveredOrPressed(watched);

    // Hide immediately when the press ends, even if the cursor is still
    // hovering over the watched element.
    bool is_pressed = watched->isPressed();
    if (showing && was_pressed && !is_pressed)
    {
        showing = false;
        setVisible(false);
        timer.stop();
        tooltipClosed();
        position_captured_on_press = false;
        was_pressed = false;
        return;
    }
    was_pressed = is_pressed;

    if (!active)
    {
        timer.stop();
        position_captured_on_press = false;
        was_pressed = false;

        if (showing)
        {
            showing = false;
            setVisible(false);
            tooltipClosed();
        }

        return;
    }

    // If the tooltip's parent is triggering a hidden tooltip, either reveal it
    // instantly when the page is warm, or tick the reveal timer on a cold page
    // and reveal the tooltip when the timer expires.
    if (!showing)
    {
        if (isTooltipPageWarm())
        {
            showing = true;
            setVisible(true);
            moveToFront();
            tooltipOpened();
        }
        else if (!timer.isRunning())
        {
            timer.start(GuiTooltip::OPEN_DELAY);
        }
        else if (timer.isExpired())
        {
            showing = true;
            setVisible(true);
            moveToFront();
            tooltipOpened();
        }
    }

    // Position the tooltip. When triggered by press, freeze the position at the
    // click location to allow finger movement out of the way on touch. When
    // triggered by hover, follow the cursor.
    if (showing)
    {
        glm::vec2 target;

        if (watched->isPressed())
        {
            if (!position_captured_on_press)
            {
                GuiCanvas* canvas = getRootCanvas();
                frozen_position = (canvas ? canvas->getMousePosition() : glm::vec2{0, 0}) + pixel_offset;
                position_captured_on_press = true;
            }
            target = frozen_position;
        }
        else
        {
            position_captured_on_press = false;
            GuiCanvas* canvas = getRootCanvas();
            target = (canvas ? canvas->getMousePosition() : glm::vec2{0, 0}) + pixel_offset;

            // If size is fixed, clamp position to keep the tooltip on screen.
            if (!layout.match_content_x && !layout.match_content_y)
            {
                const sp::Rect screen = getTopLevelContainer()->getRect();
                target.x = std::max(0.0f, std::min(target.x, screen.size.x - layout.size.x));
                target.y = std::max(0.0f, std::min(target.y, screen.size.y - layout.size.y));
            }

            frozen_position = target;
        }

        // As a direct child of the canvas, use layout.position to set absolute
        // screen coordinates.
        layout.position = target;
    }
}

GuiTooltip* GuiTooltip::setPixelOffset(glm::vec2 offset)
{
    pixel_offset = offset;
    return this;
}

GuiTextTooltip::GuiTextTooltip(GuiElement* watched, string id, string text, float text_size)
: GuiTooltip(watched, id)
{
    style = theme->getStyle("tooltip");

    setAttribute("padding", string(padding));
    label = new GuiLabel(this, "", text, text_size);
    label
        ->setWrapped()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
}

void GuiTextTooltip::onDraw(sp::RenderTarget& renderer)
{
    const auto& s = style->get(getState());
    renderer.drawStretchedHV(rect, s.size, s.texture, s.color);
}

void GuiTextTooltip::onUpdate()
{
    // Always maintain correct height so it's ready before first render.
    if (layout.size.x > 0)
        setSize(layout.size.x, label->getRenderedHeight(layout.size.x - padding * 2.0f) + padding * 2.0f);

    GuiTooltip::onUpdate();
}

GuiTextTooltip* GuiTextTooltip::setText(string text)
{
    label->setText(text);
    return this;
}

GuiTextTooltip* GuiTextTooltip::setWidth(float width)
{
    if (width > 0.0f) setSize(width, 0.0f);
    return this;
}
