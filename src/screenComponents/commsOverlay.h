#ifndef COMMS_OVERLAY_H
#define COMMS_OVERLAY_H

#include "gui/gui2_element.h"

class GuiElement;
class GuiPanel;
class GuiProgressbar;
class GuiButton;
class GuiLabel;
class GuiScrollText;
class GuiListbox;
class GuiTextEntry;
class GuiImage;

class GuiCommsOverlay : public GuiElement
{
private:
    GuiPanel* opening_box;
    GuiProgressbar* opening_progress;
    GuiButton* opening_cancel;

    GuiPanel* hailed_box;
    GuiLabel* hailed_label;
    GuiButton* hailed_answer;
    GuiButton* hailed_ignore;

    GuiPanel* no_response_box;
    GuiPanel* broken_box;
    GuiPanel* closed_box;

    GuiElement* chat_comms_box;
    GuiPanel* chat_comms_content;
    GuiElement* chat_comms_response;
    GuiPanel* chat_comms_context;

    GuiTextEntry* chat_comms_message_entry;
    GuiScrollText* chat_comms_text;
    GuiButton* chat_comms_send_button;
    GuiButton* chat_comms_close_button;
    GuiImage* chat_comms_image;
    GuiLabel* chat_comms_callsign;

    GuiElement* script_comms_box;
    GuiElement* script_comms_content;
    GuiElement* script_comms_context;

    GuiScrollText* script_comms_text;
    GuiListbox* script_comms_options;
    GuiButton* script_comms_close;
    GuiImage* script_comms_image;
    GuiLabel* script_comms_callsign;

    bool chat_open_last_update;
public:
    GuiCommsOverlay(GuiContainer* owner);

    virtual void onUpdate() override;
    void clearElements();
};

#endif//COMMS_OVERLAY_H
