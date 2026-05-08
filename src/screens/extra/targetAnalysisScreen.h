#pragma once

#include "gui/gui2_overlay.h"
#include "screenComponents/targetsContainer.h"
#include "components/shipsystem.h"

class GuiFrequencyCurve;
class GuiKeyValueDisplay;
class GuiLabel;
class GuiRotatingModelView;
class GuiSignalQualityIndicator;
class GuiScrollFormattedText;
class GuiElement;

class TargetAnalysisScreen : public GuiOverlay
{
private:
    const float KV_HEIGHT = 30.0f;
    const float KV_DIV = 0.5f;

    GuiLabel* no_target_label;

    TargetsContainer targets;
    sp::ecs::Entity target_entity;

    GuiElement* columns_container;

    GuiRotatingModelView* model_view;
    GuiElement* description_section;
    GuiScrollFormattedText* info_description;
    GuiElement* basic_info_section;
    GuiElement* systems_section;
    GuiElement* frequencies_section;
    GuiElement* signatures_section;

    GuiLabel* info_callsign;
    GuiKeyValueDisplay* info_distance;
    GuiKeyValueDisplay* info_bearing;
    GuiKeyValueDisplay* info_relspeed;
    GuiKeyValueDisplay* info_faction;
    GuiKeyValueDisplay* info_type;
    GuiKeyValueDisplay* info_hull;
    GuiKeyValueDisplay* info_shields;
    GuiKeyValueDisplay* info_class;
    GuiKeyValueDisplay* info_subclass;
    GuiKeyValueDisplay* info_size;
    GuiFrequencyCurve* info_shield_frequency;
    GuiFrequencyCurve* info_beam_frequency;
    GuiKeyValueDisplay* info_system[ShipSystem::COUNT];
    GuiSignalQualityIndicator* info_electrical_signal_band;
    GuiLabel* info_electrical_signal_label;
    GuiSignalQualityIndicator* info_gravitational_signal_band;
    GuiLabel* info_gravitational_signal_label;
    GuiSignalQualityIndicator* info_thermal_signal_band;
    GuiLabel* info_thermal_signal_label;
public:
    TargetAnalysisScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
};
