#include "helmsScreen.h"
#include <i18n.h>
#include "playerInfo.h"
#include "preferenceManager.h"
#include "featureDefs.h"
#include "crewPositionRequirements.h"

#include "components/collision.h"
#include "components/customshipfunction.h"
#include "components/docking.h"
#include "components/impulse.h"
#include "components/jumpdrive.h"
#include "components/maneuveringthrusters.h"
#include "components/mounts.h"
#include "components/reactor.h"
#include "components/utilityBeam.h"
#include "components/warpdrive.h"

#include "screenComponents/alertOverlay.h"
#include "screenComponents/combatManeuver.h"
#include "screenComponents/customShipFunctions.h"
#include "screenComponents/dockingButton.h"
#include "screenComponents/impulseControls.h"
#include "screenComponents/infoDisplay.h"
#include "screenComponents/jumpControls.h"
#include "screenComponents/radarView.h"
#include "screenComponents/utilityBeamControls.h"
#include "screenComponents/utilityBeamRotationDial.h"
#include "screenComponents/warpControls.h"

#include "gui/theme.h"
#include "gui/gui2_image.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_label.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_togglebutton.h"
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
    helms_controls
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("padding", "20");

    GuiRadarView* radar = new GuiRadarView(helms_controls, "HELMS_RADAR", nullptr);
    radar
        ->setRangeIndicatorStepSize(1000.0f)
        ->shortRange()
        ->enableGhostDots()
        ->enableWaypoints()
        ->enableCallsigns()
        ->enableHeadingIndicators()
        ->setStyle(GuiRadarView::Circular)
        ->enableMissileTubeIndicators()
        ->setCallbacks(
            [radar, this](sp::io::Pointer::Button button, glm::vec2 position)
            // onMouseDown
            {
                if (auto transform = my_spaceship.getComponent<sp::Transform>())
                {
                    auto r = radar->getRect();
                    const float angle = vec2ToAngle(position - transform->getPosition());

                    // Rotate the position to match radar's rotation.
                    glm::vec2 draw_position;
                    if (radar->getAutoRotating())
                    {
                        auto rotation = -radar->getViewRotation();
                        glm::vec2 position_from_center = position - transform->getPosition();
                        draw_position = {
                            position_from_center.x * cosf(glm::radians(rotation)) - position_from_center.y * sinf(glm::radians(rotation)),
                            position_from_center.x * sinf(glm::radians(rotation)) + position_from_center.y * cosf(glm::radians(rotation))
                        };
                    }
                    else draw_position = (position - transform->getPosition());

                    draw_position = rect.center() + draw_position / radar->getDistance() * std::min(r.size.x, r.size.y) * 0.5f;
                    heading_hint
                        ->setText(string(fmodf(angle + 90.f + 360.f, 360.f), 1))
                        ->setPosition(draw_position - rect.position - glm::vec2(0.0f, 50.0f))
                        ->show();
                    my_player_info->commandTargetRotation(angle);
                }
            },
            [radar, this](glm::vec2 position)
            // onMouseDrag
            {
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
                    else draw_position = (position - transform->getPosition());

                    draw_position = rect.center() + draw_position / radar->getDistance() * std::min(r.size.x, r.size.y) * 0.5f;
                    heading_hint
                        ->setText(string(fmodf(angle + 90.f + 360.f, 360.f), 1))
                        ->setPosition(draw_position - rect.position - glm::vec2(0.0f, 50.0f))
                        ->show();
                    my_player_info->commandTargetRotation(angle);
                }
            },
            [this](glm::vec2 position)
            // onMouseUp
            {
                if (auto transform = my_spaceship.getComponent<sp::Transform>())
                    my_player_info->commandTargetRotation(vec2ToAngle(position - transform->getPosition()));

                heading_hint->hide();
            }, nullptr
        )
        ->setAutoRotating(PreferencesManager::get("helms_radar_lock","0") == "1")
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMatchHeight, 800.0f);

    combat_maneuver = new GuiCombatManeuver(helms_controls, "COMBAT_MANEUVER");
    combat_maneuver
        ->setPosition(0.0f, 0.0f, sp::Alignment::BottomRight)
        ->setSize(280.0f, 215.0f);
    (new GuiTextTooltip(combat_maneuver, "COMBAT_MANEUVER_TIP", tr("tooltips", "Execute combat maneuvers: strafe laterally or boost forward to evade enemies."), 20.0f))->setWidth(280.0f);

    heading_hint = new GuiLabel(helms_controls, "HEADING_HINT", "", GuiElement::GuiSizeLabel);
    heading_hint
        ->setAlignment(sp::Alignment::Center)
        ->setSize(0.0f, 0.0f);

    // Key/value info displays.
    const float KV_HEIGHT = 40.0f;
    GuiElement* info_displays = new GuiElement(helms_controls, "");
    info_displays
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopLeft)
        ->setSize(240.0f, KV_HEIGHT * 3.0f)
        ->setAttribute("layout", "vertical");

    auto energy_display = new EnergyInfoDisplay(info_displays, "ENERGY_DISPLAY", 0.45f);
    energy_display ->setSize(GuiElement::GuiSizeMax, KV_HEIGHT);
    (new GuiTextTooltip(energy_display, "ENERGY_TIP", tr("tooltips", "Current reactor energy level."), 20.0f))->setWidth(280.0f);

    auto heading_display = new HeadingInfoDisplay(info_displays, "HEADING_DISPLAY", 0.45f);
    heading_display->setSize(GuiElement::GuiSizeMax, KV_HEIGHT);
    (new GuiTextTooltip(heading_display, "HEADING_TIP", tr("tooltips", "Current ship heading in degrees."), 20.0f))->setWidth(280.0f);

    auto velocity_display = new VelocityInfoDisplay(info_displays, "VELOCITY_DISPLAY", 0.45f);
    velocity_display->setSize(GuiElement::GuiSizeMax, KV_HEIGHT);
    (new GuiTextTooltip(velocity_display, "VELOCITY_TIP", tr("tooltips", "Current ship velocity."), 20.0f))->setWidth(280.0f);

    // Propulsion controls.
    const float PROPULSION_WIDTH = 100.0f;
    const float PROPULSION_WIDTH_3X = PROPULSION_WIDTH * 3.0f;
    const bool HAS_DOCKING_PORT = my_spaceship.hasComponent<DockingPort>();

    // Throttle controls.
    GuiElement* engine_layout = new GuiElement(helms_controls, "ENGINE_LAYOUT");
    engine_layout
        ->setPosition(0.0f, HAS_DOCKING_PORT ? -GuiElement::GuiSizeRow : 0.0f, sp::Alignment::BottomLeft)
        ->setSize(PROPULSION_WIDTH_3X, 300.0f)
        ->setAttribute("layout", "horizontal");

    auto* impulse = new GuiImpulseControls(engine_layout, "IMPULSE");
    impulse->setSize(PROPULSION_WIDTH, GuiElement::GuiSizeMax);
    (new GuiTextTooltip(impulse, "IMPULSE_TIP", tr("tooltips", "Adjust impulse engine throttle for sub-light travel."), 20.0f))->setWidth(280.0f);

    auto* warp = new GuiWarpControls(engine_layout, "WARP");
    warp->setSize(PROPULSION_WIDTH, GuiElement::GuiSizeMax);
    (new GuiTextTooltip(warp, "WARP_TIP", tr("tooltips", "Engage or disengage the warp drive for faster-than-light travel."), 20.0f))->setWidth(280.0f);

    auto* jump = new GuiJumpControls(engine_layout, "JUMP");
    jump->setSize(PROPULSION_WIDTH, GuiElement::GuiSizeMax);
    (new GuiTextTooltip(jump, "JUMP_TIP", tr("tooltips", "Set and activate the jump drive to instantly travel long distances."), 20.0f))->setWidth(280.0f);

    // Docking controls.
    docking_button = new GuiDockingButton(helms_controls, "DOCKING");
    docking_button
        ->setPosition(0.0f, 0.0f, sp::Alignment::BottomLeft)
        ->setSize(PROPULSION_WIDTH_3X, GuiElement::GuiSizeRow)
        ->setVisible(my_spaceship.hasComponent<DockingPort>());
    (new GuiTextTooltip(docking_button, "DOCKING_TIP", tr("tooltips", "Request docking with or undocking from the nearest station or ship."), 20.0f))->setWidth(280.0f);

    // Check mounts for utility beam controls.
    auto mounts_comp = my_spaceship.getComponent<Mounts>();
    const Mount* ub_mount = nullptr;
    if (mounts_comp)
    {
        for (auto& m : mounts_comp->mounts)
        {
            if (m.type == MountType::UtilityBeam)
            {
                ub_mount = &m;
                break;
            }
        }
    }

    sidebar_selector = new GuiSelector(helms_controls, "HELMS_SIDEBAR_SELECTOR",
        [this](int index, string value)
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
        }
    );
    sidebar_selector
        ->setPosition(0.0f, 100.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, GuiElement::GuiSizeRow)
        ->hide();
    (new GuiTextTooltip(sidebar_selector, "HELMS_SIDEBAR_TIP", tr("tooltips", "Switch between custom ship functions and utility beam controls."), 20.0f))->setWidth(280.0f);

    custom_function_sidebar = new GuiCustomShipFunctions(helms_controls, CrewPosition::helmsOfficer, "HELMS_CUSTOM_FUNCS");
    custom_function_sidebar
        ->setPosition(0.0f, 150.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, 9.0f * GuiElement::GuiSizeRow)
        ->hide();

    utility_beam_sidebar = new GuiUtilityBeamControls(helms_controls, CrewPosition::helmsOfficer, "UTILITY_BEAM_CONTROLS");
    utility_beam_sidebar
        ->setPosition(0.0f, 150.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    utility_beam_dial = new GuiUtilityBeamRotationDial(radar, "UTILITY_BEAM_DIAL", radar);
    utility_beam_dial
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide();

    if (custom_function_sidebar->hasEntries())
    {
        sidebar_selector->addEntry(tr("helmsTab", "Functions"), "func");
        sidebar_selector->show();
    }

    if (ub_mount && ub_mount->crew_positions.has(CrewPosition::helmsOfficer))
    {
        sidebar_selector->addEntry(tr("helmsTab", "Utility beam"), "util");
        sidebar_selector->show();
    }

    // Set initial sidebar state by manually applying the first tab.
    if (sidebar_selector->entryCount() > 0)
    {
        sidebar_selector->setSelectionIndex(0);
        if (sidebar_selector->getSelectionValue() == "func")
        {
            custom_function_sidebar->setVisible(
                custom_function_sidebar->hasEntries()
            );
        }
        else if (sidebar_selector->getSelectionValue() == "util")
        {
            utility_beam_sidebar->show();
            utility_beam_dial->show();
        }
    }
}

void HelmsScreen::onUpdate()
{
    // Exit if we're nto re
    if (!my_spaceship || !isVisible()) return;

    const bool HAS_ANY_PROPULSION = crewPositionRequirements::hasRequirements(CrewPosition::helmsOfficer, my_spaceship);

    background_gradient->setVisible(HAS_ANY_PROPULSION);
    helms_controls->setVisible(HAS_ANY_PROPULSION);
    no_controls_label->setVisible(!HAS_ANY_PROPULSION);

    if (!HAS_ANY_PROPULSION) return;

    // Impulse, jump, warp hotkeys are handled in their screen components.

    // Handle rotational hotkeys.
    auto thrusters = my_spaceship.getComponent<ManeuveringThrusters>();
    const float TURN_SCALE = thrusters ? thrusters->speed : 10.0f;

    auto continuous_angle = (keys.helms_turn_right.getContinuousValue() - keys.helms_turn_left.getContinuousValue()) * TURN_SCALE;
    continuous_angle += (keys.helms_turn_right.getAxis0Value() - keys.helms_turn_left.getAxis0Value()) * TURN_SCALE;
    continuous_angle += (keys.helms_turn_right.getAxis1Value() - keys.helms_turn_left.getAxis1Value()) * TURN_SCALE;

    float discrete_angle = 0.0f;
    if (keys.helms_turn_right.isDiscreteStepDown() || keys.helms_turn_right.isRepeatReady()) discrete_angle += TURN_SCALE * 0.5f;
    if (keys.helms_turn_left.isDiscreteStepDown() || keys.helms_turn_left.isRepeatReady()) discrete_angle -= TURN_SCALE * 0.5f;

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

    auto mounts_comp = my_spaceship.getComponent<Mounts>();
    const Mount* ub_mount = nullptr;
    if (mounts_comp)
    {
        for (auto& m : mounts_comp->mounts)
        {
            if (m.type == MountType::UtilityBeam)
            {
                ub_mount = &m;
                break;
            }
        }
    }

    // Synchronize the Functions sidebar tab with current custom ship functions.
    const bool SHOULD_HAVE_FUNC_TAB = custom_function_sidebar->hasEntries();
    const bool HAS_FUNC_TAB = sidebar_selector->indexByValue("func") != -1;

    if (SHOULD_HAVE_FUNC_TAB && !HAS_FUNC_TAB)
    {
        sidebar_selector->addEntry(tr("helmsTab", "Functions"), "func");
        sidebar_selector->show();

        if (sidebar_selector->getSelectionIndex() == -1)
        {
            const int FUNC_IDX = sidebar_selector->indexByValue("func");
            if (FUNC_IDX != -1)
            {
                sidebar_selector->setSelectionIndex(FUNC_IDX);
                custom_function_sidebar->show();
            }
        }
    }
    else if (!SHOULD_HAVE_FUNC_TAB && HAS_FUNC_TAB)
    {
        const bool FUNC_WAS_SELECTED = sidebar_selector->getSelectionValue() == "func";

        sidebar_selector->removeEntry(sidebar_selector->indexByValue("func"));
        custom_function_sidebar->hide();

        if (FUNC_WAS_SELECTED)
        {
            const int UTIL_IDX = sidebar_selector->indexByValue("util");
            if (UTIL_IDX != -1)
            {
                sidebar_selector->setSelectionIndex(UTIL_IDX);
                utility_beam_sidebar->show();
                utility_beam_dial->show();
            }
            else
            {
                sidebar_selector->setSelectionIndex(-1);
                sidebar_selector->hide();
            }
        }

        if (sidebar_selector->entryCount() == 0) sidebar_selector->hide();
    }

    // Synchronize the Utility Beam sidebar tab with the current crew_positions mask.
    const bool SHOULD_HAVE_UTIL_TAB = ub_mount && ub_mount->crew_positions.has(CrewPosition::helmsOfficer);
    const bool HAS_UTIL_TAB = sidebar_selector->indexByValue("util") != -1;

    if (SHOULD_HAVE_UTIL_TAB && !HAS_UTIL_TAB)
    {
        sidebar_selector->addEntry(tr("helmsTab", "Utility beam"), "util");
        sidebar_selector->show();

        if (sidebar_selector->getSelectionIndex() == -1)
        {
            int util_idx = sidebar_selector->indexByValue("util");
            if (util_idx != -1)
            {
                sidebar_selector->setSelectionIndex(util_idx);
                utility_beam_sidebar->show();
                utility_beam_dial->show();
            }
        }
    }
    else if (!SHOULD_HAVE_UTIL_TAB && HAS_UTIL_TAB)
    {
        const bool UTIL_WAS_SELECTED = sidebar_selector->getSelectionValue() == "util";

        sidebar_selector->removeEntry(sidebar_selector->indexByValue("util"));
        utility_beam_sidebar->hide();
        utility_beam_dial->hide();

        if (UTIL_WAS_SELECTED)
        {
            const int FUNC_IDX = sidebar_selector->indexByValue("func");
            if (FUNC_IDX != -1)
            {
                sidebar_selector->setSelectionIndex(FUNC_IDX);
                custom_function_sidebar->setVisible(custom_function_sidebar->hasEntries());
            }
            else
            {
                sidebar_selector->setSelectionIndex(-1);
                sidebar_selector->hide();
            }
        }

        if (sidebar_selector->entryCount() == 0) sidebar_selector->hide();
    }
}
