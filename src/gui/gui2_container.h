#pragma once

#include <vector>
#include <memory>
#include "rect.h"
#include "nonCopyable.h"
#include "stringImproved.h"
#include "io/pointer.h"
#include "graphics/alignment.h"
#include "gui/layout/layout.h"

namespace sp {
    class RenderTarget;
}

class GuiElement;
class GuiTheme;

class GuiContainer : sp::NonCopyable
{
public:
    // Nested type to capture layout attributes
    class LayoutInfo
    {
    public:
        class Sides
        {
        public:
            float left = 0.0f;
            float right = 0.0f;
            float top = 0.0f;
            float bottom = 0.0f;
        };

        glm::vec2 position{0.0f, 0.0f};
        sp::Alignment alignment = sp::Alignment::TopLeft;
        glm::vec2 size{1.0f, 1.0f};
        glm::ivec2 span{1, 1};
        Sides margin;
        Sides padding;
        bool fill_width = false;
        bool fill_height = false;
        bool lock_aspect_ratio = false;
        // Defaulting to true means containers auto-size to fit their children
        // unless explicitly given a fixed size. Callers setting layout.size
        // directly should also set this to false.
        bool match_content_x = true;
        bool match_content_y = true;
    };

    GuiContainer() = default;
    virtual ~GuiContainer();

    // Public interfaces
    template<typename T> void setLayout() { layout_manager = std::make_unique<T>(); }
    virtual void updateLayout(const sp::Rect& bounds);
    virtual bool setAttribute(const string& key, const string& value);
    const sp::Rect& getRect() const { return rect; }
    const std::vector<std::unique_ptr<GuiElement>>& getChildren() const { return children; }
    size_t getChildCount() const { return children.size(); }

    LayoutInfo& getLayout() { return layout; }
    const LayoutInfo& getLayout() const { return layout; }

protected:
    LayoutInfo layout;
    std::vector<std::unique_ptr<GuiElement>> children;

protected:
    GuiTheme* theme;

    // Protected data
    sp::Rect rect{0,0,0,0};
    std::unique_ptr<GuiLayout> layout_manager = nullptr;

    virtual void cleanTree();

    template<typename RecurseFunc, typename TestFunc>
    GuiElement* dispatchToChildren(glm::vec2 position, RecurseFunc recurse, TestFunc test);

    friend class GuiElement;

public:
    virtual void drawElements(glm::vec2 mouse_position, GuiElement* hovered_element, sp::RenderTarget& window);
    virtual void drawDebugElements(sp::RenderTarget& window);
    virtual GuiElement* getClickElement(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id);
    virtual GuiElement* executeScrollOnElement(glm::vec2 position, float value);
    virtual GuiElement* getHoverElement(glm::vec2 mouse_position);
};
