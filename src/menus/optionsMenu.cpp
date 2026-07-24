#include "optionsMenu.h"
#include <i18n.h>
#include "engine.h"
#include "hotkeyMenu.h"
#include "main.h"
#include "preferenceManager.h"
#include "scenarioInfo.h"
#include "soundManager.h"
#include "windowManager.h"
#include "dynamicLight.h"
#include "multiplayer_server.h"
#include "gameGlobalInfo.h"
#include "featureDefs.h"
#include "audio/music.h"
#include "graphics/renderTarget.h"

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
#include "gui/gui2_tooltip.h"

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
    (new GuiTextTooltip(options_selector, "OPTIONS_PAGER_TIP", tr("tooltips", "Switch between graphics, audio, and interface settings."), 20.0f))->setWidth(280.0f);

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

    auto* back_button = new GuiButton(bottom_row, "BACK", tr("button", "Back"),
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
    );
    back_button->setSize(250.0f, GuiElement::GuiSizeMax);
    (new GuiTextTooltip(back_button, "BACK_TIP", tr("tooltips", "Return to the previous screen."), 20.0f))->setWidth(280.0f);

    (new GuiElement(bottom_row, "SPACER"))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Save options button.
    auto* save_options_button = new GuiButton(bottom_row, "SAVE_OPTIONS", tr("options", "Save options"),
        []()
        {
            if (getenv("EE_CONF_DIR"))
                PreferencesManager::save(string(getenv("EE_CONF_DIR")) + "/options.ini");
            else if (getenv("HOME"))
                PreferencesManager::save(string(getenv("HOME")) + "/.emptyepsilon/options.ini");
            else
                PreferencesManager::save("options.ini");
        }
    );
    save_options_button->setSize(250.0f, GuiElement::GuiSizeMax);
    (new GuiTextTooltip(save_options_button, "SAVE_OPTIONS_TIP", tr("tooltips", "Save all current settings to the preferences file."), 20.0f))->setWidth(280.0f);
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
    auto graphics_label = tr("options_tab", "Graphics");
    auto audio_label = tr("options_tab", "Audio");
    auto interface_label = tr("options_tab", "Interface");
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
                string display_name = line.substr(static_cast<int>(strlen("# display_name:"))).strip();
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
        {"en_GB", "English (UK)"},
        {"en_US", "English (US)"},
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
        (new GuiLabel(interface_page, "LANGUAGE_OPTIONS_LABEL", tr("options_section", "Language"), GuiElement::GuiSizeLabel))
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
            PreferencesManager::get("language", "en_US")
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
        (new GuiTextTooltip(language_selector, "LANGUAGE_SELECTOR_TIP", tr("tooltips", "Change the game's display language."), 20.0f))->setWidth(280.0f);

        if (!language_enabled)
            language_selector->disable();

        (new GuiLabel(interface_page, "LANGUAGE_APPLICATION_LABEL",
            language_enabled
                ? tr("options", "Click Back to apply change")
                : tr("options", "Return to the main menu to change language"),
            20.0f))
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeLabel)
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

        (new GuiLabel(interface_page, "GUI_THEME_OPTIONS_LABEL", tr("options_section", "Interface theme"), GuiElement::GuiSizeLabel))
            ->addBackground()
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

        // Show themes selector only if more than one theme is loaded.
        if (themes.size() > 1)
        {
            auto* gui_theme_selector = new GuiSelector(interface_page, "GUI_THEME_SELECTOR",
                [](int index, string theme_name)
                {
                    GuiTheme::setCurrentTheme(theme_name);
                    main_font = GuiTheme::getCurrentTheme()->getStyle("base")->states[0].font;
                    bold_font = GuiTheme::getCurrentTheme()->getStyle("bold")->states[0].font;
                    // Font changes are applied only after clicking Back.
                    PreferencesManager::set("guitheme", theme_name);
                }
            );
            gui_theme_selector
                ->setOptions(theme_display_names, themes)
                ->setSelectionIndex(default_index)
                ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
            (new GuiTextTooltip(gui_theme_selector, "GUI_THEME_SELECTOR_TIP", tr("tooltips", "Change the visual theme of the interface."), 20.0f))->setWidth(280.0f);

            (new GuiLabel(interface_page, "THEME_APPLICATION_LABEL", tr("options", "Click Back to apply change"), 20.0f))
                ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeLabel)
                ->setAttribute("margin", "0, 0, 0, 20");
        }

        // Tooltip visibility toggle.
        auto* tooltip_toggle = new GuiToggleButton(interface_page, "TOOLTIP_VISIBILITY", tr("tooltips", "Show tooltips"),
            [](bool value)
            {
                PreferencesManager::set("tooltips", value ? "1" : "0");
            }
        );
        tooltip_toggle
            ->setValue(PreferencesManager::get("tooltips", "0") == "1")
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setAttribute("margin", "0, 0, 0, 20");
        (new GuiTextTooltip(tooltip_toggle, "TOOLTIP_VISIBILITY_TIP", tr("tooltips", "Show or hide descriptive tooltips when hovering over controls."), 20.0f))->setWidth(280.0f);

        // Lua console popup toggle.
        auto* lua_console_popup_toggle = new GuiToggleButton(interface_page, "LUA_CONSOLE_POPUP", tr("options", "Show Lua console popup"),
            [](bool value)
            {
                PreferencesManager::set("lua_console_popup", value ? "1" : "0");
            }
        );
        lua_console_popup_toggle
            ->setValue(PreferencesManager::get("lua_console_popup", "1") == "1")
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setAttribute("margin", "0, 0, 0, 20");
        (new GuiTextTooltip(lua_console_popup_toggle, "LUA_CONSOLE_POPUP_TIP", tr("tooltips", "Show a popup overlay when Lua log messages are printed. Disable to reduce on-screen distractions."), 20.0f))->setWidth(280.0f);
    }

    // Control configuration
    {
        (new GuiLabel(interface_page, "CONTROL_OPTIONS_LABEL", tr("options_section", "Control options"), GuiElement::GuiSizeLabel))
            ->addBackground()
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

        // Hotkey/bindings config
        auto* configure_bindings_button = new GuiButton(interface_page, "CONFIGURE_BINDINGS", tr("options", "Configure controls"),
            [this, return_to]()
            {
                new HotkeyMenu(return_to);
                destroy();
            }
        );
        configure_bindings_button
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setAttribute("margin", "0, 0, 0, 20");
        (new GuiTextTooltip(configure_bindings_button, "CONFIGURE_BINDINGS_TIP", tr("tooltips", "Open the keyboard, mouse, and controller binding configuration."), 20.0f))->setWidth(280.0f);
    }

    // Radar rotation lock options.
    {
        GuiElement* radar_rotation_lock = new GuiElement(interface_page, "RADAR_ROTATION_LOCK");
        radar_rotation_lock
            ->setSize(GuiElement::GuiSizeMax, 220.0f)
            ->setAttribute("layout", "vertical");

        (new GuiLabel(radar_rotation_lock, "CONTROL_OPTIONS_LABEL", tr("options_section", "Radar rotation lock"), GuiElement::GuiSizeLabel))
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
        helms_radar_lock_toggle = new GuiToggleButton(lock_row, "HELMS_RADAR_LOCK", tr("radar_locks", "Ship rotates inside radar"),
            [this](bool value)
            {
                PreferencesManager::set(       "helms_radar_lock", value ? "1" : "");
                PreferencesManager::set(    "tactical_radar_lock", value ? "1" : "");
                PreferencesManager::set("single_pilot_radar_lock", value ? "1" : "");

                helms_radar_lock_toggle->setText(value
                    ? tr("radar_locks", "Radar rotates around ship")
                    : tr("radar_locks", "Ship rotates inside radar")
                );
            }
        );
        helms_radar_lock_toggle
            ->setValue(PreferencesManager::get("helms_radar_lock", "0") == "1")
            ->setText(helms_radar_lock_toggle->getValue()
                ? tr("radar_locks", "Radar rotates around ship")
                : tr("radar_locks", "Ship rotates inside radar")
            )
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
        (new GuiTextTooltip(helms_radar_lock_toggle, "HELMS_RADAR_LOCK_TIP", tr("tooltips", "Toggles whether rotating the ship rotates the radar frame around the ship, or rotates the ship within a stationary frame."), 20.0f))->setWidth(280.0f);

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

                weapons_radar_lock_toggle->setText(value
                    ? tr("radar_locks", "Radar rotates around ship")
                    : tr("radar_locks", "Ship rotates inside radar")
                );
            }
        );
        weapons_radar_lock_toggle
            ->setValue(PreferencesManager::get("weapons_radar_lock", "0") == "1")
            ->setText(weapons_radar_lock_toggle->getValue()
                ? tr("radar_locks", "Radar rotates around ship")
                : tr("radar_locks", "Ship rotates inside radar")
            )
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
        (new GuiTextTooltip(weapons_radar_lock_toggle, "WEAPONS_RADAR_LOCK_TIP", tr("tooltips", "Toggles whether rotating the ship rotates the radar frame around the ship, or rotates the ship within a stationary frame."), 20.0f))->setWidth(280.0f);

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

                science_radar_lock_toggle->setText(value
                    ? tr("radar_locks", "Radar rotates around ship")
                    : tr("radar_locks", "Ship rotates inside radar")
                );
            }
        );
        science_radar_lock_toggle
            ->setValue(PreferencesManager::get("science_radar_lock", "0") == "1")
            ->setText(science_radar_lock_toggle->getValue()
                ? tr("radar_locks", "Radar rotates around ship")
                : tr("radar_locks", "Ship rotates inside radar")
            )
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
        (new GuiTextTooltip(science_radar_lock_toggle, "SCIENCE_RADAR_LOCK_TIP", tr("tooltips", "Toggles whether rotating the ship rotates the radar frame around the ship, or rotates the ship within a stationary frame."), 20.0f))->setWidth(280.0f);
    }

    // Cinematic view options
    {
        (new GuiLabel(interface_page, "CINEMATIC_VIEW_OPTIONS_LABEL", tr("options_section", "Cinematic view options"), GuiElement::GuiSizeLabel))
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
                    tr("options", "Mouselook sensitivity: {s}").format({
                        {"s", static_cast<string>(static_cast<int>(nearbyint(sensitivity * 100.0f)))}
                    })
                );
            }
        );
        camera_sensitivity_slider->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
        (new GuiTextTooltip(camera_sensitivity_slider, "CAMERA_SENSITIVITY_TIP", tr("tooltips", "Adjust the mouse look sensitivity for the cinematic camera view."), 20.0f))->setWidth(280.0f);

        // Override overlay label.
        camera_sensitivity_overlay_label = new GuiLabel(camera_sensitivity_slider, "CAMERA_SENSITIVITY_SLIDER_LABEL",
            tr("options", "Mouselook sensitivity: {s}").format({
                {"s", static_cast<string>(static_cast<int>(nearbyint(initial_camera_sensitivity * 100.0f)))}
            }), GuiElement::GuiSizeLabel);
        camera_sensitivity_overlay_label->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        // Cinematic fly-by randomization
        auto* randomize_flyby_toggle = new GuiToggleButton(interface_page, "RANDOMIZE_CINEMATIC_FLYBY", tr("options", "Randomize cinematic fly-by angles"),
            [](bool value)
            {
                PreferencesManager::set("camera_flyby_randomized", value ? "1" : "0");
            }
        );
        randomize_flyby_toggle
            ->setValue(PreferencesManager::get("camera_flyby_randomized", "0") == "1")
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
        (new GuiTextTooltip(randomize_flyby_toggle, "RANDOMIZE_FLYBY_TIP", tr("tooltips", "Randomize the fly-by camera angle in cinematic view for variety."), 20.0f))->setWidth(280.0f);
    }
}

void OptionsMenu::setupGraphicsOptions()
{
    // Quality/performance settings.
    {
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

        (new GuiLabel(graphics_page, "QUALITY_LABEL", tr("options_section", "Quality settings"), GuiElement::GuiSizeLabel))
            ->addBackground()
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setAttribute("margin", "0, 0, 0, 10");

        // FSAA selector.
        auto* fsaa_selector = new GuiSelector(graphics_page, "FSAA",
            [](int index, string value)
            {
                static const int fsaa[] = {0, 2, 4, 8};
                foreach (Window, window, windows)
                    window->setFSAA(fsaa[index]);
            }
        );
        fsaa_selector
            ->setOptions({
                tr("options", "Full-screen antialiasing:") + " " + tr("options_fsaa", "Off"),
                tr("options", "Full-screen antialiasing:") + " " + tr("options_fsaa",  "2x"),
                tr("options", "Full-screen antialiasing:") + " " + tr("options_fsaa",  "4x"),
                tr("options", "Full-screen antialiasing:") + " " + tr("options_fsaa",  "8x")
            })
            ->setSelectionIndex(fsaa_index)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
        (new GuiTextTooltip(fsaa_selector, "FSAA_TIP", tr("tooltips", "Set the level of full-screen antialiasing for smoother edges. Requires restart."), 20.0f))->setWidth(280.0f);

        (new GuiLabel(graphics_page, "THEME_APPLICATION_LABEL", tr("options", "Restart EmptyEpsilon to apply full-screen antialiasing changes"), 20.0f))
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeLabel)
            ->setAttribute("margin", "0, 0, 0, 20");

        // Line drawing mode selector.
        int line_mode_index = (sp::RenderTarget::getLineDrawingMode() == sp::RenderTarget::LineDrawingMode::GL) ? 0 : 1;
        auto* line_mode_selector = new GuiSelector(graphics_page, "GRAPHICS_LINE_DRAWING_MODE",
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
        );
        line_mode_selector
            ->setOptions({
                tr("options", "Line rendering:") + " " + tr("options_lines", "GL (low quality)"),
                tr("options", "Line rendering:") + " " + tr("options_lines", "Quads (high quality)")
            })
            ->setSelectionIndex(line_mode_index)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
        (new GuiTextTooltip(line_mode_selector, "LINE_MODE_TIP", tr("tooltips", "Choose between fast GL line rendering and higher-quality quad rendering."), 20.0f))->setWidth(280.0f);

        // Dynamic nebula lighting toggle.
        auto* nebula_lighting_toggle = new GuiToggleButton(graphics_page, "DYNAMIC_NEBULA_LIGHTING", tr("options", "Render dynamic lights in nebula"),
            [](bool value)
            {
                PreferencesManager::set("dynamic_nebula_lighting", value ? "1" : "0");
            }
        );
        nebula_lighting_toggle
            ->setValue(DynamicLightManager::isEnabled())
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
        (new GuiTextTooltip(nebula_lighting_toggle, "NEBULA_LIGHTING_TIP", tr("tooltips", "Toggle dynamic lighting effects inside nebula regions for visual atmosphere."), 20.0f))->setWidth(280.0f);

        // Nebula fog toggle.
        auto* nebula_fog_toggle = new GuiToggleButton(graphics_page, "NEBULA_FOG", tr("options", "Render fog in nebula"),
            [](bool value)
            {
                PreferencesManager::set("nebula_fog", value ? "1" : "0");
            }
        );
        nebula_fog_toggle
            ->setValue(PreferencesManager::get("nebula_fog", "1") == "1")
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setAttribute("margin", "0, 0, 0, 20");
        (new GuiTextTooltip(nebula_fog_toggle, "NEBULA_FOG_TIP", tr("tooltips", "Toggle visual fog effects that obscure vision inside nebula regions."), 20.0f))->setWidth(280.0f);

        // Atlas size configuration (only shown when 4K is supported).
        if (sp::RenderTarget::is4KAtlasSupported())
        {
            int atlas_index = 0;
            auto atlas_pref = PreferencesManager::get("atlas_size", "auto");
            if (atlas_pref == "4k") atlas_index = 2;
            else if (atlas_pref == "2k") atlas_index = 1;

            auto* atlas_size_selector = new GuiSelector(graphics_page, "ATLAS_SIZE",
                [](int index, string value)
                {
                    sp::RenderTarget::AtlasSizeMode mode = sp::RenderTarget::AtlasSizeMode::Automatic;
                    string pref_value = "auto";
                    if (index == 2)
                    {
                        mode = sp::RenderTarget::AtlasSizeMode::Force4K;
                        pref_value = "4k";
                    }
                    else if (index == 1)
                    {
                        mode = sp::RenderTarget::AtlasSizeMode::Force2K;
                        pref_value = "2k";
                    }
                    sp::RenderTarget::setAtlasSizeMode(mode);
                    PreferencesManager::set("atlas_size", pref_value);
                }
            );
            atlas_size_selector
                ->setOptions({
                    tr("options", "Texture atlas:") + " " + tr("options_atlas", "Automatic"),
                    tr("options", "Texture atlas:") + " " + tr("options_atlas", "2K (2048x2048)"),
                    tr("options", "Texture atlas:") + " " + tr("options_atlas", "4K (4096x4096)")
                })
                ->setSelectionIndex(atlas_index)
                ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
            (new GuiTextTooltip(atlas_size_selector, "ATLAS_SIZE_TIP", tr("tooltips", "Set the texture atlas resolution. Higher quality requires more memory. Requires restart."), 20.0f))->setWidth(280.0f);

            (new GuiLabel(graphics_page, "ATLAS_APPLICATION_NOTE",
                tr("options", "Restart EmptyEpsilon to apply texture atlas changes"),
                20.0f))
                ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeLabel)
                ->setAttribute("margin", "0, 0, 0, 20");
        }
    }

    // View/window settings.
    {
        (new GuiLabel(graphics_page, "VIEW_LABEL", tr("options_section", "View settings"), GuiElement::GuiSizeLabel))
            ->addBackground()
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setAttribute("margin", "0, 0, 0, 10");

        // Fullscreen toggle.
        auto* fullscreen_toggle = new GuiButton(graphics_page, "FULLSCREEN_TOGGLE", tr("options", "Toggle fullscreen/windowed mode"),
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
        );
        fullscreen_toggle->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
        (new GuiTextTooltip(fullscreen_toggle, "FULLSCREEN_TIP", tr("tooltips", "Switch between fullscreen and windowed display mode."), 20.0f))->setWidth(280.0f);

        // Field of view slider.
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
                graphics_fov_overlay_label->setText(tr("options", "Field of view: {fov} degrees").format({
                    {"fov", string(fov, 0)}
                }));
            }
        );
        graphics_fov_slider
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
        (new GuiTextTooltip(graphics_fov_slider, "FOV_SLIDER_TIP", tr("tooltips", "Adjust the main screen camera's field of view angle."), 20.0f))->setWidth(280.0f);

        // Override overlay label.
        graphics_fov_overlay_label = new GuiLabel(graphics_fov_slider, "GRAPHICS_FOV_SLIDER_LABEL", tr("options", "Field of view: {fov} degrees").format({
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
                graphics_draw_distance_overlay_label->setText(tr("options", "Draw distance: {dist}").format({
                    {"dist", string(static_cast<float>(static_cast<int>(dist / 1000.0f)), 1)}
                }) + DISTANCE_UNIT_1K);
            }
        );
        graphics_draw_distance_slider
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
        (new GuiTextTooltip(graphics_draw_distance_slider, "DRAW_DISTANCE_TIP", tr("tooltips", "Set how far the main screen camera renders objects."), 20.0f))->setWidth(280.0f);

        graphics_draw_distance_overlay_label = new GuiLabel(graphics_draw_distance_slider, "GRAPHICS_DRAW_DISTANCE_SLIDER_LABEL", tr("options", "Draw distance: {dist}").format({
            {"dist", string(static_cast<float>(static_cast<int>(initial_draw_distance / 1000.0f)), 1)}
        }) + DISTANCE_UNIT_1K, GuiElement::GuiSizeLabel);
        graphics_draw_distance_overlay_label
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    }
}

void OptionsMenu::setupAudioOptions()
{
    // Sound volume slider.
    sound_volume_slider = new GuiSlider(audio_page, "SOUND_VOLUME_SLIDER", 0.0f, 100.0f, soundManager->getMasterSoundVolume(),
        [this](float volume)
        {
            soundManager->setMasterSoundVolume(volume);
            sound_volume_overlay_label->setText(tr("options", "Sound effect volume: {volume}%").format({
                {"volume", string(static_cast<int>(soundManager->getMasterSoundVolume()))}
            }));
        }
    );
    sound_volume_slider
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 20");
    (new GuiTextTooltip(sound_volume_slider, "SOUND_VOLUME_TIP", tr("tooltips", "Adjust the volume of sound effects."), 20.0f))->setWidth(280.0f);

    // Override overlay label.
    sound_volume_overlay_label = new GuiLabel(sound_volume_slider, "SOUND_VOLUME_SLIDER_LABEL", tr("options", "Sound effect volume: {volume}%").format({
        {"volume", string(static_cast<int>(soundManager->getMasterSoundVolume()))}
    }), 30.0f);
    sound_volume_overlay_label
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Engine playback state.
    (new GuiLabel(audio_page, "IMPULSE_SOUND_LABEL", tr("options_section", "Impulse engine sound"), GuiElement::GuiSizeLabel))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    auto row = new GuiElement(audio_page, "");
    row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("layout", "horizontal");
    row
        ->setAttribute("margin", "0, 0, 0, 20");

    // Determine when engine sound effects are enabled.
    int impulse_enabled_index = PreferencesManager::get("impulse_sound_enabled", "2").toInt();
    auto* impulse_enabled_selector = new GuiSelector(row, "ENGINE_ENABLED", [](int index, string value)
    {
        // 0: Always off
        // 1: Always on
        // 2: On if main screen, off otherwise (default)
        PreferencesManager::set("impulse_sound_enabled", string(index));
    });
    impulse_enabled_selector
        ->setOptions({
            tr("options", "Playback disabled"),
            tr("options", "Play on all screens"),
            tr("options", "Play on main screen only")
        })
        ->setSelectionIndex(impulse_enabled_index)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    (new GuiTextTooltip(impulse_enabled_selector, "IMPULSE_ENABLED_TIP", tr("tooltips", "Choose when impulse engine sounds are audible."), 20.0f))->setWidth(280.0f);

    // Impulse engine volume slider.
    impulse_volume_slider = new GuiSlider(row, "IMPULSE_VOLUME_SLIDER", 0.0f, 100.0f, static_cast<float>(PreferencesManager::get("impulse_sound_volume", "50").toInt()),
        [this](float volume)
        {
            PreferencesManager::set("impulse_sound_volume", volume);
            impulse_volume_overlay_label->setText(tr("options", "Volume: {volume}%").format({
                {"volume", string(PreferencesManager::get("impulse_sound_volume", "50").toInt())}
            }));
        }
    );
    impulse_volume_slider
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    (new GuiTextTooltip(impulse_volume_slider, "IMPULSE_VOLUME_TIP", tr("tooltips", "Adjust the volume of impulse engine sounds."), 20.0f))->setWidth(280.0f);

    // Override overlay label.
    impulse_volume_overlay_label = new GuiLabel(impulse_volume_slider, "IMPULSE_VOLUME_SLIDER_LABEL", tr("options", "Volume: {volume}%").format({
        {"volume", string(PreferencesManager::get("impulse_sound_volume", "50").toInt())}
    }), GuiElement::GuiSizeLabel);
    impulse_volume_overlay_label
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Music playback state.
    (new GuiLabel(audio_page, "MUSIC_PLAYBACK_LABEL", tr("options_section", "Music"), GuiElement::GuiSizeLabel))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    row = new GuiElement(audio_page, "");
    row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("layout", "horizontal");
    row
        ->setAttribute("margin", "0, 0, 0, 20");

    // Determine when music is enabled.
    int music_enabled_index = PreferencesManager::get("music_enabled", "2").toInt();
    auto* music_enabled_selector = new GuiSelector(row, "MUSIC_ENABLED",
        [](int index, string value)
        {
            // 0: Always off
            // 1: Always on
            // 2: On if main screen, off otherwise (default)
            PreferencesManager::set("music_enabled", string(index));
        }
    );
    music_enabled_selector
        ->setOptions({
            tr("options", "Playback disabled"),
            tr("options", "Play on all screens"),
            tr("options", "Play on main screen only")
        })
        ->setSelectionIndex(music_enabled_index)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
    (new GuiTextTooltip(music_enabled_selector, "MUSIC_ENABLED_TIP", tr("tooltips", "Choose where background music plays."), 20.0f))->setWidth(280.0f);

    // Music volume slider.
    music_volume_slider = new GuiSlider(row, "MUSIC_VOLUME_SLIDER", 0.0f, 100.0f, soundManager->getMusicVolume(),
        [this](float volume)
        {
            soundManager->setMusicVolume(volume);
            music_volume_overlay_label->setText(tr("options", "Volume: {volume}%").format({
                {"volume", string(static_cast<int>(soundManager->getMusicVolume()))}
            }));
        }
    );
    music_volume_slider
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 20");
    (new GuiTextTooltip(music_volume_slider, "MUSIC_VOLUME_TIP", tr("tooltips", "Adjust the volume of background music."), 20.0f))->setWidth(280.0f);

    // Override overlay label.
    music_volume_overlay_label = new GuiLabel(music_volume_slider, "MUSIC_VOLUME_SLIDER_LABEL", tr("options", "Volume: {volume}%").format({
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

    (new GuiLabel(audio_page, "PREVIEW_LABEL", tr("options_section", "Preview music"), GuiElement::GuiSizeLabel))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    GuiListbox* music_list = new GuiListbox(audio_page, "MUSIC_PLAY",
        [](int index, string value)
        {
            soundManager->playMusic(value);
        }
    );

    for (string filename : ambient_music_filenames)
        music_list->addEntry(sp::audio::Music::getTagsDisplayName(filename), filename);
    for (string filename : combat_music_filenames)
        music_list->addEntry(sp::audio::Music::getTagsDisplayName(filename), filename);

    music_list->setSize(GuiElement::GuiSizeMax, 500.0f);
    (new GuiTextTooltip(music_list, "MUSIC_PREVIEW_TIP", tr("tooltips", "Click a music track to play it."), 20.0f))->setWidth(280.0f);
}
