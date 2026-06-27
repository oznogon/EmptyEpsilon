#pragma once

#include "layout.h"

class GuiLayoutVertical : public GuiLayout
{
public:
    virtual void update(GuiContainer& container, const sp::Rect& rect) override;
};

class GuiLayoutVerticalBottom : public GuiLayout
{
public:
    virtual void update(GuiContainer& container, const sp::Rect& rect) override;
};

class GuiLayoutVerticalCenter : public GuiLayout
{
public:
    virtual void update(GuiContainer& container, const sp::Rect& rect) override;
};
