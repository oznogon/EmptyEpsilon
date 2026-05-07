#pragma once

#include "gui/gui2_overlay.h"
#include "screenComponents/targetsContainer.h"
#include "components/shipsystem.h"

class GuiFrequencyCurve;
class GuiKeyValueDisplay;
class GuiLabel;
class GuiRotatingModelView;
class GuiSignalQualityIndicator;

class TargetAnalysisScreen : public GuiOverlay
{
private:
    GuiLabel* no_target_label;

    TargetsContainer targets;
    sp::ecs::Entity target_entity;

    GuiRotatingModelView* model_view;

    GuiKeyValueDisplay* info_callsign;
    GuiKeyValueDisplay* info_distance;
    GuiKeyValueDisplay* info_bearing;
    GuiKeyValueDisplay* info_relspeed;
    GuiKeyValueDisplay* info_faction;
    GuiKeyValueDisplay* info_type;
    GuiKeyValueDisplay* info_hull;
    GuiKeyValueDisplay* info_shields;
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
