#pragma once

#include "gui2_element.h"
#include "io/keybinding.h"
#include <vector>

class GuiThemeStyle;
class GuiSelector;

class GuiHotkeyBinder : public GuiElement
{
private:
    sp::io::Keybinding* key;
    sp::io::Keybinding::Type display_filter;
    sp::io::Keybinding::Type capture_filter;
    bool pending_rebind = false;
    sp::io::Keybinding::Interaction selected_interaction = sp::io::Keybinding::Interaction::None;

    GuiSelector* interaction_selector = nullptr;
    std::vector<sp::io::Keybinding::Interaction> interaction_selector_options;

    const GuiThemeStyle* front_style;
    const GuiThemeStyle* back_style;

    void clearFilteredKeys();
public:
    GuiHotkeyBinder(GuiContainer* owner, string id, sp::io::Keybinding* key, sp::io::Keybinding::Type display_filter = sp::io::Keybinding::Type::Default, sp::io::Keybinding::Type capture_filter = sp::io::Keybinding::Type::Default);

    // Returns true if any binder is actively rebinding. Used to prevent
    // game-wide binds like escape from being handled while binding a key.
    // The escape control can't be rebound otherwise.
    // Height of the interaction selector row appended below the binding field.
    // The parent container must add this to the row height when the keybinding
    // has more than one supported interaction.
    static constexpr float SELECTOR_HEIGHT = 50.0f;

    static bool isAnyRebinding();

    virtual bool onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id) override;
    virtual void onMouseUp(glm::vec2 position, sp::io::Pointer::ID id) override;
    virtual void onDraw(sp::RenderTarget& renderer) override;
};
