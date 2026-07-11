#include "helmsScreen.h"
#include <i18n.h>
#include "playerInfo.h"
#include "preferenceManager.h"
#include "featureDefs.h"
#include "crewPositionRequirements.h"

#include "components/reactor.h"
#include "components/warpdrive.h"
#include "components/jumpdrive.h"
#include "components/collision.h"
#include "components/maneuveringthrusters.h"
#include "components/impulse.h"
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
#include "screenComponents/utilityBeamControls.h"
#include "screenComponents/utilityBeamRotationDial.h"

#include "components/customshipfunction.h"
#include "components/utilityBeam.h"

#include "gui/gui2_selector.h"

#include "gui/theme.h"
#include "gui/gui2_label.h"
#include "gui/gui2_togglebutton.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_image.h"
#include "gui/gui2_tooltip.h"

HelmsScreen::HelmsScreen(GuiContainer* owner)
: GuiOverlay(owner, "HELMS_SCREEN", GuiTheme::getColor("background"))
{
    // Render the radar shadow and background decorations.
    background_gradient = new GuiImage(this, "BACKGROUND_GRADIENT", "");
    background_gradient
        ->setTextureThemed("background.gradient")
        ->setPosition(glm::vec2(0.0f, 0.0f), sp::Alignment::Center)
        ->setSize(1200.0f, 900.0f);

    (new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255, 255, 255, 255}))
        ->setTextureTiledThemed("background.crosses");

    // Render the alert level color overlay.
    new AlertLevelOverlay(this);

    // Message if entity lacks all propulsion, maneuver, and docking
    // components.
    no_controls_label = new GuiLabel(this, "NO_CONTROLS_LABEL", crewPositionRequirements::getMissingMessage(CrewPosition::helmsOfficer), GuiElement::GuiSizeRow);
    no_controls_label
        ->setAlignment(sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide();

    helms_controls = new GuiElement(this, "");
    helms_controls->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    GuiRadarView* radar = new GuiRadarView(helms_controls, "HELMS_RADAR", nullptr);

    combat_maneuver = new GuiCombatManeuver(helms_controls, "COMBAT_MANEUVER");
    combat_maneuver->setPosition(-20, -20, sp::Alignment::BottomRight)->setSize(280, 215);
    (new GuiTextTooltip(combat_maneuver, "COMBAT_MANEUVER_TIP", tr("tooltips", "Execute combat maneuvers: strafe laterally or boost forward to evade enemies."), 20.0f))->setWidth(280.0f);

    radar->setPosition(0, 0, sp::Alignment::Center)->setSize(GuiElement::GuiSizeMatchHeight, 800);
    radar->setRangeIndicatorStepSize(1000.0)->shortRange()->enableGhostDots()->enableWaypoints()->enableCallsigns()->enableHeadingIndicators()->setStyle(GuiRadarView::Circular);
    radar->enableMissileTubeIndicators();
    radar->setCallbacks(
        [radar, this](sp::io::Pointer::Button button, glm::vec2 position) { // down
            if (auto transform = my_spaceship.getComponent<sp::Transform>())
            {
                auto r = radar->getRect();
                float angle = vec2ToAngle(position - transform->getPosition());

                // Rotate the position to match radar's rotation.
                glm::vec2 draw_position;
                if (radar->getAutoRotating())
                {
                    auto rotation = -radar->getViewRotation();
                    glm::vec2 position_from_center = position - transform->getPosition();
                    draw_position.x = position_from_center.x * cosf(glm::radians(rotation)) - position_from_center.y * sinf(glm::radians(rotation));
                    draw_position.y = position_from_center.x * sinf(glm::radians(rotation)) + position_from_center.y * cosf(glm::radians(rotation));
                }
                else{
                    draw_position = (position - transform->getPosition());
                }
                draw_position = rect.center() + draw_position / radar->getDistance() * std::min(r.size.x, r.size.y) * 0.5f;
                heading_hint->setText(string(fmodf(angle + 90.f + 360.f, 360.f), 1))->setPosition(draw_position - rect.position - glm::vec2(0, 50))->show();
                my_player_info->commandTargetRotation(angle);
            }
        },
        [radar, this](glm::vec2 position) { // drag
            if (auto transform = my_spaceship.getComponent<sp::Transform>())
            {
                auto r = radar->getRect();
                float angle = vec2ToAngle(position - transform->getPosition());

                // Rotate the position to match radar's rotation.
                glm::vec2 draw_position;
                if (radar->getAutoRotating())
                {
                    auto rotation = -radar->getViewRotation();
                    glm::vec2 position_from_center = position - transform->getPosition();
                    draw_position.x = position_from_center.x * cosf(glm::radians(rotation)) - position_from_center.y * sinf(glm::radians(rotation));
                    draw_position.y = position_from_center.x * sinf(glm::radians(rotation)) + position_from_center.y * cosf(glm::radians(rotation));
                }
                else{
                    draw_position = (position - transform->getPosition());
                }
                draw_position = rect.center() + draw_position / radar->getDistance() * std::min(r.size.x, r.size.y) * 0.5f;
                heading_hint->setText(string(fmodf(angle + 90.f + 360.f, 360.f), 1))->setPosition(draw_position - rect.position - glm::vec2(0, 50))->show();
                my_player_info->commandTargetRotation(angle);
            }
        },
        [this](glm::vec2 position) { // up
            if (auto transform = my_spaceship.getComponent<sp::Transform>())
                my_player_info->commandTargetRotation(vec2ToAngle(position - transform->getPosition()));
            heading_hint->hide();
        }, nullptr
    );
    radar->setAutoRotating(PreferencesManager::get("helms_radar_lock","0")=="1");

    heading_hint = new GuiLabel(helms_controls, "HEADING_HINT", "", 30);
    heading_hint->setAlignment(sp::Alignment::Center)->setSize(0, 0);

    auto energy_display = new EnergyInfoDisplay(helms_controls, "ENERGY_DISPLAY", 0.45);
    energy_display->setPosition(20, 100, sp::Alignment::TopLeft)->setSize(240, 40);
    (new GuiTextTooltip(energy_display, "HELMS_ENERGY_TIP", tr("tooltips", "Current reactor energy level."), 20.0f))->setWidth(280.0f);
    auto heading_display = new HeadingInfoDisplay(helms_controls, "HEADING_DISPLAY", 0.45);
    heading_display->setPosition(20, 140, sp::Alignment::TopLeft)->setSize(240, 40);
    (new GuiTextTooltip(heading_display, "HEADING_TIP", tr("tooltips", "Current ship heading in degrees."), 20.0f))->setWidth(280.0f);
    auto velocity_display = new VelocityInfoDisplay(helms_controls, "VELOCITY_DISPLAY", 0.45);
    velocity_display->setPosition(20, 180, sp::Alignment::TopLeft)->setSize(240, 40);
    (new GuiTextTooltip(velocity_display, "VELOCITY_TIP", tr("tooltips", "Current ship velocity."), 20.0f))->setWidth(280.0f);

    GuiElement* engine_layout = new GuiElement(helms_controls, "ENGINE_LAYOUT");
    engine_layout->setPosition(20, -100, sp::Alignment::BottomLeft)->setSize(GuiElement::GuiSizeMax, 300)->setAttribute("layout", "horizontal");
    auto* impulse = new GuiImpulseControls(engine_layout, "IMPULSE");
    impulse->setSize(100, GuiElement::GuiSizeMax);
    (new GuiTextTooltip(impulse, "IMPULSE_TIP", tr("tooltips", "Adjust impulse engine throttle forward and reverse for sub-light travel."), 20.0f))->setWidth(280.0f);
    auto* warp = new GuiWarpControls(engine_layout, "WARP");
    warp->setSize(100, GuiElement::GuiSizeMax);
    (new GuiTextTooltip(warp, "WARP_TIP", tr("tooltips", "Engage or disengage the warp drive for faster-than-light travel."), 20.0f))->setWidth(280.0f);
    auto* jump = new GuiJumpControls(engine_layout, "JUMP");
    jump->setSize(100, GuiElement::GuiSizeMax);
    (new GuiTextTooltip(jump, "JUMP_TIP", tr("tooltips", "Charge and activate the jump drive to instantly travel long distances."), 20.0f))->setWidth(280.0f);

    docking_button = new GuiDockingButton(helms_controls, "DOCKING");
    docking_button->setPosition(20, -20, sp::Alignment::BottomLeft)->setSize(280, 50)->setVisible(my_spaceship.hasComponent<DockingPort>());
    (new GuiTextTooltip(docking_button, "DOCKING_TIP", tr("tooltips", "Request docking with or undocking from the nearest station or ship."), 20.0f))->setWidth(280.0f);

    auto ub = my_spaceship.getComponent<UtilityBeam>();

    sidebar_selector = new GuiSelector(helms_controls, "HELMS_SIDEBAR_SELECTOR", [this](int index, string value)
    {
        if (value == "func")
        {
            custom_function_sidebar->setVisible(custom_function_sidebar->hasEntries());
            utility_beam_sidebar->hide();
            utility_beam_dial->hide();
        }
        else if (value == "util")
        {
            custom_function_sidebar->hide();
            utility_beam_sidebar->show();
            utility_beam_dial->show();
        }
    });
    sidebar_selector->setPosition(-20, 120, sp::Alignment::TopRight)->setSize(250, 50)->hide();
    (new GuiTextTooltip(sidebar_selector, "HELMS_SIDEBAR_TIP", tr("tooltips", "Switch between custom ship functions and utility beam controls."), 20.0f))->setWidth(280.0f);

    custom_function_sidebar = new GuiCustomShipFunctions(helms_controls, CrewPosition::helmsOfficer, "HELMS_CUSTOM_FUNCS");
    custom_function_sidebar
        ->setPosition(-20.0f, 170.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, 450.0f)
        ->hide();

    utility_beam_sidebar = new GuiUtilityBeamControls(helms_controls, CrewPosition::helmsOfficer, "UTILITY_BEAM_CONTROLS");
    utility_beam_sidebar->setPosition(-20, 170, sp::Alignment::TopRight)->setSize(250, GuiElement::GuiSizeMax)->setAttribute("layout", "vertical");
    utility_beam_sidebar->hide();

    utility_beam_dial = new GuiUtilityBeamRotationDial(radar, "UTILITY_BEAM_DIAL", radar);
    utility_beam_dial->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)->hide();

    if (custom_function_sidebar->hasEntries())
    {
        sidebar_selector->addEntry(tr("helmsTab", "Functions"), "func");
        sidebar_selector->show();
    }
    if (ub && ub->crew_positions.has(CrewPosition::helmsOfficer))
    {
        sidebar_selector->addEntry(tr("helmsTab", "Utility Beam"), "util");
        sidebar_selector->show();
    }

    // Set initial sidebar state by manually applying the first tab.
    if (sidebar_selector->entryCount() > 0)
    {
        sidebar_selector->setSelectionIndex(0);
        if (sidebar_selector->getSelectionValue() == "func")
            custom_function_sidebar->setVisible(custom_function_sidebar->hasEntries());
        else if (sidebar_selector->getSelectionValue() == "util")
        {
            utility_beam_sidebar->show();
            utility_beam_dial->show();
        }
    }
}

void HelmsScreen::onDraw(sp::RenderTarget& renderer)
{
    if (my_spaceship)
    {
        const bool has_any_propulsion = crewPositionRequirements::hasRequirements(CrewPosition::helmsOfficer, my_spaceship);
        if (!has_any_propulsion)
        {
            GuiOverlay::onDraw(renderer);
            return;
        }
    }
    GuiOverlay::onDraw(renderer);
}

void HelmsScreen::onUpdate()
{
    if (!my_spaceship || !isVisible()) return;

    const bool has_any_propulsion = crewPositionRequirements::hasRequirements(CrewPosition::helmsOfficer, my_spaceship);

    background_gradient->setVisible(has_any_propulsion);
    helms_controls->setVisible(has_any_propulsion);
    no_controls_label->setVisible(!has_any_propulsion);

    if (!has_any_propulsion) return;

    // Impulse, jump, warp hotkeys are handled in their screen components.

    // Handle rotational hotkeys.
    auto thrusters = my_spaceship.getComponent<ManeuveringThrusters>();
    const float turn_scale = thrusters ? thrusters->speed : 10.0f;
    auto continuous_angle = (keys.helms_turn_right.getContinuousValue() - keys.helms_turn_left.getContinuousValue()) * turn_scale;
    continuous_angle += (keys.helms_turn_right.getAxis0Value() - keys.helms_turn_left.getAxis0Value()) * turn_scale;
    continuous_angle += (keys.helms_turn_right.getAxis1Value() - keys.helms_turn_left.getAxis1Value()) * turn_scale;
    float discrete_angle = 0.0f;
    if (keys.helms_turn_right.isDiscreteStepDown() || keys.helms_turn_right.isRepeatReady()) discrete_angle += turn_scale * 0.5f;
    if (keys.helms_turn_left.isDiscreteStepDown() || keys.helms_turn_left.isRepeatReady()) discrete_angle -= turn_scale * 0.5f;

    // Combine input angles and stop turning if key is up.
    if (continuous_angle != 0.0f)
    {
        if (auto transform = my_spaceship.getComponent<sp::Transform>())
            my_player_info->commandTargetRotation(transform->getRotation() + continuous_angle + discrete_angle);
        continuous_turning = true;
    }
    else if (discrete_angle != 0.0f)
    {
        if (auto transform = my_spaceship.getComponent<sp::Transform>())
            my_player_info->commandTargetRotation(transform->getRotation() + discrete_angle);
        continuous_turning = false;
    }
    else if (continuous_turning)
    {
        my_player_info->commandTurnSpeed(0.0f);
        continuous_turning = false;
    }

    auto utility_beam = my_spaceship.getComponent<UtilityBeam>();

    // Synchronize the Functions sidebar tab with current custom ship functions.
    bool should_have_func_tab = custom_function_sidebar->hasEntries();
    bool has_func_tab = sidebar_selector->indexByValue("func") != -1;
    if (should_have_func_tab && !has_func_tab)
    {
        sidebar_selector->addEntry(tr("helmsTab", "Functions"), "func");
        sidebar_selector->show();
    }
    else if (!should_have_func_tab && has_func_tab)
    {
        bool func_was_selected = sidebar_selector->getSelectionValue() == "func";
        sidebar_selector->removeEntry(sidebar_selector->indexByValue("func"));
        custom_function_sidebar->hide();
        if (func_was_selected)
        {
            int util_idx = sidebar_selector->indexByValue("util");
            if (util_idx != -1)
            {
                sidebar_selector->setSelectionIndex(util_idx);
                utility_beam_sidebar->show();
                utility_beam_dial->show();
            }
            else
            {
                sidebar_selector->setSelectionIndex(-1);
                sidebar_selector->hide();
            }
        }
        if (sidebar_selector->entryCount() == 0)
            sidebar_selector->hide();
    }

    // Synchronize the Utility Beam sidebar tab with the current crew_positions mask.
    bool should_have_util_tab = utility_beam && utility_beam->crew_positions.has(CrewPosition::helmsOfficer);
    bool has_util_tab = sidebar_selector->indexByValue("util") != -1;
    if (should_have_util_tab && !has_util_tab)
    {
        sidebar_selector->addEntry(tr("helmsTab", "Utility Beam"), "util");
        sidebar_selector->show();
    }
    else if (!should_have_util_tab && has_util_tab)
    {
        bool util_was_selected = sidebar_selector->getSelectionValue() == "util";
        sidebar_selector->removeEntry(sidebar_selector->indexByValue("util"));
        utility_beam_sidebar->hide();
        utility_beam_dial->hide();
        if (util_was_selected)
        {
            int func_idx = sidebar_selector->indexByValue("func");
            if (func_idx != -1)
            {
                sidebar_selector->setSelectionIndex(func_idx);
                custom_function_sidebar->setVisible(custom_function_sidebar->hasEntries());
            }
            else
            {
                sidebar_selector->setSelectionIndex(-1);
                sidebar_selector->hide();
            }
        }
        if (sidebar_selector->entryCount() == 0)
            sidebar_selector->hide();
    }
}
