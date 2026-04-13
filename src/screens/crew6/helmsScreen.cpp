#include "helmsScreen.h"
#include <i18n.h>
#include "playerInfo.h"
#include "preferenceManager.h"
#include "featureDefs.h"

#include "components/reactor.h"
#include "components/warpdrive.h"
#include "components/jumpdrive.h"
#include "components/collision.h"
#include "components/maneuveringthrusters.h"
#include "components/docking.h"

#include "screenComponents/combatManeuver.h"
#include "screenComponents/radarView.h"
#include "screenComponents/impulseControls.h"
#include "screenComponents/warpControls.h"
#include "screenComponents/jumpControls.h"
#include "screenComponents/dockingButton.h"
#include "screenComponents/alertOverlay.h"
#include "screenComponents/customShipFunctions.h"
#include "screenComponents/infoDisplay.h"

#include "gui/theme.h"
#include "gui/gui2_label.h"
#include "gui/gui2_tooltip.h"
#include "gui/gui2_togglebutton.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_image.h"

HelmsScreen::HelmsScreen(GuiContainer* owner)
: GuiOverlay(owner, "HELMS_SCREEN", GuiTheme::getColor("background"))
{
    // Render the radar shadow and background decorations.
    (new GuiImage(this, "BACKGROUND_GRADIENT", ""))->setTextureThemed("background.gradient")->setPosition(glm::vec2(0, 0), sp::Alignment::Center)->setSize(1200, 900);

    background_crosses = new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255,255,255,255});
    background_crosses->setTextureTiledThemed("background.crosses");

    // Render the alert level color overlay.
    (new AlertLevelOverlay(this));

    radar = new GuiRadarView(this, "HELMS_RADAR", nullptr);

    combat_maneuver = new GuiCombatManeuver(this, "COMBAT_MANEUVER");
    combat_maneuver->setPosition(-20, -20, sp::Alignment::BottomRight)->setSize(280, 215);

    radar->setPosition(0, 0, sp::Alignment::Center)->setSize(GuiElement::GuiSizeMatchHeight, 800);
    radar->setRangeIndicatorStepSize(1000.0)->shortRange()->enableGhostDots()->enableWaypoints()->enableCallsigns()->enableHeadingIndicators()->setStyle(GuiRadarView::Circular);
    radar->enableMissileTubeIndicators();
    radar->setCallbacks(
        [this](sp::io::Pointer::Button button, glm::vec2 position) { // down
            if (auto transform = my_spaceship.getComponent<sp::Transform>())
                my_player_info->commandTargetRotation(vec2ToAngle(position - transform->getPosition()));
        },
        [this](glm::vec2 position) { // drag
            if (auto transform = my_spaceship.getComponent<sp::Transform>())
                my_player_info->commandTargetRotation(vec2ToAngle(position - transform->getPosition()));
        },
        [this](glm::vec2 position) { // up
            if (auto transform = my_spaceship.getComponent<sp::Transform>())
                my_player_info->commandTargetRotation(vec2ToAngle(position - transform->getPosition()));
        }, nullptr
    );
    radar->setAutoRotating(PreferencesManager::get("helms_radar_lock","0")=="1");

    heading_hint = new GuiTooltip(radar, "HEADING_HINT");
    heading_hint
        ->setPixelOffset({-60.0f, -70.0f})
        ->setSize(120.0f, 40.0f);
    heading_label = new GuiLabel(heading_hint, "HEADING_HINT_LABEL", "", 30.0f);
    heading_label
        ->setAlignment(sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    auto energy_display = new EnergyInfoDisplay(this, "ENERGY_DISPLAY", 0.45);
    energy_display->setPosition(20, 100, sp::Alignment::TopLeft)->setSize(240, 40);
    auto heading_display = new HeadingInfoDisplay(this, "HEADING_DISPLAY", 0.45);
    heading_display->setPosition(20, 140, sp::Alignment::TopLeft)->setSize(240, 40);
    auto velocity_display = new VelocityInfoDisplay(this, "VELOCITY_DISPLAY", 0.45);
    velocity_display->setPosition(20, 180, sp::Alignment::TopLeft)->setSize(240, 40);

    GuiElement* engine_layout = new GuiElement(this, "ENGINE_LAYOUT");
    engine_layout->setPosition(20, -100, sp::Alignment::BottomLeft)->setSize(GuiElement::GuiSizeMax, 300)->setAttribute("layout", "horizontal");
    (new GuiImpulseControls(engine_layout, "IMPULSE"))->setSize(100, GuiElement::GuiSizeMax);
    (new GuiWarpControls(engine_layout, "WARP"))->setSize(100, GuiElement::GuiSizeMax);
    (new GuiJumpControls(engine_layout, "JUMP"))->setSize(100, GuiElement::GuiSizeMax);

    docking_button = new GuiDockingButton(this, "DOCKING");
    docking_button->setPosition(20, -20, sp::Alignment::BottomLeft)->setSize(280, 50)->setVisible(my_spaceship.hasComponent<DockingPort>());

    (new GuiCustomShipFunctions(this, CrewPosition::helmsOfficer, ""))->setPosition(-20, 120, sp::Alignment::TopRight)->setSize(250, GuiElement::GuiSizeMax);
}

void HelmsScreen::onDraw(sp::RenderTarget& renderer)
{
    GuiOverlay::onDraw(renderer);
}

void HelmsScreen::onUpdate()
{
    if (!my_spaceship || !isVisible()) return;

    auto angle = (keys.helms_turn_right.getValue() - keys.helms_turn_left.getValue()) * 5.0f;
    if (angle != 0.0f)
    {
        if (auto transform = my_spaceship.getComponent<sp::Transform>())
            my_player_info->commandTargetRotation(transform->getRotation() + angle);
    }

    // Keep the heading label current while the cursor is on the radar.
    // Uses hover_coordinates (= current global mouse position, set on this element
    // before onUpdate fires) and radar->screenToWorld for correct conversion
    // including auto-rotation.
    if (radar->getRect().contains(hover_coordinates) || radar->isPressed())
    {
        if (auto transform = my_spaceship.getComponent<sp::Transform>())
        {
            const glm::vec2 world = radar->screenToWorld(hover_coordinates);
            const float heading = fmodf(vec2ToAngle(world - transform->getPosition()) + 90.f + 360.f, 360.f);
            heading_label->setText(string(heading, 1));
        }
    }
}
