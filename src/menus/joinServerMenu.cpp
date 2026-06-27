#include "main.h"
#include "epsilonServer.h"
#include "menus/joinServerMenu.h"
#include "menus/serverBrowseMenu.h"
#include "playerInfo.h"
#include "preferenceManager.h"
#include "gameGlobalInfo.h"
#include "i18n.h"
#include "config.h"
#include "gui/gui2_label.h"
#include "gui/gui2_panel.h"

#include "gui/gui2_textentry.h"
#include "gui/gui2_button.h"

JoinServerScreen::JoinServerScreen(const ServerScanner::ServerInfo& target)
: target(target)
{
    status_label = new GuiLabel(this, "STATUS", tr("connectserver", "Connecting..."), GuiElement::GuiSizeLabel);
    status_label
        ->setPosition(0.0f, 300.0f, sp::Alignment::TopCenter)
        ->setSize(0.0f, GuiElement::GuiSizeRow);

    (new GuiButton(this, "BTN_CANCEL", tr("button", "Cancel"),
        [this]()
        {
            destroy();
            disconnectFromServer();
            new ServerBrowserMenu();
        }
    ))
        ->setPosition(50.0f, -50.0f, sp::Alignment::BottomLeft)
        ->setSize(250.0f, GuiElement::GuiSizeRow);

    password_entry_box = new GuiPanel(this, "PASSWORD_ENTRY_BOX");
    password_entry_box
        ->setPosition(0.0f, 350.0f, sp::Alignment::TopCenter)
        ->setSize(600.0f, 100.0f)
        ->hide();

    password_entry = new GuiTextEntry(password_entry_box, "PASSWORD_ENTRY", "");
    password_entry
        ->setHidePassword()
        ->enterCallback(
            [this](string entry)
            {
                password_entry_box->hide();
                password_focused = false;
                game_client->sendPassword(entry.upper());
            }
        )
        ->setPosition(20.0f, 0.0f, sp::Alignment::CenterLeft)
        ->setSize(400.0f, GuiElement::GuiSizeRow);

    (new GuiButton(password_entry_box, "PASSWORD_ENTRY_OK", tr("OK"),
        [this]()
        {
            password_entry_box->hide();
            password_focused = false;
            game_client->sendPassword(password_entry->getText().upper());
        }
    ))
        ->setPosition(420.0f, 0.0f, sp::Alignment::CenterLeft)
        ->setSize(160.0f, GuiElement::GuiSizeRow);

    if (target.type == ServerScanner::ServerType::SteamFriend)
    {
#ifdef STEAMSDK
        new GameClient(VERSION_NUMBER, target.port);
#endif
    }
    else new GameClient(VERSION_NUMBER, target.address, target.port);
}

void JoinServerScreen::update(float delta)
{
    switch(game_client->getStatus())
    {
    case GameClient::Connecting:
    case GameClient::Authenticating:
        //If we are still trying to connect, do nothing.
        break;
    case GameClient::WaitingForPassword:
        status_label->setText(tr("Please enter the server password:"));
        password_entry_box->show();
        if (!password_focused)
        {
            password_focused = true;
            focus(password_entry);
        }
        break;
    case GameClient::Disconnected: {
        auto reason = game_client->getDisconnectReason();
        destroy();
        disconnectFromServer();
        
        new ServerBrowserMenu(reason);
        } break;
    case GameClient::Connected:
        if (!target.address.getHumanReadable().empty())
        {
            string last_server = target.address.getHumanReadable()[0];
            if (target.port != defaultServerPort)
                last_server += ":" + string(int(target.port));
            PreferencesManager::set("last_server", last_server);
        }
        if (game_client->getClientId() > 0)
        {
            foreach(PlayerInfo, i, player_info_list)
                if (i->client_id == game_client->getClientId())
                    my_player_info = i;
            if (my_player_info && gameGlobalInfo)
            {
                returnToShipSelection(getRenderLayer());
                destroy();
            }
        }
        break;
    }
}
