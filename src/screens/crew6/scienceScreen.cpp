#include "scienceScreen.h"
#include "i18n.h"
#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "preferenceManager.h"
#include "multiplayer_client.h"
#include "featureDefs.h"
#include "crewPositionRequirements.h"
#include "random.h"
#include "ecs/query.h"

#include "components/beamweapon.h"
#include "components/beamWeaponTarget.h"
#include "components/collision.h"
#include "components/customshipfunction.h"
#include "components/drone.h"
#include "components/hull.h"
#include "components/missile.h"
#include "components/mounts.h"
#include "components/name.h"
#include "components/radar.h"
#include "components/scanning.h"
#include "components/shields.h"
#include "components/target.h"
#include "components/utilityBeam.h"

#include "systems/radarblock.h"

#include "screenComponents/alertOverlay.h"
#include "screenComponents/customShipFunctions.h"
#include "screenComponents/databaseView.h"
#include "screenComponents/frequencyCurve.h"
#include "screenComponents/powerDamageIndicator.h"
#include "screenComponents/radarView.h"
#include "screenComponents/radarZoomSlider.h"
#include "screenComponents/rawScannerDataRadarOverlay.h"
#include "screenComponents/scanningDialog.h"
#include "screenComponents/scanTargetButton.h"
#include "screenComponents/signalQualityIndicator.h"
#include "screenComponents/utilityBeamControls.h"
#include "screenComponents/utilityBeamRotationDial.h"

#include "gui/theme.h"
#include "gui/gui2_button.h"
#include "gui/gui2_image.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_label.h"
#include "gui/gui2_listbox.h"
#include "gui/gui2_scrollcontainer.h"
#include "gui/gui2_scrolltextcontainer.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_slider.h"
#include "gui/gui2_togglebutton.h"
#include "gui/gui2_tooltip.h"

ScienceScreen::ScienceScreen(GuiContainer* owner, CrewPosition crew_position)
: GuiOverlay(owner, "SCIENCE_SCREEN", GuiTheme::getColor("background")), crew_position(crew_position)
{
    auto lrr = my_spaceship.getComponent<LongRangeRadar>();
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

    float effective_short_range = lrr ? lrr->short_range : DEFAULT_MIN_ZOOM_DISTANCE;
    float effective_long_range = lrr ? lrr->long_range : DEFAULT_MAX_ZOOM_DISTANCE;
    if (lrr)
    {
        if (auto sensors = my_spaceship.getComponent<SensorsSystem>())
        {
            const float eff = sensors->getSystemEffectiveness();
            effective_short_range = sensorsScaleShortRange(effective_short_range, eff);
            effective_long_range = sensorsScaleLongRange(effective_long_range, eff);
        }
    }

    targets.setAllowWaypointSelection();

    // Render the radar shadow and background decorations.
    background_gradient = new GuiImage(this, "BACKGROUND_GRADIENT", "");
    background_gradient
        ->setTextureThemed("background.gradient_offset")
        ->setPosition(glm::vec2(105.0f, 0.0f), sp::Alignment::CenterLeft)
        ->setSize(1200.0f, 900.0f);

    (new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255, 255, 255, 255}))
        ->setTextureTiledThemed("background.crosses");

    // Render the alert level color overlay.
    new AlertLevelOverlay(this);

    // Draw the radar.
    radar_view = new GuiElement(this, "RADAR_VIEW");
    radar_view->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Message if entity lacks the LongRangeRadar component.
    no_radar_label = new GuiLabel(radar_view, "NO_RADAR_LABEL", crewPositionRequirements::getMissingMessage(CrewPosition::scienceOfficer), GuiElement::GuiSizeRow);
    no_radar_label
        ->setAlignment(sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide();

    // Draw the science radar.
    science_radar = new GuiRadarView(radar_view, "SCIENCE_RADAR", effective_long_range, &targets);
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
                if (my_spaceship && targets.get())
                    my_player_info->commandSetScanTarget(targets.get());
                else if (my_spaceship)
                    my_player_info->commandSetScanTarget({});
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
                if (my_spaceship && targets.get())
                    my_player_info->commandSetScanTarget(targets.get());
                else if (my_spaceship)
                    my_player_info->commandSetScanTarget({});
            }, nullptr, nullptr, nullptr
        )
        ->setPosition(120.0f, 0.0f, sp::Alignment::CenterLeft)
        ->setSize(900.0f, GuiElement::GuiSizeMax)
        ->hide();

    probe_raw_signals = new RawScannerDataRadarOverlay(probe_radar, "");

    sidebar_selector = new GuiSelector(radar_view, "",
        [this](int index, string value)
        {
            if (value == "scan")
            {
                info_scan_content->show();
                custom_function_sidebar->hide();
                utility_beam_sidebar->hide();
                utility_beam_dial->hide();
            }
            else if (value == "func")
            {
                info_scan_content->hide();
                custom_function_sidebar->setVisible(custom_function_sidebar->hasEntries());
                utility_beam_sidebar->hide();
                utility_beam_dial->hide();
            }
            else if (value == "util")
            {
                info_scan_content->hide();
                custom_function_sidebar->hide();
                utility_beam_sidebar->show();
                utility_beam_dial->show();
            }
       }
    );

    sidebar_selector->setOptions(
        {tr("scienceTab", "Scanning")},
        {"scan"}
    );

    if (ub_mount)
    {
        if (ub_mount->crew_positions.has(crew_position))
            sidebar_selector->addEntry(tr("scienceTab", "Utility Beam"), "util");
    }

    sidebar_selector
        ->setSelectionIndex(0)
        ->setPosition(-20.0f, 120.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, GuiElement::GuiSizeRow);
    (new GuiTextTooltip(sidebar_selector, "SCIENCE_SIDEBAR_TIP", tr("tooltips", "Switch between available science control and data views."), 20.0f))->setWidth(280.0f);

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

    // Scan data container. Hiding this hides all scan data without hiding info_sidebar.
    info_scan_content = new GuiElement(info_sidebar, "SCAN_CONTENT");
    info_scan_content
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    // Scan button.
    scan_button = new GuiScanTargetButton(info_scan_content, "SCAN_BUTTON", &targets);
    scan_button
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setVisible(my_spaceship.hasComponent<ScienceScanner>());
    (new GuiTextTooltip(scan_button, "SCAN_BUTTON_TIP", tr("tooltips", "Initiate a scan of the selected target to reveal its data and subsystems."), 20.0f))->setWidth(280.0f);

    // Link target analysis button.
    link_target_analysis_button = new GuiButton(info_scan_content, "LINK_TARGET_ANALYSIS_BUTTON", tr("scienceButton", "Link target analysis"),
        [this]()
        {
            if (my_player_info && targets.get())
                my_player_info->commandSetAnalysisTarget(targets.get());
        }
    );
    link_target_analysis_button->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
    (new GuiTextTooltip(link_target_analysis_button, "LINK_TARGET_ANALYSIS_TIP", tr("tooltips", "Send the selected target's data to the analysis screen for comparison."), 20.0f))->setWidth(280.0f);

    // Simple scan data.
    info_callsign = new GuiKeyValueDisplay(info_scan_content, "SCIENCE_CALLSIGN", 0.4f, tr("science", "Callsign"), "");
    info_callsign->setSize(GuiElement::GuiSizeMax, 30.0f);

    info_distance = new GuiKeyValueDisplay(info_scan_content, "SCIENCE_DISTANCE", 0.4f, tr("science", "Distance"), "");
    info_distance->setSize(GuiElement::GuiSizeMax, 30.0f);

    info_heading = new GuiKeyValueDisplay(info_scan_content, "SCIENCE_HEADING", 0.4f, tr("science", "Bearing"), "");
    info_heading->setSize(GuiElement::GuiSizeMax, 30.0f);

    info_relspeed = new GuiKeyValueDisplay(info_scan_content, "SCIENCE_REL_SPEED", 0.4f, tr("science", "Rel. speed"), "");
    info_relspeed->setSize(GuiElement::GuiSizeMax, 30.0f);

    info_faction = new GuiKeyValueDisplay(info_scan_content, "SCIENCE_FACTION", 0.4f, tr("science", "Faction"), "");
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
        ->setSize(30.0f, 25.0f);
    (new GuiTextTooltip(info_faction_button, "FACTION_DB_TIP", tr("tooltips", "Open this faction's entry in the science database."), 20.0f))->setWidth(280.0f);

    info_type = new GuiKeyValueDisplay(info_scan_content, "SCIENCE_TYPE", 0.4f, tr("science", "Type"), "");
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
        ->setSize(30.0f, 25.0f);
    (new GuiTextTooltip(info_type_button, "TYPE_DB_TIP", tr("tooltips", "Open this ship type's entry in the science database."), 20.0f))->setWidth(280.0f);

    info_shields = new GuiKeyValueDisplay(info_scan_content, "SCIENCE_SHIELDS", 0.4f, tr("science", "Shields"), "");
    info_shields->setSize(GuiElement::GuiSizeMax, 30.0f);

    info_hull = new GuiKeyValueDisplay(info_scan_content, "SCIENCE_HULL", 0.4f, tr("science", "Hull"), "");
    info_hull->setSize(GuiElement::GuiSizeMax, 30.0f);

    // Full scan data sidebar.
    // Draw and hide the sidebar pager. Tabs are populated dynamically in onDraw.
    sidebar_pager = new GuiSelector(info_scan_content, "SIDEBAR_PAGER", [](int index, string value) {});
    sidebar_pager
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->hide();
    (new GuiTextTooltip(sidebar_pager, "SIDEBAR_PAGER_TIP", tr("tooltips", "Browse different data views for the selected target: tactical, systems, signals, or description."), 20.0f))->setWidth(280.0f);

    // Add sidebar pages.
    // If the server uses frequencies, add the Tactical sidebar page.
    if (gameGlobalInfo->use_beam_shield_frequencies)
        sidebar_pager->addEntry(tr("scienceTab", "Tactical"), "Tactical");
    sidebar_pager->addEntry(tr("scienceTab", "Systems"), "Systems");
    sidebar_pager->addEntry(tr("scienceTab", "Signals"), "Signals");
    sidebar_pager->addEntry(tr("scienceTab", "Description"), "Description");

    // Default the pager to the first item.
    sidebar_pager->setSelectionIndex(0);

    sidebar_signals_page = new GuiScrollContainer(info_scan_content, "");
    sidebar_signals_page
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    sidebar_frequencies_page = new GuiScrollContainer(info_scan_content, "");
    sidebar_frequencies_page
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    sidebar_systems_page = new GuiScrollContainer(info_scan_content, "");
    sidebar_systems_page
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    // Radar signature bands.
    info_electrical_signal_band = new GuiSignalQualityIndicator(sidebar_signals_page, "SCIENCE_ELECTRICAL_SIGNAL");
    info_electrical_signal_band
        ->showGreen(false)
        ->showBlue(false)
        ->addModeButton()
        ->setSize(GuiElement::GuiSizeMax, 80.0f);
    info_electrical_signal_label = new GuiLabel(info_electrical_signal_band, "", tr("Electrical"), 30.0f);
    info_electrical_signal_label->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    info_gravitational_signal_band = new GuiSignalQualityIndicator(sidebar_signals_page, "SCIENCE_GRAVITY_SIGNAL");
    info_gravitational_signal_band
        ->showRed(false)
        ->showGreen(false)
        ->addModeButton()
        ->setSize(GuiElement::GuiSizeMax, 80.0f);
    info_gravitational_signal_label = new GuiLabel(info_gravitational_signal_band, "", tr("Gravitational"), 30.0f);
    info_gravitational_signal_label->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    info_thermal_signal_band = new GuiSignalQualityIndicator(sidebar_signals_page, "SCIENCE_THERMAL_SIGNAL");
    info_thermal_signal_band
        ->showRed(false)
        ->showBlue(false)
        ->addModeButton()
        ->setSize(GuiElement::GuiSizeMax, 80.0f);
    info_thermal_signal_label = new GuiLabel(info_thermal_signal_band, "", tr("Thermal"), 30.0f);
    info_thermal_signal_label->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Prep and hide the frequency graphs.
    info_shield_frequency = new GuiFrequencyCurve(sidebar_frequencies_page, "SCIENCE_SHIELD_FREQUENCY", GuiFrequencyCurve::FrequencyType::Other, GuiFrequencyCurve::DamageEffect::Positive);
    info_shield_frequency->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    (new GuiTextTooltip(info_shield_frequency, "SHIELD_FREQ_CURVE_TIP", tr("tooltips", "Shield frequency calibration of the target. Match your beam frequency to penetrate."), 20.0f))->setWidth(280.0f);

    info_beam_frequency = new GuiFrequencyCurve(sidebar_frequencies_page, "SCIENCE_BEAM_FREQUENCY", GuiFrequencyCurve::FrequencyType::Beam, GuiFrequencyCurve::DamageEffect::Negative);
    info_beam_frequency->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    (new GuiTextTooltip(info_beam_frequency, "BEAM_FREQ_CURVE_TIP", tr("tooltips", "Beam weapon frequency of the target. Adjust your shield frequency to resist."), 20.0f))->setWidth(280.0f);

    // List each system's status.
    for (int n = 0; n < ShipSystem::COUNT; n++)
    {
        info_system[n] = new GuiKeyValueDisplay(sidebar_systems_page, "SCIENCE_SYSTEM_" + string(n), 0.75f, getLocaleSystemName(ShipSystem::Type(n)), "-");
        info_system[n]
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->hide();
    }

    // Prep and hide the description text area.
    info_description = new GuiScrollFormattedText(info_scan_content, "SCIENCE_DESC", "");
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
        ->setSize(200.0f, GuiElement::GuiSizeRow)
        ->disable();
    (new GuiTextTooltip(probe_view_button, "PROBE_VIEW_TIP", tr("tooltips", "Switch to the camera view from a linked probe to see from its perspective."), 20.0f))->setWidth(280.0f);

    // Draw the zoom slider.
    zoom_slider = new GuiRadarZoomSlider(radar_view, "RADAR_ZOOM", effective_short_range, effective_long_range, effective_long_range, science_radar);
    zoom_slider
        ->setPosition(-20.0f, -20.0f, sp::Alignment::BottomRight)
        ->setSize(250.0f, GuiElement::GuiSizeRow);
    (new GuiTextTooltip(zoom_slider, "SCIENCE_ZOOM_TIP", tr("tooltips", "Adjust the science radar zoom level for closer or wider views."), 20.0f))->setWidth(280.0f);

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
    (new GuiTextTooltip(view_mode_selection, "VIEW_MODE_TIP", tr("tooltips", "Switch between the radar view and the science database browser."), 20.0f))->setWidth(280.0f);

    // Scanning dialog.
    scanning_dialog = new GuiScanningDialog(this, "SCANNING_DIALOG");

    missile_threat_label = new GuiLabel(this, "MISSILE_THREAT_LABEL", tr("scienceThreat", "Missile"), 30.0f);
    missile_threat_label
        ->setAlignment(sp::Alignment::Center)
        ->addBackground()
        ->setTextColor(glm::u8vec4(255, 0, 0, 255))
        ->setBackgroundColor(glm::u8vec4(255, 0, 0, 255))
        ->setPosition(20.0f, -25.0f, sp::Alignment::CenterLeft)
        ->setSize(150.0f, GuiElement::GuiSizeRow)
        ->hide();
    (new GuiTextTooltip(missile_threat_label, "MISSILE_THREAT_TIP", tr("tooltips", "Warning: Incoming missiles detected targeting your ship."), 20.0f))->setWidth(280.0f);

    beam_threat_label = new GuiLabel(this, "BEAM_THREAT_LABEL", tr("scienceThreat", "Beam"), 30.0f);
    beam_threat_label
        ->setAlignment(sp::Alignment::Center)
        ->addBackground()
        ->setTextColor(glm::u8vec4(255, 0, 0, 255))
        ->setBackgroundColor(glm::u8vec4(255, 0, 0, 255))
        ->setPosition(20.0f, 25.0f, sp::Alignment::CenterLeft)
        ->setSize(150.0f, GuiElement::GuiSizeRow)
        ->hide();
    (new GuiTextTooltip(beam_threat_label, "BEAM_THREAT_TIP", tr("tooltips", "Warning: Enemy beam weapons are targeting your ship."), 20.0f))->setWidth(280.0f);
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
    auto rl = my_spaceship.getComponent<RadarLink>();

    float effective_short_range = 5000.0f;
    float effective_long_range = 30000.0f;
    if (lrr)
    {
        effective_short_range = lrr->short_range;
        effective_long_range = lrr->long_range;
        if (auto sensors = my_spaceship.getComponent<SensorsSystem>())
        {
            float eff = sensors->getSystemEffectiveness();
            effective_short_range = sensorsScaleShortRange(effective_short_range, eff);
            effective_long_range = sensorsScaleLongRange(effective_long_range, eff);
        }
    }

    // Scale the scan dialog's lock tolerance and lock delay by the ship's
    // Sensors system effectiveness: higher effectiveness widens the tolerance
    // and shortens the wait, lower effectiveness tightens it and lengthens it.
    if (scanning_dialog)
    {
        if (auto sensors = my_spaceship.getComponent<SensorsSystem>())
        {
            constexpr float base_lock_range = 0.05f;
            constexpr float base_lock_delay = 2.0f;
            float eff = sensors->getSystemEffectiveness();
            scanning_dialog->setLockRange(base_lock_range * eff);
            scanning_dialog->setLockDelay(base_lock_delay / std::max(0.01f, eff));
        }
    }

    // Manage probe view button state. Probe view is independent of LRR.
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

    if (!crewPositionRequirements::hasRequirements(CrewPosition::scienceOfficer, my_spaceship))
    {
        const bool probe_view_active = rl && rl->linked_entity && probe_view_button->getValue();
        background_gradient->setVisible(probe_view_active);
        science_radar->hide();
        zoom_slider->hide();
        if (!probe_view_active)
        {
            scan_button->disable();
            no_radar_label->show();
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
            link_target_analysis_button->hide();
            sidebar_frequencies_page->hide();
            sidebar_signals_page->hide();
            sidebar_systems_page->hide();
            info_description->hide();
            sidebar_pager->hide();
            for (int n = 0; n < ShipSystem::COUNT; n++)
                info_system[n]->hide();
            targets.clear();
            return;
        }
    }
    else
    {
        no_radar_label->hide();
        science_radar->show();
        zoom_slider->show();
        scan_button->enable();
    }

    // Sync local target selection with replicated scanner target so all
    // Science and Operations clients show the same selected target.
    if (auto scanner = my_spaceship.getComponent<ScienceScanner>())
    {
        if (scanner->target != targets.get())
            targets.set(scanner->target);
    }

    if (lrr)
    {
        float view_distance = science_radar->getDistance();
        float mouse_wheel_delta = keys.zoom_in.getContinuousValue() + keys.zoom_in.getAxis0Value() + keys.zoom_in.getAxis1Value()
            - keys.zoom_out.getContinuousValue() - keys.zoom_out.getAxis0Value() - keys.zoom_out.getAxis1Value();
        if (mouse_wheel_delta != 0)
            view_distance *= (1.0f - (mouse_wheel_delta * 0.1f));
        if (keys.zoom_in.isDiscreteStepDown() || keys.zoom_in.isRepeatReady())
            view_distance = std::max(effective_short_range, view_distance * 0.9f);
        if (keys.zoom_out.isDiscreteStepDown() || keys.zoom_out.isRepeatReady())
            view_distance = std::min(effective_long_range, view_distance * 1.1f);
        view_distance = std::min(view_distance, effective_long_range);
        view_distance = std::max(view_distance, effective_short_range);

        // Update radar view distances and zoom range if changed.
        if (view_distance != science_radar->getDistance()
            || previous_long_range_radar != effective_long_range
            || previous_short_range_radar != effective_short_range)
        {
            previous_short_range_radar = effective_short_range;
            previous_long_range_radar = effective_long_range;
            zoom_slider
                ->setRange(effective_long_range, effective_short_range)
                ->setValue(view_distance);
        }
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
    else if (lrr)
    {
        auto target_transform = targets.get().getComponent<sp::Transform>();
        auto my_transform = my_spaceship.getComponent<sp::Transform>();

        if (!my_transform || RadarBlockSystem::isRadarBlockedFrom(my_transform->getPosition(), targets.get(), effective_short_range))
            targets.clear();

        // Deselect target if outside of long range radar range.
        if (my_transform && target_transform)
        {
            if (glm::length(target_transform->getPosition() - my_transform->getPosition()) > effective_long_range)
                targets.clear();
        }
    }

    // Responsive layout for custom button sidebar. 1440x900 vpixels is 16:10, so this would roughly be the threshold.
    int current_width = static_cast<int>(getRect().size.x);
    info_sidebar->setPosition(-20.0f, 170.0f, sp::Alignment::TopRight);
    sidebar_selector
        ->setPosition(-20.0f, 120.0f, sp::Alignment::TopRight)
        ->setVisible((current_width < 1435 && sidebar_selector->entryCount() > 1) || (current_width >= 1435 && sidebar_selector->entryCount() > 2));

    if (current_width < 1435 || !custom_function_sidebar->hasEntries())
    {
        custom_function_sidebar
            ->setPosition(-20.0f, 210.0f, sp::Alignment::TopRight)
            ->setVisible(current_width < 1435 && sidebar_selector->getSelectionIndex() == 1 && sidebar_selector->indexByValue("func") >= 0);
        info_sidebar->setVisible(current_width >= 1435 || sidebar_selector->getSelectionValue() != "func");
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
    info_callsign->hide();
    info_faction->hide();
    info_type->hide();
    info_hull->hide();
    info_shield_frequency->setFrequency(-1);
    info_beam_frequency->setFrequency(-1);
    info_faction_button->hide();
    info_type_button->hide();
    link_target_analysis_button->hide();
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

    auto target = targets.get();
    if (target != previous_target)
    {
        // Target changed, so reset the tracked description.
        previous_description = "";
        previous_target = target;

        info_electrical_signal_band->clearHistory();
        info_gravitational_signal_band->clearHistory();
        info_thermal_signal_band->clearHistory();
    }

    if (target)
    {
        target_entity = target;
        link_target_analysis_button->show();

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
        {
            info_callsign->setValue(cs->callsign);
            info_callsign->show();
        }

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

        // Only show Tactical tab if the target has been fully scanned and has
        // actual frequency data to report (shield frequency >= 0 or a beam
        // weapon system exists).
        bool has_tactical_data = false;
        if (target && gameGlobalInfo->use_beam_shield_frequencies && scanstate >= ScanState::State::FullScan)
        {
            auto shields_system = target.getComponent<Shields>();
            auto beam_system = target.getComponent<BeamWeaponSys>();
            has_tactical_data = (shields_system && shields_system->frequency >= 0) || beam_system;
        }
        int tactical_idx = sidebar_pager->indexByValue("Tactical");
        if (has_tactical_data && tactical_idx < 0)
            sidebar_pager->addEntry(tr("scienceTab", "Tactical"), "Tactical");
        else if (!has_tactical_data && tactical_idx >= 0)
        {
            bool tactical_was_selected = sidebar_pager->getSelectionValue() == "Tactical";
            sidebar_pager->removeEntry(tactical_idx);
            if (tactical_was_selected || sidebar_pager->getSelectionIndex() < 0)
                sidebar_pager->setSelectionIndex(0);
        }

        // Only show Systems tab if the target has subsystems to report.
        bool has_systems_data = false;
        if (target)
        {
            for (int n = 0; n < ShipSystem::COUNT; n++)
            {
                if (ShipSystem::get(target, ShipSystem::Type(n)))
                {
                    has_systems_data = true;
                    break;
                }
            }
        }
        int systems_idx = sidebar_pager->indexByValue("Systems");
        if (has_systems_data && systems_idx < 0)
            sidebar_pager->addEntry(tr("scienceTab", "Systems"), "Systems");
        else if (!has_systems_data && systems_idx >= 0)
        {
            bool systems_was_selected = sidebar_pager->getSelectionValue() == "Systems";
            sidebar_pager->removeEntry(systems_idx);
            if (systems_was_selected || sidebar_pager->getSelectionIndex() < 0)
                sidebar_pager->setSelectionIndex(0);
        }

        // Only show Signals tab if the target has radar signature data.
        bool has_signals_data = false;
        if (target)
            has_signals_data = target.hasComponent<RawRadarSignatureInfo>() || target.hasComponent<DynamicRadarSignatureInfo>();
        int signals_idx = sidebar_pager->indexByValue("Signals");
        if (has_signals_data && signals_idx < 0)
            sidebar_pager->addEntry(tr("scienceTab", "Signals"), "Signals");
        else if (!has_signals_data && signals_idx >= 0)
        {
            bool signals_was_selected = sidebar_pager->getSelectionValue() == "Signals";
            sidebar_pager->removeEntry(signals_idx);
            if (signals_was_selected || sidebar_pager->getSelectionIndex() < 0)
                sidebar_pager->setSelectionIndex(0);
        }

        // Auto-switch to the Description tab when the description text changes.
        if (!description.empty() && description != previous_description)
        {
            int desc_idx = sidebar_pager->indexByValue("Description");
            if (desc_idx >= 0)
                sidebar_pager->setSelectionIndex(desc_idx);
        }
        previous_description = description;

        string sidebar_pager_selection = sidebar_pager->getSelectionValue();

        // On a simple scan or deeper, show the faction, ship type, shields,
        // hull integrity, and database reference button.
        if (scanstate >= ScanState::State::SimpleScan)
        {
            if (target.hasComponent<Faction>())
            {
                auto faction = Faction::getInfo(target);
                info_faction_button->show();
                info_faction->setValue(faction.locale_name);
                info_faction->show();
            }

            if (auto tn = target.getComponent<TypeName>())
            {
                info_type_button->show();
                info_type->setValue(tn->localized);
                info_type->show();
            }

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
            {
                if (hull->max > 1.0f)
                {
                    info_hull->setValue(static_cast<int>(ceil(hull->current)));
                    info_hull->show();
                }
            }
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
                for (int n = 0; n < ShipSystem::COUNT; n++)
                {
                    if (ShipSystem::get(target, ShipSystem::Type(n)))
                        info_system[n]->show();
                }

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
        else if (sidebar_pager_selection != "")
            LOG(Warning, "[sciencescreen] Invalid sidebar pager state: ", sidebar_pager_selection);

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
            if (lrr && distance > effective_short_range && scanstate < ScanState::State::FullScan)
                distance_variance = (random(0.01f, (distance - effective_short_range)) / (effective_long_range - effective_short_range)) * 0.1f;

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
    else target_entity = {};

    // Show threat indicators only when the science radar is the active view.
    const bool science_radar_active = view_mode_selection->getSelectionIndex() == 0
        && !probe_view_button->getValue();

    bool missile_threat = false;
    bool beam_threat = false;

    if (science_radar_active && my_spaceship)
    {
        for (auto [entity, homing] : sp::ecs::Query<MissileHoming>())
        {
            if (homing.target == my_spaceship)
            {
                missile_threat = true;
                break;
            }
        }

        if (auto my_transform = my_spaceship.getComponent<sp::Transform>())
        {
            for (auto [entity, beamsys, transform] : sp::ecs::Query<BeamWeaponSys, sp::Transform>())
            {
                sp::ecs::Entity beam_target;
                if (auto bt = entity.getComponent<BeamWeaponTarget>())
                    beam_target = bt->entity;
                else if (auto t = entity.getComponent<Target>())
                    beam_target = t->entity;

                if (beam_target != my_spaceship) continue;

                auto mounts = entity.getComponent<Mounts>();
                if (mounts) {
                for (const auto& mount : mounts->mounts)
                {
                    if (mount.type != MountType::BeamWeapon || mount.range <= 0.0f) continue;

                    auto mount_world = transform.getPosition() + rotateVec2(glm::vec2(mount.position.x, mount.position.y), transform.getRotation());
                    float distance = glm::length(my_transform->getPosition() - mount_world);

                    if (auto physics = entity.getComponent<sp::Physics>())
                        distance -= std::max(physics->getSize().x, physics->getSize().y);

                    if (distance < mount.range)
                    {
                        beam_threat = true;
                        break;
                    }
                }
                }

                if (beam_threat) break;
            }
        }
    }

    missile_threat_label->setVisible(missile_threat);
    beam_threat_label->setVisible(beam_threat);
}

void ScienceScreen::onUpdate()
{
    if (!my_spaceship || !isVisible()) return;

    auto lrr = my_spaceship.getComponent<LongRangeRadar>();
    auto science_scanner = my_spaceship.getComponent<ScienceScanner>();
    auto my_transform = my_spaceship.getComponent<sp::Transform>();

    auto mounts_comp = my_spaceship.getComponent<Mounts>();
    const Mount* ub_mount = nullptr;
    if (mounts_comp) {
        for (auto& m : mounts_comp->mounts) {
            if (m.type == MountType::UtilityBeam) { ub_mount = &m; break; }
        }
    }

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
            info_scan_content->show();
            utility_beam_sidebar->hide();
            utility_beam_dial->hide();
        }
    }

    // Synchronize the Utility Beam sidebar tab with the current crew_positions mask.
    bool should_have_util_tab = ub_mount && ub_mount->crew_positions.has(crew_position);
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
            info_scan_content->show();
            custom_function_sidebar->hide();
        }
    }

    // Initiate a scan on scannable objects.
    if (science_scanner && science_scanner->delay == 0.0f)
    {
        // Initiate a scan on scannable objects.
        if (keys.science_scan_object.isDiscreteStepDown() || keys.science_scan_toggle.isDiscreteStepDown())
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

        // Open radar view.
        if (lrr && keys.science_open_radar.isDiscreteStepDown())
        {
            view_mode_selection->setSelectionIndex(0);
            radar_view->show();
            background_gradient->show();
            database_view->hide();
        }

        // Open database view.
        if (keys.science_open_database.isDiscreteStepDown())
        {
            view_mode_selection->setSelectionIndex(1);
            radar_view->hide();
            background_gradient->hide();
            database_view->show();
        }

        // Open database entry for the selected target.
        if (keys.science_open_database_target.isDiscreteStepDown())
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
        if (sidebar_selector->isVisible())
        {
            const int count = sidebar_selector->entryCount();
            if (count > 0)
            {
                if (keys.science_sidebar_next.isDiscreteStepDown() || keys.science_sidebar_next.isRepeatReady())
                    sidebar_selector->setSelectionIndex((sidebar_selector->getSelectionIndex() + 1) % count);

                if (keys.science_sidebar_prev.isDiscreteStepDown() || keys.science_sidebar_prev.isRepeatReady())
                    sidebar_selector->setSelectionIndex((sidebar_selector->getSelectionIndex() + count - 1) % count);
            }
        }

        // Navigate the sidebar pager. (tactical, systems, description)
        if (sidebar_pager->isVisible())
        {
            const int count = sidebar_pager->entryCount();
            if (count > 0)
            {
                if (keys.science_sidebar_pager_next.isDiscreteStepDown() || keys.science_sidebar_pager_next.isRepeatReady())
                    sidebar_pager->setSelectionIndex((sidebar_pager->getSelectionIndex() + 1) % count);

                if (keys.science_sidebar_pager_prev.isDiscreteStepDown() || keys.science_sidebar_pager_prev.isRepeatReady())
                    sidebar_pager->setSelectionIndex((sidebar_pager->getSelectionIndex() + count - 1) % count);
            }
        }
    }

    // Cycle selectable entities.
    if (my_transform)
    {
        bool use_probe_view = false;
        glm::vec2 scanner_position = my_transform->getPosition();
        float scanner_range = lrr ? science_radar->getDistance() : PROBE_ZOOM_DISTANCE;

        if (auto rl = my_spaceship.getComponent<RadarLink>())
        {
            if (probe_view_button->getValue() && rl && rl->linked_entity)
            {
                if (auto probe_transform = rl->linked_entity.getComponent<sp::Transform>())
                {
                    scanner_position = probe_transform->getPosition();
                    scanner_range = PROBE_ZOOM_DISTANCE;
                    use_probe_view = true;
                }
            }
        }

        if (science_scanner && science_scanner->delay == 0.0f && (lrr || use_probe_view))
        {
            float effective_short_range = -1.0f;
            if (!use_probe_view && lrr)
            {
                effective_short_range = lrr->short_range;
                if (auto sensors = my_spaceship.getComponent<SensorsSystem>())
                    effective_short_range = sensorsScaleShortRange(effective_short_range, sensors->getSystemEffectiveness());
            }

            // Select previous/next scannable entity.
            if (keys.science_select_next_scannable.isDiscreteStepDown() || keys.science_select_next_scannable.isRepeatReady())
            {
                targets.setNextTarget(scanner_position, scanner_range, TargetsContainer::ESelectionType::Scannable, TargetsContainer::KnownFriendOrFoe::Any, effective_short_range);
                if (targets.get()) my_player_info->commandSetScanTarget(targets.get());
            }

            if (keys.science_select_prev_scannable.isDiscreteStepDown() || keys.science_select_prev_scannable.isRepeatReady())
            {
                targets.setPrevTarget(scanner_position, scanner_range, TargetsContainer::ESelectionType::Scannable, TargetsContainer::KnownFriendOrFoe::Any, effective_short_range);
                if (targets.get()) my_player_info->commandSetScanTarget(targets.get());
            }

            // Select previous/next hostile entity.
            if (keys.science_enemy_next_target.isDiscreteStepDown() || keys.science_enemy_next_target.isRepeatReady())
            {
                targets.setNextTarget(scanner_position, scanner_range, TargetsContainer::ESelectionType::Selectable, TargetsContainer::KnownFriendOrFoe::KnownHostile, effective_short_range);
                if (targets.get()) my_player_info->commandSetScanTarget(targets.get());
            }

            if (keys.science_enemy_prev_target.isDiscreteStepDown() || keys.science_enemy_prev_target.isRepeatReady())
            {
                targets.setPrevTarget(scanner_position, scanner_range, TargetsContainer::ESelectionType::Selectable, TargetsContainer::KnownFriendOrFoe::KnownHostile, effective_short_range);
                if (targets.get()) my_player_info->commandSetScanTarget(targets.get());
            }

            // Select previous/next selectable entity.
            if (keys.science_next_target.isDiscreteStepDown() || keys.science_next_target.isRepeatReady())
            {
                targets.setNextTarget(scanner_position, scanner_range, TargetsContainer::ESelectionType::Selectable, TargetsContainer::KnownFriendOrFoe::Any, effective_short_range);
                if (targets.get()) my_player_info->commandSetScanTarget(targets.get());
            }

            if (keys.science_prev_target.isDiscreteStepDown() || keys.science_prev_target.isRepeatReady())
            {
                targets.setPrevTarget(scanner_position, scanner_range, TargetsContainer::ESelectionType::Selectable, TargetsContainer::KnownFriendOrFoe::Any, effective_short_range);
                if (targets.get()) my_player_info->commandSetScanTarget(targets.get());
            }
        }
    }
}
