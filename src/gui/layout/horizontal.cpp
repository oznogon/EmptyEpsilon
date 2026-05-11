#include <gui/layout/horizontal.h>
#include <gui/gui2_element.h>
#include <logging.h>


void GuiLayoutHorizontal::update(GuiContainer& container, const sp::Rect& rect)
{
    float total_width = 0.0f;
    float fill_width = 0.0f;
    for(auto& w_ptr : container.getChildren())
    {
        GuiElement* w = w_ptr.get();
        if (w->isDestroyed() || !w->isVisible())
            continue;
        float width = w->getLayout().size.x + w->getLayout().margin.left + w->getLayout().margin.right;
        total_width += width;
        if (w->getLayout().fill_width)
            fill_width += w->getLayout().size.x;
    }
    float remaining_width = rect.size.x - total_width;
    float x = rect.position.x;
    for(auto& w_ptr : container.getChildren())
    {
        GuiElement* w = w_ptr.get();
        if (w->isDestroyed() || !w->isVisible())
            continue;
        float width = w->getLayout().size.x + w->getLayout().margin.left + w->getLayout().margin.right;
        if (w->getLayout().fill_width && fill_width > 0.0f)
            width += remaining_width * w->getLayout().size.x / fill_width;
        basicLayout({x, rect.position.y, width, rect.size.y}, *w);
        x = w->getRect().position.x + w->getRect().size.x + w->getLayout().margin.right;
    }
}

void GuiLayoutHorizontalRight::update(GuiContainer& container, const sp::Rect& rect)
{
    float total_width = 0.0f;
    float fill_width = 0.0f;
    for(auto& w_ptr : container.getChildren())
    {
        GuiElement* w = w_ptr.get();
        if (w->isDestroyed() || !w->isVisible())
            continue;
        float width = w->getLayout().size.x + w->getLayout().margin.left + w->getLayout().margin.right;
        total_width += width;
        if (w->getLayout().fill_width)
            fill_width += w->getLayout().size.x;
    }
    float remaining_width = rect.size.x - total_width;
    float x = rect.position.x + rect.size.x;
    for(auto& w_ptr : container.getChildren())
    {
        GuiElement* w = w_ptr.get();
        if (w->isDestroyed() || !w->isVisible())
            continue;
        float width = w->getLayout().size.x + w->getLayout().margin.left + w->getLayout().margin.right;
        if (w->getLayout().fill_width && fill_width > 0.0f)
            width += remaining_width * w->getLayout().size.x / fill_width;
        basicLayout({x - width, rect.position.y, width, rect.size.y}, *w);
        x = w->getRect().position.x - w->getLayout().margin.left;
    }
}
