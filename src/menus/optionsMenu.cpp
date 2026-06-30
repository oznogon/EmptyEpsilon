#include <i18n.h>
#include "engine.h"
#include "optionsMenu.h"
#include "hotkeyMenu.h"
#include "main.h"
#include "preferenceManager.h"
#include "scenarioInfo.h"
#include "soundManager.h"
#include "windowManager.h"
#include "graphics/renderTarget.h"
#include "dynamicLight.h"
#include "multiplayer_server.h"
#include "gameGlobalInfo.h"

#include "gui/theme.h"
#include "gui/gui2_overlay.h"
#include "gui/gui2_button.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_scrollcontainer.h"
#include "gui/gui2_togglebutton.h"
#include "gui/gui2_panel.h"
#include "gui/gui2_label.h"
#include "gui/gui2_slider.h"
#include "gui/gui2_listbox.h"
#include "gui/gui2_keyvaluedisplay.h"

void exitOptionsMenu(OptionsMenu::ReturnTo return_to, RenderLayer* render_layer)
{
    if (return_to == OptionsMenu::ReturnTo::Main)
        returnToMainMenu(render_layer);
    else if (return_to == OptionsMenu::ReturnTo::ShipSelection)
        returnToShipSelection(render_layer);
    else LOG(Error, "exitOptionsMenu called without a return_to target");
}

OptionsMenu::OptionsMenu(OptionsMenu::ReturnTo return_to)
: return_to(return_to)
{
    // Draw background elements.
    new GuiOverlay(this, "", GuiTheme::getColor("background"));
    (new GuiOverlay(this, "", glm::u8vec4{255, 255, 255, 255}))
        ->setTextureTiledThemed("background.crosses");

    // Initialize autolayout.
    auto container = new GuiElement(this, "");
    container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("padding", "50");
    container
        ->setAttribute("layout", "vertical");

    auto top_row = new GuiElement(container, "TOP_ROW_CONTAINER");
    top_row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 20");

    (new GuiLabel(top_row, "HEADER", tr("title", "Options"), GuiElement::GuiSizeLabel))
        ->addBackground()
        ->setSize(250.0f, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 20");

    // Options pager selector
    options_selector = new GuiSelector(top_row, "OPTIONS_PAGER",
        [this](int index, string value)
        {
            graphics_page->setVisible(index == 0);
            audio_page->setVisible(index == 1);
            interface_page->setVisible(index == 2);
        }
    );
    options_selector
        ->setSize(300.0f, GuiElement::GuiSizeMax)
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopCenter);

    setTabOptions();

    auto main_panel = new GuiPanel(container, "");
    main_panel
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopCenter)
        ->setSize(800.0f, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    main_panel
        ->setAttribute("margin", "0, 0, 0, 20");

    // Options pages
    auto page_row = new GuiScrollContainer(main_panel, "");
    page_row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    page_row
        ->setAttribute("padding", "20");

    graphics_page = new GuiElement(page_row, "OPTIONS_GRAPHICS");
    graphics_page
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->show()
        ->setAttribute("layout", "vertical");
    graphics_page->getLayout().match_content_y = true;

    audio_page = new GuiElement(page_row, "OPTIONS_AUDIO");
    audio_page
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");
    audio_page->getLayout().match_content_y = true;

    interface_page = new GuiElement(page_row, "OPTIONS_INTERFACE");
    interface_page
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");
    interface_page->getLayout().match_content_y = true;

    setupInterfaceOptions(return_to);
    setupGraphicsOptions();
    setupAudioOptions();

    // Bottom GUI.
    // Back button.
    auto bottom_row = new GuiElement(container, "");
    bottom_row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("layout", "horizontal");

    (new GuiButton(bottom_row, "BACK", tr("button", "Back"),
        [this, return_to]()
        {
            // Apply potentially modified font now, in order not to have some
            // half-rendered panel with one font and another.
            sp::RenderTarget::setDefaultFont(main_font);

            // Close this menu, stop the music, and return to the main menu.
            destroy();
            soundManager->stopMusic();
            exitOptionsMenu(return_to, getRenderLayer());
        }
    ))
        ->setSize(250.0f, GuiElement::GuiSizeMax);

    (new GuiElement(bottom_row, "SPACER"))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Save options button.
    (new GuiButton(bottom_row, "SAVE_OPTIONS", tr("options", "Save options"),
        [this]()
        {
            if (getenv("EE_CONF_DIR"))
                PreferencesManager::save(string(getenv("EE_CONF_DIR")) + "/options.ini");
            else if (getenv("HOME"))
                PreferencesManager::save(string(getenv("HOME")) + "/.emptyepsilon/options.ini");
            else
                PreferencesManager::save("options.ini");
        }
    ))
        ->setSize(250.0f, GuiElement::GuiSizeMax);
}

void OptionsMenu::update(float delta)
{
    if (keys.escape.getDown())
    {
        exitOptionsMenu(return_to, getRenderLayer());
        destroy();
        soundManager->stopMusic();
    }
}

void OptionsMenu::setTabOptions()
{
    auto old_index = std::max(0, options_selector->getSelectionIndex());
    auto graphics_label = tr("Graphics");
    auto audio_label = tr("Audio");
    auto interface_label = tr("Interface");
    options_selector
        ->setOptions({graphics_label, audio_label, interface_label})
        ->setSelectionIndex(old_index);
}

static string getThemeDisplayName(const string& theme_name)
{
    auto stream = getResourceStream("gui/" + theme_name + ".theme.txt");
    if (stream)
    {
        string line = stream->readLine();
        while (!line.empty())
        {
            line = line.strip();
            if (line.startswith("# display_name:"))
            {
                string display_name = line.substr(strlen("# display_name:")).strip();
                if (!display_name.empty())
                    return display_name;
                break;
            }
            line = stream->readLine();
        }
    }
    return theme_name;
}

static string getLanguageDisplayName(const string& code)
{
    static std::unordered_map<string, string> msgids = {
        {"cs", "Czech"},
        {"de", "German"},
        {"en", "English"},
        {"fr", "French"},
        {"it", "Italian"},
    };

    auto it = msgids.find(code);
    if (it != msgids.end()) return tr("language_name", it->second);
    // Unused dummy to add English to languages for localization
    { string english = tr("language_name", "English"); };

    return code.upper();
}

void OptionsMenu::setupInterfaceOptions(OptionsMenu::ReturnTo return_to)
{
    // Select language
    {
        (new GuiLabel(interface_page, "LANGUAGE_OPTIONS_LABEL", tr("Language"), 30.0f))
            ->addBackground()
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
        
        // Name language by language code in main locale filename.
        std::vector<string> languages = findResources("locale/main.*.po");
        for (string &language : languages)
            language = language.substr(language.find(".") + 1, language.rfind("."));
        std::sort(languages.begin(), languages.end());

        std::vector<string> language_display_names;
        language_display_names.reserve(languages.size());
        for (const auto& code : languages)
            language_display_names.push_back(getLanguageDisplayName(code));

        int default_index = 0;
        auto default_elem = std::find(
            languages.begin(),
            languages.end(),
            PreferencesManager::get("language", "en")
        );
        if (default_elem != languages.end())
            default_index = static_cast<int>(default_elem - languages.begin());

        bool language_enabled = !game_server || !gameGlobalInfo || !gameGlobalInfo->main_scenario_script;

        auto language_selector = new GuiSelector(interface_page, "LANGUAGE_SELECTOR",
            [this](int index, string value)
            {
                PreferencesManager::set("language", value);
                i18n::reset();
                i18n::load("locale/main." + value + ".po");
                i18n::load("locale/comms_ship." + value + ".po");
                i18n::load("locale/comms_station." + value + ".po");
                i18n::load("locale/factionInfo." + value + ".po");
                i18n::load("locale/science_db." + value + ".po");
                // Reinit keyboard shortcut labels to new language.
                keys.init();
                // Clear cached scenario metadata.
                ScenarioInfo::clearCache();
                // Reset options tabs to the new language.
                setTabOptions();
            }
        );
        language_selector
            ->setOptions(language_display_names, languages)
            ->setSelectionIndex(default_index)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

        if (!language_enabled)
            language_selector->disable();

        (new GuiLabel(interface_page, "LANGUAGE_APPLICATION_LABEL",
            language_enabled
                ? tr("Click Back to apply change")
                : tr("Return to the main menu to change language"),
            20.0f))
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("margin", "0, 0, 0, 20");
    }
    
    // GUI theme selection
    {
        std::vector<string> themes = findResources("gui/*.theme.txt");

        // Populate list of themes by first segment of theme filename.
        auto iter = themes.begin();
        while (iter != themes.end())
        {
            *iter = iter->substr(iter->find("/") + 1, iter->find("."));
            if (!GuiTheme::loadTheme(*iter, "gui/" + *iter + ".theme.txt"))
            {
                LOG(Error, "Failed to load theme ", *iter);
                iter = themes.erase(iter);
            }
            else if (!GuiTheme::getTheme(*iter)->getStyle("base")->states[0].font 
                     || !GuiTheme::getTheme(*iter)->getStyle("bold")->states[0].font)
            {
                LOG(Error, "Missing base font or bold font for theme ", *iter);
                iter = themes.erase(iter);
            }
            else ++iter;
        }
        
        std::sort(themes.begin(), themes.end());
        if (themes.size() == 0)
        {
            LOG(Error, "Failed to load any theme, exiting");
            SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Error", "Failed to load any theme. Are resources missing or invalid? Themes should be in gui/*.theme.txt and not contain errors.", nullptr);
            exit(1);
        }

        std::vector<string> theme_display_names;
        theme_display_names.reserve(themes.size());
        for (const auto& t : themes)
            theme_display_names.push_back(getThemeDisplayName(t));

        int default_index = 0;
        auto default_elem = std::find(themes.begin(), themes.end(), PreferencesManager::get("guitheme", "default"));

        if (default_elem != themes.end())
            default_index = static_cast<int>(default_elem - themes.begin());

        // Only show themes selector if more than one theme is loaded.
        if (themes.size() > 1)
        {
            (new GuiLabel(interface_page, "GUI_THEME_OPTIONS_LABEL", tr("Interface theme"), 30.0f))
                ->addBackground()
                ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

            (new GuiSelector(interface_page, "GUI_THEME_SELECTOR",
                [](int index, string theme_name)
                {
                    GuiTheme::setCurrentTheme(theme_name);
                    main_font = GuiTheme::getCurrentTheme()->getStyle("base")->states[0].font;
                    bold_font = GuiTheme::getCurrentTheme()->getStyle("bold")->states[0].font;
                    // Font changes are applied only after clicking Back.
                    PreferencesManager::set("guitheme", theme_name);
                }
            ))
                ->setOptions(theme_display_names, themes)
                ->setSelectionIndex(default_index)
                ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

            (new GuiLabel(interface_page, "THEME_APPLICATION_LABEL", tr("Click Back to apply change"), 20.0f))
                ->setSize(GuiElement::GuiSizeMax, 30.0f)
                ->setAttribute("margin", "0, 0, 0, 20");
        }
    }

    // Control configuration
    (new GuiLabel(interface_page, "CONTROL_OPTIONS_LABEL", tr("Control options"), 30))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    // Keyboard config (hotkeys/keybindings)
    (new GuiButton(interface_page, "CONFIGURE_KEYBOARD", tr("Configure controls"),
        [this, return_to]()
        {
            new HotkeyMenu(return_to);
            destroy();
        }
    ))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    // Tooltip visibility toggle.
    (new GuiToggleButton(interface_page, "TOOLTIP_VISIBILITY", tr("tooltips", "Show tooltips"),
        [](bool value)
        {
            PreferencesManager::set("tooltips", value ? "1" : "0");
        }
    ))
        ->setValue(PreferencesManager::get("tooltips", "0") == "1")
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 20");

    // Radar rotation lock options.
    {
        GuiElement* radar_rotation_lock = new GuiElement(interface_page, "RADAR_ROTATION_LOCK");
        radar_rotation_lock
            ->setSize(GuiElement::GuiSizeMax, 220.0f)
            ->setAttribute("layout", "vertical");

        (new GuiLabel(radar_rotation_lock, "CONTROL_OPTIONS_LABEL", tr("Radar rotation lock"), 30.0f))
            ->addBackground()
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

        // Helms/Tactical/Single pilot rotation lock.
        GuiElement* lock_row = new GuiElement(radar_rotation_lock, "HELMS_RADAR_LOCK_ROW");
        lock_row
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(lock_row, "HELMS_LOCK_DETAILS", tr("radar_locks", "Helms, tactical, single pilot"), 25.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setAttribute("margin", "0, 10, 0, 0");
        helms_radar_lock_toggle = new GuiToggleButton(lock_row, "HELMS_RADAR_LOCK", tr("radar_locks", "Ship rotates"),
            [this](bool value)
            {
                PreferencesManager::set(       "helms_radar_lock", value ? "1" : "");
                PreferencesManager::set(    "tactical_radar_lock", value ? "1" : "");
                PreferencesManager::set("single_pilot_radar_lock", value ? "1" : "");

                helms_radar_lock_toggle->setText(value
                    ? tr("radar_locks", "Radar rotates")
                    : tr("radar_locks", "Ship rotates")
                );
            }
        );
        helms_radar_lock_toggle
            ->setValue(PreferencesManager::get("helms_radar_lock", "0") == "1")
            ->setText(helms_radar_lock_toggle->getValue()
                ? tr("radar_locks", "Radar rotates")
                : tr("radar_locks", "Ship rotates"))
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

        // Weapons rotation lock.
        lock_row = new GuiElement(radar_rotation_lock, "WEAPONS_RADAR_LOCK_ROW");
        lock_row
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(lock_row, "WEAPONS_LOCK_DETAILS", tr("radar_locks", "Weapons"), 25.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setAttribute("margin", "0, 10, 0, 0");

        weapons_radar_lock_toggle = new GuiToggleButton(lock_row, "WEAPONS_RADAR_LOCK", tr("radar_locks", "Lock"),
            [this](bool value)
            {
                PreferencesManager::set("weapons_radar_lock", value ? "1" : "");

                weapons_radar_lock_toggle->setText(value ? tr("radar_locks", "Radar rotates") : tr("radar_locks", "Ship rotates"));
            }
        );
        weapons_radar_lock_toggle
            ->setValue(PreferencesManager::get("weapons_radar_lock", "0") == "1")
            ->setText(weapons_radar_lock_toggle->getValue()
                ? tr("radar_locks", "Radar rotates")
                : tr("radar_locks", "Ship rotates"))
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

        // Science/Ops rotation lock.
        lock_row = new GuiElement(radar_rotation_lock, "SCIENCE_RADAR_LOCK_ROW");
        lock_row
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(lock_row, "SCIENCE_LOCK_DETAILS", tr("radar_locks", "Science, operations"), 25.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setAttribute("margin", "0, 10, 0, 0");

        science_radar_lock_toggle = new GuiToggleButton(lock_row, "SCIENCE_RADAR_LOCK", tr("radar_locks", "Lock"),
            [this](bool value)
            {
                PreferencesManager::set("science_radar_lock", value ? "1" : "");
                PreferencesManager::set("operations_radar_lock", value ? "1" : "");

                science_radar_lock_toggle->setText(value ? tr("radar_locks", "Radar rotates") : tr("radar_locks", "Ship rotates"));
            }
        );
        science_radar_lock_toggle
            ->setValue(PreferencesManager::get("science_radar_lock", "0") == "1")
            ->setText(science_radar_lock_toggle->getValue()
                ? tr("radar_locks", "Radar rotates")
                : tr("radar_locks", "Ship rotates"))
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
    }

    (new GuiLabel(interface_page, "CINEMATIC_VIEW_OPTIONS_LABEL", tr("Cinematic view options"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    auto initial_camera_sensitivity = PreferencesManager::get("camera_mouse_sensitivity", "0.15").toFloat();
    if (initial_camera_sensitivity <= 0.0f)
    {
        LOG(Warning, "camera_mouse_sensitivity value invalid: ", PreferencesManager::get("camera_mouse_sensitivity", "0.15"));
        initial_camera_sensitivity = 0.15f;
    }

    camera_sensitivity_slider = new GuiBasicSlider(interface_page, "CAMERA_SENSITIVITY_SLIDER", 0.01f, 1.0f, initial_camera_sensitivity,
        [this](float sensitivity)
        {
            PreferencesManager::set("camera_mouse_sensitivity", sensitivity);
            camera_sensitivity_overlay_label->setText(
                tr("Mouselook sensitivity: {s}").format({
                    {"s", static_cast<string>(static_cast<int>(nearbyint(sensitivity * 100.0f)))}
                })
            );
        }
    );
    camera_sensitivity_slider->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    // Override overlay label.
    camera_sensitivity_overlay_label = new GuiLabel(camera_sensitivity_slider, "CAMERA_SENSITIVITY_SLIDER_LABEL",
        tr("Mouselook sensitivity: {s}").format({
            {"s", static_cast<string>(static_cast<int>(nearbyint(initial_camera_sensitivity * 100.0f)))}
        }), 30.0f);
    camera_sensitivity_overlay_label->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Cinematic fly-by randomization
    (new GuiToggleButton(interface_page, "RANDOMIZE_CINEMATIC_FLYBY", tr("Randomize cinematic fly-by angles"),
        [this](bool value)
        {
            PreferencesManager::set("camera_flyby_randomized", value ? "1" : "0");
        })
    )
        ->setValue(PreferencesManager::get("camera_flyby_randomized", "0") == "1")
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
}

void OptionsMenu::setupGraphicsOptions()
{
    // Fullscreen toggle.
    (new GuiButton(graphics_page, "FULLSCREEN_TOGGLE", tr("Toggle fullscreen/windowed mode"),
        []()
        {
            foreach (Window, window, windows)
            {
                window->setMode(
                    window->getMode() == Window::Mode::Window
                        ? Window::Mode::Fullscreen
                        : Window::Mode::Window
                );
            }
        }
    ))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 20");

    // FSAA configuration.
    int fsaa = std::max(1, windows[0]->getFSAA());
    int fsaa_index = 0;

    // Convert selector index to an FSAA amount.
    switch (fsaa)
    {
    case  8: fsaa_index = 3; break;
    case  4: fsaa_index = 2; break;
    case  2: fsaa_index = 1; break;
    default: fsaa_index = 0; break;
    }

    // FSAA selector.
    (new GuiSelector(graphics_page, "FSAA",
        [](int index, string value)
        {
            static const int fsaa[] = {0, 2, 4, 8};
            foreach (Window, window, windows)
                window->setFSAA(fsaa[index]);
        }
    ))
        ->setOptions({
            tr("Full-screen antialiasing: Off"),
            tr("Full-screen antialiasing: 2x"),
            tr("Full-screen antialiasing: 4x"),
            tr("Full-screen antialiasing: 8x")})
        ->setSelectionIndex(fsaa_index)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    (new GuiLabel(graphics_page, "THEME_APPLICATION_LABEL", tr("Restart EmptyEpsilon to apply full-screen antialiasing changes"), 20.0f))
        ->setSize(GuiElement::GuiSizeMax, 30.0f)
        ->setAttribute("margin", "0, 0, 0, 20");

    // Line drawing mode selector.
    int line_mode_index = (sp::RenderTarget::getLineDrawingMode() == sp::RenderTarget::LineDrawingMode::GL) ? 0 : 1;
    (new GuiSelector(graphics_page, "GRAPHICS_LINE_DRAWING_MODE",
        [](int index, string value)
        {
            if (index == 1)
            {
                PreferencesManager::set("line_drawing_mode", "quad");
                sp::RenderTarget::setLineDrawingMode(sp::RenderTarget::LineDrawingMode::Quad);
            }
            else
            {
                PreferencesManager::set("line_drawing_mode", "gl");
                sp::RenderTarget::setLineDrawingMode(sp::RenderTarget::LineDrawingMode::GL);
            }
        }
    ))
        ->setOptions({
            tr("options", "Line rendering: GL (Low quality)"),
            tr("options", "Line rendering: Quads (High quality)"
        )})
        ->setSelectionIndex(line_mode_index)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 20");

    // FoV slider.
    auto initial_fov = PreferencesManager::get("main_screen_camera_fov", "60").toFloat();
    if (initial_fov <= 30.0f || initial_fov >= 140.0f)
    {
        LOG(Warning, "main_screen_camera_fov value invalid: ", PreferencesManager::get("main_screen_camera_fov"));
        initial_fov = std::clamp(initial_fov, 30.0f, 140.0f);
    }

    graphics_fov_slider = new GuiBasicSlider(graphics_page, "GRAPHICS_FOV_SLIDER", 30.f, 140.0f, initial_fov,
        [this](float fov)
        {
            fov = std::round(fov);
            graphics_fov_slider->setValue(fov);
            PreferencesManager::set("main_screen_camera_fov", fov);
            graphics_fov_overlay_label->setText(tr("Field of view: {fov} degrees").format({
                {"fov", string(fov, 0)}
            }));
        }
    );
    graphics_fov_slider
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 20");

    // Override overlay label.
    graphics_fov_overlay_label = new GuiLabel(graphics_fov_slider, "GRAPHICS_FOV_SLIDER_LABEL", tr("Field of view: {fov} degrees").format({
        {"fov", string(initial_fov, 0)}
    }), 30.0f);
    graphics_fov_overlay_label->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Default draw distance slider.
    auto initial_draw_distance = PreferencesManager::get("default_draw_distance", "25000").toFloat();
    if (initial_draw_distance <= 1000.0f)
    {
        LOG(Warning, "default_draw_distance value invalid: ", initial_draw_distance);
        initial_draw_distance = 25000.0f;
    }
    graphics_draw_distance_slider = new GuiBasicSlider(graphics_page, "GRAPHICS_DRAW_DISTANCE_SLIDER", 1000.0f, 100000.0f, initial_draw_distance,
        [this](float dist)
        {
            dist = std::round(dist / 100.0f) * 100.0f;
            graphics_draw_distance_slider->setValue(dist);
            PreferencesManager::set("default_draw_distance", string(static_cast<int>(dist)));
            graphics_draw_distance_overlay_label->setText(tr("Draw distance: {dist}U").format({
                {"dist", string(static_cast<int>(dist / 1000.0f), 1)}
            }));
        }
    );
    graphics_draw_distance_slider
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 20");

    graphics_draw_distance_overlay_label = new GuiLabel(graphics_draw_distance_slider, "GRAPHICS_DRAW_DISTANCE_SLIDER_LABEL", tr("Draw distance: {dist}U").format({
        {"dist", string(static_cast<int>(initial_draw_distance / 1000.0f), 1)}
    }), 30.0f);
    graphics_draw_distance_overlay_label
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Dynamic nebula lighting toggle.
    (new GuiToggleButton(graphics_page, "DYNAMIC_NEBULA_LIGHTING", tr("Dynamic nebula lighting"),
        [](bool value)
        {
            PreferencesManager::set("dynamic_nebula_lighting", value ? "1" : "0");
        }
    ))
        ->setValue(DynamicLightManager::isEnabled())
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    // Nebula fog toggle.
    (new GuiToggleButton(graphics_page, "NEBULA_FOG", tr("Nebula fog"),
        [](bool value)
        {
            PreferencesManager::set("nebula_fog", value ? "1" : "0");
        }
    ))
        ->setValue(PreferencesManager::get("nebula_fog", "1") == "1")
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 20");
}

void OptionsMenu::setupAudioOptions()
{
    // Sound volume slider.
    sound_volume_slider = new GuiSlider(audio_page, "SOUND_VOLUME_SLIDER", 0.0f, 100.0f, soundManager->getMasterSoundVolume(),
        [this](float volume)
        {
            soundManager->setMasterSoundVolume(volume);
            sound_volume_overlay_label->setText(tr("Sound effect volume: {volume}%").format({
                {"volume", string(static_cast<int>(soundManager->getMasterSoundVolume()))}
            }));
        }
    );
    sound_volume_slider
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 20");

    // Override overlay label.
    sound_volume_overlay_label = new GuiLabel(sound_volume_slider, "SOUND_VOLUME_SLIDER_LABEL", tr("Sound effect volume: {volume}%").format({
        {"volume", string(static_cast<int>(soundManager->getMasterSoundVolume()))}
    }), 30.0f);
    sound_volume_overlay_label
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Engine playback state.
    (new GuiLabel(audio_page, "IMPULSE_SOUND_LABEL", tr("Impulse engine sound"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    // Determine when engine sound effects are enabled.
    int impulse_enabled_index = PreferencesManager::get("impulse_sound_enabled", "2").toInt();
    (new GuiSelector(audio_page, "ENGINE_ENABLED", [](int index, string value)
    {
        // 0: Always off
        // 1: Always on
        // 2: On if main screen, off otherwise (default)
        PreferencesManager::set("impulse_sound_enabled", string(index));
    }))
        ->setOptions({
            tr("Disabled"),
            tr("Enabled"),
            tr("Main screen only")
        })
        ->setSelectionIndex(impulse_enabled_index)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    // Impulse engine volume slider.
    impulse_volume_slider = new GuiSlider(audio_page, "IMPULSE_VOLUME_SLIDER", 0.0f, 100.0f, static_cast<float>(PreferencesManager::get("impulse_sound_volume", "50").toInt()),
        [this](float volume)
        {
            PreferencesManager::set("impulse_sound_volume", volume);
            impulse_volume_overlay_label->setText(tr("Volume: {volume}%").format({
                {"volume", string(PreferencesManager::get("impulse_sound_volume", "50").toInt())}
            }));
        }
    );
    impulse_volume_slider
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 20");

    // Override overlay label.
    impulse_volume_overlay_label = new GuiLabel(impulse_volume_slider, "IMPULSE_VOLUME_SLIDER_LABEL", tr("Volume: {volume}%").format({
        {"volume", string(PreferencesManager::get("impulse_sound_volume", "50").toInt())}
    }), 30.0f);
    impulse_volume_overlay_label
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Music playback state.
    (new GuiLabel(audio_page, "MUSIC_PLAYBACK_LABEL", tr("Music"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    // Determine when music is enabled.
    int music_enabled_index = PreferencesManager::get("music_enabled", "2").toInt();
    (new GuiSelector(audio_page, "MUSIC_ENABLED",
        [](int index, string value)
        {
            // 0: Always off
            // 1: Always on
            // 2: On if main screen, off otherwise (default)
            PreferencesManager::set("music_enabled", string(index));
        }
    ))
        ->setOptions({
            tr("Disabled"),
            tr("Enabled"),
            tr("Main screen only")
        })
        ->setSelectionIndex(music_enabled_index)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    // Music volume slider.
    music_volume_slider = new GuiSlider(audio_page, "MUSIC_VOLUME_SLIDER", 0.0f, 100.0f, soundManager->getMusicVolume(),
        [this](float volume)
        {
            soundManager->setMusicVolume(volume);
            music_volume_overlay_label->setText(tr("Volume: {volume}%").format({
                {"volume", string(static_cast<int>(soundManager->getMusicVolume()))}
            }));
        }
    );
    music_volume_slider
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 20");

    // Override overlay label.
    music_volume_overlay_label = new GuiLabel(music_volume_slider, "MUSIC_VOLUME_SLIDER_LABEL", tr("Volume: {volume}%").format({
        {"volume", string(static_cast<int>(soundManager->getMusicVolume()))}
    }), 30.0f);
    music_volume_overlay_label
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Music preview jukebox.

    // Draw list of available music. Grabs every ogg file in the
    // resources/music folder and lists them by filename.
    std::vector<string> ambient_music_filenames = findResources("music/ambient/*.ogg");
    std::sort(ambient_music_filenames.begin(), ambient_music_filenames.end());
    std::vector<string> combat_music_filenames = findResources("music/combat/*.ogg");
    std::sort(combat_music_filenames.begin(), combat_music_filenames.end());

    (new GuiLabel(audio_page, "PREVIEW_LABEL", tr("Preview music"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    GuiListbox* music_list = new GuiListbox(audio_page, "MUSIC_PLAY",
        [](int index, string value)
        {
            soundManager->playMusic(value);
        }
    );

    for (string filename : ambient_music_filenames)
        music_list->addEntry(filename.substr(filename.rfind("/") + 1, filename.rfind(".")), filename);
    for (string filename : combat_music_filenames)
        music_list->addEntry(filename.substr(filename.rfind("/") + 1, filename.rfind(".")), filename);

    music_list->setSize(GuiElement::GuiSizeMax, 500.0f);
}
