#pragma once

#include "gui/gui2_overlay.h"

class GuiKeyValueDisplay;
class GuiButton;
class GuiSelector;
class GuiCommsOverlay;
class GuiToggleButton;
class ScienceScreen;
class ShipsLog;

class OperationScreen : public GuiOverlay
{
private:
    enum EMode
    {
        TargetSelection,
        WaypointPlacement,
        MoveWaypoint
    };

    EMode mode;
    int drag_waypoint_index;
    int drag_waypoint_set;
    int active_waypoint_set = 1;

    ScienceScreen* science;

    GuiKeyValueDisplay* info_reputation;
    GuiKeyValueDisplay* info_clock;

    GuiToggleButton* place_waypoint_button;
    GuiButton* delete_waypoint_button;
    GuiSelector* waypoint_set_selector;
    GuiToggleButton* route_toggle;

    GuiCommsOverlay* comms_overlay;
    ShipsLog* ships_log;

    glm::vec2 mouse_down_position{0, 0};
public:
    OperationScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};
