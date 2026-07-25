#include "serverBrowseMenu.h"
#include <i18n.h>
#include "main.h"
#include "joinServerMenu.h"
#include "multiplayer_server_scanner.h"
#include "preferenceManager.h"
#include "config.h"

#include "gui/theme.h"
#include "gui/gui2_overlay.h"
#include "gui/gui2_button.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_textentry.h"
#include "gui/gui2_label.h"
#include "gui/gui2_listbox.h"
#include "gui/gui2_tooltip.h"

namespace
{
    const string disconnectErrorMessage(GameClient::DisconnectReason reason)
    {
        switch (reason)
        {
        case GameClient::DisconnectReason::None:
            return tr("game_client_disconnect_reason", "still connected");
        case GameClient::DisconnectReason::FailedToConnect:
            return tr("game_client_disconnect_reason", "failed to connect to server");
        case GameClient::DisconnectReason::BadCredentials:
            return tr("game_client_disconnect_reason", "bad credentials");
        case GameClient::DisconnectReason::ClosedByServer:
            return tr("game_client_disconnect_reason", "closed by server");
        case GameClient::DisconnectReason::TimedOut:
            return tr("game_client_disconnect_reason", "timed out");
        case GameClient::DisconnectReason::Unknown:
            return tr("game_client_disconnect_reason", "unknown");
        case GameClient::DisconnectReason::VersionMismatch:
            return tr("game_client_disconnect_reason", "version mismatch");
        default:
            return tr("game_client_disconnect_reason", "unspecified error {error}").format({ {"error", string{static_cast<int>(reason)}} });
        }
    }
}

ServerBrowserMenu::ServerBrowserMenu(std::optional<GameClient::DisconnectReason> last_attempt /* = {} */)
{
    scanner = new ServerScanner(VERSION_NUMBER);
    scanner->scanLocalNetwork();
    scanner->scanMasterServer(PreferencesManager::get("registry_list_url", "http://daid.eu/ee/list.php"));

    // Draw background elements.
    new GuiOverlay(this, "", GuiTheme::getColor("background"));
    (new GuiOverlay(this, "", glm::u8vec4{255, 255, 255, 255}))
        ->setTextureTiledThemed("background.crosses");

    (new GuiLabel(this, "HEADER", tr("title", "Join game"), GuiElement::GuiSizeLabel))
        ->addBackground()
        ->setPosition(50.0f, 50.0f, sp::Alignment::TopLeft)
        ->setSize(250.0f, GuiElement::GuiSizeRow);

    auto back_button = new GuiButton(this, "BACK", tr("button", "Back"),
        [this]()
        {
            destroy();
            returnToMainMenu(getRenderLayer());
        }
    );
    back_button
        ->setPosition(50.0f, -50.0f, sp::Alignment::BottomLeft)
        ->setSize(250.0f, GuiElement::GuiSizeRow);

    (new GuiTextTooltip(back_button, "BACK_TIP", tr("tooltips", "Return to the main menu."), 20.0f))->setWidth(280.0f);

    if (last_attempt)
    {
        auto error_message = tr("Connection error: {message}").format({
            {"message", disconnectErrorMessage(*last_attempt)}
        });

        auto error_info = new GuiLabel(this, "LAST_ATTEMPT_ERROR_MESSAGE", error_message, GuiElement::GuiSizeLabel);
        error_info->setPosition(0.0f, -80.0f, sp::Alignment::BottomCenter);
    }

    connect_button = new GuiButton(this, "CONNECT", tr("button", "Connect to server"),
        [this]()
        {
            if (selected_server)
                connect(selected_server.value());
            else
                connect(manual_ip->getText());
        }
    );
    connect_button
        ->setPosition(-50.0f, -50.0f, sp::Alignment::BottomRight)
        ->setSize(250.0f, GuiElement::GuiSizeRow);
    (new GuiTextTooltip(connect_button, "CONNECT_TIP", tr("tooltips", "Connect to the EmptyEpsilon server at this address."), 20.0f))->setWidth(280.0f);

    manual_ip = new GuiTextEntry(this, "IP", "");
    manual_ip
        ->enterCallback(
            [this](string text)
            {
                connect(text);
            }
        )
        ->callback(
            [this](string text)
            {
                selected_server.reset();
            }
        )
        ->setPosition(-50.0f, -120.0f, sp::Alignment::BottomRight)
        ->setSize(250.0f, GuiElement::GuiSizeRow);
    (new GuiTextTooltip(manual_ip, "MANUAL_IP_TIP", tr("tooltips", "Enter the server's IP address or domain. If it uses a custom port, add a colon (:) and then the port number at the end."), 20.0f))->setWidth(280.0f);

    server_list_box = new GuiListbox(this, "SERVERS",
        [this](int index, string value)
        {
            if (value == "last_server")
            {
                manual_ip->setText(PreferencesManager::get("last_server", ""));
                selected_server.reset();
            }
            else
            {
                selected_server = server_list[value.toInt()];
                manual_ip->setText(selected_server.value().address.getHumanReadable()[0]);
            }
        }
    );
    server_list_box
        ->setPosition(0.0f, 120.0f, sp::Alignment::TopCenter)
        ->setSize(700.0f, 500.0f);

    scanner
        ->addCallbacks(
            // New server found
            [this](const ServerScanner::ServerInfo& info)
            {
                if (info.address.getHumanReadable().empty()) return;

                server_list.push_back(info);
                updateServerList();

                if (manual_ip->getText() == "")
                    manual_ip->setText(info.address.getHumanReadable()[0]);
            },
            // Server removed from list
            [this](const ServerScanner::ServerInfo& info)
            {
                if (info.address.getHumanReadable().empty()) return;

                server_list.erase(std::remove_if(
                    server_list.begin(),
                    server_list.end(),
                    [&info](const ServerScanner::ServerInfo& entry)
                    {
                        return info.type == entry.type && info.address == entry.address && info.port == entry.port;
                    }
                ), server_list.end());
            }
        );

    updateServerList();
}

void ServerBrowserMenu::updateServerList()
{
    server_list_box->setOptions({});

    // Show previous server, if known.
    if (PreferencesManager::get("last_server", "") != "")
    {
        server_list_box->addEntry(tr("Previous session: ({last})").format({
            {"last", PreferencesManager::get("last_server", "")}
        }), "last_server");
    }

    // Sort server list by type, then by server name, and finally by IP address
    // (prefering short addresses first)
    std::stable_sort(
        server_list.begin(),
        server_list.end(),
        [](const auto& a, const auto& b)
        {
            if (a.type == b.type && a.name == b.name)
            {
                auto aa = a.address.getHumanReadable()[0];
                auto ba = b.address.getHumanReadable()[0];

                if (aa.size() == ba.size()) return aa < ba;
                return aa.size() < ba.size();
            }

            if (a.type == b.type) return a.name < b.name;
            return a.type < b.type;
        }
    );

    for (int idx = 0; idx < static_cast<int>(server_list.size()); idx++)
    {
        const auto& entry = server_list[idx];
        auto label = entry.name + " (" + entry.address.getHumanReadable()[0] + ")";

        switch (entry.type)
        {
        case ServerScanner::ServerType::Manual:
            break;
        case ServerScanner::ServerType::LAN:
            label = tr("server_type", "LAN: ") + label;
            break;
        case ServerScanner::ServerType::MasterServer:
            label = tr("server_type", "Internet: ") + label;
            break;
        case ServerScanner::ServerType::SteamFriend:
            label = tr("server_type", "Steam: ") + entry.name;
            break;
        }

        server_list_box->addEntry(label, string(idx));
    }
}

ServerBrowserMenu::~ServerBrowserMenu()
{
    scanner->destroy();
}

void ServerBrowserMenu::connect(string host)
{
    host = host.strip();
    uint64_t port = DEFAULT_SERVER_PORT;

    if (host.find(":") != -1)
    {
        port = host.substr(host.find(":") + 1).toInt64();
        host = host.substr(0, host.find(":"));
    }

    ServerScanner::ServerInfo info;
    info.type = ServerScanner::ServerType::Manual;
    info.name = host;
    info.port = port;
    info.address = sp::io::network::Address(host);
    connect(info);
}

void ServerBrowserMenu::connect(const ServerScanner::ServerInfo& info)
{
    new JoinServerScreen(info);
    destroy();
}
