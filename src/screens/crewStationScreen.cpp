#include "crewStationScreen.h"
#include "epsilonServer.h"
#include "main.h"
#include "gameGlobalInfo.h"
#include "preferenceManager.h"
#include "playerInfo.h"
#include "multiplayer_client.h"
#include "soundManager.h"

#include "components/customshipfunction.h"

#include "screenComponents/indicatorOverlays.h"
#include "screenComponents/noiseOverlay.h"
#include "screenComponents/shipDestroyedPopup.h"
#include "screenComponents/helpOverlay.h"
#include "screenComponents/impulseSound.h"
#include "screenComponents/utilityBeamSound.h"
#include "screenComponents/viewportMainScreen.h"

#include "gui/gui2_togglebutton.h"
#include "gui/gui2_panel.h"
#include "gui/gui2_scrolltext.h"
#include "gui/joystickConfig.h"

#include <i18n.h>

CrewStationScreen::CrewStationScreen(RenderLayer* render_layer, bool with_main_screen)
: GuiCanvas(render_layer)
{
    if (with_main_screen)
    {
        // Create a 3D viewport behind everything, to serve as the right-side
        // panel if the aspect ratio is wide enough.
        viewport = new GuiViewportMainScreen(this, "3D_VIEW");
        viewport
            ->showCallsigns()
            ->showHeadings()
            ->showSpacedust()
            ->setPosition(1200.0f, 0.0f, sp::Alignment::TopLeft)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
            ->hide();
    }

    main_panel = new GuiElement(this, "MAIN");
    main_panel->setSize(1200.0f, GuiElement::GuiSizeMax);

    select_station_button = new GuiButton(main_panel, "", "",
        [this]()
        {
            button_strip->show();
        }
    );
    select_station_button
        ->setPosition(-20.0f, 20.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, BUTTON_HEIGHT);

    button_strip = new GuiPanel(main_panel, "");
    button_strip
        ->setPosition(-20.0f, 20.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, BUTTON_HEIGHT)
        ->hide();

    message_frame = new GuiPanel(main_panel, "");
    message_frame->setPosition(0, 0, sp::Alignment::TopCenter)->setSize(900, 230)->hide();

    message_text = new GuiScrollFormattedText(message_frame, "", "");
    message_text->setTextSize(20)->setPosition(20, 20, sp::Alignment::TopLeft)->setSize(900 - 40, 200 - 40);
    message_close_button = new GuiButton(message_frame, "", tr("button", "Close"), [this]() {
        if (auto csf = my_spaceship.getComponent<CustomShipFunctions>())
        {
            for(auto& f : csf->functions)
            {
                if (f.crew_positions.has(current_position) && f.type == CustomShipFunctions::Function::Type::Message)
                {
                    my_player_info->commandCustomFunction(f.name);
                    break;
                }
            }
        }
    });
    message_close_button->setTextSize(30)->setPosition(-20, -20, sp::Alignment::BottomRight)->setSize(300, 30);

    if (PreferencesManager::get("voice_chat_enabled", "1") == "1")
        hotkey_categories.push_back(tr("hotkey_menu", "Voice Chat"));
    keyboard_help = new GuiHotkeyHelpOverlay(this, hotkey_categories);

#ifndef __ANDROID__
    if (PreferencesManager::get("music_enabled") == "1")
    {
        threat_estimate = new ThreatLevelEstimate();
        threat_estimate->setCallbacks([]()
        {
            LOG(INFO) << "Switching to ambient music";
            soundManager->playMusicSet(findResources("music/ambient/*.ogg"));
        }, []() {
            LOG(INFO) << "Switching to combat music";
            soundManager->playMusicSet(findResources("music/combat/*.ogg"));
        });
    }
#endif

    // Initialize and play the impulse engine sound.
    impulse_sound = std::unique_ptr<ImpulseSound>( new ImpulseSound(PreferencesManager::get("impulse_sound_enabled", "2") == "1") );
    utility_beam_sound = std::unique_ptr<UtilityBeamSound>( new UtilityBeamSound() );
}

void CrewStationScreen::destroy()
{
    if (threat_estimate)
        threat_estimate->destroy();
    PObject::destroy();
}

GuiContainer* CrewStationScreen::getTabContainer()
{
    return main_panel;
}

void CrewStationScreen::addStationTab(GuiElement* element, CrewPosition position, string name, string icon)
{
    CrewTabInfo info;
    tileViewport();
    element->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    info.position = position;
    info.element = element;

    info.button = new GuiToggleButton(button_strip, "STATION_BUTTON_" + name, name, [this, element](bool value) {
        showTab(element);
        button_strip->hide();
    });
    info.button
        ->setIcon(icon)
        ->setPosition(0.0f, tabs.size() * BUTTON_HEIGHT, sp::Alignment::TopLeft)
        ->setSize(GuiElement::GuiSizeMax, BUTTON_HEIGHT);

    if (tabs.size() == 0)
    {
        current_position = position;
        element->show();
        info.button->setValue(true);
        select_station_button
            ->setText(name)
            ->setIcon(icon);

        keyboard_help->addCategory(getCrewPositionName(position));
    }
    else
    {
        element->hide();
        info.button->setValue(false);
    }

    tabs.push_back(info);
}

void CrewStationScreen::finishCreation()
{
    select_station_button->moveToFront();
    button_strip->moveToFront();

    // Show Help and Exit buttons in screen selection button strip if
    // touchscreen mode is enabled.
    if (PreferencesManager::get("touchscreen").toInt() == 1)
    {
        int extra_buttons = 1;
        if (PreferencesManager::get("autoconnect") == "")
            extra_buttons++;

        (new GuiButton(button_strip, "HELP_BUTTON", tr("button", "Help"),
            [this]()
            {
                button_strip->hide();
                keyboard_help->frame->setVisible(true);
            }
        ))->setPosition(0.0f, tabs.size() * BUTTON_HEIGHT, sp::Alignment::TopLeft)
            ->setSize(GuiElement::GuiSizeMax, BUTTON_HEIGHT);

        // If we're using autoconnect, don't show an exit button.
        if (PreferencesManager::get("autoconnect") == "")
        {
            (new GuiButton(button_strip, "EXIT_BUTTON", tr("button", "Exit to ship selection"),
                [this]()
                {
                    destroy();
                    soundManager->stopMusic();
                    impulse_sound->stop();
                    returnToShipSelection(getRenderLayer());
                }))->setPosition(0.0f, static_cast<float>((tabs.size() + 1)) * BUTTON_HEIGHT, sp::Alignment::TopLeft)
                    ->setSize(GuiElement::GuiSizeMax, BUTTON_HEIGHT);
        }

        button_strip->setSize(button_strip->getSize().x, BUTTON_HEIGHT * (tabs.size() + extra_buttons));
    }
    else
        button_strip->setSize(button_strip->getSize().x, BUTTON_HEIGHT * tabs.size());

    message_frame->moveToFront();

    // Init overlays.
    new GuiIndicatorOverlays(main_panel);
    new GuiNoiseOverlay(main_panel);
    new GuiShipDestroyedPopup(this);

    // Hide the screen selection button menu if we're not in touchscreen mode
    // and have fewer than two tabs.
    if (tabs.size() < 2 && PreferencesManager::get("touchscreen").toInt() != 1)
        select_station_button->hide();

    keyboard_help->moveToFront();
}

void CrewStationScreen::update(float delta)
{
    // Destroy the screen on disconnect.
    if (game_client && game_client->getStatus() == GameClient::Disconnected)
    {
        destroy();
        soundManager->stopMusic();
        impulse_sound->stop();
        disconnectFromServer();
        returnToMainMenu(getRenderLayer());
        return;
    }

    // If we're using autoconnect, do nothing on escape. Otherwise, go back to
    // ship selection. 
    if (keys.escape.getDown() && PreferencesManager::get("autoconnect") == "")
    {
        destroy();
        soundManager->stopMusic();
        impulse_sound->stop();
        returnToShipSelection(getRenderLayer());
    }

    // Toggle keyboard help.
    if (keys.help.getDown())
        keyboard_help->frame->setVisible(!keyboard_help->frame->isVisible());

    // On the server, toggle pause.
    if (keys.pause.getDown())
    {
        if (game_server && !gameGlobalInfo->getVictoryFaction())
            engine->setGameSpeed(engine->getGameSpeed() > 0.0f ? 0.0f : 1.0f);
    }

    // Responsively show the 3D viewport if the aspect ratio is wide enough.
    if (viewport)
    {
        if (getRect().size.x < 1250)
        {
            viewport->hide();
            main_panel->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
        }
        else
        {
            viewport->show();
            tileViewport();
        }
    }
    else
        main_panel->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Show custom ship function messages if present.
    message_frame->hide();
    if (auto csf = my_spaceship.getComponent<CustomShipFunctions>())
    {
        for (auto& f : csf->functions)
        {
            if (f.crew_positions.has(current_position) && f.type == CustomShipFunctions::Function::Type::Message)
            {
                message_frame->show();
                message_text->setText(f.caption);
                break;
            }
        }
    }

    // Update the impulse engine sound. If we're not the player ship (i.e. we
    // exploded), stop playing the impulse engine sound.
    if (my_spaceship) impulse_sound->update(delta);
    else impulse_sound->stop();

    utility_beam_sound->update(delta);

    // Navigate between stations via keybinds.
    if (keys.next_station.getDown())
        showNextTab(1);
    else if (keys.prev_station.getDown())
        showNextTab(-1);
    else if (keys.station_helms.getDown())
        showTab(findTab(getCrewPositionName(CrewPosition::helmsOfficer)));
    else if (keys.station_weapons.getDown())
        showTab(findTab(getCrewPositionName(CrewPosition::weaponsOfficer)));
    else if (keys.station_engineering.getDown())
        showTab(findTab(getCrewPositionName(CrewPosition::engineering)));
    else if (keys.station_science.getDown())
        showTab(findTab(getCrewPositionName(CrewPosition::scienceOfficer)));
    else if (keys.station_relay.getDown())
        showTab(findTab(getCrewPositionName(CrewPosition::relayOfficer)));
}

void CrewStationScreen::showNextTab(int offset)
{
    if (tabs.size() < 1) return;
    int current = 0;

    for (unsigned int n = 0; n < tabs.size(); n++)
        if (tabs[n].element->isVisible()) current = n;

    int next = (current + offset + tabs.size()) % tabs.size();

    showTab(tabs[next].element);
}

void CrewStationScreen::showTab(GuiElement* element)
{
    if (!element) return;

    for (CrewTabInfo& info : tabs)
    {
        // If this is the selected tab, update its shared elements.
        if (info.element == element)
        {
            current_position = info.position;
            info.element->show();
            info.button->setValue(true);
            select_station_button->setText(info.button->getText());
            select_station_button->setIcon(info.button->getIcon());

            std::vector<string> categories = hotkey_categories;
            categories.push_back(getCrewPositionName(current_position));
            keyboard_help->setCategories(categories);

            // Explicitly reset focus after switching tabs, such as when changed
            // via hotkey.
            focus(main_panel);
        }
        else 
        {
            info.element->hide();
            info.button->setValue(false);
        }
    }
}

GuiElement* CrewStationScreen::findTab(string name)
{
    // Return the tab element that matches the string.
    for (CrewTabInfo& info : tabs)
        if (info.button->getText() == name) return info.element;

    return nullptr;
}

void CrewStationScreen::tileViewport()
{
    if (!viewport) return;

    // Render the 3D viewport on the right side. The controls should use at most
    // 1,200 virtual px (1,000 on SinglePilot or DroneOperations), the viewport
    // takes the rest.
    if (current_position == CrewPosition::singlePilot || current_position == CrewPosition::droneOperations)
    {
        main_panel->setSize(1000.0f, GuiElement::GuiSizeMax);
        main_panel->getLayout().fill_width = false;
        viewport->setPosition(1000.0f, 0.0f, sp::Alignment::TopLeft);
    }
    else
    {
        main_panel->setSize(1200.0f, GuiElement::GuiSizeMax);
        main_panel->getLayout().fill_width = false;
        viewport->setPosition(1200.0f, 0.0f, sp::Alignment::TopLeft);
    }
}

void CrewStationScreen::setDroneViewport(sp::ecs::Entity drone)
{
    if (viewport)
        viewport->override_entity = drone;
}

void CrewStationScreen::clearDroneViewport()
{
    if (viewport)
        viewport->override_entity = sp::ecs::Entity{};
}
