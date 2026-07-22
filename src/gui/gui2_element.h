#pragma once

#include <functional>
#include "stringImproved.h"
#include "hotkeyConfig.h"
#include "gui2_container.h"
#include "gui/layout/layout.h"
#include "graphics/font.h"
#include "graphics/renderTarget.h"
#include "io/textinput.h"

class GuiCanvas;

class GuiElement : public GuiContainer
{
private:
    bool destroyed = false;
    bool pressed = false;
protected:
    GuiContainer* owner;
    GuiCanvas* root_canvas = nullptr;
    bool visible = true;
    bool enabled = true;
    bool hover = false;
    glm::vec2 hover_coordinates;
    bool focus = false;
    bool intercepts_pointer = false;
    string id;
public:
    constexpr static float GuiSizeMatchHeight = -1.0f;
    constexpr static float GuiSizeMatchWidth = -1.0f;
    constexpr static float GuiSizeMax = -2.0f;
    constexpr static float GuiSizeRow = 50.0f;
    constexpr static float GuiSizeLabel = 30.0f;
    constexpr static float GuiSizePad = 20.0f;

    enum class State
    {
        Normal,
        Disabled,
        Hover,
        Focus,
        COUNT
    };

    GuiElement(GuiContainer* owner, const string& id);
    virtual ~GuiElement();

    virtual void onUpdate() {}
    virtual void onDraw(sp::RenderTarget& renderer) {}
    virtual bool onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id);
    virtual void onMouseDrag(glm::vec2 position, sp::io::Pointer::ID id);
    virtual void onMouseUp(glm::vec2 position, sp::io::Pointer::ID id);
    virtual bool onMouseWheelScroll(glm::vec2 position, float value);
    virtual void onPinch(float scale) {}
    virtual void onTextInput(const string& text);
    virtual void onTextInput(sp::TextInputEvent e);
    virtual void onFocusGained() {}
    virtual void onFocusLost() {}

    virtual bool setAttribute(const string& key, const string& value) override;
    GuiElement* setSize(glm::vec2 size);
    GuiElement* setSize(float x, float y);
    glm::vec2 getSize() const;
    float getAspectRatio() const;
    GuiElement* setMargins(float n);
    GuiElement* setMargins(float x, float y);
    GuiElement* setMargins(float left, float top, float right, float bottom);
    GuiElement* setPosition(float x, float y, sp::Alignment alignment = sp::Alignment::TopLeft);
    GuiElement* setPosition(glm::vec2 position, sp::Alignment alignment = sp::Alignment::TopLeft);
    glm::vec2 getPositionOffset() const;
    GuiElement* setVisible(bool visible);
    GuiElement* hide();
    GuiElement* show();
    bool isVisible() const;
    bool isEffectivelyVisible() const;
    GuiElement* setEnable(bool enable);
    GuiElement* enable();
    GuiElement* disable();
    bool isEnabled() const;
    bool hasFocus() const { return focus; }

    void moveToFront();
    void moveToBack();

    glm::vec2 getCenterPoint() const;

    GuiContainer* getOwner();
    GuiContainer* getTopLevelContainer();
    GuiCanvas* getRootCanvas() const { return root_canvas; }
    const string& getID() { return id; }

    // Change this element's owner/container safely (removes from old owner and
    // adds to new owner)
    GuiElement* setParent(GuiContainer* new_owner);
    // Return if the element has cursor hover state.
    bool isHovered() const { return hover; }
    void setHover(bool has_hover) { hover = has_hover; }
    // Return if the element has pressed (click/tap and hold) state.
    bool isPressed() const { return pressed; }
    void setFocus(bool has_focus) { focus = has_focus; }

    // Flag this GuiElement for destruction at a safe point and time, handled by
    // the container.
    void destroy();

    bool isDestroyed();

    friend class GuiContainer;
    friend class GuiCanvas;

protected:
    State getState() const;
};
