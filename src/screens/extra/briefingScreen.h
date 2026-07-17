#pragma once

#include "gui/gui2_overlay.h"

class GuiBriefingMap;
class GuiButton;
class GuiImageContain;
class GuiLabel;
class GuiProgressbar;
class GuiScrollFormattedText;
class GuiSlider;
class GuiToggleButton;
class Briefing;

class BriefingScreen : public GuiOverlay
{
private:
    GuiLabel* no_pages_label;
    GuiElement* page_container;
    GuiImageContain* page_image;
    GuiBriefingMap* page_map;
    GuiScrollFormattedText* page_caption;
    GuiSlider* page_slider;
    GuiButton* prev_button;
    GuiButton* next_button;
    GuiToggleButton* play_button;
    GuiToggleButton* caption_button;
    GuiProgressbar* page_progress;
    int current_page = 0;
    size_t last_page_count = SIZE_MAX;
    bool is_playing = false;
    float play_timer = 0.0f;
    float last_update_time = -1.0f;
    int active_sound = -1;
    bool caption_visible = true;

    // Return the active player ship's Briefing component, if any.
    const Briefing* getBriefing() const;
    // Update the BriefingPage selection.
    void updatePage();
    // Show the given page.
    void setCurrentPage(int page);
    // Stop the old page's audio and play the new page's audio, if relevant.
    void updateAudioForPageChange();
    // Stop and reset playback.
    void stopPlaybackAndReset();
    // Start or stop playback.
    void togglePlay();
public:
    BriefingScreen(GuiContainer* owner);
    virtual ~BriefingScreen();

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};
