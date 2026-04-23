#include "utilityBeamScreen.h"
#include <i18n.h>
#include "playerInfo.h"
#include "preferenceManager.h"

#include "components/radar.h"
#include "components/utilityBeam.h"

#include "screenComponents/utilityBeamControls.h"
#include "screenComponents/alertOverlay.h"
#include "screenComponents/customShipFunctions.h"
#include "screenComponents/radarZoomSlider.h"

#include "gui/theme.h"
#include "gui/gui2_image.h"
#include "gui/gui2_label.h"

UtilityBeamScreen::UtilityBeamScreen(GuiContainer* owner)
: GuiOverlay(owner, "TRACTOR_BEAM_SCREEN", GuiTheme::getColor("background"))
{
    float lrr_short = DEFAULT_MIN_ZOOM_DISTANCE;
    float lrr_long = DEFAULT_MAX_ZOOM_DISTANCE;

    background_gradient = new GuiImage(this, "BACKGROUND_GRADIENT", "");
    background_gradient
        ->setTextureThemed("background.gradient")
        ->setPosition(120.0f, 0.0f, sp::Alignment::CenterLeft)
        ->setSize(900.0f, GuiElement::GuiSizeMax);

    (new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255,255,255,255}))
        ->setTextureTiledThemed("background.crosses");

    (new AlertLevelOverlay(this));

    missing_beam_warning = new GuiLabel(this, "", tr("No utility beam"), 50.0f);
    missing_beam_warning
        ->setAlignment(sp::Alignment::Center)
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    radar_container = new GuiElement(this, "");
    radar_container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    if (auto lrr = my_spaceship.getComponent<LongRangeRadar>())
    {
        lrr_short = lrr->short_range;
        lrr_long = lrr->long_range;
    }

    // Draw the radar.
    radar = new GuiRadarView(radar_container, "UTILITY_BEAM_RADAR", lrr_long, nullptr);
    radar
        ->setRangeIndicatorStepSize(DEFAULT_MIN_ZOOM_DISTANCE)
        ->shortRange()
        ->enableWaypoints()
        ->enableCallsigns()
        ->enableHeadingIndicators()
        ->setStyle(GuiRadarView::Circular)
        ->setFogOfWarStyle(GuiRadarView::NebulaFogOfWar)
        ->setCallbacks(
            // On pointer button down
            [this](sp::io::Pointer::Button button, glm::vec2 position)
            {
                if (auto transform = my_spaceship.getComponent<sp::Transform>())
                {
                    if (my_spaceship.hasComponent<UtilityBeam>())
                    {
                        const float distance = glm::length(position - transform->getPosition());
                        float angle = fmodf(vec2ToAngle(position - transform->getPosition()) + 90.0f, 360.0f);
                        if (angle < 0.0f) angle += 360.0f;
                        my_player_info->commandSetUtilityBeamBearing(angle);
                        my_player_info->commandSetUtilityBeamRange(distance);
                    }
                }
            },
            // On pointer button drag
            [this](glm::vec2 position)
            {
                if (auto transform = my_spaceship.getComponent<sp::Transform>())
                {
                    if (my_spaceship.hasComponent<UtilityBeam>())
                    {
                        const float distance = glm::length(position - transform->getPosition());
                        float angle = fmodf(vec2ToAngle(position - transform->getPosition()) + 90.0f, 360.0f);
                        if (angle < 0.0f) angle += 360.0f;
                        my_player_info->commandSetUtilityBeamBearing(angle);
                        my_player_info->commandSetUtilityBeamRange(distance);
                    }
                }
            },
            // On pointer button up
            [this](glm::vec2 position)
            {
                if (auto transform = my_spaceship.getComponent<sp::Transform>())
                {
                    if (my_spaceship.hasComponent<UtilityBeam>())
                    {
                        const float distance = glm::length(position - transform->getPosition());
                        float angle = fmodf(vec2ToAngle(position - transform->getPosition()) + 90.0f, 360.0f);
                        if (angle < 0.0f) angle += 360.0f;
                        my_player_info->commandSetUtilityBeamBearing(angle);
                        my_player_info->commandSetUtilityBeamRange(distance);
                    }
                }
            },
            // On mousewheel
            [this](float value, glm::vec2 position)
            {
                doRadarZoom(value);
            }
        )
        ->setAutoRotating(PreferencesManager::get("science_radar_lock", "0") == "1")
        ->setPosition(120.0f, 0.0f, sp::Alignment::CenterLeft)
        ->setSize(900.0f, GuiElement::GuiSizeMax);

    zoom_slider = new GuiRadarZoomSlider(radar_container, "RADAR_ZOOM", lrr_short, lrr_long, lrr_long, radar);
    zoom_slider
        ->setPosition(-20.0f, -20.0f, sp::Alignment::BottomRight)
        ->setSize(250.0f, 50.0f);

    (new GuiUtilityBeamControls(radar_container, CrewPosition::utilityBeam, "UTILITY_BEAM_CONTROLS"))
        ->setPosition(-20.0f, 120.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, 400.0f)
        ->setAttribute("layout", "vertical");

    (new GuiCustomShipFunctions(radar_container, CrewPosition::utilityBeam, ""))
        ->setPosition(-20.0f, 520.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, 400.0f);
}

void UtilityBeamScreen::onDraw(sp::RenderTarget& renderer)
{
    GuiOverlay::onDraw(renderer);

    if (!isVisible()) return;

    auto utility_beam = my_spaceship.getComponent<UtilityBeam>();
    background_gradient->setVisible(utility_beam);
    radar_container->setVisible(utility_beam);
    missing_beam_warning->setVisible(!utility_beam);
    if (!utility_beam) return;

    radar->setDistance(utility_beam->max_range);
}

void UtilityBeamScreen::doRadarZoom(float value)
{
    const float view_distance = std::clamp(
        radar->getDistance() * (1.0f - value * 0.1f),
        previous_short_range_radar,
        previous_long_range_radar
    );
    radar->setDistance(view_distance);
    zoom_slider->setValue(view_distance);
}
