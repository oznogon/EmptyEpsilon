#include "hotkeyBinder.h"
#include <i18n.h>
#include "theme.h"

#include "gui/gui2_button.h"
#include "gui/gui2_label.h"
#include "gui/gui2_overlay.h"
#include "gui/gui2_panel.h"
#include "gui/gui2_scrolltext.h"
#include "gui/gui2_selector.h"

// Track which binder and which key are actively performing a rebind.
static GuiHotkeyBinder* active_rebinder = nullptr;
static sp::io::Keybinding* active_key = nullptr;


GuiHotkeyBinder::GuiHotkeyBinder(GuiContainer* owner, string id, sp::io::Keybinding* key,
    sp::io::Keybinding::Type display_filter, sp::io::Keybinding::Type capture_filter)
: GuiElement(owner, id), key(key), display_filter(display_filter), capture_filter(capture_filter)
{
    // Use textentry theme styles for binder inputs.
    // TODO:
    //    - Allow for icon representations instead of text.
    //    - Populate a GuiSelector instead of a bespoke entry field with custom
    //      drawing.
    //    - Consolidate bind add/removal to +/- buttons instead of field click.
    //    - Single list, scroll to section headers.
    //    - Text filter for binds.
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
    interaction_row = row2;

    // Collect supported interactions in display order.
    auto supported_interactions = key->getSupportedInteractions();
    if (supported_interactions & sp::io::Keybinding::Interaction::Discrete)
        interaction_selector_options.push_back(sp::io::Keybinding::Interaction::Discrete);
    if (supported_interactions & sp::io::Keybinding::Interaction::Continuous)
        interaction_selector_options.push_back(sp::io::Keybinding::Interaction::Continuous);
    if (supported_interactions & sp::io::Keybinding::Interaction::Repeating)
        interaction_selector_options.push_back(sp::io::Keybinding::Interaction::Repeating);
    if (supported_interactions & sp::io::Keybinding::Interaction::Axis0)
        interaction_selector_options.push_back(sp::io::Keybinding::Interaction::Axis0);
    if (supported_interactions & sp::io::Keybinding::Interaction::Axis1)
        interaction_selector_options.push_back(sp::io::Keybinding::Interaction::Axis1);

    // Pre-select the first supported interaction.
    if (!interaction_selector_options.empty())
        selected_interaction = interaction_selector_options[0];

    interaction_selector = new GuiSelector(row2, id + "_INTERACTION",
        [this](int index, string value)
        {
            selected_interaction = interaction_selector_options[index];
        }
    );
    interaction_selector
        ->setTextSize(18.0f)
        ->setSelectionIndex(0)
        ->setSize(GuiElement::GuiSizeMax, SELECTOR_HEIGHT)
        ->disable();

    // Populate selector. Enable it if it has multiple options.
    for (auto inter : interaction_selector_options)
    {
        string name = "";

        switch (inter)
        {
        case sp::io::Keybinding::Interaction::Discrete:
            name = tr("interaction", "Discrete"); // Push-and-release?
            break;
        case sp::io::Keybinding::Interaction::Continuous:
            name = tr("interaction", "Continuous"); // Push-and-hold? But that's also repeating
            break;
        case sp::io::Keybinding::Interaction::Repeating:
            name = tr("interaction", "Repeating"); // Rapid fire?
            break;
        case sp::io::Keybinding::Interaction::Axis0:
            name = tr("interaction", "Axis 0 to 1"); // Throttle/trigger?
            break;
        case sp::io::Keybinding::Interaction::Axis1:
            name = tr("interaction", "Axis -1 to 1"); // Stick axis?
            break;
        default: break;
        }

        int entry_index = interaction_selector->addEntry(name, "");
        interaction_selector->setEntryIcon(entry_index, interactionIcon(inter));
    }

    if (interaction_selector_options.size() > 1)
        interaction_selector->enable();

    (new GuiButton(row2, "ADD_BIND", "+",
        [this]()
        {
            if (rebind_dialog)
            {
                rebind_dialog->startRebind(this->key, this->capture_filter, this->display_filter, this->key->getLabel());
                return;
            }
            // Copied from onMouseDown.
            // Delay startUserRebind until onMouseUp so that the triggering
            // mouse click is not immediately captured as the new binding.
            if (this->capture_filter & sp::io::Keybinding::Type::Mouse)
                pending_rebind = true;
            else
            {
                active_rebinder = this;
                active_key = this->key;
                sp::io::Keybinding::setUserRebindCancelKey(&keys.cancel_rebind);
                this->key->startUserRebind(this->capture_filter, selected_interaction);
            }
        }
    ))
        ->setSize(SELECTOR_HEIGHT, GuiElement::GuiSizeMax);

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
        ->setSize(SELECTOR_HEIGHT, GuiElement::GuiSizeMax);
}

GuiHotkeyBinder::~GuiHotkeyBinder()
{
    if (active_rebinder == this)
    {
        sp::io::Keybinding::cancelUserRebind();
        active_rebinder = nullptr;
        active_key = nullptr;
    }
}

bool GuiHotkeyBinder::isAnyRebinding()
{
    return active_rebinder != nullptr || GuiRebindDialog::isAnyActive();
}

void GuiHotkeyBinder::setDialog(GuiRebindDialog* dialog)
{
    rebind_dialog = dialog;
    interaction_row->setVisible(dialog == nullptr);
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

    // In dialog mode, left/middle click opens the dialog instead of rebinding.
    // Right click still removes the last matching bind directly.
    if (rebind_dialog)
    {
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
        else if (button == sp::io::Pointer::Button::Left || button == sp::io::Pointer::Button::Middle)
        {
            rebind_dialog->startRebind(key, capture_filter, display_filter, key->getLabel());
        }
        return true;
    }

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
        // Delay startUserRebind until onMouseUp so that the triggering
        // mouse click is not immediately captured as the new binding.
        if (capture_filter & sp::io::Keybinding::Type::Mouse)
            pending_rebind = true;
        else
        {
            active_rebinder = this;
            active_key = key;
            sp::io::Keybinding::setUserRebindCancelKey(&keys.cancel_rebind);
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
        sp::io::Keybinding::setUserRebindCancelKey(&keys.cancel_rebind);
        key->startUserRebind(capture_filter, selected_interaction);
    }
}

void GuiHotkeyBinder::onDraw(sp::RenderTarget& renderer)
{
    // Clear the active rebind indicator only when the tracked key's rebind
    // completes and there is no pending preview capture for it.
    if (active_key != nullptr
        && !active_key->isUserRebinding()
        && !active_key->hasPendingRebind())
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

// Pop-up dialog panel for advanced rebinding
GuiRebindDialog* GuiRebindDialog::active_dialog = nullptr;

GuiRebindDialog::GuiRebindDialog(GuiContainer* owner, string id)
: GuiElement(owner, id)
{
    setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    overlay = new GuiOverlay(this, id + "_OVERLAY", glm::u8vec4{0, 0, 0, 100});
    overlay
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    panel = new GuiPanel(this, id + "_PANEL");
    panel
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(500.0f, 400.0f);

    auto* content = new GuiElement(panel, id + "_CONTENT");
    content
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setMargins(15.0f)
        ->setAttribute("layout", "vertical");

    action_label = new GuiLabel(content, id + "_ACTION", "", 22.0f);
    action_label
        ->setAlignment(sp::Alignment::CenterLeft)
        ->setSize(GuiElement::GuiSizeMax, 40.0f)
        ->setMargins(0.0f, 5.0f);

    input_label = new GuiLabel(content, id + "_INPUT", tr("hotkey_menu", "[Press any key or input...]"), 24.0f);
    input_label
        ->addBackground()
        ->setAlignment(sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setMargins(0.0f, 5.0f);

    mouse_panel_btn = new GuiButton(content, id + "_MOUSE_PANEL",
        tr("hotkey_menu", "Press mouse button here"),
        [this]()
        {
            // Button callback fires on mouse-up, so the triggering click is
            // already consumed. The next click is captured as the new binding.
            startCapture();
        }
    );
    mouse_panel_btn
        ->setSize(GuiElement::GuiSizeMax, 55.0f)
        ->setMargins(0.0f, 5.0f)
        ->hide();

    interaction_row = new GuiElement(content, id + "_INTER_ROW");
    interaction_row
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setMargins(0.0f, 5.0f)
        ->setAttribute("layout", "horizontal");

    (new GuiLabel(interaction_row, id + "_INTER_LABEL", tr("hotkey_menu", "Interaction:"), 20.0f))
        ->setAlignment(sp::Alignment::CenterLeft)
        ->setSize(130.0f, GuiElement::GuiSizeMax);

    interaction_selector = new GuiSelector(interaction_row, id + "_INTER_SEL",
        [this](int index, string /*value*/)
        {
            if (index < 0 || index >= static_cast<int>(interaction_options.size()))
                return;
            selected_interaction = interaction_options[index];
            if (state == State::HasInput && target_key)
                target_key->setPendingRebindInteraction(selected_interaction);
        }
    );
    interaction_selector
        ->setTextSize(18.0f)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    legend_text = new GuiScrollText(content, id + "_LEGEND",
        tr("hotkey_menu",
            "Discrete: Acts only once when pressed. (Buttons, encoders, switches)\n"
            "Continuous: Acts every frame for as long as it's held down. (Steering using buttons, smooth sliders)\n"
            "Repeating: Acts once, waits, then acts repeatedly. (Keyboard repeating, sliders with stepped values)\n"
            "Axis 0 to 1: Value is between a minimum value when released and maximum when fully pressed in one direction. (Triggers, throttles)\n"
            "Axis -1 to 1: Value is 0 or centered when released and can be pushed in either direction. (Joysticks)"
        )
    );
    legend_text
        ->setTextSize(16.0f)
        ->setSize(GuiElement::GuiSizeMax, 90.0f)
        ->setMargins(0.0f, 5.0f);

    auto* btn_row = new GuiElement(content, id + "_BTN_ROW");
    btn_row
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setMargins(0.0f, 5.0f)
        ->setAttribute("layout", "horizontal");

    replace_btn = new GuiButton(btn_row, id + "_REPLACE",
        tr("button", "Replace"), [this]() { commitReplace(); });
    replace_btn
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setMargins(0.0f, 0.0f, 5.0f, 0.0f)
        ->hide();

    add_btn = new GuiButton(btn_row, id + "_ADD",
        tr("button", "Add"), [this]() { commitAdd(); });
    add_btn
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setMargins(0.0f, 0.0f, 5.0f, 0.0f)
        ->hide();

    // Spacer pushes OK to the right when Replace/Add are hidden.
    (new GuiElement(btn_row, id + "_BTN_SPACER"))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    ok_btn = new GuiButton(btn_row, id + "_OK",
        tr("button", "OK"),
        [this]()
        {
            if (state == State::HasInput)
            {
                // Discard the pending capture and return to WaitingForInput.
                if (target_key)
                    target_key->discardPendingRebind();
                state = State::WaitingForInput;
                input_label->setText(tr("hotkey_menu", "[Press any key or input...]"));
                replace_btn->hide();
                add_btn->hide();
                // Restart capture for non-mouse filters.
                if (!(capture_filter & sp::io::Keybinding::Type::Mouse))
                    startCapture();
                else
                {
                    mouse_panel_btn->setText(tr("hotkey_menu", "Press mouse button here"));
                    mouse_panel_btn->enable();
                }
            }
            else
            {
                // WaitingForInput: cancel any active capture and close.
                sp::io::Keybinding::cancelUserRebind();
                closeDialog();
            }
        }
    );
    ok_btn
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    setVisible(false);
}

void GuiRebindDialog::startRebind(sp::io::Keybinding* key,
    sp::io::Keybinding::Type cf,
    sp::io::Keybinding::Type df,
    const string& action_name)
{
    target_key = key;
    capture_filter = cf;
    display_filter = df;
    state = State::WaitingForInput;

    action_label->setText(tr("hotkey_menu", "Rebinding: ") + action_name);
    input_label->setText(tr("hotkey_menu", "[Press any key or input...]"));
    replace_btn->hide();
    add_btn->hide();

    populateInteractionSelector();

    bool has_mouse = static_cast<bool>(capture_filter & sp::io::Keybinding::Type::Mouse);

    mouse_panel_btn->setVisible(has_mouse);
    if (has_mouse)
    {
        mouse_panel_btn->setText(tr("hotkey_menu", "Press mouse button here"));
        mouse_panel_btn->enable();
    }

    active_dialog = this;
    setVisible(true);

    // For non-mouse filters, start listening immediately.
    if (!has_mouse) startCapture();
}

void GuiRebindDialog::closeIfOpen()
{
    if (active_dialog == this)
    {
        sp::io::Keybinding::cancelUserRebind();
        closeDialog();
    }
}

bool GuiRebindDialog::isAnyActive()
{
    return active_dialog != nullptr;
}

void GuiRebindDialog::startCapture()
{
    if (!target_key) return;
    target_key->startUserRebindPreview(capture_filter, selected_interaction);
}

void GuiRebindDialog::populateInteractionSelector()
{
    interaction_options.clear();
    interaction_selector->clear();

    if (!target_key) return;

    auto supported = target_key->getSupportedInteractions();

    // Associate interaction names with types
    struct {
        sp::io::Keybinding::Interaction inter;
        const char* name;
    } opts[] = {
        {sp::io::Keybinding::Interaction::Discrete, "Discrete"},
        {sp::io::Keybinding::Interaction::Continuous, "Continuous"},
        {sp::io::Keybinding::Interaction::Repeating, "Repeating"},
        {sp::io::Keybinding::Interaction::Axis0, "Axis 0 to 1"},
        {sp::io::Keybinding::Interaction::Axis1, "Axis -1 to 1"},
    };

    for (auto& o : opts)
    {
        if (supported & o.inter)
        {
            interaction_options.push_back(o.inter);
            interaction_selector->setEntryIcon(interaction_selector->addEntry(tr("interaction", o.name), ""), interactionIcon(o.inter));
        }
    }

    if (!interaction_options.empty())
    {
        interaction_selector->setSelectionIndex(0);
        selected_interaction = interaction_options[0];
    }
    else selected_interaction = sp::io::Keybinding::Interaction::None;

    interaction_row->setVisible(interaction_options.size() > 1);
}

bool GuiRebindDialog::onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    // Block clicks from reaching elements behind the dialog.
    // Children handle their own events through the normal GuiElement dispatch.
    return true;
}

void GuiRebindDialog::onDraw(sp::RenderTarget& renderer)
{
    // Detect transition from WaitingForInput to HasInput when a key is captured.
    if (target_key && target_key->hasPendingRebind() && state == State::WaitingForInput)
    {
        state = State::HasInput;
        input_label->setText(target_key->getPendingRebindKeyName());
        replace_btn->show();
        add_btn->show();
    }
}

void GuiRebindDialog::closeDialog()
{
    target_key = nullptr;
    active_dialog = nullptr;
    setVisible(false);
}

void GuiRebindDialog::commitReplace()
{
    if (!target_key || !target_key->hasPendingRebind()) return;

    target_key->setPendingRebindInteraction(selected_interaction);
    int new_raw_key = target_key->getPendingRebindRawKey();

    // Remove existing bindings that match display_filter and don't share the
    // same raw key number as the pending binding.
    int count = 0;
    while (target_key->getKeyType(count) != sp::io::Keybinding::Type::None)
        count++;

    for (int i = count - 1; i >= 0; --i)
    {
        if ((target_key->getKeyType(i) & display_filter)
            && target_key->getRawKeyNumber(i) != new_raw_key)
        {
            target_key->removeKey(i);
        }
    }

    target_key->commitPendingRebind();
    closeDialog();
}

void GuiRebindDialog::commitAdd()
{
    if (!target_key || !target_key->hasPendingRebind()) return;
    target_key->setPendingRebindInteraction(selected_interaction);
    target_key->commitPendingRebind();
    closeDialog();
}
