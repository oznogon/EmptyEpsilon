#include "globalMessageEntryView.h"
#include <i18n.h>
#include "GMActions.h"

#include "gui/gui2_textentry.h"
#include "gui/gui2_button.h"

GuiGlobalMessageEntryView::GuiGlobalMessageEntryView(GuiContainer* owner)
: GuiPanel(owner, "GLOBAL_MESSAGE_ENTRY")
{
    setPosition(0.0f, -100.0f, sp::Alignment::BottomCenter);
    setSize(800.0f, 140.0f);
    setAttribute("padding", "20");
    setAttribute("layout", "vertical");

    message_entry = new GuiTextEntry(this, "MESSAGE_ENTRY", "");
    message_entry
        ->setSize(GuiElement::GuiSizeMax, 50.0f);

    GuiElement* row = new GuiElement(this, "");
    row
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("layout", "horizontal");

    (new GuiButton(row, "CLOSE_BUTTON", tr("button", "Cancel"),
        [this]() { hide(); }
    ))
        ->setSize(300.0f, GuiElement::GuiSizeMax);

    (new GuiElement(row, "SPACER"))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    (new GuiButton(row, "SEND_BUTTON", tr("button", "Send"),
        [this]()
        {
            string message = message_entry->getText();
            gameMasterActions->commandSendGlobalMessage(message);
            hide();
        }
    ))
        ->setSize(300.0f, GuiElement::GuiSizeMax);
}

bool GuiGlobalMessageEntryView::onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    // Catch clicks.
    return true;
}
