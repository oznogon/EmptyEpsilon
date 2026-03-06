#include "gui2_arrowbutton.h"
#include "soundManager.h"
#include "theme.h"

#include "gui2_label.h"
#include "gui2_panel.h"
#include "gui2_selector.h"
#include "gui2_togglebutton.h"

GuiSelector::GuiSelector(GuiContainer* owner, string id, func_t func)
: GuiEntryList(owner, id, func)
{
    back_style = theme->getStyle("selector.back");
    front_style = theme->getStyle("selector.front");
    left = new GuiArrowButton(this, id + "_ARROW_LEFT", 0, [this]() {
        soundManager->playSound("sfx/button.wav");
        if (getSelectionIndex() <= 0)
            setSelectionIndex(entries.size() - 1);
        else
            setSelectionIndex(getSelectionIndex() - 1);
        callback();
    });
    left->setPosition(0, 0, sp::Alignment::TopLeft)->setSize(GuiSizeMatchHeight, GuiSizeMax);
    right = new GuiArrowButton(this, id + "_ARROW_RIGHT", 180, [this]() {
        soundManager->playSound("sfx/button.wav");
        if (getSelectionIndex() >= (int)entries.size() - 1)
            setSelectionIndex(0);
        else
            setSelectionIndex(getSelectionIndex() + 1);
        callback();
    });
    right->setPosition(0, 0, sp::Alignment::TopRight)->setSize(GuiSizeMatchHeight, GuiSizeMax);

    popup = new GuiPanel(getTopLevelContainer(), "");
    popup->hide();
}

void GuiSelector::onDraw(sp::RenderTarget& renderer)
{
    left->setEnable(enabled);
    right->setEnable(enabled);

    const auto& back = back_style->get(getState());
    const auto& front = front_style->get(getState());

    renderer.drawStretched(rect, back.texture, back.color);
    if (selection_index >= 0 && selection_index < (int)entries.size())
        renderer.drawText(rect, entries[selection_index].name, sp::Alignment::Center, text_size, nullptr, front.color);

    if (!focus)
        popup->hide();
    int max_visible = std::max(1, (int)(900.0f / button_height));
    int visible_count = std::min((int)entries.size(), max_visible);
    popup_scroll_offset = 0;
    if (selection_index >= 0 && visible_count < (int)entries.size())
        popup_scroll_offset = std::clamp(selection_index - visible_count / 2, 0, (int)entries.size() - visible_count);
    float height = std::min((float)visible_count * button_height, 900.0f);
    float top = rect.position.y;
    if (selection_index >= 0)
        top -= (selection_index - popup_scroll_offset) * button_height;
    top = std::max(0.0f, top);
    top = std::min(900.0f - height, top);
    popup
        ->setPosition(rect.position.x, top, sp::Alignment::TopLeft)
        ->setSize(rect.size.x, height);
}

GuiSelector* GuiSelector::setTextSize(float size)
{
    text_size = size;
    return this;
}

GuiSelector* GuiSelector::setButtonHeight(float height)
{
    button_height = height;
    return this;
}

bool GuiSelector::onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    return true;
}

void GuiSelector::onMouseUp(glm::vec2 position, sp::io::Pointer::ID id)
{
    if (rect.contains(position))
    {
        soundManager->playSound("sfx/button.wav");
        int max_visible = std::max(1, (int)(900.0f / button_height));
        int visible_count = std::min((int)entries.size(), max_visible);
        for(unsigned int n=0; n<entries.size(); n++)
        {
            if (popup_buttons.size() <= n)
            {
                popup_buttons.push_back(new GuiToggleButton(popup, "", entries[n].name, [this, n](bool b)
                {
                    setSelectionIndex(n);
                    callback();
                }));
                popup_buttons[n]
                    ->setTextSize(text_size)
                    ->setSize(GuiElement::GuiSizeMax, button_height);
            }
            else
            {
                popup_buttons[n]->setText(entries[n].name);
            }
            int row = (int)n - popup_scroll_offset;
            if (row < 0 || row >= visible_count)
                popup_buttons[n]->hide();
            else
            {
                popup_buttons[n]->show();
                popup_buttons[n]
                    ->setValue(static_cast<int>(n) == selection_index)
                    ->setPosition(0.0f, row * button_height, sp::Alignment::TopLeft);
            }
        }
        for (unsigned int n=entries.size(); n<popup_buttons.size(); n++)
            popup_buttons[n]->hide();

        popup
            ->show()
            ->moveToFront();
    }
}

void GuiSelector::onFocusLost()
{
    // Explicitly hide the popup when the selector loses focus.
    popup->hide();
}
