#pragma once

#include "gui/gui2_canvas.h"
#include "Updatable.h"

class GuiSelector;
class GuiBasicSlider;
class GuiSlider;
class GuiToggleButton;
class GuiLabel;

class OptionsMenu : public GuiCanvas, public Updatable
{
public:
    enum class ReturnTo
    {
        Main,
        ShipSelection,
        None
    };
private:
    const float ROW_HEIGHT = 50.0f;

    GuiElement* container;
    GuiToggleButton* graphics_tab;
    GuiToggleButton* audio_tab;
    GuiToggleButton* interface_tab;
    GuiElement* graphics_page;
    GuiElement* audio_page;
    GuiElement* interface_page;

    GuiToggleButton* helms_radar_lock_toggle;
    GuiToggleButton* weapons_radar_lock_toggle;
    GuiToggleButton* science_radar_lock_toggle;
    GuiBasicSlider* camera_sensitivity_slider;
    GuiLabel* camera_sensitivity_overlay_label;
    GuiSlider* sound_volume_slider;
    GuiSlider* music_volume_slider;
    GuiSlider* impulse_volume_slider;
    GuiLabel* sound_volume_overlay_label;
    GuiLabel* music_volume_overlay_label;

    GuiBasicSlider* graphics_fov_slider{};
    GuiLabel* graphics_fov_overlay_label{};
    GuiBasicSlider* graphics_draw_distance_slider{};
    GuiLabel* graphics_draw_distance_overlay_label{};

    std::vector<string> hotkey_categories;
    GuiLabel* impulse_volume_overlay_label;
    OptionsMenu::ReturnTo return_to;

    void setupInterfaceOptions(OptionsMenu::ReturnTo return_to);
    void setupGraphicsOptions();
    void setupAudioOptions();
public:
    OptionsMenu(ReturnTo return_to=ReturnTo::Main);

    virtual void update(float delta) override;
};
