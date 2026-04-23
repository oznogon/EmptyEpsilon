#pragma once

#include "gui/gui2_overlay.h"

class GuiImage;
class GuiLabel;
class GuiRadarView;
class GuiRadarZoomSlider;

class UtilityBeamScreen : public GuiOverlay
{
public:
    UtilityBeamScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& renderer) override;
private:
    const float DEFAULT_MIN_ZOOM_DISTANCE = 5000.0f;
    const float DEFAULT_MAX_ZOOM_DISTANCE = 30000.0f;

    GuiImage* background_gradient;
    GuiLabel* missing_beam_warning;
    GuiElement* radar_container;
    GuiRadarView* radar;
    GuiRadarZoomSlider* zoom_slider;
    // Used to judge when to update the UI label and zoom
    float previous_long_range_radar = 0.0f;
    float previous_short_range_radar = 0.0f;

    void doRadarZoom(float value);
};
