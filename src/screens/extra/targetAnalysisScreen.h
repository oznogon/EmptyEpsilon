#pragma once

#include "gui/gui2_overlay.h"
#include "screenComponents/targetsContainer.h"
#include "components/shipsystem.h"

class GuiKeyValueDisplay;
class GuiRadarView;
class GuiRotatingModelView;
class GuiFrequencyCurve;

class TargetAnalysisScreen : public GuiOverlay
{
private:
    TargetsContainer targets;
    sp::ecs::Entity target_entity;

    GuiRadarView* radar;
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
public:
    TargetAnalysisScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
};
