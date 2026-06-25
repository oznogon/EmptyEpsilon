#include <i18n.h>
#include "init/config.h"
#include "engine.h"
#include "hotkeyMenu.h"
#include <regex>
#include "soundManager.h"
#include "main.h"

#include "gui/hotkeyBinder.h"
#include "gui/theme.h"
#include "gui/gui2_button.h"
#include "gui/gui2_canvas.h"
#include "gui/gui2_label.h"
#include "gui/gui2_overlay.h"
#include "gui/gui2_scrollcontainer.h"
#include "gui/gui2_scrolltextcontainer.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_textentry.h"
#include "gui/gui2_togglebutton.h"

HotkeyMenu::HotkeyMenu(OptionsMenu::ReturnTo return_to)
: return_to(return_to)
{
    // Background decorations
    new GuiOverlay(this, "", GuiTheme::getColor("background"));
    (new GuiOverlay(this, "", glm::u8vec4{255, 255, 255, 255}))
        ->setTextureTiledThemed("background.crosses");

    container = new GuiElement(this, "HOTKEY_CONFIG_CONTAINER");
    container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopLeft)
        ->setAttribute("padding", "50");
    container
        ->setAttribute("layout", "vertical");

    top_row = new GuiElement(container, "TOP_ROW_CONTAINER");
    top_row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 20");

    // Fixed column header row (shows KB/JS/Mouse labels, not scrollable).
    auto* header_row = new GuiElement(container, "HOTKEY_HEADER");
    header_row
        ->setSize(KEY_COLUMN_WIDTH + FRAME_MARGIN, GuiElement::GuiSizeRow * 0.5f)
        ->setAttribute("layout", "horizontal");
    header_row
        ->setAttribute("margin", "0, 0, 0, 10");

    (new GuiElement(header_row, "HOTKEY_HEADER_SPACER"))
        ->setSize(KEY_LABEL_WIDTH + KEY_LABEL_MARGIN + KEY_BINDER_MARGIN, GuiElement::GuiSizeMax);
    (new GuiLabel(header_row, "HOTKEY_HEADER_KB", tr("Keyboard"), 30.0f))
        ->setAlignment(sp::Alignment::CenterLeft)
        ->setSize(KEY_BINDER_WIDTH + KEY_BINDER_MARGIN, GuiElement::GuiSizeMax);
    (new GuiLabel(header_row, "HOTKEY_HEADER_JS", tr("Joystick"), 30.0f))
        ->setAlignment(sp::Alignment::CenterLeft)
        ->setSize(KEY_BINDER_WIDTH + KEY_BINDER_MARGIN, GuiElement::GuiSizeMax);
    (new GuiLabel(header_row, "HOTKEY_HEADER_MS", tr("Mouse"), 30.0f))
        ->setAlignment(sp::Alignment::CenterLeft)
        ->setSize(KEY_BINDER_WIDTH + KEY_BINDER_MARGIN, GuiElement::GuiSizeMax);

    rebinding_scroll = new GuiScrollContainer(container, "HOTKEY_SCROLL", GuiScrollContainer::ScrollMode::Scroll);
    rebinding_scroll
        ->setSize(KEY_COLUMN_WIDTH + FRAME_MARGIN, GuiElement::GuiSizeMax)
        ->setMargins(0.0f, 20.0f)
        ->setAttribute("layout", "vertical");

    info_container = new GuiElement(container, "INFO_CONTAINER");
    info_container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow * 3.0f);

    bottom_row = new GuiElement(container, "BOTTOM_ROW_CONTAINER");
    bottom_row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    // Title label
    (new GuiLabel(top_row, "CONFIGURE_CONTROLS_LABEL", tr("Configure controls"), 30.0f))
        ->addBackground()
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopLeft)
        ->setSize(300.0f, GuiElement::GuiSizeMax);

    // Category selector
    category_list = sp::io::Keybinding::getCategories();
    category_selector = new GuiSelector(top_row, "Category",
        [this](int index, string value)
        {
            HotkeyMenu::setCategory(index);
        }
    );
    category_selector
        ->setOptions(category_list)
        ->setSelectionIndex(category_index)
        ->setSize(300.0f, GuiElement::GuiSizeMax)
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopCenter);

    // Info text for non-dialog mode
    (new GuiScrollFormattedText(info_container, "HOTKEY_INFO_LABEL", tr("Left click: Assign input. Middle click: Add input. Right click: Delete inputs.\nPossible inputs: Keyboard keys, joystick buttons, joystick axes, mouse axes.")))
        ->setPosition(10.0f, 0.0f, sp::Alignment::TopCenter)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow * 3.0f);

    (new GuiButton(bottom_row, "BACK", tr("button", "Back"),
        [this, return_to]()
        {
            destroy();
            soundManager->stopMusic();
            returnToOptionMenu(return_to);
        }
    ))
        ->setPosition(0, 0, sp::Alignment::BottomLeft)
        ->setSize(250.0f, GuiElement::GuiSizeMax);

    // Reset keybinds confirmation
    reset_label = new GuiLabel(bottom_row, "RESET_LABEL", tr("Bindings reset to defaults"), GuiElement::GuiSizeLabel);
    reset_label
        ->addBackground()
        ->setAlignment(sp::Alignment::Center)
        ->setPosition(-250.0f, 0.0f, sp::Alignment::BottomRight)
        ->setSize(300.0f, GuiElement::GuiSizeRow)
        ->hide();

    // Reset keybinds button
    (new GuiButton(bottom_row, "RESET", tr("button", "Reset"),
        [this]()
        {
            reset_label->setVisible(true);
            reset_label_timer.start(RESET_LABEL_TIMEOUT);

            // Iterate through all bindings and reset to defaults.
            for (auto category : sp::io::Keybinding::getCategories())
            {
                for (auto item : sp::io::Keybinding::listAllByCategory(category))
                {
                    item->clearKeys();

                    std::vector<string> default_bindings = item->getDefaultBindings();
                    for (auto binding : default_bindings) item->addKey(binding);

                    // Set each restored binding's interaction to the keybinding's
                    // default interaction for that input type.
                    for (int i = 0; item->getKeyType(i) != sp::io::Keybinding::Type::None; i++)
                        item->setInteraction(i, item->getDefaultInteraction(item->getKeyType(i)));
                }
            }
        }
    ))
        ->setPosition(0.0f, 0.0f, sp::Alignment::BottomRight)
        ->setSize(250.0f, GuiElement::GuiSizeMax);

    // Build the rebind dialog. Created last so it renders on top of everything.
    rebind_dialog = new GuiRebindDialog(this, "REBIND_DIALOG");

    // Dialog mode is on by default; hide the info text since the dialog
    // provides its own legend.
    info_container->hide();

    // Show category 0 ("General")
    HotkeyMenu::setCategory(0);
    category_selector->setSelectionIndex(0);
}

void HotkeyMenu::update(float delta)
{
    if (reset_label->isVisible() && reset_label_timer.isExpired())
        reset_label->hide();

    // Return to the options menu on Esc/Home bind, but not while rebinding or
    // while the rebind dialog is open.
    if (keys.escape.getDown()
        && !GuiHotkeyBinder::isAnyRebinding())
    {
        destroy();
        returnToOptionMenu(return_to);
    }

    // Change rebind category, but not while rebinding or while the rebind
    // dialog is open.
    if (keys.next_rebind_category.getDown()
        && !GuiHotkeyBinder::isAnyRebinding())
        setCategory(category_index + 1);
    if (keys.prev_rebind_category.getDown()
        && !GuiHotkeyBinder::isAnyRebinding())
        setCategory(category_index - 1);
}

// Display a list of hotkeys to bind from the given hotkey category.
void HotkeyMenu::setCategory(int cat)
{
    // Loop category index if out of range.
    if (cat >= static_cast<int>(category_list.size())) cat = 0;
    if (cat < 0) cat = static_cast<int>(category_list.size()) - 1;

    // Close the dialog if it was open for a binder that is about to be destroyed.
    rebind_dialog->closeIfOpen();

    // Remove any previous category's hotkey entries.
    for (GuiHotkeyBinder* text : text_entries) text->destroy();
    text_entries.clear();
    for (auto label : label_entries) label->destroy();
    label_entries.clear();
    for (auto row : rebinding_rows) row->destroy();
    rebinding_rows.clear();

    // Get the chosen category
    category_index = cat;
    category = category_list[cat];

    // Get all hotkeys in this category.
    hotkey_list = sp::io::Keybinding::listAllByCategory(category);

    const sp::io::Keybinding::Type joystick_type = sp::io::Keybinding::Type::Joystick | sp::io::Keybinding::Type::Controller;

    // Render hotkey rebinding fields for this category.
    for (auto item : hotkey_list)
    {
        // Add a rebinding row.
        rebinding_rows.push_back(new GuiElement(rebinding_scroll, ""));
        rebinding_rows.back()->setSize(GuiElement::GuiSizeMax, KEY_ROW_HEIGHT)->setAttribute("layout", "horizontal");

        // Add a label to the current row.
        label_entries.push_back(new GuiLabel(rebinding_rows.back(), "HOTKEY_LABEL_" + item->getName(), item->getLabel(), 30.0f));
        label_entries.back()
            ->setWrapped()
            ->setAlignment(sp::Alignment::TopRight)
            ->setSize(KEY_LABEL_WIDTH, GuiElement::GuiSizeMax)
            ->setMargins(0.0f, 2.0f, KEY_LABEL_MARGIN, 0.0f);

        // Keyboard-only binder.
        text_entries.push_back(new GuiHotkeyBinder(rebinding_rows.back(), "HOTKEY_KB_" + item->getName(), item,
            sp::io::Keybinding::Type::Keyboard, sp::io::Keybinding::Type::Keyboard));
        text_entries.back()
            ->setSize(KEY_BINDER_WIDTH, GuiElement::GuiSizeMax)
            ->setMargins(0.0f, 0.0f, KEY_BINDER_MARGIN, 0.0f);
        text_entries.back()->setDialog(rebind_dialog);

        // Joystick/controller-only binder.
        text_entries.push_back(new GuiHotkeyBinder(rebinding_rows.back(), "HOTKEY_JS_" + item->getName(), item,
            joystick_type, joystick_type));
        text_entries.back()
            ->setSize(KEY_BINDER_WIDTH, GuiElement::GuiSizeMax)
            ->setMargins(0.0f, 0.0f, KEY_BINDER_MARGIN, 0.0f);
        text_entries.back()->setDialog(rebind_dialog);

        // Mouse-only binder.
        text_entries.push_back(new GuiHotkeyBinder(rebinding_rows.back(), "HOTKEY_MS_" + item->getName(), item,
            sp::io::Keybinding::Type::Mouse, sp::io::Keybinding::Type::Mouse));
        text_entries.back()
            ->setSize(KEY_BINDER_WIDTH, GuiElement::GuiSizeMax)
            ->setMargins(0.0f, 0.0f, KEY_BINDER_MARGIN, 0.0f);
        text_entries.back()->setDialog(rebind_dialog);
    }

    category_selector->setSelectionIndex(cat);
}
