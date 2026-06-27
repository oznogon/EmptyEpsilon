#pragma once

#include "Updatable.h"
#include "dynamicLibrary.h"

class DiscordRichPresence : public Updatable
{
public:
    explicit DiscordRichPresence(const std::filesystem::path& discord_sdk);
    ~DiscordRichPresence();

    void update(float delta) override;

private:
    float updateDelay = 0.0f;
    std::unique_ptr<DynamicLibrary> discord;
};
