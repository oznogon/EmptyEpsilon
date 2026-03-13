#include "hotkeyBinder.h"
#include <i18n.h>
#include "engine.h"
#include "hotkeyConfig.h"
#include "theme.h"

#include "gui/gui2_button.h"
#include "gui/gui2_selector.h"

// Track which binder and which key are actively performing a rebind.
static GuiHotkeyBinder* active_rebinder = nullptr;
static sp::io::Keybinding* active_key = nullptr;

static string interactionIcon(sp::io::Keybinding::Interaction inter)
{
    switch (inter)
    {
    case sp::io::Keybinding::Interaction::Sustained: return "gui/icons/key_sustained";
    case sp::io::Keybinding::Interaction::Stepped: return "gui/icons/key_stepped";
    case sp::io::Keybinding::Interaction::Axis0: return "gui/icons/axis_0";
    case sp::io::Keybinding::Interaction::Axis1: return "gui/icons/axis_1";
    default: return "";
    }
}

GuiHotkeyBinder::GuiHotkeyBinder(GuiContainer* owner, string id, sp::io::Keybinding* key,
    sp::io::Keybinding::Type display_filter, sp::io::Keybinding::Type capture_filter)
: GuiElement(owner, id), key(key), display_filter(display_filter), capture_filter(capture_filter)
{
    // Use textentry theme styles for binder inputs.
    // Someday, this should allow for icon representations instead of relying
    // on text.
    front_style = theme->getStyle("textentry.front");
    back_style = theme->getStyle("textentry.back");
    setAttribute("layout", "vertical");

    auto* row1 = new GuiElement(this, "");
    row1
        ->setSize(GuiElement::GuiSizeMax, 50.0f);

    auto* row2 = new GuiElement(this, "");
    row2
        ->setSize(GuiElement::GuiSizeMax, SELECTOR_HEIGHT)
        ->setAttribute("layout", "horizontal");

    // Collect supported interactions in display order.
    auto supported_interactions = key->getSupportedInteractions();
    if (supported_interactions & sp::io::Keybinding::Interaction::Stepped)
        interaction_selector_options.push_back(sp::io::Keybinding::Interaction::Stepped);
    if (supported_interactions & sp::io::Keybinding::Interaction::Sustained)
        interaction_selector_options.push_back(sp::io::Keybinding::Interaction::Sustained);
    if (supported_interactions & sp::io::Keybinding::Interaction::Axis0)
        interaction_selector_options.push_back(sp::io::Keybinding::Interaction::Axis0);
    if (supported_interactions & sp::io::Keybinding::Interaction::Axis1)
        interaction_selector_options.push_back(sp::io::Keybinding::Interaction::Axis1);

    // Pre-select the first supported interaction.
    if (!interaction_selector_options.empty())
        selected_interaction = interaction_selector_options[0];

    // Show a selector only when there are multiple interaction choices.
    if (interaction_selector_options.size() > 1)
    {
        interaction_selector = new GuiSelector(row2, id + "_INTERACTION",
            [this](int index, string value)
            {
                selected_interaction = interaction_selector_options[index];
            }
        );

        for (auto inter : interaction_selector_options)
        {
            string name = "";

            switch (inter)
            {
            case sp::io::Keybinding::Interaction::Stepped:
                name = tr("interaction", "Stepped");
                break;
            case sp::io::Keybinding::Interaction::Sustained:
                name = tr("interaction", "Sustained");
                break;
            case sp::io::Keybinding::Interaction::Axis0:
                name = tr("interaction", "Axis 0 to 1");
                break;
            case sp::io::Keybinding::Interaction::Axis1:
                name = tr("interaction", "Axis -1 to 1");
                break;
            default: break;
            }

            int entry_index = interaction_selector->addEntry(name, "");
            interaction_selector->setEntryIcon(entry_index, interactionIcon(inter));
        }

        interaction_selector
            ->setTextSize(18.0f)
            ->setSelectionIndex(0)
            ->setSize(GuiElement::GuiSizeMax, SELECTOR_HEIGHT);
    }
    else
    {
        // Pad for add/remove bind button alignment.
        (new GuiElement(row2, "PAD"))
            ->setSize(GuiElement::GuiSizeMax, SELECTOR_HEIGHT);
    }

    (new GuiButton(row2, "ADD_BIND", "+",
        [this]()
        {
            // Copied from onMouseDown
            const sp::io::Keybinding::Type mouse_types = sp::io::Keybinding::Type::Pointer | sp::io::Keybinding::Type::MouseMovement | sp::io::Keybinding::Type::MouseWheel;
            if (this->capture_filter & mouse_types)
            {
                // Delay startUserRebind until onMouseUp so that the triggering
                // mouse click is not immediately captured as the new binding.
                pending_rebind = true;
            }
            else
            {
                active_rebinder = this;
                active_key = this->key;
                this->key->startUserRebind(this->capture_filter, selected_interaction);
            }
        }
    ))
        ->setSize(25.0f, GuiElement::GuiSizeMax);

    (new GuiButton(row2, "REMOVE_BIND", "-",
        [this]()
        {
            // Copied from onMouseDown
            int count = 0;
            while (this->key->getKeyType(count) != sp::io::Keybinding::Type::None) count++;
            for (int i = count - 1; i >= 0; --i)
            {
                if (this->key->getKeyType(i) & this->display_filter)
                {
                    this->key->removeKey(i);
                    break;
                }
            }
        }
    ))
        ->setSize(25.0f, GuiElement::GuiSizeMax);
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

    // When the selector is below, restrict rendering to the binding field portion only.
    const float text_height = rect.size.y - SELECTOR_HEIGHT;
    renderer.drawStretched(sp::Rect(rect.position.x, rect.position.y, rect.size.x, text_height), back.texture, back.color);

    if (is_my_rebind)
    {
        renderer.drawText(sp::Rect(rect.position.x + 16.0f, rect.position.y, rect.size.x, text_height), tr("[New input]"), sp::Alignment::CenterLeft, front.size, front.font, front.color);
    }
    else
    {
        // Collect bindings that match the display filter.
        struct BindingInfo { string name; sp::io::Keybinding::Interaction interaction; };
        std::vector<BindingInfo> bindings;
        for (int n = 0; key->getKeyType(n) != sp::io::Keybinding::Type::None; n++)
        {
            if (key->getKeyType(n) & display_filter)
                bindings.push_back({key->getHumanReadableKeyName(n), key->getInteraction(n)});
        }

        const float icon_size = text_height * 0.7f;
        const float icon_y = rect.position.y + text_height * 0.5f;
        sp::Font* font = front.font ? front.font : sp::RenderTarget::getDefaultFont();
        float x = rect.position.x + 16.0f;

        for (size_t i = 0; i < bindings.size(); i++)
        {
            // Separator between bindings
            if (i > 0)
            {
                auto sep = font->prepare(", ", 32, front.size, front.color, {1600.0f, text_height}, sp::Alignment::CenterLeft, 0);
                float sep_w = sep.getUsedAreaSize().x;
                renderer.drawText({x, rect.position.y, sep_w, text_height}, sep);
                x += sep_w;
            }

            // Key name
            auto& b = bindings[i];
            auto prepared = font->prepare(b.name, 32, front.size, front.color, {1600.0f, text_height}, sp::Alignment::CenterLeft, 0);
            float text_w = prepared.getUsedAreaSize().x;
            renderer.drawText({x, rect.position.y, text_w, text_height}, prepared);
            x += text_w;

            // Interaction icon immediately after the key name
            string icon = interactionIcon(b.interaction);
            if (!icon.empty())
            {
                renderer.drawRotatedSprite(icon, glm::vec2(x + icon_size * 0.5f, icon_y), icon_size, 0.0f, front.color);
                x += icon_size;
            }
        }
    }
}
