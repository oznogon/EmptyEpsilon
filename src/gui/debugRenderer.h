#pragma once

#include <deque>
#include "gui/gui2_resizabledialog.h"
#include "timer.h"
#include "engine.h"

class GuiKeyValueDisplay;
class GuiToggleButton;
class GuiButton;
class GuiSlider;
class GuiLabel;

class DebugRenderer : public GuiResizableDialog
{
private:
    static constexpr size_t MAX_TIMING_POINTS = 1800;

    sp::SystemStopwatch fps_timer;
    float fps = 0.0f;
    int fps_counter = 0;

    bool show_datarate = true;
    bool show_timing_graph = false;
    bool show_atlas = false;

    float scale = 10.0f;
    bool scale_press_handled = false;
    bool timing_paused = false;
    bool timing_graph_stacked = false;
    float time_window = 300.0f;
    sp::io::Pointer::Button mouse_down_button;

    // Toolbar widgets
    GuiElement* toolbar;
    GuiToggleButton* pause_button;
    GuiLabel* scale_label;
    GuiSlider* scale_slider;
    GuiButton* scale_down_button;
    GuiButton* scale_reset_button;
    GuiButton* scale_up_button;
    GuiLabel* tw_label;
    GuiSlider* tw_slider;
    GuiButton* tw_down_button;
    GuiButton* tw_reset_button;
    GuiButton* tw_up_button;
    GuiToggleButton* stack_button;

    std::map<string, bool> timing_graph_enabled;
    std::vector<string> key_order;
    std::map<string, std::deque<float>> timing_graph_points;
    std::vector<glm::vec2> timing_graph_draw_points;

    GuiKeyValueDisplay* fps_display;
    GuiKeyValueDisplay* threat_display;
    GuiKeyValueDisplay* rate_display;
    GuiToggleButton* high_latency_button;
    GuiToggleButton* random_latency_button;

public:
    DebugRenderer(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual bool onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id) override;
    virtual void onMouseUp(glm::vec2 position, sp::io::Pointer::ID id) override;
    void onClose() override;
};
