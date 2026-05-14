#include "scienceScreen.h"
#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "preferenceManager.h"
#include "multiplayer_client.h"
#include "i18n.h"
#include "featureDefs.h"

#include "components/beamweapon.h"
#include "components/customshipfunction.h"
#include "components/utilityBeam.h"
#include "components/shields.h"
#include "components/hull.h"
#include "components/collision.h"
#include "components/radar.h"
#include "components/scanning.h"
#include "components/name.h"

#include "systems/radarblock.h"

#include "screenComponents/radarView.h"
#include "screenComponents/radarZoomSlider.h"
#include "screenComponents/rawScannerDataRadarOverlay.h"
#include "screenComponents/scanTargetButton.h"
#include "screenComponents/frequencyCurve.h"
#include "screenComponents/signalQualityIndicator.h"
#include "screenComponents/scanningDialog.h"
#include "screenComponents/databaseView.h"
#include "screenComponents/alertOverlay.h"
#include "screenComponents/customShipFunctions.h"
#include "screenComponents/powerDamageIndicator.h"
#include "screenComponents/utilityBeamControls.h"

#include "gui/theme.h"
#include "random.h"

#include "gui/gui2_button.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_label.h"
#include "gui/gui2_togglebutton.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_scrollcontainer.h"
#include "gui/gui2_scrolltext.h"
#include "gui/gui2_listbox.h"
#include "gui/gui2_slider.h"
#include "gui/gui2_image.h"
#include "screenComponents/utilityBeamRotationDial.h"

ScienceScreen::ScienceScreen(GuiContainer* owner, CrewPosition crew_position)
: GuiOverlay(owner, "SCIENCE_SCREEN", GuiTheme::getColor("background")), crew_position(crew_position)
{
    auto lrr = my_spaceship.getComponent<LongRangeRadar>();
    auto utility_beam = my_spaceship.getComponent<UtilityBeam>();
    targets.setAllowWaypointSelection();

    // Render the radar shadow and background decorations.
    background_gradient = new GuiImage(this, "BACKGROUND_GRADIENT", "");
    background_gradient
        ->setTextureThemed("background.gradient_offset")
        ->setPosition(glm::vec2(105.0f, 0.0f), sp::Alignment::CenterLeft)
        ->setSize(1200.0f, 900.0f);

    background_crosses = new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255, 255, 255, 255});
    background_crosses->setTextureTiledThemed("background.crosses");

    // Render the alert level color overlay.
    (new AlertLevelOverlay(this));

    // Draw the radar.
    radar_view = new GuiElement(this, "RADAR_VIEW");
    radar_view->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Draw the science radar.
    science_radar = new GuiRadarView(radar_view, "SCIENCE_RADAR", lrr ? lrr->long_range : DEFAULT_MAX_ZOOM_DISTANCE, &targets);
    science_radar
        ->setRangeIndicatorStepSize(DEFAULT_MIN_ZOOM_DISTANCE)
        ->longRange()
        ->enableWaypoints()
        ->enableCallsigns()
        ->enableHeadingIndicators()
        ->setStyle(GuiRadarView::Circular)
        ->setFogOfWarStyle(GuiRadarView::NebulaFogOfWar)
        ->setCallbacks(
            [this](sp::io::Pointer::Button button, glm::vec2 position)
            { // down
                if (auto scanner = my_spaceship.getComponent<ScienceScanner>())
                    if (scanner->delay > 0.0f) return;

                targets.setToClosestTo(position, 1000.0f, TargetsContainer::Selectable);
            }, nullptr, nullptr,
            [this](float value, glm::vec2 position)
            { // wheel
                doRadarZoom(value);
            }
        )
        ->setAutoRotating(PreferencesManager::get("science_radar_lock","0") == "1")
        ->setPosition(120.0f, 0.0f, sp::Alignment::CenterLeft)
        ->setSize(900.0f, GuiElement::GuiSizeMax);

    science_raw_signals = new RawScannerDataRadarOverlay(science_radar, "");

    // Draw and hide the probe radar.
    probe_radar = new GuiRadarView(radar_view, "PROBE_RADAR", PROBE_ZOOM_DISTANCE, &targets);
    probe_radar
        ->setAutoCentering(false)
        ->longRange()
        ->enableWaypoints()
        ->enableCallsigns()
        ->enableHeadingIndicators()
        ->setStyle(GuiRadarView::Circular)
        ->setFogOfWarStyle(GuiRadarView::NoFogOfWar)
        ->setCallbacks(
            [this](sp::io::Pointer::Button button, glm::vec2 position)
            {
                if (auto scanner = my_spaceship.getComponent<ScienceScanner>())
                    if (scanner->delay > 0.0f) return;

                targets.setToClosestTo(position, 1000.0f, TargetsContainer::Selectable);
            }, nullptr, nullptr, nullptr
        )
        ->setPosition(120.0f, 0.0f, sp::Alignment::CenterLeft)
        ->setSize(900.0f, GuiElement::GuiSizeMax)
        ->hide();

    probe_raw_signals = new RawScannerDataRadarOverlay(probe_radar, "");

    sidebar_selector = new GuiSelector(radar_view, "", [this, utility_beam](int index, string value)
    {
        if (value == "scan")
        {
            info_sidebar->show();
            custom_function_sidebar->hide();
            utility_beam_sidebar->hide();
            utility_beam_dial->hide();
        }
        else if (value == "func")
        {
            info_sidebar->hide();
            custom_function_sidebar->setVisible(custom_function_sidebar->hasEntries());
            utility_beam_sidebar->hide();
            utility_beam_dial->hide();
        }
        else if (value == "util")
        {
            info_sidebar->hide();
            custom_function_sidebar->hide();
            if (utility_beam)
            {
                const bool show = utility_beam->crew_positions.has(this->crew_position);
                utility_beam_sidebar->setVisible(show);
                utility_beam_dial->setVisible(show);
            }
            else
            {
                LOG(Warning, "Utility beam controls requested on Science, but this entity lacks a UtilityBeam component");
            }
        }
        else
        {
            LOG(Warning, "Science sidebar selector is bad: ", value);
        }
    });

    sidebar_selector->setOptions(
        {tr("scienceTab", "Scanning")},
        {"scan"}
    );

    if (utility_beam)
    {
        if (utility_beam->crew_positions.has(crew_position))
            sidebar_selector->addEntry(tr("scienceTab", "Utility Beam"), "util");
    }

    sidebar_selector
        ->setSelectionIndex(0)
        ->setPosition(-20.0f, 120.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, 50.0f);

    // Target scan data sidebar.
    info_sidebar = new GuiElement(radar_view, "SIDEBAR");
    info_sidebar
        ->setPosition(-20.0f, 170.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    info_sidebar
        ->setAttribute("margin", "0, 0, 0, 75");
    
    custom_function_sidebar = new GuiCustomShipFunctions(radar_view, crew_position, "");
    float height = crew_position == CrewPosition::operationsOfficer
        ? 550.0f
        : 600.0f;
    custom_function_sidebar
        ->setPosition(-15.0f, 210.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, height)
        ->hide();

    // Scan button.
    scan_button = new GuiScanTargetButton(info_sidebar, "SCAN_BUTTON", &targets);
    scan_button
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setVisible(my_spaceship.hasComponent<ScienceScanner>());

    // Link to analysis button.
    link_to_analysis_button = new GuiButton(info_sidebar, "LINK_TO_ANALYSIS", tr("scienceButton", "Link to analysis"),
        [this]()
        {
            if (my_player_info && targets.get())
                my_player_info->commandSetTarget(targets.get());
        }
    );
    link_to_analysis_button->setSize(GuiElement::GuiSizeMax, 50.0f);

    // Simple scan data.
    info_callsign = new GuiKeyValueDisplay(info_sidebar, "SCIENCE_CALLSIGN", 0.4f, tr("science", "Callsign"), "");
    info_callsign->setSize(GuiElement::GuiSizeMax, 30.0f);

    info_distance = new GuiKeyValueDisplay(info_sidebar, "SCIENCE_DISTANCE", 0.4f, tr("science", "Distance"), "");
    info_distance->setSize(GuiElement::GuiSizeMax, 30.0f);

    info_heading = new GuiKeyValueDisplay(info_sidebar, "SCIENCE_HEADING", 0.4f, tr("science", "Bearing"), "");
    info_heading->setSize(GuiElement::GuiSizeMax, 30.0f);

    info_relspeed = new GuiKeyValueDisplay(info_sidebar, "SCIENCE_REL_SPEED", 0.4f, tr("science", "Rel. speed"), "");
    info_relspeed->setSize(GuiElement::GuiSizeMax, 30.0f);

    info_faction = new GuiKeyValueDisplay(info_sidebar, "SCIENCE_FACTION", 0.4f, tr("science", "Faction"), "");
    info_faction->setSize(GuiElement::GuiSizeMax, 30.0f);
    info_faction_button = new GuiButton(info_faction, "SCIENCE_FACTION_BUTTON", tr("scienceButton", "DB"),
        [this]()
        {
            auto ship = targets.get();
            auto faction = Faction::getInfo(ship);

            if (!faction.locale_name.empty())
            {
                if (database_view->findAndDisplayEntry(faction.locale_name))
                {
                    view_mode_selection->setSelectionIndex(1);
                    radar_view->hide();
                    background_gradient->hide();
                    database_view->show();
                }
            }
        }
    );
    info_faction_button
        ->setTextSize(20.0f)
        ->setPosition(0.0f, 1.0f, sp::Alignment::TopLeft)
        ->setSize(50.0f, 28.0f);

    info_type = new GuiKeyValueDisplay(info_sidebar, "SCIENCE_TYPE", 0.4f, tr("science", "Type"), "");
    info_type->setSize(GuiElement::GuiSizeMax, 30.0f);

    info_type_button = new GuiButton(info_type, "SCIENCE_TYPE_BUTTON", tr("scienceButton", "DB"),
        [this]()
        {
            auto ship = targets.get();
            if (auto tn = ship.getComponent<TypeName>())
            {
                if (database_view->findAndDisplayEntry(tn->type_name) || database_view->findAndDisplayEntry(tn->localized))
                {
                    view_mode_selection->setSelectionIndex(1);
                    radar_view->hide();
                    background_gradient->hide();
                    database_view->show();
                }
            }
        }
    );
    info_type_button
        ->setTextSize(20.0f)
        ->setPosition(0.0f, 1.0f, sp::Alignment::TopLeft)
        ->setSize(50.0f, 28.0f);

    info_shields = new GuiKeyValueDisplay(info_sidebar, "SCIENCE_SHIELDS", 0.4f, tr("science", "Shields"), "");
    info_shields->setSize(GuiElement::GuiSizeMax, 30.0f);

    info_hull = new GuiKeyValueDisplay(info_sidebar, "SCIENCE_HULL", 0.4f, tr("science", "Hull"), "");
    info_hull->setSize(GuiElement::GuiSizeMax, 30.0f);

    // Full scan data sidebar.
    // Draw and hide the sidebar pager. Tabs are populated dynamically in onDraw.
    sidebar_pager = new GuiSelector(info_sidebar, "SIDEBAR_PAGER", [](int index, string value) {});
    sidebar_pager
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->hide();

    // If the server uses frequencies, add the Tactical sidebar page.
    if (gameGlobalInfo->use_beam_shield_frequencies)
        sidebar_pager->addEntry(tr("scienceTab", "Tactical"), "Tactical");

    // Add sidebar page for systems.
    sidebar_pager->addEntry(tr("scienceTab", "Systems"), "Systems");

    // Add sidebar page for signals.
    sidebar_pager->addEntry(tr("scienceTab", "Signals"), "Signals");

    // Add sidebar page for a description.
    sidebar_pager->addEntry(tr("scienceTab", "Description"), "Description");

    // Default the pager to the first item.
    sidebar_pager->setSelectionIndex(0);

    sidebar_signals_page = new GuiScrollContainer(info_sidebar, "");
    sidebar_signals_page
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    sidebar_frequencies_page = new GuiScrollContainer(info_sidebar, "");
    sidebar_frequencies_page
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    sidebar_systems_page = new GuiScrollContainer(info_sidebar, "");
    sidebar_systems_page
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    // Radar signature bands.
    info_electrical_signal_band = new GuiSignalQualityIndicator(sidebar_signals_page, "SCIENCE_ELECTRICAL_SIGNAL");
    info_electrical_signal_band
        ->showGreen(false)
        ->showBlue(false)
        ->setSize(GuiElement::GuiSizeMax, 80.0f);
    info_electrical_signal_label = new GuiLabel(info_electrical_signal_band, "", tr("Electrical"), 30.0f);
    info_electrical_signal_label->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    info_gravitational_signal_band = new GuiSignalQualityIndicator(sidebar_signals_page, "SCIENCE_GRAVITY_SIGNAL");
    info_gravitational_signal_band
        ->showRed(false)
        ->showGreen(false)
        ->setSize(GuiElement::GuiSizeMax, 80.0f);
    info_gravitational_signal_label = new GuiLabel(info_gravitational_signal_band, "", tr("Gravitational"), 30.0f);
    info_gravitational_signal_label->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    info_thermal_signal_band = new GuiSignalQualityIndicator(sidebar_signals_page, "SCIENCE_THERMAL_SIGNAL");
    info_thermal_signal_band
        ->showRed(false)
        ->showBlue(false)
        ->setSize(GuiElement::GuiSizeMax, 80.0f);
    info_thermal_signal_label = new GuiLabel(info_thermal_signal_band, "", tr("Thermal"), 30.0f);
    info_thermal_signal_label->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Prep and hide the frequency graphs.
    info_shield_frequency = new GuiFrequencyCurve(sidebar_frequencies_page, "SCIENCE_SHIELD_FREQUENCY", GuiFrequencyCurve::FrequencyType::Other, GuiFrequencyCurve::DamageEffect::Positive);
    info_shield_frequency->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    info_beam_frequency = new GuiFrequencyCurve(sidebar_frequencies_page, "SCIENCE_BEAM_FREQUENCY", GuiFrequencyCurve::FrequencyType::Beam, GuiFrequencyCurve::DamageEffect::Negative);
    info_beam_frequency->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // List each system's status.
    for (int n = 0; n < ShipSystem::COUNT; n++)
    {
        info_system[n] = new GuiKeyValueDisplay(sidebar_systems_page, "SCIENCE_SYSTEM_" + string(n), 0.75f, getLocaleSystemName(ShipSystem::Type(n)), "-");
        info_system[n]
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->hide();
    }

    // Prep and hide the description text area.
    info_description = new GuiScrollFormattedText(info_sidebar, "SCIENCE_DESC", "");
    info_description
        ->setTextSize(28.0f)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("padding", "20, 0, 0, 0");

    // END info_sidebar

    // Utility sidebar.
    utility_beam_sidebar = new GuiUtilityBeamControls(info_sidebar, crew_position, "UTILITY_BEAM_CONTROLS");
    utility_beam_sidebar
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    utility_beam_dial = new GuiUtilityBeamRotationDial(science_radar, "UTILITY_BEAM_DIAL", science_radar);
    utility_beam_dial
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide();
    // END utility_beam_sidebar

    // Prep and hide the database view.
    database_view = new DatabaseViewComponent(this);
    database_view
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("padding", "20");

    // Pad top of details column if crew screen selection controls are visible,
    // and bottom of item list column to prevent overlap with probe/radar view
    // selectors.
    int details_padding = 0;
    if (my_player_info)
    {
        if (my_player_info->main_screen_control != 0) details_padding = 120;
        else if (my_player_info->countTotalPlayerPositions() > 1) details_padding = 70;
    }
    database_view
        ->setDetailsPadding(details_padding)
        ->setItemsPadding(120);

    // Probe view button
    probe_view_button = new GuiToggleButton(radar_view, "PROBE_VIEW", tr("scienceButton", "Probe view"),
        [this](bool value)
        {
            auto rl = my_spaceship.getComponent<RadarLink>();
            if (value && rl && rl->linked_entity)
            {
                if (auto transform = rl->linked_entity.getComponent<sp::Transform>())
                {
                    science_radar->hide();
                    probe_radar
                        ->setViewPosition(transform->getPosition())
                        ->show();
                }
            }
            else
            {
                probe_view_button->setValue(false);
                science_radar->show();
                probe_radar->hide();
            }
        }
    );
    probe_view_button
        ->setPosition(20.0f, -120.0f, sp::Alignment::BottomLeft)
        ->setSize(200.0f, 50.0f)
        ->disable();

    // Draw the zoom slider.
    float lrr_long = lrr ? lrr->long_range : DEFAULT_MAX_ZOOM_DISTANCE;
    float lrr_short = lrr ? lrr->short_range : DEFAULT_MIN_ZOOM_DISTANCE;
    zoom_slider = new GuiRadarZoomSlider(radar_view, "RADAR_ZOOM", lrr_short, lrr_long, lrr_long, science_radar);
    zoom_slider
        ->setPosition(-20.0f, -20.0f, sp::Alignment::BottomRight)
        ->setSize(250.0f, 50.0f);

    // Radar/database view toggle.
    view_mode_selection = new GuiListbox(this, "VIEW_SELECTION",
        [this](int index, string value)
        {
            radar_view->setVisible(index == 0);
            background_gradient->setVisible(index == 0);
            database_view->setVisible(index == 1);
        }
    );
    view_mode_selection
        ->setOptions({tr("scienceButton", "Radar"), tr("scienceButton", "Database")})
        ->setSelectionIndex(0)
        ->setPosition(20.0f, -20.0f, sp::Alignment::BottomLeft)
        ->setSize(200.0f, 100.0f);

    // Scanning dialog.
    new GuiScanningDialog(this, "SCANNING_DIALOG");
}

static float calculateSignalError(float signal)
{
    return std::max(0.0f, (signal - 1.0f) * 0.1f);
}

void ScienceScreen::doRadarZoom(float value)
{
    float view_distance = std::clamp(
        science_radar->getDistance() * (1.0f - value * 0.1f),
        previous_short_range_radar,
        previous_long_range_radar
    );
    science_radar->setDistance(view_distance);
    zoom_slider->setValue(view_distance);
}

void ScienceScreen::onDraw(sp::RenderTarget& renderer)
{
    GuiOverlay::onDraw(renderer);
    if (!isVisible()) return;

    auto lrr = my_spaceship.getComponent<LongRangeRadar>();
    science_radar->setVisible(lrr);
    if (!lrr) return;

    auto rl = my_spaceship.getComponent<RadarLink>();
    float view_distance = science_radar->getDistance();
    float mouse_wheel_delta = keys.zoom_in.getContinuousValue() + keys.zoom_in.getAxis0Value() + keys.zoom_in.getAxis1Value()
        - keys.zoom_out.getContinuousValue() - keys.zoom_out.getAxis0Value() - keys.zoom_out.getAxis1Value();
    if (mouse_wheel_delta != 0)
        view_distance *= (1.0f - (mouse_wheel_delta * 0.1f));
    if (keys.zoom_in.isDiscreteStepDown() || keys.zoom_in.isRepeatReady())
        view_distance = std::max(lrr->short_range, view_distance * 0.9f);
    if (keys.zoom_out.isDiscreteStepDown() || keys.zoom_out.isRepeatReady())
        view_distance = std::min(lrr->long_range, view_distance * 1.1f);
    view_distance = std::min(view_distance, lrr->long_range);
    view_distance = std::max(view_distance, lrr->short_range);

    // Update radar view distances and zoom range if changed.
    if (view_distance != science_radar->getDistance()
        || previous_long_range_radar != lrr->long_range
        || previous_short_range_radar != lrr->short_range)
    {
        previous_short_range_radar = lrr->short_range;
        previous_long_range_radar = lrr->long_range;
        zoom_slider
            ->setRange(lrr->long_range, lrr->short_range)
            ->setValue(view_distance);
    }

    // If in probe view to a radar-linked entity, clear target selection if
    // target is out of probe view range.
    if (probe_view_button->getValue() && rl && rl->linked_entity)
    {
        auto probe_transform = rl->linked_entity.getComponent<sp::Transform>();
        auto target_transform = targets.get().getComponent<sp::Transform>();

        if (!probe_transform || !target_transform || glm::length2(probe_transform->getPosition() - target_transform->getPosition()) > 5000.0f * 5000.0f)
            targets.clear();
    }
    // Otherwise, clear target if target is radar blocked/out of range or if we
    // don't have a transform (exploded or internally docked).
    else
    {
        auto target_transform = targets.get().getComponent<sp::Transform>();
        auto my_transform = my_spaceship.getComponent<sp::Transform>();

        if (!my_transform || RadarBlockSystem::isRadarBlockedFrom(my_transform->getPosition(), targets.get(), lrr->short_range))
            targets.clear();

        // Deselect target if outside of long range radar range.
        if (my_transform && target_transform)
        {
            if (glm::length(target_transform->getPosition() - my_transform->getPosition()) > lrr->long_range)
                targets.clear();
        }
    }

    // Responsive layout for custom button sidebar. 1440x900 vpixels is 16:10, so this would roughly be the threshold.
    int current_width = getRect().size.x;
    info_sidebar->setPosition(-20.0f, 170.0f, sp::Alignment::TopRight);
    sidebar_selector
        ->setPosition(-20.0f, 120.0f, sp::Alignment::TopRight)
        ->setVisible((current_width < 1435 && sidebar_selector->entryCount() > 1) || (current_width >= 1435 && sidebar_selector->entryCount() > 2));

    if (current_width < 1435 || !custom_function_sidebar->hasEntries())
    {
        custom_function_sidebar
            ->setPosition(-20.0f, 210.0f, sp::Alignment::TopRight)
            ->setVisible(current_width < 1435 && sidebar_selector->getSelectionIndex() == 1 && sidebar_selector->indexByValue("func") >= 0);
        info_sidebar->setVisible(current_width >= 1435 || sidebar_selector->getSelectionIndex() == 0);
    }
    else
    {
        custom_function_sidebar
            ->setPosition(-280.0f, 170.0f, sp::Alignment::TopRight)
            ->show();
        info_sidebar->show();
    }

    // Reset scan info.
    info_callsign->setValue("-");
    info_distance->setValue("-");
    info_heading->setValue("-");
    info_relspeed->setValue("-");
    info_faction->setValue("-");
    info_type->setValue("-");
    info_shields->setValue("-");
    info_hull->setValue("-");
    info_shield_frequency->setFrequency(-1);
    info_beam_frequency->setFrequency(-1);
    info_faction_button->hide();
    info_type_button->hide();
    link_to_analysis_button->hide();
    sidebar_frequencies_page->hide();
    sidebar_signals_page->hide();
    sidebar_systems_page->hide();
    info_description->hide();
    sidebar_pager->hide();

    for (int n = 0; n < ShipSystem::COUNT; n++)
    {
        info_system[n]
            ->setValue("-")
            ->hide();
    }

    // Manage probe view button state.
    probe_view_button->setVisible(rl);
    if (rl && rl->linked_entity)
    {
        probe_view_button->enable();
        if (auto probe_transform = rl->linked_entity.getComponent<sp::Transform>())
            probe_radar->setViewPosition(probe_transform->getPosition());
    }
    else
    {
        probe_view_button->disable();
        probe_view_button->setValue(false);
        science_radar->show();
        probe_radar->hide();
    }

    auto target = targets.get();
    if (target != target_entity)
    {
        info_electrical_signal_band->clearHistory();
        info_gravitational_signal_band->clearHistory();
        info_thermal_signal_band->clearHistory();
    }

    if (target)
    {
        target_entity = target;
        link_to_analysis_button->show();

        auto my_transform = my_spaceship.getComponent<sp::Transform>();
        auto target_transform = target.getComponent<sp::Transform>();
        float distance = 0.0f;

        if (my_transform && target_transform)
        {
            auto position_diff = target_transform->getPosition() - my_transform->getPosition();
            distance = glm::length(position_diff);
            float heading = vec2ToAngle(position_diff) - 270.0f;
            while (heading < 0) heading += 360.0f;

            info_distance->setValue(string(distance / 1000.0f, 1) + DISTANCE_UNIT_1K);
            info_heading->setValue(string(static_cast<int>(heading)));

            auto my_physics = my_spaceship.getComponent<sp::Physics>();
            auto target_physics = target.getComponent<sp::Physics>();
            if (my_physics && target_physics && distance > 0.0f)
            {
                float rel_velocity = dot(target_physics->getVelocity(), position_diff / distance) - dot(my_physics->getVelocity(), position_diff / distance);

                if (std::abs(rel_velocity) < 0.01f) rel_velocity = 0.0f;
                info_relspeed->setValue(tr("{relative_velocity} {unit}/min.").format({
                    {"relative_velocity", string(rel_velocity / 1000.0f * 60.0f, 1)},
                    {"unit", DISTANCE_UNIT_1K}
                }));
            }
        }

        if (auto cs = target.getComponent<CallSign>())
            info_callsign->setValue(cs->callsign);

        auto scanstate_component = target.getComponent<ScanState>();
        auto scanstate = scanstate_component ? scanstate_component->getStateFor(my_spaceship) : ScanState::State::FullScan;

        string description = "";
        if (auto sd = target.getComponent<ScienceDescription>())
        {
            switch (scanstate)
            {
            case ScanState::State::NotScanned: description = sd->not_scanned; break;
            case ScanState::State::FriendOrFoeIdentified: description = sd->friend_or_foe_identified; break;
            case ScanState::State::SimpleScan: description = sd->simple_scan; break;
            case ScanState::State::FullScan: description = sd->full_scan; break;
            }
        }

        if (!description.empty())
        {
            info_description
                ->setText(description)
                ->show();

            if (sidebar_pager->indexByValue("Description") < 0)
                sidebar_pager->addEntry("Description", "Description");
        }
        else
        {
            sidebar_pager->removeEntry(sidebar_pager->indexByValue("Description"));
            if (sidebar_pager->getSelectionIndex() < 0)
                sidebar_pager->setSelectionIndex(0);
        }

        string sidebar_pager_selection = sidebar_pager->getSelectionValue();

        // On a simple scan or deeper, show the faction, ship type, shields,
        // hull integrity, and database reference button.
        if (scanstate >= ScanState::State::SimpleScan)
        {
            auto faction = Faction::getInfo(target);
            info_faction_button->show();
            info_faction->setValue(faction.locale_name);

            info_type_button->show();
            if (auto tn = target.getComponent<TypeName>())
                info_type->setValue(tn->localized);

            if (auto shields = target.getComponent<Shields>())
            {
                string str = "";
                for (size_t n = 0; n < shields->entries.size(); n++)
                {
                    if (n > 0) str += ":";
                    str += string(int(shields->entries[n].level));
                }

                info_shields->setValue(str);
            }

            if (auto hull = target.getComponent<Hull>())
                info_hull->setValue(static_cast<int>(ceil(hull->current)));
        }

        sidebar_pager->setVisible(sidebar_pager->entryCount() > 1);

        // Check sidebar pager state.
        if (sidebar_pager_selection == "Tactical")
        {
            sidebar_frequencies_page->show();

            if (scanstate >= ScanState::State::FullScan)
            {
                info_shield_frequency->show();
                info_beam_frequency->show();
            }

            for (int n = 0; n < ShipSystem::COUNT; n++) info_system[n]->hide();

            sidebar_signals_page->hide();
            sidebar_systems_page->hide();
            info_description->hide();
        }
        else if (sidebar_pager_selection == "Systems")
        {
            sidebar_systems_page->show();

            if (scanstate >= ScanState::State::FullScan)
                for (int n = 0; n < ShipSystem::COUNT; n++) info_system[n]->show();

            sidebar_frequencies_page->hide();
            sidebar_signals_page->hide();
            info_description->hide();
        }
        else if (sidebar_pager_selection == "Signals")
        {
            sidebar_signals_page->show();

            for (int n = 0; n < ShipSystem::COUNT; n++) info_system[n]->hide();

            sidebar_frequencies_page->hide();
            sidebar_systems_page->hide();
            info_description->hide();
        }
        else if (sidebar_pager_selection == "Description")
        {
            info_description->show();

            for (int n = 0; n < ShipSystem::COUNT; n++) info_system[n]->hide();

            sidebar_frequencies_page->hide();
            sidebar_signals_page->hide();
            sidebar_systems_page->hide();
        }
        else LOG(Warning, "Invalid pager state: ", sidebar_pager_selection);

        // On a full scan, populate tactical and systems data.
        if (scanstate >= ScanState::State::FullScan)
        {
            // If beam and shield frequencies are enabled on the server,
            // populate their graphs.
            if (gameGlobalInfo->use_beam_shield_frequencies)
            {
                auto shields_system = target.getComponent<Shields>();
                info_shield_frequency
                    ->setFrequency(shields_system ? shields_system->frequency : -1)
                    ->setEnemyHasEquipment(shields_system);

                auto beam_system = target.getComponent<BeamWeaponSys>();
                info_beam_frequency
                    ->setFrequency(beam_system ? beam_system->frequency : -1)
                    ->setEnemyHasEquipment(beam_system);
            }

            // Show the status of each subsystem.
            for (int n = 0; n < ShipSystem::COUNT; n++)
            {
                auto sys = ShipSystem::get(target, ShipSystem::Type(n));
                if (sys)
                {
                    const float system_health = sys->health;
                    info_system[n]
                        ->setValue(string(static_cast<int>(system_health * 100.0f)) + "%")
                        ->setBackColor(glm::u8vec4(255, static_cast<int>(127.5f * (system_health + 1.0f)), static_cast<int>(127.5f * (system_health + 1.0f)), 255));
                }
            }
        }

        // Show and update radar signature bands.
        float electrical = 0.0f;
        float gravitational = 0.0f;
        float thermal = 0.0f;

        if (auto info = target.getComponent<RawRadarSignatureInfo>())
        {
            float distance_variance = 0.0f;
            if (lrr && distance > lrr->short_range && scanstate < ScanState::State::FullScan)
                distance_variance = (random(0.01f, (distance - lrr->short_range)) / (lrr->long_range - lrr->short_range)) * 0.1f;

            electrical = std::max(0.0f, info->electrical - distance_variance);
            gravitational = std::max(0.0f, info->gravitational - distance_variance);
            thermal = std::max(0.0f, info->thermal - distance_variance);

            if (auto dynamic_info = target.getComponent<DynamicRadarSignatureInfo>())
            {
                electrical = std::max(0.0f, electrical + dynamic_info->electrical);
                gravitational = std::max(0.0f, gravitational + dynamic_info->gravitational);
                thermal = std::max(0.0f, thermal + dynamic_info->thermal);
            }

            if (sidebar_pager_selection == "Signals")
            {
                sidebar_signals_page->show();

                info_electrical_signal_band
                    ->setMaxAmp(electrical)
                    ->setNoiseError(calculateSignalError(electrical));
                info_electrical_signal_label->setText(tr("Electrical: {signal} MJ").format({{"signal", string(electrical)}}));

                info_thermal_signal_band
                    ->setMaxAmp(thermal)
                    ->setPhaseError(calculateSignalError(thermal));
                info_thermal_signal_label->setText(tr("Thermal: {signal} um").format({{"signal", string(thermal)}}));

                info_gravitational_signal_band
                    ->setMaxAmp(gravitational)
                    ->setPeriodError(calculateSignalError(gravitational));
                info_gravitational_signal_label->setText(tr("Gravitational: {signal} dN").format({{"signal", string(gravitational)}}));
            }
        }
    }
    // If the target is a waypoint, show its heading and distance, and our
    // velocity toward it.
    else if (targets.getWaypointIndex() >= 0)
    {
        sidebar_pager->hide();
        if (auto waypoints = my_spaceship.getComponent<Waypoints>())
        {
            if (auto transform = my_spaceship.getComponent<sp::Transform>())
            {
                if (auto waypoint_position = waypoints->get(targets.getWaypointIndex()))
                {
                    auto position_diff = waypoint_position.value() - transform->getPosition();
                    float distance = glm::length(position_diff);
                    float heading = vec2ToAngle(position_diff) - 270.0f;

                    while (heading < 0.0f) heading += 360.0f;

                    info_distance->setValue(string(distance / 1000.0f, 1) + DISTANCE_UNIT_1K);
                    info_heading->setValue(string(static_cast<int>(heading)));

                    if (distance > 0.0f)
                    {
                        float rel_velocity = 0.0f;
                        if (auto physics = my_spaceship.getComponent<sp::Physics>())
                            rel_velocity = -dot(physics->getVelocity(), position_diff / distance);

                        if (std::abs(rel_velocity) < 0.01f) rel_velocity = 0.0f;

                        info_relspeed->setValue(tr("{relative_velocity} {unit}/min.").format({
                            {"relative_velocity", string(rel_velocity / 1000.0f * 60.0f, 1)},
                            {"unit", DISTANCE_UNIT_1K}
                        }));
                    }
                }
            }
        }
    }
    else
    {
        target_entity = {};
    }
}

void ScienceScreen::onUpdate()
{
    if (!my_spaceship || !isVisible()) return;

    // Initiate a scan on scannable objects.
    if (keys.science_scan_object.getDown() &&
        my_spaceship.hasComponent<ScienceScanner>() &&
        my_spaceship.getComponent<ScienceScanner>()->delay == 0.0f)
    {
        auto my_transform = my_spaceship.getComponent<sp::Transform>();
        auto utility_beam = my_spaceship.getComponent<UtilityBeam>();

        // Synchronize the Functions sidebar tab with current custom ship functions.
        bool should_have_func_tab = custom_function_sidebar->hasEntries();
        bool has_func_tab = sidebar_selector->indexByValue("func") != -1;
        if (should_have_func_tab && !has_func_tab)
            sidebar_selector->addEntry(tr("scienceTab", "Functions"), "func");
        else if (!should_have_func_tab && has_func_tab)
        {
            bool func_was_selected = sidebar_selector->getSelectionValue() == "func";
            sidebar_selector->removeEntry(sidebar_selector->indexByValue("func"));
            custom_function_sidebar->hide();
            if (func_was_selected)
            {
                sidebar_selector->setSelectionIndex(0);
                info_sidebar->show();
            }
        }

        // Synchronize the Utility Beam sidebar tab with the current crew_positions mask.
        bool should_have_util_tab = utility_beam && utility_beam->crew_positions.has(crew_position);
        bool has_util_tab = sidebar_selector->indexByValue("util") != -1;
        if (should_have_util_tab && !has_util_tab)
            sidebar_selector->addEntry(tr("scienceTab", "Utility Beam"), "util");
        else if (!should_have_util_tab && has_util_tab)
        {
            bool util_was_selected = sidebar_selector->getSelectionValue() == "util";
            sidebar_selector->removeEntry(sidebar_selector->indexByValue("util"));
            utility_beam_sidebar->hide();
            utility_beam_dial->hide();
            if (util_was_selected)
            {
                sidebar_selector->setSelectionIndex(0);
                info_sidebar->show();
                custom_function_sidebar->hide();
            }
        }

        // Initiate a scan on scannable objects.
        if (keys.science_scan_object.isDiscreteStepDown() &&
            my_spaceship.hasComponent<ScienceScanner>() &&
            my_spaceship.getComponent<ScienceScanner>()->delay == 0.0f)
        {
            auto obj = targets.get();

            // Allow scanning only if the object is scannable, and if the player
            // isn't already scanning something.
            auto scanstate = obj.getComponent<ScanState>();

            if (scanstate && scanstate->getStateFor(my_spaceship) != ScanState::State::FullScan)
            {
                // Check for active radar link and validate the linked entity
                auto rl = my_spaceship.getComponent<RadarLink>();
                if (rl && rl->linked_entity && rl->linked_entity.hasComponent<AllowRadarLink>() && probe_radar->isVisible())
                    my_player_info->commandScan(obj, rl->linked_entity);
                else my_player_info->commandScan(obj);
                return;
            }
        }

        // Cycle selection through scannable objects.
        if ((keys.science_select_next_scannable.isDiscreteStepDown() || keys.science_select_next_scannable.isRepeatReady()) &&
            my_spaceship.hasComponent<ScienceScanner>() &&
            my_spaceship.getComponent<ScienceScanner>()->delay == 0.0f)
        {
            if (my_transform)
            {
                auto lrr = my_spaceship.getComponent<LongRangeRadar>();
                targets.setNext(my_transform->getPosition(), lrr ? lrr->long_range : DEFAULT_MAX_ZOOM_DISTANCE, TargetsContainer::ESelectionType::Scannable);
            }
        }

        // Open radar view.
        if (keys.science_open_radar.getDown())
        {
            view_mode_selection->setSelectionIndex(0);
            radar_view->show();
            background_gradient->show();
            database_view->hide();
        }

        // Open database view.
        if (keys.science_open_database.getDown())
        {
            view_mode_selection->setSelectionIndex(1);
            radar_view->hide();
            background_gradient->hide();
            database_view->show();
        }

        // Open database entry for the selected target.
        if (keys.science_open_database_target.getDown())
        {
            auto target = targets.get();
            auto scanstate_component = target.getComponent<ScanState>();
            auto scanstate = scanstate_component ? scanstate_component->getStateFor(my_spaceship) : ScanState::State::FullScan;
            if (auto tn = target.getComponent<TypeName>())
            {
                if (scanstate >= ScanState::State::SimpleScan
                    && (database_view->findAndDisplayEntry(tn->type_name) || database_view->findAndDisplayEntry(tn->localized)))
                {
                    view_mode_selection->setSelectionIndex(1);
                    radar_view->hide();
                    background_gradient->hide();
                    database_view->show();
                }
            }
        }

        // Navigate the sidebar tab selector. (scanning, custom functions)
        if (keys.science_sidebar_next.getDown() && sidebar_selector->isVisible())
        {
            const int count = sidebar_selector->entryCount();
            if (count > 0)
                sidebar_selector->setSelectionIndex((sidebar_selector->getSelectionIndex() + 1) % count);
        }
        if (keys.science_sidebar_prev.getDown() && sidebar_selector->isVisible())
        {
            const int count = sidebar_selector->entryCount();
            if (count > 0)
                sidebar_selector->setSelectionIndex((sidebar_selector->getSelectionIndex() + count - 1) % count);
        }

        // Navigate the sidebar pager. (tactical, systems, description)
        if (keys.science_sidebar_pager_next.getDown() && sidebar_pager->isVisible())
        {
            const int count = sidebar_pager->entryCount();
            if (count > 0)
                sidebar_pager->setSelectionIndex((sidebar_pager->getSelectionIndex() + 1) % count);
        }
        if (keys.science_sidebar_pager_prev.getDown() && sidebar_pager->isVisible())
        {
            const int count = sidebar_pager->entryCount();
            if (count > 0)
                sidebar_pager->setSelectionIndex((sidebar_pager->getSelectionIndex() + count - 1) % count);
        }
    }

    // Cycle selectable entities.
    if (auto transform = my_spaceship.getComponent<sp::Transform>())
    {
        auto scanner = my_spaceship.getComponent<ScienceScanner>();
        glm::vec2 scanner_position = transform->getPosition();
        float scanner_range = science_radar->getDistance();

        if (auto rl = my_spaceship.getComponent<RadarLink>())
        {
            if (probe_view_button->getValue() && rl && rl->linked_entity)
            {
                if (auto probe_transform = rl->linked_entity.getComponent<sp::Transform>())
                {
                    scanner_position = probe_transform->getPosition();
                    scanner_range = PROBE_ZOOM_DISTANCE;
                }
            }
        }

        // Select previous/next scannable entity.
        if (scanner && scanner->delay == 0.0f)
        {
            if (keys.science_select_next_scannable.getDown())
                targets.setNext(scanner_position, scanner_range, TargetsContainer::ESelectionType::Scannable);
            if (keys.science_select_prev_scannable.getDown())
                targets.setPrev(scanner_position, scanner_range, TargetsContainer::ESelectionType::Scannable);
        }

        // Select previous/next hostile entity.
        if (keys.science_enemy_next_target.getDown())
            targets.setNext(scanner_position, scanner_range, TargetsContainer::ESelectionType::Selectable, TargetsContainer::KnownFriendOrFoe::KnownHostile);
        if (keys.science_enemy_prev_target.getDown())
            targets.setPrev(scanner_position, scanner_range, TargetsContainer::ESelectionType::Selectable, TargetsContainer::KnownFriendOrFoe::KnownHostile);

        // Select previous/next selectable entity.
        if (keys.science_next_target.getDown())
            targets.setNext(scanner_position, scanner_range, TargetsContainer::ESelectionType::Selectable);
        if (keys.science_prev_target.getDown())
            targets.setPrev(scanner_position, scanner_range, TargetsContainer::ESelectionType::Selectable);
    }
}
