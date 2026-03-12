#include "hotkeyBinder.h"
#include <i18n.h>
#include "engine.h"
#include "hotkeyConfig.h"
#include "theme.h"
#include "gui/gui2_selector.h"

// Track which binder and which key are actively performing a rebind.
static GuiHotkeyBinder* active_rebinder = nullptr;
static sp::io::Keybinding* active_key = nullptr;

GuiHotkeyBinder::GuiHotkeyBinder(GuiContainer* owner, string id, sp::io::Keybinding* key,
    sp::io::Keybinding::Type display_filter, sp::io::Keybinding::Type capture_filter)
: GuiElement(owner, id), key(key), display_filter(display_filter), capture_filter(capture_filter)
{
    // Use textentry theme styles for binder inputs.
    // Someday, this should allow for icon representations instead of relying
    // on text.
    front_style = theme->getStyle("textentry.front");
    back_style = theme->getStyle("textentry.back");

    // Collect supported interactions in display order.
    auto si = key->getSupportedInteractions();
    if (si & sp::io::Keybinding::Interaction::Stepped)   interaction_selector_options.push_back(sp::io::Keybinding::Interaction::Stepped);
    if (si & sp::io::Keybinding::Interaction::Sustained) interaction_selector_options.push_back(sp::io::Keybinding::Interaction::Sustained);
    if (si & sp::io::Keybinding::Interaction::Axis0)     interaction_selector_options.push_back(sp::io::Keybinding::Interaction::Axis0);
    if (si & sp::io::Keybinding::Interaction::Axis1)     interaction_selector_options.push_back(sp::io::Keybinding::Interaction::Axis1);

    // Pre-select the first supported interaction.
    if (!interaction_selector_options.empty())
        selected_interaction = interaction_selector_options[0];

    // Show a selector only when there are multiple interaction choices.
    if (interaction_selector_options.size() > 1)
    {
        interaction_selector = new GuiSelector(this, id + "_INTERACTION", [this](int index, string value) {
            selected_interaction = interaction_selector_options[index];
        });

        for (auto inter : interaction_selector_options)
        {
            string name;
            switch (inter)
            {
            case sp::io::Keybinding::Interaction::Stepped:   name = tr("interaction", "Stepped"); break;
            case sp::io::Keybinding::Interaction::Sustained: name = tr("interaction", "Sustained"); break;
            case sp::io::Keybinding::Interaction::Axis0:     name = tr("interaction", "Axis 0 to 1"); break;
            case sp::io::Keybinding::Interaction::Axis1:     name = tr("interaction", "Axis -1 to 1"); break;
            default: break;
            }
            interaction_selector->addEntry(name, "");
        }

        interaction_selector->setSelectionIndex(0);
        interaction_selector->setTextSize(18.0f);
        interaction_selector
            ->setPosition(0, 0, sp::Alignment::BottomLeft)
            ->setSize(GuiElement::GuiSizeMax, SELECTOR_HEIGHT);
    }
}

bool GuiHotkeyBinder::isAnyRebinding()
{
    return active_rebinder != nullptr;
}

void GuiHotkeyBinder::clearFilteredKeys()
{
    // Filter binds for this control by their type.
    int count = 0;
    while (key->getKeyType(count) != sp::io::Keybinding::Type::None) count++;
    for (int i = count - 1; i >= 0; --i)
        if (key->getKeyType(i) & display_filter) key->removeKey(i);
}

bool GuiHotkeyBinder::onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    // If this binder is already rebinding, just take the input and skip this.
    // This should allow binding left/middle/right-click without also changing
    // the binder's state at the same time.
    if (active_rebinder == this) return true;

    // Left click: Assign input. Middle click: Add input.
    // Right click: Remove last input. Ignore all other mouse buttons.
    if (button == sp::io::Pointer::Button::Left)
        clearFilteredKeys();
    if (button == sp::io::Pointer::Button::Right)
    {
        int count = 0;
        while (key->getKeyType(count) != sp::io::Keybinding::Type::None) count++;
        for (int i = count - 1; i >= 0; --i)
        {
            if (key->getKeyType(i) & display_filter)
            {
                key->removeKey(i);
                break;
            }
        }
    }

    if (button == sp::io::Pointer::Button::Left || button == sp::io::Pointer::Button::Middle)
    {
        const sp::io::Keybinding::Type mouse_types = sp::io::Keybinding::Type::Pointer | sp::io::Keybinding::Type::MouseMovement | sp::io::Keybinding::Type::MouseWheel;
        if (capture_filter & mouse_types)
        {
            // Delay startUserRebind until onMouseUp so that the triggering
            // mouse click is not immediately captured as the new binding.
            pending_rebind = true;
        }
        else
        {
            active_rebinder = this;
            active_key = key;
            key->startUserRebind(capture_filter, selected_interaction);
        }
    }

    return true;
}

void GuiHotkeyBinder::onMouseUp(glm::vec2 position, sp::io::Pointer::ID id)
{
    // Complete a pending rebind action.
    if (pending_rebind)
    {
        pending_rebind = false;
        active_rebinder = this;
        active_key = key;
        key->startUserRebind(capture_filter, selected_interaction);
    }
}

void GuiHotkeyBinder::onDraw(sp::RenderTarget& renderer)
{
    // Clear the active rebind indicator only when the tracked key's rebind
    // completes.
    if (active_key != nullptr && !active_key->isUserRebinding())
    {
        active_rebinder = nullptr;
        active_key = nullptr;
    }

    bool is_my_rebind = (active_rebinder == this);
    focus = is_my_rebind;

    const auto& back = back_style->get(getState());
    const auto& front = front_style->get(getState());

    renderer.drawStretched(rect, back.texture, back.color);

    string text;

    // If this is the active rebinder, update its state to indicate that it's
    // ready for input. Otherwise, list the associated binds.
    // TODO: This list can get quite long. What should it do on overflow?
    if (is_my_rebind) text = tr("[New input]");
    else
    {
        for (int n = 0; key->getKeyType(n) != sp::io::Keybinding::Type::None; n++)
        {
            if (key->getKeyType(n) & display_filter)
            {
                if (!text.empty()) text += ",";
                text += key->getHumanReadableKeyName(n);
                auto inter = key->getInteraction(n);
                if (inter != sp::io::Keybinding::Interaction::None)
                {
                    string inter_name;
                    switch (inter)
                    {
                    case sp::io::Keybinding::Interaction::Sustained: inter_name = tr("interaction-abbreviated", "Sst"); break;
                    case sp::io::Keybinding::Interaction::Stepped:   inter_name = tr("interaction-abbreviated", "Stp"); break;
                    case sp::io::Keybinding::Interaction::Axis0:     inter_name = tr("interaction-abbreviated", "A0"); break;
                    case sp::io::Keybinding::Interaction::Axis1:     inter_name = tr("interaction-abbreviated", "A1"); break;
                    default: break;
                    }
                    if (!inter_name.empty())
                        text += " [" + inter_name + "]";
                }
            }
        }
    }

    // When the selector is below, restrict text to the binding field portion only.
    float text_height = interaction_selector ? (rect.size.y - SELECTOR_HEIGHT) : rect.size.y;
    renderer.drawText(sp::Rect(rect.position.x + 16.0f, rect.position.y, rect.size.x, text_height), text, sp::Alignment::CenterLeft, front.size, front.font, front.color);
}
