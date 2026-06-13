#pragma once

#include "gui2_button.h"

class GuiToggleButton : public GuiButton
{
public:
    typedef std::function<void(bool active)> func_t;
protected:
    bool value;
    func_t toggle_func;

    const GuiThemeStyle* back_on_style;
    const GuiThemeStyle* front_on_style;
public:
    GuiToggleButton(GuiContainer* owner, string id, string text, func_t func);

    virtual void onDraw(sp::RenderTarget& renderer) override;

    GuiToggleButton* setOnStyle(const string& style);

    bool getValue() const;
    GuiToggleButton* setValue(bool value);
private:
    void onClick();
};
