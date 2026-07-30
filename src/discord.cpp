#include "discord.h"
#include <discord_game_sdk.h>
#ifdef interface
#undef interface
#endif
#ifdef TRANSPARENT
#undef TRANSPARENT
#endif
#include "playerInfo.h"
#include "gameGlobalInfo.h"

#include "components/name.h"

static IDiscordCore* core;
static IDiscordActivityManager* activityManager;
static IDiscordCoreEvents events;

static DiscordActivity previousActivity;

DiscordRichPresence::DiscordRichPresence(const std::filesystem::path& discord_sdk)
    :discord{DynamicLibrary::open(discord_sdk)}
{
    if (!discord)
    {
        LOG(Warning, "[discord] Failed to initialize Discord. Not using rich presence.");
        return;
    }

    auto discord_create = discord->getFunction<decltype(&DiscordCreate)>("DiscordCreate");

    if (!discord_create)
    {
        LOG(Warning, "[discord] Failed to load Discord factory function. Not using rich presence.");
        return;
    }

    DiscordCreateParams params;
    params.client_id = 697525001603252304;
    params.flags = DiscordCreateFlags_NoRequireDiscord;
    params.events = &events;
    params.event_data = nullptr;

    if (discord_create(DISCORD_VERSION, &params, &core) != DiscordResult_Ok)
    {
        LOG(Warning, "[discord] Discord not installed or not running. Not using rich presence.");
        return;
    }

    activityManager = core->get_activity_manager(core);
}

DiscordRichPresence::~DiscordRichPresence() = default;

void DiscordRichPresence::update(float delta)
{
    if (!core) return;

    core->run_callbacks(core);

    if (updateDelay >= 0.0f) updateDelay -= delta;
    if (updateDelay >= 0.0f) return;

    DiscordActivity activity;
    memset(&activity, 0, sizeof(activity));
    strcpy(activity.assets.large_image, "logo");

    if (my_spaceship && my_player_info)
    {
        string name;
        if (auto callsign = my_spaceship.getComponent<CallSign>())
            name = callsign->callsign;
        if (auto type_name = my_spaceship.getComponent<TypeName>())
            name += " [" + type_name->type_name + "]";
        strncpy(activity.details, name.c_str(), sizeof(activity.details));

        for (int idx = 0; idx < static_cast<int>(CrewPosition::MAX); idx++)
        {
            auto cp = CrewPosition(idx);
            if (my_player_info->hasPosition(cp))
            {
                strncpy(activity.state, getCrewPositionName(cp).c_str(), sizeof(activity.state));
                if (cp == CrewPosition::helmsOfficer)
                    strcpy(activity.assets.small_image, "helms_white");
                if (cp == CrewPosition::weaponsOfficer)
                    strcpy(activity.assets.small_image, "weapons_white");
                if (cp == CrewPosition::engineering)
                    strcpy(activity.assets.small_image, "engineering_white");
                if (cp == CrewPosition::scienceOfficer)
                    strcpy(activity.assets.small_image, "science_white");
                if (cp == CrewPosition::relayOfficer)
                    strcpy(activity.assets.small_image, "relay_white");
                break;
            }
        }

        if (my_player_info->isOnlyMainScreen(0))
        {
            strncpy(activity.state, "Captain", sizeof(activity.state));
            strcpy(activity.assets.small_image, "captain_white");
        }
    }

    if (memcmp(&activity, &previousActivity, sizeof(activity)) != 0)
    {
        activityManager->update_activity(activityManager, &activity, nullptr, nullptr);
        previousActivity = activity;
        updateDelay = 4.0f;
    }
}
