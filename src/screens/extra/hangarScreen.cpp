#include "hangarScreen.h"
#include "shipTemplate.h"
#include "playerInfo.h"
#include "spaceObjects/playerSpaceship.h"
#include "screenComponents/customShipFunctions.h"

#include "screenComponents/hangarView.h"

HangarScreen::HangarScreen(GuiContainer* owner)
: GuiOverlay(owner, "HANGAR_SCREEN", colorConfig.background)
{
    (new HangarViewComponent(this))->setPosition(0, 0, sp::Alignment::TopLeft)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    if (my_spaceship)
    {
        // LOG(INFO) << "HEY BUDDY WE IN A SHIP LMFOA";
    }
}
