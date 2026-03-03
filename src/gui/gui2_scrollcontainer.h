#pragma once
#include "gui2_element.h"

class GuiScrollbar;

class GuiScrollContainer : public GuiElement
{
public:
    enum class OverflowMode { Clip, Scroll, Page };

    GuiScrollContainer(GuiContainer* owner, const string& id,
                       OverflowMode mode = OverflowMode::Scroll);

    GuiScrollContainer* setMode(OverflowMode mode);
    GuiScrollContainer* setScrollbarWidth(float width);
    void scrollToFraction(float fraction);

    virtual void onDraw(sp::RenderTarget& renderer) override;
    virtual void updateLayout(const sp::Rect& rect) override;
    virtual bool onMouseWheelScroll(glm::vec2 position, float value) override;
    virtual void onMouseDrag(glm::vec2 position, sp::io::Pointer::ID id) override;
    virtual void onMouseUp(glm::vec2 position, sp::io::Pointer::ID id) override;

protected:
    virtual void drawElements(glm::vec2 mouse_position, sp::Rect parent_rect,
                              sp::RenderTarget& renderer) override;
    virtual GuiElement* getClickElement(sp::io::Pointer::Button button,
                                        glm::vec2 position,
                                        sp::io::Pointer::ID id) override;
    virtual GuiElement* executeScrollOnElement(glm::vec2 position, float value) override;

private:
    OverflowMode mode;
    float scrollbar_width = 30.0f;
    GuiScrollbar* scrollbar_v = nullptr;

    float scroll_offset = 0.0f;
    float content_height = 0.0f;
    float visible_height = 0.0f;
    bool scrollbar_visible = false;

    GuiElement* pressed_element = nullptr;
    float pressed_scroll = 0.0f;

    sp::Rect getContentRect() const;
    float getEffectiveScrollbarWidth() const;
};
