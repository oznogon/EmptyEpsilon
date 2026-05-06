#pragma once

#include <math.h>

#include "gui/gui2_element.h"
#include "timer.h"

class GuiThemeStyle;

// Class for drawing bands in the Science Station's "Scanning" mini-game
class GuiSignalQualityIndicator : public GuiElement
{
private:
    sp::SystemStopwatch clock;
    float max_amp = 1.0f;
    float target_period;
    float error_noise = 0.0f;
    float error_period = 0.0f;
    float error_phase = 0.0f;
    bool show_red = true;
    bool show_green = true;
    bool show_blue = true;
    const GuiThemeStyle* signalquality_style;
    const GuiThemeStyle* electrical_band_style;
    const GuiThemeStyle* biological_band_style;
    const GuiThemeStyle* gravitational_band_style;
public:
    GuiSignalQualityIndicator(GuiContainer* owner, string id);

    virtual void onDraw(sp::RenderTarget& target) override;

    GuiSignalQualityIndicator* setMaxAmp(float f) { max_amp = std::min(fabsf(f), 1.0f); return this; }
    GuiSignalQualityIndicator* setNoiseError(float f) { error_noise = std::min(fabsf(f), 1.0f); return this; }
    GuiSignalQualityIndicator* setPeriodError(float f) { error_period = std::min(fabsf(f), 1.0f); return this; }
    GuiSignalQualityIndicator* setPhaseError(float f) { error_phase = std::min(fabsf(f), 1.0f); return this; }

    GuiSignalQualityIndicator* showRed(bool show) { show_red = show; return this; }
    GuiSignalQualityIndicator* showGreen(bool show) { show_green = show; return this; }
    GuiSignalQualityIndicator* showBlue(bool show) { show_blue = show; return this; }
};
