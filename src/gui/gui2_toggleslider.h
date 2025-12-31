#pragma once

#include "gui2_entrylist.h"

class GuiSlider;
class GuiThemeStyle;

class GuiToggleSlider : public GuiEntryList
{
public:
    typedef std::function<void(int index, string value)> func_t;

private:
    struct TickEntry
    {
        float position;
        TickEntry() : position(0.0f) {}
        TickEntry(float pos) : position(pos) {}
    };

    GuiSlider* slider;
    std::vector<TickEntry> tick_positions;
    const float collision_threshold = 0.01f;

public:
    GuiToggleSlider(GuiContainer* owner, string id, func_t func);

    // Override GuiEntryList methods to manage tick positions
    GuiToggleSlider* setOptions(const std::vector<string>& options);
    GuiToggleSlider* setOptions(const std::vector<string>& options, const std::vector<string>& values);
    int addEntry(string name, string value);
    void removeEntry(int index);
    void clear();
    GuiToggleSlider* setSelectionIndex(int index);

    // New methods for managing tick positions
    GuiToggleSlider* setEntryPosition(int index, float position);
    GuiToggleSlider* addEntry(string name, string value, float position);
    float getEntryPosition(int index) const;

private:
    void rebuildTicks();
    void updateSliderFromSelection();
    void updateSelectionFromSlider(float slider_value);
    bool checkTickCollision(float position, int exclude_index = -1);
    float calculateDefaultPosition(int index) const;

    virtual void entriesChanged() override;
};
