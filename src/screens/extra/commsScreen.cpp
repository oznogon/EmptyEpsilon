#include "commsScreen.h"
#include <i18n.h>
#include "playerInfo.h"

#include "components/comms.h"

#include "gui/theme.h"
#include "gui/gui2_label.h"

#include "screenComponents/alertOverlay.h"
#include "screenComponents/commsOverlay.h"
#include "screenComponents/shipsLogControl.h"

CommsScreen::CommsScreen(GuiContainer* owner)
: GuiOverlay(owner, "COMMS_SCREEN", GuiTheme::getColor("background"))
{
    // Render the background decorations.
    (new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255, 255, 255, 255}))
        ->setTextureTiledThemed("background.crosses");

    // Render the alert level color overlay.
    new AlertLevelOverlay(this);

    // Message if entity lacks CommsTransmitter or CommsReceiver components.
    no_comms_label = new GuiLabel(this, "NO_COMMS_LABEL", tr("comms", "No comms available"), 50.0f);
    no_comms_label
        ->setAlignment(sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Render the ship's log.
    new ShipsLog(this);

    // Render the comms interaction overlay.
    (new GuiCommsOverlay(this))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
}

void CommsScreen::onUpdate()
{
    if (!my_spaceship || !isVisible()) return;

    // Message if entity lacks CommsTransmitter or CommsReceiver components.
    no_comms_label->setVisible(!my_spaceship.hasComponent<CommsTransmitter>() && !my_spaceship.hasComponent<CommsReceiver>());
}
