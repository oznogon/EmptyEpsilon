#pragma once

#include "gui/gui2_resizabledialog.h"
#include "ecs/entity.h"

class GuiButton;
class GuiTextEntry;
class GuiScrollFormattedText;
class GuiRadarView;

class GameMasterChatDialog : public GuiResizableDialog
{
public:
    GameMasterChatDialog(GuiContainer* owner, GuiRadarView* radar, sp::ecs::Entity player);

    virtual void onDraw(sp::RenderTarget& target) override;

    sp::ecs::Entity player;
private:
    GuiRadarView* radar;

    bool notification;

    GuiTextEntry* text_entry;
    GuiScrollFormattedText* chat_text;
    GuiButton* use_comms_script;

    void disableComms(string title);

    void onClose() override;
};
