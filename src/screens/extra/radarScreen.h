#pragma once

#include "gui/gui2_overlay.h"
#include "screenComponents/targetsContainer.h"

class GuiRadarView;
class GuiRadarZoomSlider;
class GuiSelector;
class GuiToggleButton;
class RawScannerDataRadarOverlay;

class RadarScreen : public GuiOverlay
{
private:
    TargetsContainer targets;
    string radar_type;
    GuiRadarView* radar;
    RawScannerDataRadarOverlay* signal_bands;
    GuiRadarView* probe_radar;
    RawScannerDataRadarOverlay* probe_signal_bands;
    GuiRadarZoomSlider* zoom_slider;
    GuiSelector* view_mode_selection;
    GuiToggleButton* auto_rotate_button;
    string previous_radar_type;
    float previous_short_range = 0.0f;
    float previous_long_range = 0.0f;
    bool probe_entry_added = false;
public:
    RadarScreen(GuiContainer* owner, string type = "Short range");

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;

    void setRadarMode(string mode);
};
