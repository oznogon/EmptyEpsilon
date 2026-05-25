#pragma once

#include "screenComponents/targetsContainer.h"
#include "gui/gui2_overlay.h"
#include "playerInfo.h"

class DatabaseViewComponent;
class GuiButton;
class GuiCustomShipFunctions;
class GuiFrequencyCurve;
class GuiImage;
class GuiKeyValueDisplay;
class GuiLabel;
class GuiListbox;
class GuiRadarView;
class GuiRadarZoomSlider;
class GuiScanTargetButton;
class GuiScrollContainer;
class GuiScrollFormattedText;
class GuiSelector;
class GuiSignalQualityIndicator;
class GuiToggleButton;
class GuiUtilityBeamControls;
class GuiUtilityBeamRotationDial;
class RawScannerDataRadarOverlay;

class ScienceScreen : public GuiOverlay
{
public:
    const float PROBE_ZOOM_DISTANCE = 5000.0f;
    const float DEFAULT_MIN_ZOOM_DISTANCE = 5000.0f;
    const float DEFAULT_MAX_ZOOM_DISTANCE = 30000.0f;

    GuiImage* background_gradient;

    GuiElement* radar_view;
    DatabaseViewComponent* database_view;

    TargetsContainer targets;
    GuiRadarView* science_radar;
    RawScannerDataRadarOverlay* science_raw_signals;
    GuiRadarView* probe_radar;
    RawScannerDataRadarOverlay* probe_raw_signals;
    GuiRadarZoomSlider* zoom_slider;

    GuiSelector* sidebar_selector;
    GuiElement* info_sidebar;
    GuiScrollContainer* sidebar_signals_page;
    GuiScrollContainer* sidebar_frequencies_page;
    GuiScrollContainer* sidebar_systems_page;
    GuiCustomShipFunctions* custom_function_sidebar;
    GuiUtilityBeamControls* utility_beam_sidebar;
    GuiSelector* sidebar_pager;
    // info_sidebar
    GuiScanTargetButton* scan_button;
    GuiButton* link_to_analysis_button;
    GuiKeyValueDisplay* info_callsign;
    GuiKeyValueDisplay* info_distance;
    GuiKeyValueDisplay* info_heading;
    GuiKeyValueDisplay* info_relspeed;
    GuiKeyValueDisplay* info_faction;
    GuiButton* info_faction_button;
    GuiKeyValueDisplay* info_type;
    GuiButton* info_type_button;
    GuiKeyValueDisplay* info_shields;
    GuiKeyValueDisplay* info_hull;
    GuiScrollFormattedText* info_description;
    GuiFrequencyCurve* info_shield_frequency;
    GuiFrequencyCurve* info_beam_frequency;
    GuiKeyValueDisplay* info_system[ShipSystem::COUNT];
    // Utility beam controls
    GuiUtilityBeamRotationDial* utility_beam_dial;

    GuiSignalQualityIndicator* info_electrical_signal_band;
    GuiLabel* info_electrical_signal_label;
    GuiSignalQualityIndicator* info_gravitational_signal_band;
    GuiLabel* info_gravitational_signal_label;
    GuiSignalQualityIndicator* info_thermal_signal_band;
    GuiLabel* info_thermal_signal_label;

    GuiToggleButton* probe_view_button;
    sp::ecs::Entity observation_point;
    sp::ecs::Entity target_entity;
    GuiListbox* view_mode_selection;

    ScienceScreen(GuiContainer* owner, CrewPosition crew_position=CrewPosition::scienceOfficer);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
    void doRadarZoom(float value);
private:
    CrewPosition crew_position;
    // Used to judge when to update the UI label and zoom
    float previous_long_range_radar = 0.0f;
    float previous_short_range_radar = 0.0f;
    sp::ecs::Entity previous_target;
};
