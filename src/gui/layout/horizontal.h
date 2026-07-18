#pragma once

#include "layout.h"

class GuiLayoutHorizontal : public GuiLayout
{
public:
    virtual void update(GuiContainer& container, const sp::Rect& rect) override;
};

class GuiLayoutHorizontalRight : public GuiLayout
{
public:
    virtual void update(GuiContainer& container, const sp::Rect& rect) override;
};

class GuiLayoutHorizontalCenter : public GuiLayout
{
public:
    virtual void update(GuiContainer& container, const sp::Rect& rect) override;
};
