#pragma once

#include "gui2_element.h"
#include "timer.h"

// GuiTooltip is a layout container that renders on top of all other elements.
// It appears after its watched element has been hovered or pressed for 500ms,
// and hides when the interaction ends.
//
// Usage is similar to any GuiElement used as a layout container:
//
// GuiTooltip* tip = new GuiTooltip(some_button, "TOOLTIP");
// tip->setSize(280.0f, 120.0f);
// GuiPanel* panel = new GuiPanel(tip, "");
// panel
//     ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
//     ->setAttribute("padding", "10");
// (new GuiLabel(panel, "", tr("Description text"), 20.0f))
//     ->setWrapped()
//     ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
class GuiTooltip : public GuiElement
{
public:
    GuiTooltip(GuiElement* watched, string id);
    virtual ~GuiTooltip();

    virtual void onUpdate() override;

    GuiTooltip* setPixelOffset(glm::vec2 offset);

private:
    // Invisible element in the watched element's subtree, to null the tooltip's
    // watched pointer and trigger self-destruction when the watched element's
    // tree is torn down.
    struct Anchor : public GuiElement
    {
        GuiTooltip* tooltip;
        Anchor(GuiElement* watched, GuiTooltip* tooltip);
        virtual ~Anchor();
    };

    // The parent element being watched for the triggering event.
    GuiElement* watched;
    // A placeholder element used to handle the parent element's teardown.
    Anchor* anchor = nullptr;
    // The timer to reveal the tooltip.
    sp::SystemTimer timer;
    // True if the tooltip should be visible.
    bool showing = false;
    // A virtual-pixel offset from the cursor position for spawning the tooltip.
    glm::vec2 pixel_offset{0.0f, 20.0f};

    // Called by Anchor::~Anchor() when the watched element's tree is destroyed.
    void anchorDestroyed();
};
