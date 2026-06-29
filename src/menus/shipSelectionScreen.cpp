#include "shipSelectionScreen.h"
#include "i18n.h"
#include "featureDefs.h"
#include "glObjects.h"
#include "soundManager.h"
#include "random.h"
#include "multiplayer_client.h"
#include "ecs/query.h"
#include "serverCreationScreen.h"
#include "epsilonServer.h"
#include "main.h"
#include "playerInfo.h"
#include "preferenceManager.h"
#include "gameGlobalInfo.h"
#include "scenarioInfo.h"
#include "crewPositionRequirements.h"

#include "components/database.h"
#include "components/name.h"

#include "screens/cinematicViewScreen.h"
#include "screens/gm/gameMasterScreen.h"
#include "screens/gm/limitedGameMasterScreen.h"
#include "screens/spectatorScreen.h"
#include "screens/windowScreen.h"

#include "menus/luaConsole.h"
#include "menus/optionsMenu.h"

#include "gui/theme.h"
#include "gui/gui2_label.h"
#include "gui/gui2_listbox.h"
#include "gui/gui2_overlay.h"
#include "gui/gui2_panel.h"
#include "gui/gui2_scrollcontainer.h"
#include "gui/gui2_scrolltextcontainer.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_slider.h"
#include "gui/gui2_textentry.h"
#include "gui/gui2_togglebutton.h"
#include "gui/gui2_tooltip.h"

class PasswordDialog : public GuiOverlay
{
public:
    PasswordDialog(GuiContainer* parent, string id)
    : GuiOverlay(parent, id, glm::u8vec4(0, 0, 0, 64))
    {
        hide();

        auto entry_box = new GuiPanel(this, "PASSWORD_ENTRY_BOX");
        entry_box
            ->setPosition(0.0f, 350.0f, sp::Alignment::TopCenter)
            ->setSize(600.0f, 200.0f);

        label = new GuiLabel(entry_box, "PASSWORD_LABEL", tr("Enter this ship's control code:"), GuiElement::GuiSizeLabel);
        label
            ->setPosition(0.0f, 40.0f, sp::Alignment::TopCenter);

        entry = new GuiTextEntry(entry_box, "PASSWORD_ENTRY", "");
        entry
            ->setHidePassword()
            ->enterCallback(
                [this](string text)
                {
                    if (confirmation->isVisible())
                    {
                        hide();
                        on_ready();
                    }
                    if (text != "") checkPassword();
                }
            )
            ->setPosition(20.0f, 0.0f, sp::Alignment::CenterLeft)
            ->setSize(400.0f, GuiElement::GuiSizeRow);

        cancel = new GuiButton(entry_box, "PASSWORD_CANCEL_BUTTON", tr("button", "Cancel"),
            [this]()
            {
                // Reset the dialog.
                entry->setText("");

                // Hide the password overlay and show the ship selection screen.
                hide();
                on_cancel();
            }
        );
        cancel
            ->setPosition(0.0f, -20.0f, sp::Alignment::BottomCenter)
            ->setSize(250.0f, GuiElement::GuiSizeRow);

        entry_ok = new GuiButton(entry_box, "PASSWORD_ENTRY_OK", tr("OK"),
            [this]()
            {
                checkPassword();
            }
        );
        entry_ok
            ->setPosition(420.0f, 0.0f, sp::Alignment::CenterLeft)
            ->setSize(160.0f, GuiElement::GuiSizeRow);

        // Control code confirmation button
        confirmation = new GuiButton(entry_box, "PASSWORD_CONFIRMATION_BUTTON", tr("OK"),
            [this]()
            {
                // Hide the dialog.
                hide();
                on_ready();
            }
        );
        confirmation
            ->setPosition(0.0f, -20.0f, sp::Alignment::BottomCenter)
            ->setSize(250.0f, GuiElement::GuiSizeRow)
            ->hide();
    }

    void open(string label, string preset_password, std::function<bool(string)> on_password_check, std::function<void()> on_ready, std::function<void()> on_cancel)
    {
        this->label->setText(label);
        this->on_password_check = on_password_check;
        this->on_ready = on_ready;
        this->on_cancel = on_cancel;

        entry->setText(preset_password);
        entry->show();
        cancel->show();
        entry_ok->show();
        confirmation->hide();
        show();
    }
private:
    std::function<bool(string)> on_password_check;
    std::function<void()> on_ready;
    std::function<void()> on_cancel;

    void checkPassword() {
        string password = entry->getText().upper();

        if (this->on_password_check(password))
        {
            // Notify the player.
            label->setText(tr("Control code accepted.\nGranting access."));

            // Reset and hide the password field.
            entry->setText("");
            entry->hide();
            cancel->hide();
            entry_ok->hide();

            // Show a confirmation button.
            confirmation->show();
        }
        else
        {
            label->setText(tr("Incorrect control code. Re-enter code:"));
            entry->setText("");
        }
    }

    GuiLabel* label;
    GuiButton* cancel;
    GuiButton* entry_ok;
    GuiButton* confirmation;

public:
    GuiTextEntry* entry;
};

ShipSelectionScreen::ShipSelectionScreen()
{
    // Draw background decorations.
    new GuiOverlay(this, "", GuiTheme::getColor("background"));
    (new GuiOverlay(this, "", glm::u8vec4{255, 255, 255, 255}))
        ->setTextureTiledThemed("background.crosses");

    // Easiest place to ensure that positional sound is disabled on crew screen
    // views. As soon as a 3D view is rendered, positional sound is re-enabled.
    soundManager->disablePositionalSound();

    // Draw a container with two columns.
    const int column_width = 550;
    container = new GuiElement(this, "MAIN_CONTAINER");
    container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");
    container
        ->setAttribute("padding", "50");

    left_container = new GuiElement(container, "LEFT_CONTAINER");
    left_container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("padding", "0, 10, 0, 0");
    left_column = new GuiElement(left_container, "LEFT_COLUMN");
    left_column
        ->setSize(column_width, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    left_column
        ->setAttribute("alignment", "topright");

    right_container = new GuiElement(container, "RIGHT_CONTAINER");
    right_container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("padding", "10, 0, 0, 0");
    right_column = new GuiElement(right_container, "RIGHT_COLUMN");
    right_column
        ->setSize(column_width, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    right_column
        ->setAttribute("alignment", "topleft");

    right_panel = new GuiPanel(right_column, "DIRECT_OPTIONS_PANEL");
    right_panel
        ->setAttribute("layout", "vertical");
    right_panel
        ->setAttribute("padding", "20, 0");
    right_panel
        ->setAttribute("margin", "0, 0, 0, 20");

    (new GuiLabel(right_panel, "DIRECT_OPTIONS_LABEL", tr("Additional views and options"), GuiElement::GuiSizeLabel))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    // Attach a single-text tooltip to a button.
    auto addTooltip = [](GuiElement* btn, const string& id, const string& text)
    {
        (new GuiTextTooltip(btn, id, text, 20.0f))->setWidth(280.0f);
    };

    // Game Master button (server only)
    if (game_server.isAlive())
    {
        auto game_master_button = new GuiButton(right_panel, "GAME_MASTER_BUTTON", tr("Game master"),
            [this]()
            {
                if (gameGlobalInfo->gm_control_code.length() > 0)
                {
                    LOG(Info, "Player selected game master mode, which has a control code.");
                    focus(password_dialog->entry);
                    password_dialog->open(tr("Enter the GM control code:"), "",
                        [](string code)
                        {
                            return code == gameGlobalInfo->gm_control_code;
                        },
                        [this]()
                        {
                            my_player_info->commandSetShip({});
                            destroy();
                            new GameMasterScreen(getRenderLayer());
                        },
                        [this]()
                        {
                            left_container->show();
                            right_container->show();
                        }
                    );

                    left_container->hide();
                    right_container->hide();
                }
                else
                {
                    my_player_info->commandSetShip({});
                    destroy();
                    new GameMasterScreen(getRenderLayer());
                }
            }
        );

        game_master_button->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
        addTooltip(game_master_button, "GAME_MASTER_TOOLTIP",
            tr("shipSelect", "Control the scenario as Game Master. Spawn and tweak objects, communicate with players, monitor activity, and trigger scenario events. Requires GM code if set.")
        );
    }

    // Limited Game Master button (client-side only)
    if (game_client)
    {
        auto limited_gm_button = new GuiButton(right_panel, "LIMITED_GM_BUTTON", tr("Limited game master"),
            [this]()
            {
                if (gameGlobalInfo->gm_control_code.length() > 0)
                {
                    LOG(Info, "Player selected limited game master mode, which has a control code.");
                    focus(password_dialog->entry);
                    password_dialog->open(tr("Enter the GM control code:"), "",
                        [](string code)
                        {
                            return code == gameGlobalInfo->gm_control_code;
                        },
                        [this]()
                        {
                            my_player_info->commandSetShip({});
                            destroy();
                            new LimitedGameMasterScreen(getRenderLayer());
                        },
                        [this]()
                        {
                            left_container->show();
                            right_container->show();
                        }
                    );
                    left_container->hide();
                    right_container->hide();
                }
                else
                {
                    my_player_info->commandSetShip({});
                    destroy();
                    new LimitedGameMasterScreen(getRenderLayer());
                }
            }
        );

        limited_gm_button->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
        addTooltip(limited_gm_button, "LIMITED_GM_TOOLTIP",
            tr("shipSelect", "Control the scenario with limited GM powers from a client. Move/delete entities, change factions, issue AI orders, manage waypoints, and send messages. Requires GM code if set.")
        );
    }

    // Spectator view button
    auto spectator_button = new GuiButton(right_panel, "SPECTATOR_BUTTON", tr("Spectator map"),
        [this]()
        {
            if (gameGlobalInfo->gm_control_code.length() > 0)
            {
                LOG(Info, "Player selected spectate mode, which has a control code.");
                focus(password_dialog->entry);
                password_dialog->open(tr("Enter the GM control code:"), "",
                    [](string code)
                    {
                        return code == gameGlobalInfo->gm_control_code;
                    },
                    [this]()
                    {
                        my_player_info->commandSetShip({});
                        destroy();
                        new SpectatorScreen(getRenderLayer());
                    },
                    [this]()
                    {
                        left_container->show();
                        right_container->show();
                    }
                );
                left_container->hide();
                right_container->hide();
            }
            else
            {
                my_player_info->commandSetShip({});
                destroy();
                new SpectatorScreen(getRenderLayer());
            }
        }
    );

    spectator_button->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
    addTooltip(spectator_button, "SPECTATOR_TOOLTIP",
        tr("shipSelect", "View the full tactical map as a spectator. Shows all ships and objects without crew screen controls. Requires GM code if set.")
    );

    // Cinematic view button
    auto cinematic_button = new GuiButton(right_panel, "", tr("Cinematic view"),
        [this]()
        {
            if (gameGlobalInfo->gm_control_code.length() > 0)
            {
                LOG(Info, "Player selected cinematic view mode, which has a control code.");
                focus(password_dialog->entry);
                password_dialog->open(tr("Enter the GM control code:"), "",
                    [](string code)
                    {
                        return code == gameGlobalInfo->gm_control_code;
                    },
                    [this]()
                    {
                        my_player_info->commandSetShip({});
                        destroy();
                        new CinematicViewScreen(getRenderLayer());
                    },
                    [this]()
                    {
                        left_container->show();
                        right_container->show();
                    }
                );
                left_container->hide();
                right_container->hide();
            }
            else
            {
                my_player_info->commandSetShip({});
                destroy();
                new CinematicViewScreen(getRenderLayer());
            }
        }
    );

    cinematic_button->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
    addTooltip(cinematic_button, "CINEMATIC_TOOLTIP",
        tr("shipSelect", "A cinematic camera that can automatically follow the action. Best for demonstrations or display screens. Requires GM code if set.")
    );

    auto options_button = new GuiButton(right_panel, "OPEN_OPTIONS", tr("mainMenu", "Options"),
        [this]()
        {
            new OptionsMenu(OptionsMenu::ReturnTo::ShipSelection);
            this->destroy();
        }
    );

    options_button->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
    addTooltip(options_button, "OPTIONS_TOOLTIP",
        tr("shipSelect", "Adjust audio, display, and control settings.")
    );

    if (game_server.isAlive())
    {
        auto extra_settings_panel = new GuiPanel(this, "");
        extra_settings_panel
            ->setSize(600.0f, 425.0f)
            ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
            ->hide();

        auto extra_settings = new GuiElement(extra_settings_panel, "");
        extra_settings
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
            ->setMargins(25)
            ->setAttribute("layout", "vertical");

        // Science scan complexity selector.
        auto row = new GuiElement(extra_settings, "");
        row
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(row, "GAME_SCANNING_COMPLEXITY_LABEL", tr("Scan complexity: "), GuiElement::GuiSizeLabel))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(250.0f, GuiElement::GuiSizeMax);

        (new GuiSelector(row, "GAME_SCANNING_COMPLEXITY",
            [](int index, string value)
            {
                gameGlobalInfo->scanning_complexity = EScanningComplexity(index);
            }
        ))
            ->setOptions({
                tr("scanning", "None (delay)"),
                tr("scanning", "Simple"),
                tr("scanning", "Normal"),
                tr("scanning", "Advanced")
            })
                ->setSelectionIndex(static_cast<int>(gameGlobalInfo->scanning_complexity))
                ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        // Hacking difficulty selector.
        row = new GuiElement(extra_settings, "");
        row
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(row, "GAME_HACKING_DIFFICULTY_LABEL", tr("Hacking difficulty: "), GuiElement::GuiSizeLabel))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(250.0f, GuiElement::GuiSizeMax);

        (new GuiSelector(row, "GAME_HACKING_DIFFICULTY",
            [](int index, string value)
            {
                gameGlobalInfo->hacking_difficulty = index;
            }
        ))
            ->setOptions({
                tr("hacking_difficulty", "Simple"),
                tr("hacking_difficulty", "Normal"),
                tr("hacking_difficulty", "Difficult"),
                tr("hacking_difficulty", "Fiendish")
            })
            ->setSelectionIndex(gameGlobalInfo->hacking_difficulty)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        // Hacking games selector.
        row = new GuiElement(extra_settings, "");
        row
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(row, "GAME_HACKING_GAMES_LABEL", tr("Hacking type: "), GuiElement::GuiSizeLabel))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(250, GuiElement::GuiSizeMax);

        (new GuiSelector(row, "GAME_HACKING_TYPE",
            [](int index, string value)
            {
                gameGlobalInfo->hacking_games = EHackingGames(index);
            }
        ))
            ->setOptions({
                tr("hacking_type", "Mine"),
                tr("hacking_type", "Lights"),
                tr("hacking_type", "All")
            })
            ->setSelectionIndex(static_cast<int>(gameGlobalInfo->hacking_games))
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        // Collision damage slider row.
        row = new GuiElement(extra_settings, "");
        row
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(row, "GAME_COLLISION_DAMAGE_LABEL", tr("Collision damage: "), GuiElement::GuiSizeLabel))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(250.0f, GuiElement::GuiSizeMax);

        (new GuiSelector(row, "GAME_COLLISION_DAMAGE",
            [](int index, string value)
            {
                gameGlobalInfo->collision_damage_factor = index * index * 0.001f;
            }
        ))
            ->setOptions({
                tr("collision_damage", "Off"),
                tr("collision_damage", "Minor"),
                tr("collision_damage", "Dangerous"),
                tr("collision_damage", "Lethal")
            })
            ->setSelectionIndex(0)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        // Frequency and system damage row.
        row = new GuiElement(extra_settings, "");
        row
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setAttribute("layout", "horizontal");

        (new GuiToggleButton(row, "GAME_FREQUENCIES_TOGGLE", tr("Beam/shield frequencies"),
            [](bool value)
            {
                gameGlobalInfo->use_beam_shield_frequencies = value == 1;
            })
        )
            ->setValue(gameGlobalInfo->use_beam_shield_frequencies)
            ->setSize(275.0f, GuiElement::GuiSizeMax)
            ->setPosition(0.0f, 0.0f, sp::Alignment::CenterLeft);

        (new GuiToggleButton(row, "GAME_SYS_DAMAGE_TOGGLE", tr("Per-system damage"),
            [](bool value)
            {
                gameGlobalInfo->use_system_damage = value == 1;
            }
        ))
            ->setValue(gameGlobalInfo->use_system_damage)
            ->setSize(275.0f, GuiElement::GuiSizeMax)
            ->setPosition(0.0f, 0.0f, sp::Alignment::CenterRight);

        // Waypoint settings row.
        row = new GuiElement(extra_settings, "");
        row
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setAttribute("layout", "horizontal");

        (new GuiToggleButton(row, "GAME_MULTI_WP_SETS_TOGGLE", tr("Multiple waypoint sets"),
            [](bool value)
            {
                gameGlobalInfo->enable_multiple_waypoint_sets = value == 1;
            }
        ))
            ->setValue(gameGlobalInfo->enable_multiple_waypoint_sets)
            ->setSize(275.0f, GuiElement::GuiSizeMax)
            ->setPosition(0.0f, 0.0f, sp::Alignment::CenterLeft);

        (new GuiToggleButton(row, "GAME_WP_ROUTES_TOGGLE", tr("Waypoint routes"),
            [](bool value)
            {
                gameGlobalInfo->enable_waypoint_routes = value == 1;
            }
        ))
            ->setValue(gameGlobalInfo->enable_waypoint_routes)
            ->setSize(275.0f, GuiElement::GuiSizeMax)
            ->setPosition(0.0f, 0.0f, sp::Alignment::CenterRight);

        auto close_button = new GuiButton(extra_settings_panel, "", tr("Close"),
            [this, extra_settings_panel]()
            {
                extra_settings_panel->hide();
                container->show();
            }
        );
        close_button
            ->setSize(200.0f, GuiElement::GuiSizeRow)
            ->setPosition(0.0f, -25.0f, sp::Alignment::BottomCenter);

        // Server settings
        auto extra_settings_button = new GuiButton(right_panel, "", tr("Server settings"),
            [this, extra_settings_panel]()
            {
                extra_settings_panel->show();
                container->hide();
            }
        );
        extra_settings_button
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

        addTooltip(extra_settings_button, "EXTRA_SETTINGS_TOOLTIP",
            tr("ship_select", "Modify server-wide settings, such as minigame difficulty and common ship features.")
        );
    }

    right_panel->setSize(GuiElement::GuiSizeMax, 30.0f + right_panel->getChildCount() * GuiElement::GuiSizeRow);

    right_panel_2 = new GuiPanel(right_column, "RIGHT_PANEL_2");
    right_panel_2
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    right_panel_2
        ->setAttribute("padding", "20, 20, 0, 20");

    right_panel_2_label = new GuiLabel(right_panel_2, "RIGHT_PANEL_2_LABEL", tr("Connected players"), GuiElement::GuiSizeLabel);
    right_panel_2_label
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    right_panel_2_text = new GuiScrollFormattedText(right_panel_2, "RIGHT_PANEL_2_TEXT", tr("No players connected"));
    right_panel_2_text->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Left column
    left_panel = new GuiPanel(left_column, "CREATE_SHIP_BOX");
    left_panel
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    left_panel
        ->setAttribute("padding", "20, 20, 0, 20");
    left_panel
        ->setAttribute("margin", "0, 0, 0, 20");

    left_panel_2 = new GuiPanel(left_column, "LEFT_PANEL_2");
    left_panel_2
        ->setSize(GuiElement::GuiSizeMax, 430.0f)
        ->setAttribute("layout", "vertical");
    left_panel_2
        ->setAttribute("padding", "20, 20, 0, 20");
    left_panel_2
        ->setAttribute("margin", "0, 0, 0, 20");

    left_panel_2_label = new GuiLabel(left_panel_2, "LEFT_PANEL_2_LABEL", "", GuiElement::GuiSizeLabel);
    left_panel_2_label
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    ship_action_row = new GuiElement(left_panel_2, "SHIP_SPAWN_ROW");
    ship_action_row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->hide()
        ->setAttribute("layout", "horizontal");
    ship_action_row
        ->setAttribute("margin", "0, 0, 0, 10");

    left_panel_2_text = new GuiScrollFormattedText(left_panel_2, "LEFT_PANEL_2_TEXT", tr("No information for the selected ship type"));
    left_panel_2_text->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // If this is the server, add buttons and a selector to create player ships.
    if (game_server.isAlive())
    {
        left_panel_2_label->setText(tr("Create player ship"));

        // List only ships with templates designated for player use.
        ship_spawn_info = gameGlobalInfo->getSpawnablePlayerShips();

        if (ship_spawn_info.size() > 0)
        {
            ship_action_row->show();
            left_panel_2_label->setText(tr("Create player ship"));
            ship_template_selector = new GuiSelector(ship_action_row, "CREATE_SHIP_SELECTOR",
                [this](int index, string value)
                {
                    if (index < int(ship_spawn_info.size()))
                        left_panel_2_text->setText(ship_spawn_info[index].description);
                }
            );

            for (const auto& info : ship_spawn_info)
                ship_template_selector->addEntry(info.label, info.label);

            ship_template_selector
                ->setSelectionIndex(0)
                ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

            // Spawn a ship of the selected template near 0,0 and give it a random
            // heading.
            ship_template_button = new GuiButton(ship_action_row, "CREATE_SHIP_BUTTON", tr("Create"),
                [this]()
                {
                    auto index = ship_template_selector->getSelectionIndex();
                    if (index < static_cast<int>(ship_spawn_info.size()))
                    {
                        auto res = ship_spawn_info[index].create_callback.call<sp::ecs::Entity>();
                        LuaConsole::checkResult(res);
                        if (res.isOk())
                        {
                            // TODO: Apply some player properties like faction/position.
                        }
                    }
                }
            );

            ship_template_button->setSize(150.0f, GuiElement::GuiSizeMax);
            left_panel_2_text->setText(ship_spawn_info[0].description);
        }
        else
        {
            left_panel_2_text->setText(tr("No description provided"));

            for (const auto& info : ScenarioInfo::getScenarios())
            {
                if (info.name == gameGlobalInfo->scenario)
                {
                    left_panel_2_label->setText(info.name);
                    left_panel_2_text->setText(info.description);
                }
            }
        }
    }

    if (game_client)
    {
        left_panel_2_label->setText(tr("Player ship description"));
        left_panel_2_text->setText(tr("No player ship description available"));

        (new GuiButton(ship_action_row, "JOIN_SHIP_BUTTON", tr("Join ship"),
            [this]()
            {
                joinPlayerShip(player_ship_list->getSelectionValue());
            }
        ))
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    }

    // Player ship selection panel
    (new GuiLabel(left_panel, "SHIP_SELECTION_LABEL", tr("Select ship"), GuiElement::GuiSizeLabel))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    no_ships_label = new GuiLabel(left_panel, "SHIP_SELECTION_NO_SHIPS_LABEL", tr("Waiting for server to spawn a ship"), GuiElement::GuiSizeLabel);
    no_ships_label
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Player ship list
    player_ship_list = new GuiListbox(left_panel, "PLAYER_SHIP_LIST",
        [this](int index, string value)
        {
            if (game_server || last_selection_index == index || player_ship_list->entryCount() == 1)
                joinPlayerShip(value);

            last_selection_index = index;
        }
    );
    player_ship_list->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    auto disconnect_row = new GuiElement(left_column, "DISCONNECT_ROW");
    disconnect_row->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    if (game_server.isAlive())
    {
        // If this is the server, the "back" button goes to the scenario
        // selection/server creation screen.
        (new GuiButton(disconnect_row, "DISCONNECT", tr("Scenario selection"),
            [this]()
            {
                destroy();
                new ServerScenarioSelectionScreen();
            }
        ))
            ->setSize(300.0f, GuiElement::GuiSizeMax)
            ->setAttribute("alignment", "bottomcenter");
    }
    else
    {
        // If this is a client, the "back" button disconnects from the server
        // and returns to the main menu.
        (new GuiButton(disconnect_row, "DISCONNECT", tr("Disconnect"),
            [this]()
            {
                destroy();
                disconnectFromServer();
                returnToMainMenu(getRenderLayer());
            }
        ))
            ->setSize(300.0f, GuiElement::GuiSizeMax)
            ->setAttribute("alignment", "bottomcenter");
    }

    // Control code entry dialog.
    password_dialog = new PasswordDialog(this, "PASSWORD_DIALOG");

    crew_position_selection_overlay = new GuiOverlay(this, "", glm::u8vec4(0, 0, 0, 64));
    crew_position_selection_overlay->hide();

    crew_position_selection = new CrewPositionSelection(crew_position_selection_overlay, "", 0,
        [this]()
        {
            crew_position_selection_overlay->hide();
            my_player_info->commandSetShip({});
        },
        [this]()
        {
            crew_position_selection->spawnUI(getRenderLayer());
            destroy();
        }
    );
}

void ShipSelectionScreen::update(float delta)
{
    // If this is a client and is disconnected from the server, destroy the
    // screen and return to the main menu.
    if (game_client)
    {
        if (game_client->getStatus() == GameClient::Disconnected)
        {
            destroy();
            disconnectFromServer();
            returnToMainMenu(getRenderLayer());
            return;
        }

        string ship_type_name = "";
        string result = tr("No player ship description available");
        left_panel_2_label->setText(tr("Player ship description"));

        if (player_ship_list->getSelectionIndex() >= 0)
        {
            left_panel_2->show();
            if (auto ship = sp::ecs::Entity::fromString(player_ship_list->getSelectionValue()))
            {
                if (auto tn = ship.getComponent<TypeName>())
                    ship_type_name = tn->type_name;
            }
        }
        else if (player_ship_list->entryCount() > 0)
            player_ship_list->setSelectionIndex(0);
        else
            left_panel_2->hide();

        if (ship_type_name != "")
        {
            left_panel_2_label->setText(tr("{type} description").format({{"type", ship_type_name}}));
            ship_action_row->show();

            for (auto [entity, database] : sp::ecs::Query<Database>())
            {
                if (database.name == ship_type_name)
                {
                    result = database.description;
                    continue;
                }
            }
        }

        left_panel_2_text->setText(result);
    }

    // Update the player ship list with all player ships.
    for (auto [entity, pc] : sp::ecs::Query<PlayerControl>())
    {
        string ship_name = Faction::getInfo(entity).locale_name;
        if (auto tn = entity.getComponent<TypeName>())
            ship_name += " " + tn->type_name;
        if (auto cs = entity.getComponent<CallSign>())
            ship_name += " " + cs->callsign;

        int index = player_ship_list->indexByValue(entity.toString());
        // If a player ship isn't in already in the list, add it.
        if (index == -1)
        {
            index = player_ship_list->addEntry(ship_name, entity.toString());
            if (my_spaceship == entity)
                player_ship_list->setSelectionIndex(index);
        }

        // If the ship is crewed, count how many positions are filled.
        int ship_position_count = 0;
        for (int n = 0; n < static_cast<int>(CrewPosition::MAX); n++)
        {
            if (PlayerInfo::hasPlayerAtPosition(entity, CrewPosition(n)))
                ship_position_count += 1;
        }

        player_ship_list->setEntryName(index, ship_name + " (" + string(ship_position_count) + ")");
    }

    // Clear player ships that no longer exist.
    for (int i = 0; i < player_ship_list->entryCount(); i++)
    {
        bool keeper = false;

        for (auto [entity, pc] : sp::ecs::Query<PlayerControl>())
        {
            if (entity.toString() == player_ship_list->getEntryValue(i))
                keeper = true;
        }

        if (!keeper) player_ship_list->removeEntry(i);
    }

    // If there aren't any player ships, show a label stating so.
    no_ships_label->setVisible(!(player_ship_list->entryCount() > 0));
    player_ship_list->setVisible(player_ship_list->entryCount() > 0);

    // Sync our configured user name with the server
    if (my_player_info->name != PreferencesManager::get("username"))
        my_player_info->commandSetName(PreferencesManager::get("username"));

    // Update the list of connected players
    string player_list = "";

    for (auto player : player_info_list)
    {
        player_list += player->name;
        auto player_ship = player->ship;
        auto tn = player_ship.getComponent<TypeName>();
        auto cs = player_ship.getComponent<CallSign>();

        if (player_ship && (tn || cs))
        {
            player_list += " (";
            player_list += Faction::getInfo(player_ship).locale_name;
            if (tn) player_list += " " + tn->localized;
            if (tn && cs) player_list += " ";
            if (cs) player_list += cs->callsign;
            player_list += ")";
        }
        player_list += "\n";
    }

    right_panel_2_text->setText(player_list);
}

void ShipSelectionScreen::joinPlayerShip(string entity_string)
{
    auto ship = sp::ecs::Entity::fromString(entity_string);

    // If the selected item is a ship ...
    if (auto pc = ship.getComponent<PlayerControl>())
    {
        // ... and it has a control code, ask the player for it.
        if (pc->control_code.length() > 0)
        {
            LOG(Info, "Player selected ", ship.getComponent<CallSign>() ? ship.getComponent<CallSign>()->callsign : string("[NO CALLSIGN]"), ", which has a control code.");

            // Hide the ship selection UI temporarily to deter sneaky ship thieves.
            left_container->hide();
            right_container->hide();

            // Show the control code entry dialog.
            focus(password_dialog->entry);
            password_dialog->open(tr("Enter this ship's control code:"), my_player_info->last_ship_password,
                [ship, pc](string code)
                {
                    return ship && pc->control_code == code;
                },
                [this, ship, pc]()
                {
                    my_player_info->commandSetShip(ship);
                    crew_position_selection_overlay->show();
                    my_player_info->last_ship_password = pc->control_code;
                    left_container->show();
                    right_container->show();
                },
                [this]()
                {
                    left_container->show();
                    right_container->show();
                }
            );
        }
        // Otherwise, select and set this ship ID in the player info.
        else
        {
            my_player_info->commandSetShip(ship);
            crew_position_selection_overlay->show();
        }
    }
    // If the selected item isn't a ship, reset the ship ID in player info.
    else my_player_info->commandSetShip({});
}

CrewPositionSelection::CrewPositionSelection(GuiContainer* owner, string id, int _window_index, std::function<void()> on_cancel, std::function<void()> on_ready)
: GuiPanel(owner, id), window_index(_window_index)
{
    // Layout
    setSize(1120.0f, GuiElement::GuiSizeMax);
    setPosition(0.0f, 0.0f, sp::Alignment::Center);
    setAttribute("layout", "vertical");
    setAttribute("margin", "50");
    setAttribute("padding", "20");

    auto container = new GuiElement(this, "");
    container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");
    container
        ->setAttribute("margin", "0, 0, 0, 20");

    auto left_container = new GuiElement(container, "");
    left_container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    auto center_container = new GuiElement(container, "");
    center_container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    center_container
        ->setAttribute("margin", "20, 20, 0, 0");

    auto right_container = new GuiElement(container, "");
    right_container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    auto bottom_row = new GuiElement(this, "");
    bottom_row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("layout", "horizontal");

    // Left column
    auto standard_crew_panel = new GuiPanel(left_container, "");
    standard_crew_panel
        ->setSize(GuiElement::GuiSizeMax, 80.0f)
        ->setAttribute("margin", "0, 0, 0, 20");
    standard_crew_panel
        ->setAttribute("padding", "20, 20, 0, 20");
    standard_crew_panel
        ->setAttribute("layout", "vertical");

    auto limited_crew_panel = new GuiPanel(left_container, "");
    limited_crew_panel
        ->setSize(GuiElement::GuiSizeMax, 80.0f)
        ->setAttribute("margin", "0, 0, 0, 20");
    limited_crew_panel
        ->setAttribute("padding", "20, 20, 0, 20");
    limited_crew_panel
        ->setAttribute("layout", "vertical");

    (new GuiLabel(limited_crew_panel, "CREW_POSITION_SELECT_LABEL", tr("4/3/1 player crew"), GuiElement::GuiSizeLabel))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    // 6/5 player crew panel
    (new GuiLabel(standard_crew_panel, "CREW_POSITION_SELECT_LABEL", tr("6/5 player crew"), GuiElement::GuiSizeLabel))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    auto createCrewPositionButton = [this](GuiElement* standard_crew_panel, int n)
    {
        auto cp = CrewPosition(n);
        auto button = new GuiToggleButton(standard_crew_panel, "", getCrewPositionName(cp),
            [this, cp](bool value)
            {
                my_player_info->commandSetCrewPosition(window_index, cp, value);
                unselectSingleOptions();
                setCrewScreenInfo(cp);
            }
        );
        button
            ->setValue(static_cast<size_t>(window_index) < my_player_info->crew_positions.size() && my_player_info->crew_positions[window_index].has(cp))
            ->setIcon(getCrewPositionIcon(cp))
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

        crew_position_button[n] = button;

        return button;
    };

    for (int n = 0; n <= int(CrewPosition::relayOfficer); n++)
    {
        createCrewPositionButton(standard_crew_panel, n);
        standard_crew_panel
            ->setSize(standard_crew_panel->getSize() + glm::vec2(0.0f, GuiElement::GuiSizeRow));
    }

    // 4/3/1 player crew panel
    for (int n = int(CrewPosition::tacticalOfficer); n <= int(CrewPosition::singlePilot); n++)
    {
        createCrewPositionButton(limited_crew_panel, n);
        limited_crew_panel->setSize(limited_crew_panel->getSize() + glm::vec2(0.0f, GuiElement::GuiSizeRow));
    }

    // Center column
    auto space_screens_panel = new GuiPanel(center_container, "");
    space_screens_panel
        ->setSize(GuiElement::GuiSizeMax, 180.0f)
        ->setAttribute("margin", "0, 0, 0, 20");
    space_screens_panel
        ->setAttribute("padding", "20, 20, 0, 20");
    space_screens_panel
        ->setAttribute("layout", "vertical");

    (new GuiLabel(space_screens_panel, "CREW_POSITION_SELECT_LABEL", tr("3D screens"), GuiElement::GuiSizeLabel))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    // 3D screens panel
    // Main screen button
    main_screen_button = new GuiToggleButton(space_screens_panel, "", tr("Main screen"),
        [this](bool value)
        {
            my_player_info->commandSetMainScreen(window_index, value);
            unselectSingleOptions();
        }
    );
    main_screen_button
        ->setValue(my_player_info->main_screen & (1 << window_index))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    // Window button
    auto window_button_row = new GuiElement(space_screens_panel, "");
    window_button_row->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)->setAttribute("layout", "horizontal");
    window_button = new GuiToggleButton(window_button_row, "WINDOW_BUTTON", tr("Ship window"),
        [this](bool value)
        {
            disableAllExcept(window_button);
        }
    );
    window_button->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    window_angle = new GuiTextEntry(window_button_row, "WINDOW_ANGLE","0");
    window_angle
        ->setSelectOnFocus()
        ->callback(
            // Check validity: allow only numbers, and no more than 3 digits.
            [this](string text)
            {
                if (text != "" && text != "-")
                    window_angle->setText(text.toInt());
                if (text.length() > 3 && text.toInt() >= 0)
                    window_angle->setText(text.substr(0, 3));
                if (text.length() > 4 && text.toInt() < 0)
                    window_angle->setText(text.substr(0, 4));

                window_angle->setSize(75.0f, GuiElement::GuiSizeRow);
            }
        )
        ->setSize(75.0f, GuiElement::GuiSizeRow);

    window_angle_label = new GuiLabel(window_button_row, "WINDOW_ANGLE_LABEL", "°", GuiElement::GuiSizeLabel);
    window_angle_label->setSize(12.0f, GuiElement::GuiSizeMax);

    // Alternative options panel
    auto alternative_options_panel = new GuiPanel(center_container, "");
    alternative_options_panel
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "0, 0, 0, 20");
    alternative_options_panel
        ->setAttribute("padding", "20, 20, 0, 20");
    alternative_options_panel
        ->setAttribute("layout", "vertical");

    (new GuiLabel(alternative_options_panel, "CREW_POSITION_SELECT_LABEL", tr("Alternative options"), GuiElement::GuiSizeLabel))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    auto alternative_scroll = new GuiScrollContainer(alternative_options_panel, "", GuiScrollContainer::ScrollMode::Scroll);
    alternative_scroll
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    // Main screen controls button
    main_screen_controls_button = new GuiToggleButton(alternative_scroll, "MAIN_SCREEN_CONTROLS_ENABLE", tr("Main screen controls"),
        [this](bool value)
        {
            my_player_info->commandSetMainScreenControl(window_index, value);
        }
    );
    main_screen_controls_button
        ->setValue(my_player_info->main_screen_control)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    for (int n = static_cast<int>(CrewPosition::singlePilot) + 1; n < static_cast<int>(CrewPosition::MAX); n++)
        createCrewPositionButton(alternative_scroll, n);

    // Right column
    // Info text panel
    crew_screen_info = new GuiScrollFormattedText(right_container, "CREW_SCREEN_INFO",
        tr("Select at least one crew screen to play.\nYou can select multiple crew screens and switch between them during the game.")
    );
    crew_screen_info
        ->setSize(GuiElement::GuiSizeMax, 325.0f)
        ->setAttribute("margin", "0, 0, 0, 20");

    (new GuiLabel(right_container, "STATION_PLAYERS_LABEL", tr("Crew assignments"), GuiElement::GuiSizeLabel))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    station_players = new GuiScrollFormattedText(right_container, "STATION_PLAYERS", "");
    station_players->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Bottom row
    auto bottom_left = new GuiElement(bottom_row, "");
    bottom_left->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    auto bottom_right = new GuiElement(bottom_row, "");
    bottom_right->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    if (on_cancel)
    {
        (new GuiButton(bottom_left, "CANCEL", tr("button", "Cancel"), on_cancel))
            ->setSize(300.0f, GuiElement::GuiSizeMax)
            ->setPosition(0.0f, 0.0f, sp::Alignment::Center);
    }

    ready_button = new GuiButton(bottom_right, "READY", tr("button", "Ready"), on_ready);
    ready_button->setSize(300.0f, GuiElement::GuiSizeMax)->setPosition(0, 0, sp::Alignment::Center);
}

void CrewPositionSelection::onUpdate()
{
    auto pc = my_spaceship.getComponent<PlayerControl>();
    bool crew_position_selected = false;
    // If a position already has a player on the currently selected player ship,
    // indicate that on the button.
    string crew_text = "";

    for (int n = 0; n < static_cast<int>(CrewPosition::MAX); n++)
    {
        auto cp = CrewPosition(n);
        string button_text = getCrewPositionName(cp);

        if (my_spaceship)
        {
            std::vector<string> players;

            foreach (PlayerInfo, i, player_info_list)
            {
                if (i->ship == my_spaceship && i->hasPosition(cp))
                    players.push_back(i->name);
            }

            std::sort(players.begin(), players.end());
            players.resize(std::distance(players.begin(), std::unique(players.begin(), players.end())));

            if (players.size() > 0)
            {
                crew_position_button[n]->setText(button_text + " ["+ std::to_string(players.size()) +"]");
                if (!crew_text.empty()) crew_text += "\n";
                crew_text += button_text + ": " + string(", ").join(players);
            }
            else
                crew_position_button[n]->setText(button_text);

            bool has_components = crewPositionRequirements::hasRequirements(cp, my_spaceship);

            crew_position_button[n]->setEnable((!pc || pc->allowed_positions.has(cp)) && has_components);
            crew_position_selected = crew_position_selected || crew_position_button[n]->getValue();
        }
    }

    if (crew_text.empty()) crew_text = tr("No crew members assigned");
    main_screen_button->setText(crew_position_selected ? tr("Main screen (split)") : tr("Main screen"));

    station_players->setText(crew_text);
    ready_button->setEnable(main_screen_button->getValue() || window_button->getValue() || crew_position_selected);
}

void CrewPositionSelection::disableAllExcept(GuiToggleButton* button)
{
    for (int n = 0; n < static_cast<int>(CrewPosition::MAX); n++)
    {
        if (crew_position_button[n] != button)
        {
            crew_position_button[n]->setValue(false);
            my_player_info->commandSetCrewPosition(window_index, CrewPosition(n), false);
        }
    }

    if (main_screen_button != button)
    {
        main_screen_button->setValue(false);
        my_player_info->commandSetMainScreen(window_index, false);
    }

    if (main_screen_controls_button != button)
        main_screen_controls_button->setValue(false);

    if (window_button != button)
        window_button->setValue(false);
}

void CrewPositionSelection::unselectSingleOptions()
{
    window_button->setValue(false);
}

void CrewPositionSelection::setCrewScreenInfo(CrewPosition cp)
{
    string text = "";
    switch (cp)
    {
    case CrewPosition::helmsOfficer:
        text = "<color=#C0C0FF>Helms</>\nManeuvers the ship with thrusters and impulse engines, employs faster-than-light propulsion methods, docks with other ships and space stations, and retrieves objects";
        break;
    case CrewPosition::weaponsOfficer:
        text = "<color=#C0C0FF>Weapons</>\nManages a ship's offensive and defensive systems; loads, unloads, aims, and fires weapon tubes; targets beam weapons; and sets beam and shield frequencies";
        break;
    case CrewPosition::engineering:
        text = "<color=#C0C0FF>Engineering</>\nManages a ship's power, heat, coolant, and damage; directs repair crews; tracks system effectiveness; and controls the ship's self-destruct system";
        break;
    case CrewPosition::scienceOfficer:
        text = "<color=#C0C0FF>Science</>\nExamines and reports on the ship's surroundings, and researches entities using the ship's sensors and database";
        break;
    case CrewPosition::relayOfficer:
        text = "<color=#C0C0FF>Relay</>\nManages the flow of information between the ship and other ships and space stations across the region, hails and communicates with other entities, launches scan probes, sets navigational waypoints, and hacks hostile entities";
        break;
    case CrewPosition::tacticalOfficer:
        text = "<color=#C0C0FF>Tactical</>\nCombines the responsibilities of Helms (maneuvering, propulsion, docking) with Weapons (loading, targeting, and firing weapons). However, also lacks Weapons' control over shields.";
        break;
    case CrewPosition::engineeringAdvanced:
        text = "<color=#C0C0FF>Engineering+</>\nManages a ship's power, heat, coolant, and damage; manages shield activation and calibration; directs repair crews; tracks system effectiveness; and controls the ship's self-destruct system";
        break;
    case CrewPosition::operationsOfficer:
        text = "<color=#C0C0FF>Operations</>\nCombines the responsibilities of Science (scanning, research) with Relay (communication, navigation). However, also lacks Relay's access to the sector map or hacking features.";
        break;
    case CrewPosition::singlePilot:
        text = "<color=#C0C0FF>Single pilot</>\nCombines essential functions from Helms, Weapons, and Relay, at the expense of several other features";
        break;
    case CrewPosition::beamWeaponsOfficer:
        text = "<color=#C0C0FF>Beam weapons</>\nManages and targets the ship's beam weapons, as a specialized subset of Weapons functions";
        break;
    case CrewPosition::missileWeaponsOfficer:
        text = "<color=#C0C0FF>Beam weapons</>\nManages and targets the ship's weapons tubes, including missiles and mines, as a specialized subset of Weapons functions";
        break;
    case CrewPosition::damageControl:
        text = "<color=#C0C0FF>Damage control</>\nManages the ship's repair crews from a systems overview display, as a specialized subset of Engineering functions";
        break;
    case CrewPosition::powerManagement:
        text = "<color=#C0C0FF>Power management</>\nRoutes power and coolant to the ship's systems, as a specialized subset of Engineering functions";
        break;
    case CrewPosition::databaseView:
        text = "<color=#C0C0FF>Database</>\nResearches information in the ship's database, as a specialized subset of Science functions";
        break;
    case CrewPosition::dockingBay:
        text = "<color=#C0C0FF>Docking bay</>\nControls the ship's internal docking bay, if any, including launching, reparing, and restocking berthed ships";
        break;
    case CrewPosition::strategicMap:
        text = "<color=#C0C0FF>Strategic map</>\nViews a sector map, launches scan probes, sets navigational waypoints, and hacks hostile entities. A specialized subset of Relay functions, with communications delegated to the Comms screen.";
        break;
    case CrewPosition::commsOnly:
        text = "<color=#C0C0FF>Comms</>\nDisplays active communications with other entities, as a specialized subset of Relay functions";
        break;
    case CrewPosition::shipLog:
        text = "<color=#C0C0FF>Ship's log</>\nDisplays the ship's log, as a specialized subset of Relay functions";
        break;
    case CrewPosition::radarOfficer:
        text = "<color=#C0C0FF>Radar</>\nDisplays a non-interactive ship's radar at short, long, and sector ranges, as well as of any linked probe, as a specialized subset of Science and Relay functions";
        break;
    case CrewPosition::probeCamera:
        text = "<color=#C0C0FF>Probe camera</>\nDisplays the view from the linked probe's camera, with rotation controls";
        break;
    case CrewPosition::targetAnalysis:
        text = "<color=#C0C0FF>Target analysis</>\nDisplays known information about a target linked to this screen by the Science officer, as a specialized subset of Science functions";
        break;
    case CrewPosition::briefing:
        text = "<color=#C0C0FF>Briefing</>\nDisplays the scenario's missing briefing presentation, if implemented by the scenario";
        break;
    case CrewPosition::droneOperations:
        text = "<color=#C0C0FF>Drone operations</>\nProvides control over linked probes, if the ship has a drone controller and linked drones are within control range";
        break;
    default:
        text = "Select at least one crew screen to play.\nYou can select multiple crew screens and switch between them during the game. You can also select the main screen alongside any other screen, which splits the screen to show the viewscreen if your display's width is sufficient.";
    }

    crew_screen_info->setText(text);
}

void CrewPositionSelection::spawnUI(RenderLayer* render_layer)
{
    // When the Ready button is clicked, destroy the ship selection screen and
    // create the position's screen. If selecting a non-player screen, set the
    // ship ID to -1 (no ship).
    if (window_button->getValue())
    {
        destroy();
        uint8_t window_flags = PreferencesManager::get("ship_window_flags", "1").toInt();
        new WindowScreen(render_layer, window_angle->getText().toInt(), window_flags);
    }
    else
    {
        destroy();
        my_player_info->spawnUI(window_index, render_layer);
    }
}

SecondMonitorScreen::SecondMonitorScreen(int monitor_index)
: GuiCanvas(window_render_layers[monitor_index]), monitor_index(monitor_index)
{
    // Draw background decorations only.
    new GuiOverlay(this, "", GuiTheme::getColor("background"));
    (new GuiOverlay(this, "", glm::u8vec4{255, 255, 255, 255}))
        ->setTextureTiledThemed("background.crosses");
}

void SecondMonitorScreen::update(float delta)
{
    if (!crew_position_selection && my_player_info && my_spaceship)
    {
        crew_position_selection = new CrewPositionSelection(this, "", monitor_index, nullptr,
            [this]()
            {
                crew_position_selection->spawnUI(getRenderLayer());
                destroy();
            }
        );
    }

    if (crew_position_selection && (!my_player_info || !my_spaceship))
    {
        crew_position_selection->destroy();
        crew_position_selection = nullptr;
    }
}
