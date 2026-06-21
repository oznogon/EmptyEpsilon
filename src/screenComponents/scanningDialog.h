#pragma once

#include "gui/gui2_element.h"
#include "signalQualityIndicator.h"
#include "gameGlobalInfo.h"

class GuiPanel;
class GuiLabel;
class GuiSlider;
class GuiButton;

class GuiScanningDialog : public GuiElement
{
private:
    static constexpr int MAX_SLIDERS = 4;

    GuiPanel* box;
    GuiLabel* signal_label;
    GuiLabel* locked_label;
    GuiSignalQualityIndicator* signal_quality;
    GuiSlider* sliders[MAX_SLIDERS];
    GuiButton* cancel_button;

    float target[MAX_SLIDERS];
    bool locked = false;
    float lock_start_time = 0.0f;
    float lock_delay = 2.0f;
    float lock_range = 0.05f;
    int scan_depth = 0;
    std::array<bool, MAX_SLIDERS> set_active = {false, false, false, false};
    std::pair<int, int> getScanComplexityDepth();
public:
    GuiScanningDialog(GuiContainer* owner, string id);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;

    void setupParameters();
    void updateSignal();
    void setLockDelay(float delay);
    float getLockDelay();
    void setLockRange(float range);
    float getLockRange();
};
