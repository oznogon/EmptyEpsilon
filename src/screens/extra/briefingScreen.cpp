#include "briefingScreen.h"
#include "i18n.h"
#include "engine.h"
#include "soundManager.h"
#include "preferenceManager.h"
#include "resources.h"
#include "gameGlobalInfo.h"
#include "playerInfo.h"

#include "components/briefing.h"

#include "screenComponents/alertOverlay.h"

#include "gui/hotkeyConfig.h"
#include "gui/theme.h"
#include "gui/gui2_button.h"
#include "gui/gui2_togglebutton.h"
#include "gui/gui2_image.h"
#include "gui/gui2_label.h"
#include "gui/gui2_progressbar.h"
#include "gui/gui2_scrolltext.h"
#include "gui/gui2_slider.h"

static int playBriefingAudio(const string& filename)
{
    int n = filename.rfind(".");
    if (n > -1)
    {
        // Get locale audio file if present.
        string filename_with_locale = filename.substr(0, n) + "." + PreferencesManager::get("language", "en") + filename.substr(n);
        if (getResourceStream(filename_with_locale))
            return soundManager->playSound(filename_with_locale);
    }

    // Play the given sound.
    return soundManager->playSound(filename);
}

BriefingScreen::BriefingScreen(GuiContainer* owner)
: GuiOverlay(owner, "BRIEFING_SCREEN", GuiTheme::getColor("background"))
{
    (new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255,255,255,255}))
        ->setTextureTiledThemed("background.crosses");

    (new AlertLevelOverlay(this));

    page_container = new GuiElement(this, "");
    page_container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    // Message if briefing doesn't exist or lacks slides.
    no_pages_label = new GuiLabel(page_container, "NO_PAGES_LABEL", tr("briefing", "No briefing available"), 50.0f);
    no_pages_label
        ->setAlignment(sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Fixtures for page slides.
    page_image = new GuiImageContain(page_container, "BRIEFING_PAGE_IMAGE", "");
    page_image
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    page_caption = new GuiScrollFormattedText(page_container, "PAGE_CAPTION", "");
    page_caption
        ->setAlignment(sp::Alignment::Center)
        ->setTextSize(25.0f)
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopCenter)
        ->setSize(GuiElement::GuiSizeMax, 100.0f)
        ->setAttribute("margin", "50, 10");

    auto page_nav = new GuiElement(page_container, "PAGE_NAV");
    page_nav
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("margin", "50");

    // Playback timing progress indicator.
    page_progress = new GuiProgressbar(page_nav, "PAGE_PROGRESS", 0.0f, 1.0f, 0.0f);
    page_progress
        ->setPosition(0.0f, 0.0f, sp::Alignment::BottomCenter)
        ->setSize(260.0f, GuiElement::GuiSizeMax)
        ->hide();

    // Navigate pages.
    page_slider = new GuiSlider(page_nav, "PAGE_SLIDER", 1.0f, 1.0f, 1.0f,
        [this](float value)
        {
            setCurrentPage(static_cast<int>(value) - 1);
        }
    );
    page_slider
        ->addOverlay(0, 30.0f)
        ->setPosition(0.0f, 0.0f, sp::Alignment::BottomCenter)
        ->setSize(300.0f, GuiElement::GuiSizeMax);

    prev_button = new GuiButton(page_nav, "PREV_BUTTON", tr("briefing", "Previous"),
        [this]()
        {
            if (current_page > 0)
                setCurrentPage(current_page - 1);
        }
    );
    prev_button
        ->setPosition(0.0f, 0.0f, sp::Alignment::BottomLeft)
        ->setSize(150.0f, GuiElement::GuiSizeMax);

    next_button = new GuiButton(page_nav, "NEXT_BUTTON", tr("briefing", "Next"),
        [this]()
        {
            auto briefing = getBriefing();
            if (briefing && current_page < static_cast<int>(briefing->pages.size()) - 1)
                setCurrentPage(current_page + 1);
        }
    );
    next_button
        ->setPosition(0.0f, 0.0f, sp::Alignment::BottomRight)
        ->setSize(150.0f, GuiElement::GuiSizeMax);

    // Toggle playback mode (audio playback + timed page auto-advancement).
    play_button = new GuiToggleButton(page_nav, "PLAY_BUTTON", tr("briefing", "Play"),
        [this](bool value)
        {
            togglePlay();
        }
    );
    play_button
        ->setPosition(-155.0f, 0.0f, sp::Alignment::BottomRight)
        ->setSize(150.0f, GuiElement::GuiSizeMax);

    // Toggle caption visibility
    caption_button = new GuiToggleButton(page_nav, "CAPTION_BUTTON", tr("briefing", "Caption"),
        [this](bool value)
        {
            caption_visible = value;
            updatePage();
        }
    );
    caption_button
        ->setValue(caption_visible)
        ->setPosition(155.0f, 0.0f, sp::Alignment::BottomLeft)
        ->setSize(150.0f, GuiElement::GuiSizeMax);

    updatePage();
}

BriefingScreen::~BriefingScreen()
{
    // Stop audio playback if the BriefingScreen is destroyed.
    if (active_sound != -1)
    {
        soundManager->stopSound(active_sound);
        active_sound = -1;
    }
}

const Briefing* BriefingScreen::getBriefing() const
{
    if (!my_spaceship) return nullptr;
    return my_spaceship.getComponent<Briefing>();
}

void BriefingScreen::setCurrentPage(int page)
{
    const int old_page = current_page;
    current_page = page;
    updatePage();

    // Reset the playback-mode advancement timer on page change.
    if (is_playing && old_page != current_page)
    {
        play_timer = 0.0f;
        last_update_time = engine->getElapsedTime();
        updateAudioForPageChange();
    }
}

void BriefingScreen::updateAudioForPageChange()
{
    auto briefing = getBriefing();
    if (!briefing || briefing->pages.empty())
        return;

    const auto& pages = briefing->pages;
    if (pages.size() > 1)
    {
        if (active_sound != -1)
        {
            soundManager->stopSound(active_sound);
            active_sound = -1;
        }
        if (current_page >= 0 && current_page < static_cast<int>(pages.size()) && !pages[current_page].audio.empty())
            active_sound = playBriefingAudio(pages[current_page].audio);
    }
}

void BriefingScreen::updatePage()
{
    // Read the briefing, if any. If none, reset and hide everything but the
    // message indicating that there's no briefing, then bail.
    auto briefing = getBriefing();
    if (!briefing || briefing->pages.empty())
    {
        current_page = 0;
        page_image->hide();
        page_caption->hide();
        no_pages_label->show();
        page_slider->hide();
        prev_button->hide();
        next_button->hide();
        play_button->hide();
        caption_button->hide();
        last_page_count = 0;
        return;
    }

    const auto& pages = briefing->pages;
    last_page_count = pages.size();

    // Clamp the page to valid values.
    current_page = std::clamp(current_page, 0, static_cast<int>(pages.size()) - 1);

    // Show the page image, if any, and hide the no-pages message.
    page_image
        ->setTexture(pages[current_page].image)
        ->show();
    no_pages_label->hide();

    bool has_audio = false;
    bool has_timing = false;
    bool has_caption = false;

    // Associate audio and timings with their corresponding pages.
    for (const auto& page : pages)
    {
        if (!page.audio.empty()) has_audio = true;
        if (page.duration > 0.0f) has_timing = true;
        if (!page.caption.empty()) has_caption = true;
    }

    // Show the Play button only if playback mode is relevant.
    play_button->setVisible(has_audio || (pages.size() > 1 && has_timing));
    caption_button->setVisible(has_caption);

    prev_button->show();
    next_button->show();

    // Set and show the caption if present and enabled.
    if (!pages[current_page].caption.empty() && caption_visible)
    {
        page_caption
            ->setText(pages[current_page].caption)
            ->show();
    }
    else page_caption->hide();

    // Define and show the page slider if there's more than 1 page.
    if (pages.size() > 1)
    {
        page_slider
            ->clearSnapValues()
            ->setRange(1.0f, static_cast<float>(pages.size()))
            ->setValue(static_cast<float>(current_page + 1))
            ->show();
    }
    else page_slider->hide();

    // Add tick stops on integers for each page.
    for (int i = 1; i <= static_cast<int>(pages.size()); i++)
        page_slider->addSnapValue(static_cast<float>(i), 0.5f);

    prev_button->setEnable(current_page > 0);
    next_button->setEnable(current_page < static_cast<int>(pages.size()) - 1);
}

void BriefingScreen::onUpdate()
{
    // Stop playback mode and bail if not visible.
    if (!isVisible())
    {
        if (is_playing) togglePlay();
        return;
    }

    // Read the briefing, if available.
    auto briefing = getBriefing();

    // Hotkey handling
    // Next page
    if (keys.briefing_next_page.getDown())
    {
        if (briefing && current_page < static_cast<int>(briefing->pages.size()) - 1)
            setCurrentPage(current_page + 1);
    }

    // Previous page
    if (keys.briefing_prev_page.getDown())
        if (current_page > 0) setCurrentPage(current_page - 1);

    // Toggle playback
    if (keys.briefing_play.getDown()) togglePlay();

    // Toggle caption visibility
    if (keys.briefing_toggle_caption.getDown())
    {
        caption_visible = !caption_visible;
        caption_button->setValue(caption_visible);
        updatePage();
    }

    // If playback mode is enabled, play audio and advance pages on the given
    // timings.
    if (is_playing)
    {
        if (!briefing || briefing->pages.empty() || briefing->pages.size() != last_page_count)
        {
            stopPlaybackAndReset();
            return;
        }

        const auto& pages = briefing->pages;

        const float now = engine->getElapsedTime();
        if (last_update_time >= 0.0f) play_timer += now - last_update_time;
        last_update_time = now;

        if (current_page < static_cast<int>(pages.size()) - 1)
        {
            if (play_timer >= pages[current_page].duration)
            {
                play_timer = 0.0f;
                setCurrentPage(current_page + 1);
            }
        }
        else
        {
            if (pages[current_page].duration > 0.0f && play_timer >= pages[current_page].duration)
                togglePlay();
        }
    }
    else last_update_time = -1.0f;

    // Update play button text to match state.
    play_button->setText(is_playing ? tr("briefing", "Stop") : (tr("briefing", "Play")));

    // Update the playback timing progress bar.
    if (is_playing && briefing && current_page >= 0 && current_page < static_cast<int>(briefing->pages.size()) && briefing->pages[current_page].duration > 0.0f)
    {
        page_progress
            ->setRange(0.0f, briefing->pages[current_page].duration)
            ->setValue(play_timer)
            ->show();
    }
    else page_progress->hide();
}

void BriefingScreen::onDraw(sp::RenderTarget& renderer)
{
    // Stop playback if no briefing exists or it's been cleared.
    auto briefing = getBriefing();
    size_t current_count = briefing ? briefing->pages.size() : 0;

    if (current_count != last_page_count)
    {
        if (is_playing) stopPlaybackAndReset();
        else updatePage();
    }

    GuiOverlay::onDraw(renderer);
}

void BriefingScreen::stopPlaybackAndReset()
{
    is_playing = false;
    play_timer = 0.0f;
    last_update_time = -1.0f;

    if (active_sound != -1)
    {
        soundManager->stopSound(active_sound);
        active_sound = -1;
    }

    current_page = 0;

    play_button->setValue(is_playing);
    updatePage();
}

void BriefingScreen::togglePlay()
{
    auto briefing = getBriefing();

    // Stop audio playback, and reset and stop the timer, if mid-playback.
    if (is_playing)
    {
        is_playing = false;
        play_timer = 0.0f;
        last_update_time = -1.0f;

        if (active_sound != -1)
        {
            soundManager->stopSound(active_sound);
            active_sound = -1;
        }

    }
    // Start audio playback, and reset and start the timer, if not mid-playback.
    else
    {
        if (briefing && !briefing->pages.empty())
        {
            is_playing = true;
            play_timer = 0.0f;
            last_update_time = engine->getElapsedTime();
            current_page = 0;
            updatePage();
            const auto& pages = briefing->pages;

            if (!pages.empty() && current_page < static_cast<int>(pages.size()) && !pages[current_page].audio.empty())
                active_sound = playBriefingAudio(pages[current_page].audio);
            else active_sound = -1;
        }
    }

    play_button->setValue(is_playing);
}
