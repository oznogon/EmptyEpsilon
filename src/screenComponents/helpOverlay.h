#ifndef HELP_OVERLAY_H
#define HELP_OVERLAY_H

#include "gui/gui2_element.h"

class GuiCanvas;
class GuiPanel;
class GuiScrollText;
class GuiToggleButton;

class GuiHelpOverlay : public GuiElement
{
private:
    GuiScrollText* text;

    string help_text = "";
public:
    GuiHelpOverlay(GuiContainer* owner, string title = "", string contents = "");
    GuiPanel* frame;
    GuiToggleButton* radar_lock_toggle;

    virtual void setText(string new_text);
    virtual void onDraw(sp::RenderTarget& target) override;
};

#endif//HELP_OVERLAY_H
