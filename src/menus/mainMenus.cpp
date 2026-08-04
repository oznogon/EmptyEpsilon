#include "mainMenus.h"
#include <i18n.h>
#include "engine.h"
#include "main.h"
#include "preferenceManager.h"
#include "epsilonServer.h"
#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "config.h"

#include "menus/serverCreationScreen.h"
#include "menus/optionsMenu.h"
#include "menus/tutorialMenu.h"
#include "menus/serverBrowseMenu.h"

#include "screens/gm/gameMasterScreen.h"

#include "screenComponents/rotatingModelView.h"

#include "gui/theme.h"
#include "gui/gui2_image.h"
#include "gui/gui2_label.h"
#include "gui/gui2_button.h"
#include "gui/gui2_textentry.h"
#include "gui/gui2_scrolltextcontainer.h"
#include "gui/gui2_tooltip.h"

MainMenu::MainMenu()
{
    constexpr float logo_size = 256.0f;
    constexpr float logo_size_y = 256.0f;
    constexpr float logo_size_x = 1024.0f;
    constexpr float title_y = 160.0f;
    constexpr float button_height = GuiElement::GuiSizeRow;

    // Background elements
    new GuiOverlay(this, "", GuiTheme::getColor("background"));
    (new GuiOverlay(this, "", glm::u8vec4{255, 255, 255, 255}))
        ->setTextureTiledThemed("background.crosses");

    (new GuiImage(this, "LOGO", "logo_full.png"))
        ->setPosition(0.0f, title_y, sp::Alignment::TopCenter)
        ->setSize(logo_size_x, logo_size_y);

    // Version number
    (new GuiLabel(this, "VERSION", tr("Credits", "Oznogon fork\nVersion {version}").format({{"version", string(VERSION_NUMBER)}}), 25.0f))
        ->setPosition(0.0f, title_y + logo_size, sp::Alignment::TopCenter)
        ->setSize(0.0f, GuiElement::GuiSizeRow);

    // Menu selections
    auto* container = new GuiElement(this, "");
    container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("padding", "50");

    auto* menu_selections = new GuiElement(container, "");
    menu_selections
        ->setSize(250.0f, 600.0f)
        ->setPosition(0.0f, 0.0f, sp::Alignment::BottomLeft)
        ->setAttribute("layout", "verticalbottom");

    auto* quit_button = new GuiButton(menu_selections, "QUIT", tr("mainMenu", "Quit"),
        []()
        {
            engine->shutdown();
        }
    );
    quit_button->setSize(GuiElement::GuiSizeMax, button_height);
    (new GuiTextTooltip(quit_button, "QUIT_TIP", tr("tooltips", "Exit and close EmptyEpsilon.")))->setWidth();

    auto* options_button = new GuiButton(menu_selections, "OPEN_OPTIONS", tr("mainMenu", "Options"),
        [this]()
        {
            new OptionsMenu(OptionsMenu::ReturnTo::Main);
            destroy();
        }
    );
    options_button->setSize(GuiElement::GuiSizeMax, button_height);
    (new GuiTextTooltip(options_button, "OPTIONS_TIP", tr("tooltips", "Open the graphics, audio, and interface settings.")))->setWidth();

#ifdef DEBUG
    auto* gm_button = new GuiButton(menu_selections, "", tr("mainMenu", "GM screen"),
        [this]()
        {
            new EpsilonServer(DEFAULT_SERVER_PORT);
            if (game_server.isAlive())
            {
                gameGlobalInfo->startScenario("scenario_90_empty_space.lua");

                my_player_info->commandSetShip({});
                destroy();
                new GameMasterScreen(nullptr);
            }
        }
    );
    gm_button->setSize(GuiElement::GuiSizeMax, button_height);
    (new GuiTextTooltip(gm_button, "GM_SCREEN_TIP", tr("tooltips", "Open a game master console for testing and debugging.")))->setWidth();
#endif

    auto* tutorials_button = new GuiButton(menu_selections, "START_TUTORIAL", tr("mainMenu", "Tutorials"),
        [this]()
        {
            new TutorialMenu();
            destroy();
        }
    );
    tutorials_button->setSize(GuiElement::GuiSizeMax, button_height);
    (new GuiTextTooltip(tutorials_button, "TUTORIALS_TIP", tr("tooltips", "Play through tutorial scenarios to learn the game.")))->setWidth();

    auto* join_button = new GuiButton(menu_selections, "START_CLIENT", tr("mainMenu", "Join game"),
        [this]()
        {
            new ServerBrowserMenu();
            destroy();
        }
    );
    join_button->setSize(GuiElement::GuiSizeMax, button_height);
    (new GuiTextTooltip(join_button, "JOIN_TIP", tr("tooltips", "Browse and connect to LAN or online game servers.")))->setWidth();

    auto* host_button = new GuiButton(menu_selections, "START_SERVER", tr("mainMenu", "Host game"),
        [this]()
        {
            new ServerSetupScreen();
            destroy();
        }
    );
    host_button->setSize(GuiElement::GuiSizeMax, button_height);
    host_button->setAttribute("margin", "0, 0, 50, 0");
    (new GuiTextTooltip(host_button, "HOST_TIP", tr("tooltips", "Create and host a new game server with your chosen scenario.")))->setWidth();

    auto* username_entry = new GuiTextEntry(menu_selections, "USERNAME", PreferencesManager::get("username"));
    username_entry->callback(
        [](string text)
        {
            PreferencesManager::set("username", text);
        }
    );
    username_entry->setSize(GuiElement::GuiSizeMax, button_height);
    (new GuiTextTooltip(username_entry, "USERNAME_TIP", tr("tooltips", "Set your player name displayed to other players.")))->setWidth();

    (new GuiLabel(menu_selections, "", tr("mainMenu", "Your name:")))
        ->setAlignment(sp::Alignment::CenterLeft)
        ->setSize(GuiElement::GuiSizeMax, button_height);

    // Credits screen button
    auto* credits_button = new GuiButton(container, "CREDITS_SCREEN", tr("mainMenu", "Credits"),
        [this]()
        {
            new CreditsScreen();
            destroy();
        }
    );
    credits_button
        ->setPosition(0.0f, 0.0f, sp::Alignment::BottomRight)
        ->setSize(250.0f, button_height);
    (new GuiTextTooltip(credits_button, "CREDITS_TIP", tr("tooltips", "View the credits and acknowledgments.")))->setWidth();

    if (PreferencesManager::get("instance_name") != "")
    {
        (new GuiLabel(container, "", PreferencesManager::get("instance_name"), 25.0f))
            ->setAlignment(sp::Alignment::CenterLeft)
            ->setPosition(0.0f, 0.0f, sp::Alignment::TopLeft)
            ->setSize(0.0f, 18.0f);
    }
}

CreditsScreen::CreditsScreen()
{
    // Background elements
    new GuiOverlay(this, "", GuiTheme::getColor("background"));
    (new GuiOverlay(this, "", glm::u8vec4{255, 255, 255, 255}))
        ->setTextureTiledThemed("background.crosses");

    auto* container = new GuiElement(this, "");
    container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    container
        ->setAttribute("padding", "50");

    // Header
    (new GuiLabel(container, "HEADER", tr("EmptyEpsilon Credits")))
        ->addBackground()
        ->setSize(250.0f, GuiElement::GuiSizeRow);

    // Prep credits text
    string credits_text =
        "<h2>" + tr("Credits", "Programming") + "</>\n\n" +
        "Daid\n" +
        "gcask\n" +
        "Nallath\n" +
        "Xansta\n" +
        "StarryWisdom\n\n" +
        "<h2>" + tr("Credits", "Scenarios") + "</>\n\n" +
        "Daid\n" +
        "Elliot Drees\n" +
        "Fouindor\n" +
        "Kilted-Klingon\n" +
        "David Priddy\n" +
        "Chris 'csibbitt' Sibbitt\n" +
        "Xansta\n" +
        "Visjammer\n\n" +
        "<h3>" + tr("Credits", "Scenario voice acting") + "</>\n\n" +
        "Andrew 'Snow' Kenny\n" +
        "Bart K7AAY\n" +
        "SANTAtheGREY\n" +
        "Xansta\n\n" +
        "<h2>" + tr("Credits", "Localizations") + "</>\n\n" +
        "<h3>" + tr("language_name", "French") + "</>\n\n" +
        "Muerte\n" +
        "Thomas L\n" +
        "ciseur68\n\n" +
        "<h3>" + tr("language_name", "German") + "</>\n\n" +
        "aBlueShadow\n" +
        "PET2001\n" +
        "Hagen Rothe\n\n" +
        "<h3>" + tr("language_name", "Czech") + "</>\n\n" +
        "Tomáš 'hemmond' Látal\n\n" +
        "<h3>" + tr("language_name", "Italian") + "</>\n\n" +
        "NinoSecret\n\n"
        "<h3>" + tr("Credits", "Additional support") + "</>\n\n" +
        "Tsht\n" +
        "GinjaNinja32\n" +
        "Chris 'csibbitt' Sibbitt\n" +
        "Pithlit\n\n"
        "<h2>" + tr("Credits", "Models") + "</>\n\n" +
        "Angryfly (turbosquid.com)\n" +
        "MSGDI (https://www.cgtrader.com/3d-models/msgdi)\n" +
        "SolCommand (https://www.solcommand.com/)\n\n" +
        "<h2>" + tr("Credits", "Icons and graphics") + "</>\n\n" +
        "Interesting John\n\n"
        "<h2>" + tr("Credits", "Crew sprites") + "</>\n\n" +
        "Tokka (http://bekeen.de/)\n\n" +
        "<h2>" + tr("Credits", "Special thanks") + "</>\n\n" +
        "Marty Lewis (MadKat)\n" +
        "Serge Wroclawski\n" +
        "Dennis Shelton\n" +
        "VolgClawtooth\n" +
        "Daniel Loftis\n" +
        "David Concepcion\n" +
        "Philippe Bruylant\n" +
        "Ralf Leichter\n" +
        "Lee McDonough (Flea)\n" +
        "Mickael Houet\n\n" +
        "<h1>" + tr("Credits", "Oznogon Fork Credits") + "</>\n\n" +
        "<h2>" + tr("Credits", "Additional feature design or implementation") + "</>\n\n" +
        "Amir Arad\n" +
        "Bridge Command (Natalia Bogdanova)\n" +
        "Clockwork Dog (Tom Bull, Sam Lee)\n" +
        "Dave Kapell\n" +
        "GinjaNinja32\n" +
        "Oznogon\n" +
        "tdelc\n\n" +
        "<h2>" + tr("Credits", "Additional artwork") + "</>\n\n" +
        "Oznogon (GUI icons)\n" +
        "<h2>" + tr("Credits", "Additional sound effects") + "</>\n\n" +
        "The Sound Pack Tree (GameAudioGDC bundle)\n" +
        "Digital Rain Lab (GameAudioGDC bundle)\n" +
        "<h2>" + tr("Credits", "Music") + "</>\n\n" +
        "Rafael Krux, Orchestralis.net (CC-BY)\n" +
        "LonePeakMusic, lonepeakmusic.itch.io\n\n";

    // Draw credits
    (new GuiScrollFormattedText(container, "CREDITS", credits_text))
        ->setTextSize(30.0f)
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(800.0f, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "20");

    auto* back_row = new GuiElement(container, "");
    back_row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    (new GuiButton(back_row, "BACK", tr("button", "Back"),
        [this]()
        {
            new MainMenu();
            destroy();
        }
    ))
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopLeft)
        ->setSize(250.0f, GuiElement::GuiSizeMax);
}