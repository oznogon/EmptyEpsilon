#include <gui/layout/layout.h>
#include <gui/gui2_element.h>
#include <logging.h>


GuiLayoutClassRegistry* GuiLayoutClassRegistry::first;

void GuiLayout::updateLoop(GuiContainer& container, const sp::Rect& rect)
{
    int repeat_counter = 10;
    do
    {
        require_repeat = false;
        update(container, rect);
        if (--repeat_counter < 1)
        {
            LOG(Warning, "Possible infinite loop in gui layout.");
            return;
        }
    } while(require_repeat);
}

void GuiLayout::update(GuiContainer& container, const sp::Rect& rect)
{
    for(auto& w_ptr : container.getChildren())
    {
        GuiElement* w = w_ptr.get();
        if (w->isDestroyed() || !w->isVisible()) {
            continue;
        }
        basicLayout(rect, *w);
    }
}

void GuiLayout::basicLayout(const sp::Rect& rect, GuiElement& widget)
{
    glm::vec2 result_position{};
    glm::vec2 result_size{};
    switch(widget.getLayout().alignment)
    {
    case sp::Alignment::TopLeft:
    case sp::Alignment::BottomLeft:
    case sp::Alignment::CenterLeft:
        result_position.x = rect.position.x + widget.getLayout().position.x + widget.getLayout().margin.left;
        if (widget.getLayout().fill_width)
            result_size.x = rect.size.x - widget.getLayout().margin.left - widget.getLayout().margin.right - widget.getLayout().position.x;
        else
            result_size.x = widget.getLayout().size.x;
        break;
    case sp::Alignment::TopCenter:
    case sp::Alignment::Center:
    case sp::Alignment::BottomCenter:
        if (widget.getLayout().fill_width)
            result_size.x = rect.size.x - widget.getLayout().margin.left - widget.getLayout().margin.right;
        else
            result_size.x = widget.getLayout().size.x;
        result_position.x = rect.position.x + rect.size.x / 2.0f - result_size.x / 2.0f + widget.getLayout().position.x;
        break;
    case sp::Alignment::TopRight:
    case sp::Alignment::CenterRight:
    case sp::Alignment::BottomRight:
        result_position.x = rect.position.x + widget.getLayout().position.x + widget.getLayout().margin.left;
        if (widget.getLayout().fill_width)
            result_size.x = rect.size.x - widget.getLayout().margin.left - widget.getLayout().margin.right + widget.getLayout().position.x;
        else
            result_size.x = widget.getLayout().size.x;
        result_position.x = rect.position.x + rect.size.x - widget.getLayout().margin.right + widget.getLayout().position.x - result_size.x;
        break;
    }

    switch(widget.getLayout().alignment)
    {
    case sp::Alignment::TopLeft:
    case sp::Alignment::TopCenter:
    case sp::Alignment::TopRight:
        result_position.y = rect.position.y + widget.getLayout().position.y + widget.getLayout().margin.top;
        if (widget.getLayout().fill_height)
            result_size.y = rect.size.y - widget.getLayout().margin.top - widget.getLayout().margin.bottom - widget.getLayout().position.y;
        else
            result_size.y = widget.getLayout().size.y;
        break;
    case sp::Alignment::CenterLeft:
    case sp::Alignment::Center:
    case sp::Alignment::CenterRight:
        if (widget.getLayout().fill_height)
            result_size.y = rect.size.y - widget.getLayout().margin.top - widget.getLayout().margin.bottom;
        else
            result_size.y = widget.getLayout().size.y;
        result_position.y = rect.position.y + rect.size.y / 2.0f - result_size.y / 2.0f + widget.getLayout().position.y;
        break;
    case sp::Alignment::BottomLeft:
    case sp::Alignment::BottomCenter:
    case sp::Alignment::BottomRight:
        result_position.y = rect.position.y + widget.getLayout().position.y + widget.getLayout().margin.top;
        if (widget.getLayout().fill_height)
            result_size.y = rect.size.y - widget.getLayout().margin.top - widget.getLayout().margin.bottom + widget.getLayout().position.y;
        else
            result_size.y = widget.getLayout().size.y;
        result_position.y = rect.position.y + rect.size.y - widget.getLayout().margin.bottom + widget.getLayout().position.y - result_size.y;
        break;
    }
    if (widget.getLayout().lock_aspect_ratio)
    {
        float aspect = widget.getLayout().size.x / widget.getLayout().size.y;
        if (widget.getLayout().fill_height && widget.getLayout().fill_width)
        {
            float current_aspect = result_size.x / result_size.y;
            if (current_aspect > aspect)
            {
                switch(widget.getLayout().alignment)
                {
                case sp::Alignment::TopLeft:
                case sp::Alignment::CenterLeft:
                case sp::Alignment::BottomLeft:
                    break;
                case sp::Alignment::TopCenter:
                case sp::Alignment::Center:
                case sp::Alignment::BottomCenter:
                    result_position.x += (result_size.x - result_size.y * aspect) * 0.5f;
                    break;
                case sp::Alignment::TopRight:
                case sp::Alignment::CenterRight:
                case sp::Alignment::BottomRight:
                    result_position.x += result_size.x - result_size.y * aspect;
                    break;
                }
                result_size.x = result_size.y * aspect;
            }
            else
            {
                switch(widget.getLayout().alignment)
                {
                case sp::Alignment::TopLeft:
                case sp::Alignment::TopCenter:
                case sp::Alignment::TopRight:
                    break;
                case sp::Alignment::CenterLeft:
                case sp::Alignment::Center:
                case sp::Alignment::CenterRight:
                    result_position.y += (result_size.y - result_size.x / aspect) * 0.5f;
                    break;
                case sp::Alignment::BottomLeft:
                case sp::Alignment::BottomCenter:
                case sp::Alignment::BottomRight:
                    result_position.y += result_size.y - result_size.x / aspect;
                    break;
                }
                result_size.y = result_size.x / aspect;
            }
        }
        else if (widget.getLayout().fill_height)
        {
            switch(widget.getLayout().alignment)
            {
            case sp::Alignment::TopLeft:
            case sp::Alignment::CenterLeft:
            case sp::Alignment::BottomLeft:
                break;
            case sp::Alignment::TopCenter:
            case sp::Alignment::Center:
            case sp::Alignment::BottomCenter:
                result_position.x += (result_size.x - result_size.y * aspect) * 0.5f;
                break;
            case sp::Alignment::TopRight:
            case sp::Alignment::CenterRight:
            case sp::Alignment::BottomRight:
                result_position.x += result_size.x - result_size.y * aspect;
                break;
            }
            result_size.x = result_size.y * aspect;
        }
        else if (widget.getLayout().fill_width)
        {
            switch(widget.getLayout().alignment)
            {
            case sp::Alignment::TopLeft:
            case sp::Alignment::TopCenter:
            case sp::Alignment::TopRight:
                break;
            case sp::Alignment::CenterLeft:
            case sp::Alignment::Center:
            case sp::Alignment::CenterRight:
                result_position.y += (result_size.y - result_size.x / aspect) * 0.5f;
                break;
            case sp::Alignment::BottomLeft:
            case sp::Alignment::BottomCenter:
            case sp::Alignment::BottomRight:
                result_position.y += result_size.y - result_size.x / aspect;
                break;
            }
            result_size.y = result_size.x / aspect;
        }
    }
    auto pre_layout_size = widget.getLayout().size;
    widget.updateLayout({result_position, result_size});

    auto size_diff = pre_layout_size - widget.getLayout().size;
    if (std::abs(size_diff.x) + std::abs(size_diff.y) > 0.1f)
    {
        require_repeat = true;
    }
}
