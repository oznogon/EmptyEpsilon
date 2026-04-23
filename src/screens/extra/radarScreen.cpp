#include "radarScreen.h"
#include "playerInfo.h"
#include "gameGlobalInfo.h"

#include "components/radar.h"

#include "screenComponents/radarView.h"
#include "screenComponents/alertOverlay.h"
#include "screenComponents/jumpIndicator.h"
#include "screenComponents/selfDestructIndicator.h"
#include "screenComponents/globalMessage.h"
#include "screenComponents/customShipFunctions.h"

#include "gui/theme.h"
#include "gui/gui2_image.h"

RadarScreen::RadarScreen(GuiContainer* owner, string type)
: GuiOverlay(owner, "RADAR_SCREEN", GuiTheme::getColor("background")), radar_type(type)
{
    (new GuiImage(this, "BACKGROUND_GRADIENT", ""))
        ->setTextureThemed("background.gradient")
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(1200.0f, 900.0f);

    (new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255,255,255,255}))
        ->setTextureTiledThemed("background.crosses");

    (new AlertLevelOverlay(this));

    auto lrr = my_spaceship.getComponent<LongRangeRadar>();
    float initial_distance;
    if (type == "long_range")
        initial_distance = lrr ? lrr->long_range : 30000.0f;
    else
        initial_distance = lrr ? lrr->short_range : 5000.0f;

    radar = new GuiRadarView(this, "RADAR_VIEW", initial_distance, &targets);
    radar
        ->setRangeIndicatorStepSize(1000.0f)
        ->enableCallsigns()
        ->enableHeadingIndicators()
        ->setStyle(GuiRadarView::Circular)
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMatchHeight, 900.0f);

    if (type == "long_range")
        radar->longRange();
    else
        radar->shortRange();

    (new GuiJumpIndicator(this))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    (new GuiSelfDestructIndicator(this))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    (new GuiGlobalMessage(this))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    (new GuiCustomShipFunctions(this, CrewPosition::radarOfficer, ""))
        ->setPosition(-20.0f, 120.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, GuiElement::GuiSizeMax);
}

void RadarScreen::onDraw(sp::RenderTarget& renderer)
{
    if (my_spaceship)
    {
        auto lrr = my_spaceship.getComponent<LongRangeRadar>();
        if (radar_type == "long_range")
            radar->setDistance(lrr ? lrr->long_range : 30000.0f);
        else
            radar->setDistance(lrr ? lrr->short_range : 5000.0f);
    }
    GuiOverlay::onDraw(renderer);
}
