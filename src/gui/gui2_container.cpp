#include "gui2_container.h"
#include "gui2_element.h"
#include "gui2_canvas.h"

GuiContainer::~GuiContainer()
{
    for (auto& element_ptr : children)
    {
        GuiElement* element = element_ptr.get();
        element->owner = nullptr;
    }
    children.clear();
}

void GuiContainer::drawElements(glm::vec2 mouse_position, GuiElement* hovered_element, sp::RenderTarget& renderer)
{
    for (auto& element_ptr : children)
    {
        GuiElement* element = element_ptr.get();
        // Manage this element's hover state.
        element->hover = (element == hovered_element);
        element->hover_coordinates = (element == hovered_element) ? mouse_position : glm::vec2{-100, -100};

        // Draw the element.
        if (element->visible)
        {
            element->onDraw(renderer);
            element->drawElements(mouse_position, hovered_element, renderer);
        }
    }
}

void GuiContainer::drawDebugElements(sp::RenderTarget& renderer)
{
    for(auto& element_ptr : children)
    {
        GuiElement* element = element_ptr.get();
        if (element->visible)
        {
            renderer.fillRect(element->rect, glm::u8vec4(255, 255, 255, 5));
            renderer.drawRectOutline(element->rect, 1.0f, glm::u8vec4(255, 0, 255, 255));

            element->drawDebugElements(renderer);

            renderer.drawText(sp::Rect(element->rect.position.x, element->rect.position.y - 20, element->rect.size.x, 20), element->id, sp::Alignment::TopLeft, 20, nullptr, glm::u8vec4(255, 0, 0, 255));
        }
    }
}

GuiElement* GuiContainer::getClickElement(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    return dispatchToChildren(position,
        [&](GuiElement* element) { return element->getClickElement(button, position, id); },
        [&](GuiElement* element) { return element->onMouseDown(button, position, id); });
}

GuiElement* GuiContainer::executeScrollOnElement(glm::vec2 position, float value)
{
    return dispatchToChildren(position,
        [&](GuiElement* element) { return element->executeScrollOnElement(position, value); },
        [&](GuiElement* element) { return element->onMouseWheelScroll(position, value); });
}

GuiElement* GuiContainer::getHoverElement(glm::vec2 mouse_position)
{
    return dispatchToChildren(mouse_position,
        [&](GuiElement* element) { return element->getHoverElement(mouse_position); },
        [&](GuiElement* element) { return element->intercepts_pointer; });
}

void GuiContainer::cleanTree()
{
    for (size_t i = 0; i < children.size(); )
    {
        auto& element_ptr = children[i];
        GuiElement* element = element_ptr.get();
        if (element->destroyed)
        {
            // Find the owning canvas to clear focus/click references.
            if (GuiCanvas* canvas = element->getRootCanvas())
                canvas->unfocusElementTree(element);

            // Take ownership of the element to delete, then swap-and-pop.
            // We must move element_ptr out FIRST, because the swap-and-pop
            // assignment will destroy whatever is at children[i].
            std::unique_ptr<GuiElement> doomed = std::move(element_ptr);
            if (i + 1 < children.size())
            {
                children[i] = std::move(children.back());
            }
            children.pop_back();

            doomed->owner = nullptr;
            // doomed deleted here when it goes out of scope
        }
        else
        {
            element->cleanTree();
            ++i;
        }
    }
}

void GuiContainer::updateLayout(const sp::Rect& bounds)
{
    this->rect = bounds;

    if (layout_manager || !children.empty())
    {
        if (!layout_manager) layout_manager = std::make_unique<GuiLayout>();

        glm::vec2 padding_size(layout.padding.left + layout.padding.right, layout.padding.top + layout.padding.bottom);
        layout_manager->updateLoop(*this, sp::Rect(rect.position + glm::vec2{layout.padding.left, layout.padding.top}, rect.size - padding_size));
        if (layout.match_content_x || layout.match_content_y)
        {
            bool has_visible_child = false;
            glm::vec2 content_size_min;
            glm::vec2 content_size_max;

            for (auto& w : children)
            {
                if (w && w->isVisible())
                {
                    glm::vec2 p0 = w->rect.position;
                    glm::vec2 p1 = p0 + w->rect.size;
                    if (!has_visible_child)
                    {
                        content_size_min = {
                            p0.x - w->layout.margin.left,
                            p0.y - w->layout.margin.top
                        };
                        content_size_max = {
                            p1.x + w->layout.margin.right,
                            p1.y + w->layout.margin.bottom
                        };
                        has_visible_child = true;
                    }
                    else
                    {
                        content_size_min = {
                            std::min(content_size_min.x, p0.x - w->layout.margin.left),
                            std::min(content_size_min.y, p0.y - w->layout.margin.top)
                        };
                        content_size_max = {
                            std::max(content_size_max.x, p1.x + w->layout.margin.right),
                            std::max(content_size_max.y, p1.y + w->layout.margin.bottom)
                        };
                    }
                }
            }

            if (has_visible_child)
            {
                auto new_size = (content_size_max - content_size_min) + padding_size;
                if (layout.match_content_x) rect.size.x = new_size.x;
                if (layout.match_content_y) rect.size.y = new_size.y;
                layout.size = rect.size;
            }
        }
    }
}

static bool parseSides(const string& value, GuiContainer::LayoutInfo::Sides& sides)
{
    auto values = value.split(",", 3);
    if (values.size() == 1)
    {
        sides.top = sides.bottom = sides.left = sides.right = values[0].strip().toFloat();
    }
    else if (values.size() == 2)
    {
        sides.left = sides.right = values[0].strip().toFloat();
        sides.top = sides.bottom = values[1].strip().toFloat();
    }
    else if (values.size() == 3)
    {
        sides.left = sides.right = values[0].strip().toFloat();
        sides.top = values[1].strip().toFloat();
        sides.bottom = values[2].strip().toFloat();
    }
    else if (values.size() == 4)
    {
        sides.left = values[0].strip().toFloat();
        sides.right = values[1].strip().toFloat();
        sides.top = values[2].strip().toFloat();
        sides.bottom = values[3].strip().toFloat();
    }
    else
    {
        return false;
    }
    return true;
}

bool GuiContainer::setAttribute(const string& key, const string& value)
{
    if (key == "size")
    {
        auto p = value.partition(",");
        layout.size.x = p.first.strip().toFloat();
        layout.size.y = p.second.strip().toFloat();
        layout.match_content_x = false;
        layout.match_content_y = false;
        return true;
    }
    else if (key == "width")
    {
        layout.size.x = value.toFloat();
        layout.match_content_x = false;
        layout.match_content_y = false;
        return true;
    }
    else if (key == "height")
    {
        layout.size.y = value.toFloat();
        layout.match_content_x = false;
        layout.match_content_y = false;
        return true;
    }
    else if (key == "position")
    {
        auto p = value.partition(",");
        layout.position.x = p.first.strip().toFloat();
        layout.position.y = p.second.strip().toFloat();
        return true;
    }
    else if (key == "margin")
    {
        if (parseSides(value, layout.margin))
            return true;
    }
    else if (key == "padding")
    {
        if (parseSides(value, layout.padding))
            return true;
    }
    else if (key == "span")
    {
        auto p = value.partition(",");
        layout.span.x = p.first.strip().toInt();
        layout.span.y = p.second.strip().toInt();
        return true;
    }
    else if (key == "alignment")
    {
        string v = value.lower();
        if (v == "topleft" || v == "lefttop") layout.alignment = sp::Alignment::TopLeft;
        else if (v == "top" || v == "topcenter" || v == "centertop") layout.alignment = sp::Alignment::TopCenter;
        else if (v == "topright" || v == "righttop") layout.alignment = sp::Alignment::TopRight;
        else if (v == "left" || v == "leftcenter" || v == "centerleft") layout.alignment = sp::Alignment::CenterLeft;
        else if (v == "center") layout.alignment = sp::Alignment::Center;
        else if (v == "right" || v == "rightcenter" || v == "centerright") layout.alignment = sp::Alignment::CenterRight;
        else if (v == "bottomleft" || v == "leftbottom") layout.alignment = sp::Alignment::BottomLeft;
        else if (v == "bottom" || v == "bottomcenter" || v == "centerbottom") layout.alignment = sp::Alignment::BottomCenter;
        else if (v == "bottomright" || v == "rightbottom") layout.alignment = sp::Alignment::BottomRight;
        else LOG(Warning, "[guicontainer] Unknown alignment: ", value);
        return true;
    }
    else if (key == "layout")
    {
        GuiLayoutClassRegistry* reg;

        for (reg = GuiLayoutClassRegistry::first; reg != nullptr; reg = reg->next)
            if (value == reg->name) break;

        if (reg)
        {
            layout_manager = reg->creation_function();
            return true;
        }
        else
            LOG(Error, "[guicontainer] Failed to find layout type: ", value);
    }
    else if (key == "stretch")
    {
        if (value == "aspect")
            layout.fill_height = layout.fill_width = layout.lock_aspect_ratio = true;
        else
            layout.fill_height = layout.fill_width = value.toBool();

        layout.match_content_x = false;
        layout.match_content_y = false;
        return true;
    }
    else if (key == "fill_height")
    {
        layout.fill_height = value.toBool();
        layout.match_content_x = false;
        layout.match_content_y = false;
        return true;
    }
    else if (key == "fill_width")
    {
        layout.fill_width = value.toBool();
        layout.match_content_x = false;
        layout.match_content_y = false;
        return true;
    }
    else
        LOG(Warning, "[guicontainer] Tried to set unknown widget attribute: ", key, " to ", value);
    return false;
}

template<typename RecurseFunc, typename TestFunc>
GuiElement* GuiContainer::dispatchToChildren(glm::vec2 position, RecurseFunc recurse, TestFunc test)
{
    for (auto it = children.rbegin(); it != children.rend(); ++it)
    {
        GuiElement* element = it->get();
        if (element->visible && element->enabled && element->rect.contains(position))
        {
            GuiElement* result = recurse(element);
            if (result) return result;
            if (test(element)) return element;
        }
    }
    return nullptr;
}
