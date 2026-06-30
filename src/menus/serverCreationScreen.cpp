#include "serverCreationScreen.h"
#include <i18n.h>
#include "preferenceManager.h"
#include "shipSelectionScreen.h"
#include "gameGlobalInfo.h"
#include "epsilonServer.h"
#include "scenarioInfo.h"
#include "main.h"
#include "clipboard.h"

#include "gui/theme.h"
#include "gui/gui2_label.h"
#include "gui/gui2_listbox.h"
#include "gui/gui2_overlay.h"
#include "gui/gui2_panel.h"
#include "gui/gui2_scrolltextcontainer.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_textentry.h"
#include "gui/gui2_togglebutton.h"

ServerSetupScreen::ServerSetupScreen()
{
    // Draw background elements.
    new GuiOverlay(this, "", GuiTheme::getColor("background"));
    (new GuiOverlay(this, "", glm::u8vec4{255, 255, 255, 255}))
        ->setTextureTiledThemed("background.crosses");

    // Layout elements.
    GuiElement* container = new GuiElement(this, "CONTAINER");
    container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("padding", "50");
    container
        ->setAttribute("layout", "vertical");

    (new GuiLabel(container, "HEADER", tr("title", "Host game"), GuiElement::GuiSizeLabel))
        ->addBackground()
        ->setSize(250.0f, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 20");

    GuiElement* column = new GuiElement(container, "COLUMN");
    column
        ->setSize(800.0f, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    column
        ->setAttribute("alignment", "topcenter");

    // Server configuration section.
    (new GuiLabel(column, "CONFIG_LABEL", tr("Server configuration"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    // Server name row.
    GuiElement* row = new GuiElement(column, "");
    row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("layout", "horizontal");

    (new GuiLabel(row, "NAME_LABEL", tr("Server name:"), 30.0f))
        ->setAlignment(sp::Alignment::CenterRight)
        ->setSize(250.0f, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "0, 10, 0, 0");

    server_name = new GuiTextEntry(row, "SERVER_NAME", "server");
    server_name->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Server password row.
    row = new GuiElement(column, "");
    row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("layout", "horizontal");

    (new GuiLabel(row, "PASSWORD_LABEL", tr("Server password:"), 30.0f))
        ->setAlignment(sp::Alignment::CenterRight)
        ->setSize(250.0f, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "0, 10, 0, 0");

    server_password = new GuiTextEntry(row, "SERVER_PASSWORD", "");
    server_password->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // GM control code row.
    row = new GuiElement(column, "");
    row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("layout", "horizontal");

    (new GuiLabel(row, "GM_CONTROL_CODE_LABEL", tr("GM control code:"), 30.0f))
        ->setAlignment(sp::Alignment::CenterRight)
        ->setSize(250.0f, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "0, 10, 0, 0");

    gm_password = new GuiTextEntry(row, "GM_CONTROL_CODE", "");
    gm_password->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // LAN/Internet row.
    row = new GuiElement(column, "");
    row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("layout", "horizontal");

    (new GuiLabel(row, "LAN_INTERNET_LABEL", tr("List on internet registry:"), 30.0f))
        ->setAlignment(sp::Alignment::CenterRight)
        ->setSize(250.0f, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "0, 10, 0, 0");

    server_visibility = new GuiToggleButton(row, "LAN_INTERNET_SELECT", tr("No"),
        [this](bool active)
        {
            if (active) server_visibility->setText("Yes (" + PreferencesManager::get("registry_registration_url", DEFAULT_REGISTRY) + ")");
            else server_visibility->setText(tr("No"));
        }
    );
    server_visibility
        ->setValue(false)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    row = new GuiElement(column, "");
    row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("layout", "horizontal");
    row
        ->setAttribute("margin", "0, 0, 0, 20");

    (new GuiLabel(row, "SERVER_PORT", tr("Server port:"), 30.0f))
        ->setAlignment(sp::Alignment::CenterRight)
        ->setSize(250.0f, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "0, 10, 0, 0");

    server_port = new GuiTextEntry(row, "SERVER_PORT", string(defaultServerPort));
    server_port
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Server info section.
    (new GuiLabel(column, "INFO_LABEL", tr("Server information"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    // Reverse proxy server IP row.
    string reverse_proxy_value = PreferencesManager::get("serverproxy");
    GuiPanel* server_proxy_panel = new GuiPanel(column, "SERVERPROXY_MESSAGE_BOX");
    server_proxy_panel
        ->setSize(GuiElement::GuiSizeMax, 80.0f)
        ->setVisible(reverse_proxy_value != "");
    // Serverproxy (reverse proxy) is directly configured as a preference.
    (new GuiLabel(server_proxy_panel, "PROXY_LABEL", tr("Server configured to connect to reverse proxy at "), 30.0f))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    string proxy_ips;
    string sep = "";
    for (auto proxy_ip : reverse_proxy_value.split(":"))
    {
        proxy_ips = proxy_ips + sep + "[" + proxy_ip + "]";
        sep = ",";
    }
    (new GuiLabel(server_proxy_panel, "PROXY_IPS", proxy_ips, 30.0f))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setPosition(0.0f, 30.0f);

    // Server IP row.
    row = new GuiElement(column, "");
    row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");

    (new GuiLabel(row, "SERVER_IP_LABEL", tr("Server IPs:\n(click to copy)"), 30.0f))
        ->setAlignment(sp::Alignment::TopRight)
        ->setSize(250.0f, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "0, 10, 0, 0");

    auto server_ips = new GuiListbox(row, "SERVER_IPS",
        [](int index, string value)
        {
            // Copy the IP to the clipboard.
            Clipboard::setClipboard(value);
        }
    );
    server_ips
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "0, 0, 0, 40");

    for (auto addr_str : sp::io::network::Address::getLocalAddress().getHumanReadable())
    {
        if (addr_str == "::1" || addr_str == "127.0.0.1") continue;
        server_ips->addEntry(addr_str, addr_str);
    }

    // Bottom buttons.
    row = new GuiElement(container, "");
    row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("layout", "horizontal");

    // Close server button.
    (new GuiButton(row, "CANCEL_SERVER", tr("Cancel server"),
        [this]()
        {
            destroy();
            returnToMainMenu(getRenderLayer());
        }
    ))
        ->setSize(250.0f, GuiElement::GuiSizeMax);

    (new GuiElement(row, "SPACER"))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Start server button.
    (new GuiButton(row, "START_SERVER", tr("Start server"),
        [this]()
        {
            int port = server_port->getText().toInt();
            if (port < 80) port = defaultServerPort;
            new EpsilonServer(port);
            if (!game_server.isAlive())
            {
                LOG(Error, "Failed to start server on port " + string(port) + " (port may be in use)");
                return;
            }
            game_server->setServerName(server_name->getText());
            game_server->setPassword(server_password->getText().upper());
            gameGlobalInfo->gm_control_code = gm_password->getText().upper();

            if (server_visibility->getValue())
            {
                game_server->registerOnMasterServer(PreferencesManager::get("registry_registration_url", DEFAULT_REGISTRY));
                new ServerSetupMasterServerRegistrationScreen();
            }
            else new ServerScenarioSelectionScreen();
            destroy();
        }
    ))
        ->setSize(250.0f, GuiElement::GuiSizeMax);
}

ServerSetupMasterServerRegistrationScreen::ServerSetupMasterServerRegistrationScreen()
{
    // Draw background elements.
    new GuiOverlay(this, "", GuiTheme::getColor("background"));
    (new GuiOverlay(this, "", glm::u8vec4{255, 255, 255, 255}))
        ->setTextureTiledThemed("background.crosses");

    info_label = new GuiLabel(this, "INFO", "", GuiElement::GuiSizeLabel);
    info_label->setPosition(0.0f, 0.0f, sp::Alignment::Center);

    auto* row = new GuiElement(this, "");
    row
        ->setPosition(0.0f, -50.0f, sp::Alignment::BottomCenter)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("padding", "50, 0");
    row
        ->setAttribute("layout", "horizontal");

    (new GuiButton(row, "CLOSE_SERVER", tr("Close"),
        [this]()
        {
            disconnectFromServer();
            new ServerSetupScreen();
            destroy();
        }
    ))
        ->setSize(250.0f, GuiElement::GuiSizeMax);

    (new GuiElement(row, "SPACER"))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Start server button.
    continue_button = new GuiButton(row, "CONTINUE", tr("Continue"),
        [this]()
        {
            new ServerScenarioSelectionScreen();
            destroy();
        }
    );
    continue_button->setSize(250.0f, GuiElement::GuiSizeMax);
}

void ServerSetupMasterServerRegistrationScreen::update(float delta)
{
    switch (game_server->getMasterServerState())
    {
    case GameServer::MasterServerState::Disabled:
        info_label->setText("Not connecting to master server?");
        continue_button->enable();
        break;
    case GameServer::MasterServerState::Registering:
        info_label->setText("Connecting to master server");
        continue_button->disable();
        break;
    case GameServer::MasterServerState::Success:
        info_label->setText("Master server connection successful");
        continue_button->enable();
        break;
    case GameServer::MasterServerState::FailedToReachMasterServer:
        info_label->setText("Failed to reach the master server");
        continue_button->disable();
        break;
    case GameServer::MasterServerState::FailedPortForwarding:
        info_label->setText("Port forwarding check failed");
        continue_button->disable();
        break;
    }
}

ServerScenarioSelectionScreen::ServerScenarioSelectionScreen()
{
    // Draw background elements.
    new GuiOverlay(this, "", GuiTheme::getColor("background"));
    (new GuiOverlay(this, "", glm::u8vec4{255, 255, 255, 255}))
        ->setTextureTiledThemed("background.crosses");

    // Layout elements.
    GuiElement* container = new GuiElement(this, "");
    container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("padding", "50");
    container
        ->setAttribute("layout", "vertical");

    (new GuiLabel(container, "HEADER", tr("title", "Select scenario"), GuiElement::GuiSizeLabel))
        ->addBackground()
        ->setSize(250.0f, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 20");

    GuiElement* columns = new GuiElement(container, "");
    columns
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");

    GuiElement* left = new GuiElement(columns, "LEFT_COLUMN");
    left
        ->setSize(250.0f, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    GuiElement* middle = new GuiElement(columns, "MIDDLE_COLUMN");
    middle
        ->setSize(350.0f, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    middle
        ->setAttribute("margin", "20, 0");

    GuiElement* right = new GuiElement(columns, "RIGHT_COLUMN");
    right
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    // Scenario categories.
    (new GuiLabel(left, "CATEGORY_LABEL", tr("Category"), GuiElement::GuiSizeLabel))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    category_list = new GuiListbox(left, "SCENARIO_CATEGORY",
        [this](int index, string value)
        {
            loadScenarioList(value);
        }
    );
    category_list->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Scenario list.
    (new GuiLabel(middle, "LIST_LABEL", tr("Scenario"), GuiElement::GuiSizeLabel))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    scenario_list = new GuiListbox(middle, "SCENARIO_LIST",
        [this](int index, string value)
        {
            ScenarioInfo info(value);
            description_text->setText(info.description);
            start_button
                ->setText(info.settings.empty()
                    ? tr("Start scenario")
                    : tr("Configure scenario")
                )
                ->enable();
        }
    );
    scenario_list->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Scenario description.
    (new GuiLabel(right, "DESCRIPTION_LABEL", tr("Description"), GuiElement::GuiSizeLabel))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    description_text = new GuiScrollFormattedText(right, "SCENARIO_DESCRIPTION", tr("Select a scenario..."));
    description_text->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    for (const auto& category : ScenarioInfo::getCategories())
        category_list->addEntry(tr("category", category), category);

    // Bottom buttons.
    GuiElement* row = new GuiElement(container, "");
    row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 50, 0");
    row
        ->setAttribute("layout", "horizontal");

    // Close server button.
    (new GuiButton(row, "CLOSE_SERVER", tr("Close server"),
        [this]()
        {
            destroy();
            disconnectFromServer();
            new ServerSetupScreen();
        }
    ))
        ->setSize(250.0f, GuiElement::GuiSizeMax);

    (new GuiElement(row, "SPACER"))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Start server button.
    start_button = new GuiButton(row, "START_SCENARIO", tr("Start scenario"),
        [this]()
        {
            if (scenario_list->getSelectionIndex() == -1) return;

            auto filename = scenario_list->getEntryValue(scenario_list->getSelectionIndex());
            ScenarioInfo info(filename);

            if (info.settings.empty())
            {
                // Start the selected scenario.
                gameGlobalInfo->scenario = info.name;
                gameGlobalInfo->startScenario(filename);

                // Destroy this screen and move on to ship selection.
                destroy();
                returnToShipSelection(getRenderLayer());
            }
            else
            {
                new ServerScenarioOptionsScreen(filename);
                destroy();
            }
        }
    );
    start_button
        ->setSize(250.0f, GuiElement::GuiSizeMax)
        ->disable();

    // Select the previously selected scenario.
    for (const auto& info : ScenarioInfo::getScenarios())
    {
        if (info.name == gameGlobalInfo->scenario)
        {
            for (int n = 0; n < category_list->entryCount(); n++)
            {
                if (info.hasCategory(category_list->getEntryValue(n)))
                {
                    category_list->setSelectionIndex(n);
                    category_list->scrollTo(n);
                    loadScenarioList(category_list->getEntryValue(n));
                    break;
                }
            }
            for (int n = 0; n < scenario_list->entryCount(); n++)
            {
                if (info.filename == scenario_list->getEntryValue(n))
                {
                    scenario_list->setSelectionIndex(n);
                    scenario_list->scrollTo(n);
                    description_text->setText(info.description);
                    start_button
                        ->setText(info.settings.empty()
                            ? tr("Start scenario")
                            : tr("Configure scenario")
                        )
                        ->enable();
                    break;
                }
            }
        }
    }

    gameGlobalInfo->reset();
    gameGlobalInfo->scenario_settings.clear();
}

void ServerScenarioSelectionScreen::loadScenarioList(const string& category)
{
    scenario_list
        ->setSelectionIndex(-1)
        ->setOptions({});

    for (const auto& info : ScenarioInfo::getScenarios(category))
        scenario_list->addEntry(info.name, info.filename);

    start_button
        ->setText(tr("Start scenario"))
        ->disable();
    description_text->setText(tr("Select a scenario..."));
}

ServerScenarioOptionsScreen::ServerScenarioOptionsScreen(string filename)
{
    ScenarioInfo info(filename);
    scenario_settings = {};

    // Background elements.
    new GuiOverlay(this, "", GuiTheme::getColor("background"));
    (new GuiOverlay(this, "", glm::u8vec4{255, 255, 255, 255}))
        ->setTextureTiledThemed("background.crosses");

    // Layout elements.
    GuiElement* container = new GuiElement(this, "");
    container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("padding", "50");
    container
        ->setAttribute("layout", "vertical");

    (new GuiLabel(container, "HEADER", tr("title", "Configure scenario"), GuiElement::GuiSizeLabel))
        ->addBackground()
        ->setSize(250.0f, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 20");

    GuiElement* columns = new GuiElement(container, "");
    columns
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");

    // Scenario options.
    GuiElement* option_container = nullptr;
    int count = 0;
    // Allow wider columns if there are fewer than 5 options.
    float column_width = static_cast<int>(info.settings.size()) < 5
        ? 450.0f
        : 300.0f;

    // Left centering spacer for dynamic-width column.
    (new GuiElement(columns, ""))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Add an item per option, in up to 2 rows of 3 columns.
    for (auto& setting : info.settings)
    {
        // Break columns at two options.
        if (!option_container || count == 2)
        {
            option_container = new GuiElement(columns, "");
            option_container
                ->setSize(column_width, GuiElement::GuiSizeMax)
                ->setAttribute("layout", "vertical");
            // Add margin to columns after the first.
            if (count == 2)
                option_container->setAttribute("margin", "20, 0, 0, 0");

            count = 0;
        }

        // Option name.
        (new GuiLabel(option_container, "", setting.key_localized, 30.0f))
            ->addBackground()
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setAttribute("margin", "0, 0, 0, 10");

        // Option value selector.
        GuiSelector* selector = new GuiSelector(option_container, "",
            [this, info, setting](int index, string value)
            {
                this->scenario_settings[setting.key] = value;
                for (auto& option : setting.options)
                {
                    if (option.value == value)
                        description_per_setting[setting.key]->setText(option.description);
                }

                start_button->setEnable(this->scenario_settings.size() >= info.settings.size());
            }
        );
        selector->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

        for (auto& option : setting.options)
        {
            selector->addEntry(option.value_localized, option.value);
            if (option.value == setting.default_option)
            {
                selector->setSelectionIndex(selector->entryCount() - 1);
                this->scenario_settings[setting.key] = option.value;
            }
        }

        // Option description.
        GuiScrollFormattedText* description = new GuiScrollFormattedText(option_container, "", setting.description);
        description->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
        // Add margin to bottom of first row.
        if (count == 0) description->setAttribute("margin", "0, 0, 0, 20");
        description_per_setting[setting.key] = description;

        count++;
    }

    // Right centering spacer for dynamic-width column.
    (new GuiElement(columns, ""))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Bottom buttons.
    GuiElement* row = new GuiElement(container, "");
    row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 50, 0");
    row
        ->setAttribute("layout", "horizontal");

    // Back button.
    (new GuiButton(row, "BACK", tr("Back"),
        [this]()
        {
            new ServerScenarioSelectionScreen();
            destroy();
        }
    ))
        ->setSize(250.0f, GuiElement::GuiSizeMax);

    (new GuiElement(row, "SPACER"))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Start server button.
    start_button = new GuiButton(row, "START_SCENARIO", tr("Start scenario"),
        [this, info, filename]()
        {
            // Start the selected scenario.
            gameGlobalInfo->scenario = info.name;
            gameGlobalInfo->startScenario(filename, this->scenario_settings);

            // Destroy this screen and move on to ship selection.
            destroy();
            returnToShipSelection(getRenderLayer());
        }
    );
    start_button
        ->setSize(250.0f, GuiElement::GuiSizeMax)
        ->setEnable(scenario_settings.size() >= info.settings.size());
}
