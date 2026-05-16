#include <gui/layout/vertical.h>
#include <gui/gui2_element.h>
#include <logging.h>


void GuiLayoutVertical::update(GuiContainer& container, const sp::Rect& rect)
{
    float total_height = 0.0f;
    float fill_height = 0.0f;
    for(auto& w_ptr : container.getChildren())
    {
        GuiElement* w = w_ptr.get();
        if (w->isDestroyed() || !w->isVisible())
            continue;
        float height = w->getLayout().size.y + w->getLayout().margin.top + w->getLayout().margin.bottom;
        total_height += height;
        if (w->getLayout().fill_height)
            fill_height += w->getLayout().size.y;
    }
    float remaining_height = rect.size.y - total_height;
    float y = rect.position.y;
    for(auto& w_ptr : container.getChildren())
    {
        GuiElement* w = w_ptr.get();
        if (w->isDestroyed() || !w->isVisible())
            continue;
        float height = w->getLayout().size.y + w->getLayout().margin.top + w->getLayout().margin.bottom;
        if (w->getLayout().fill_height && fill_height > 0.0f)
            height += remaining_height * w->getLayout().size.y / fill_height;
        basicLayout({rect.position.x, y, rect.size.x, height}, *w);
        y = w->getRect().position.y + w->getRect().size.y + w->getLayout().margin.bottom;
    }
}

void GuiLayoutVerticalBottom::update(GuiContainer& container, const sp::Rect& rect)
{
    float total_height = 0.0f;
    float fill_height = 0.0f;
    for(auto& w_ptr : container.getChildren())
    {
        GuiElement* w = w_ptr.get();
        if (w->isDestroyed() || !w->isVisible())
            continue;
        float height = w->getLayout().size.y + w->getLayout().margin.top + w->getLayout().margin.bottom;
        total_height += height;
        if (w->getLayout().fill_height)
            fill_height += w->getLayout().size.y;
    }
    float remaining_height = rect.size.y - total_height;
    float y = rect.position.y + rect.size.y;
    for(auto& w_ptr : container.getChildren())
    {
        GuiElement* w = w_ptr.get();
        if (w->isDestroyed() || !w->isVisible())
            continue;
        float height = w->getLayout().size.y + w->getLayout().margin.top + w->getLayout().margin.bottom;
        if (w->getLayout().fill_height && fill_height > 0.0f)
            height += remaining_height * w->getLayout().size.y / fill_height;
        basicLayout({rect.position.x, y - height, rect.size.x, height}, *w);
        y = w->getRect().position.y - w->getLayout().margin.top;
    }
}

void GuiLayoutVerticalCenter::update(GuiContainer& container, const sp::Rect& rect)
{
    float total_height = 0.0f;
    float fill_height = 0.0f;
    for(auto& w_ptr : container.getChildren())
    {
        GuiElement* w = w_ptr.get();
        if (w->isDestroyed() || !w->isVisible())
            continue;
        float height = w->getLayout().size.y + w->getLayout().margin.top + w->getLayout().margin.bottom;
        total_height += height;
        if (w->getLayout().fill_height)
            fill_height += w->getLayout().size.y;
    }
    float remaining_height = rect.size.y - total_height;
    float y = rect.position.y + remaining_height * 0.5f;
    for(auto& w_ptr : container.getChildren())
    {
        GuiElement* w = w_ptr.get();
        if (w->isDestroyed() || !w->isVisible())
            continue;
        float height = w->getLayout().size.y + w->getLayout().margin.top + w->getLayout().margin.bottom;
        if (w->getLayout().fill_height && fill_height > 0.0f)
            height += remaining_height * w->getLayout().size.y / fill_height;
        basicLayout({rect.position.x, y, rect.size.x, height}, *w);
        y = w->getRect().position.y + w->getRect().size.y + w->getLayout().margin.bottom;
    }
}
