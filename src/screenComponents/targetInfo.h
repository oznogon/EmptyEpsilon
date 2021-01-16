#ifndef TARGET_INFO_H
#define TARGET_INFO_H

#include "gui/gui2_autolayout.h"
#include "screenComponents/targetsContainer.h"

class GuiKeyValueDisplay;

class GuiTargetInfo : public GuiAutoLayout
{
private:
	TargetsContainer targets;
    GuiKeyValueDisplay* target_callsign;
    GuiKeyValueDisplay* target_distance;
    GuiKeyValueDisplay* target_bearing;
    GuiKeyValueDisplay* target_relspeed;
    GuiKeyValueDisplay* target_faction;
    GuiKeyValueDisplay* target_type;
    GuiKeyValueDisplay* target_shields;
    GuiKeyValueDisplay* target_hull;
public:
    GuiTargetInfo(GuiContainer* owner, string id, TargetsContainer targets);

    virtual void onDraw(sf::RenderTarget& window) override;
};

#endif//TARGET_INFO_H
