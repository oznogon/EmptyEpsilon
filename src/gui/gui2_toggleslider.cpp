#include "gui2_toggleslider.h"
#include "gui2_slider.h"

GuiToggleSlider::GuiToggleSlider(GuiContainer* owner, string id, func_t func)
: GuiEntryList(owner, id, func)
{
    // Create the slider child element
    slider = new GuiSlider(this, id + "_SLIDER", 0.0f, 1.0f, 0.0f, [this](float value) {
        updateSelectionFromSlider(value);
    });
    slider->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
}

GuiToggleSlider* GuiToggleSlider::setOptions(const std::vector<string>& options)
{
    GuiEntryList::setOptions(options);
    rebuildTicks();
    return this;
}

GuiToggleSlider* GuiToggleSlider::setOptions(const std::vector<string>& options, const std::vector<string>& values)
{
    GuiEntryList::setOptions(options, values);
    rebuildTicks();
    return this;
}

int GuiToggleSlider::addEntry(string name, string value)
{
    int index = GuiEntryList::addEntry(name, value);
    float position = calculateDefaultPosition(index);

    if (checkTickCollision(position, index))
        LOG(Warning, "GuiToggleSlider: Tick collision detected at position", position, "for entry " + name + ".");

    tick_positions.emplace_back(position);
    rebuildTicks();
    return index;
}

GuiToggleSlider* GuiToggleSlider::addEntry(string name, string value, float position)
{
    // TODO: DRY with setEntryPosition
    // Clamp position to valid range.
    if (position < 0.0f)
    {
        position = 0.0f;
        LOG(Warning, "GuiToggleSlider: New entry ", name, " has invalid position value ", position);
    }
    if (position > 1.0f)
    {
        position = 1.0f;
        LOG(Warning, "GuiToggleSlider: New entry ", name, " has invalid position value ", position);
    }

    // Add entry to base class and call entriesChanged.
    int index = GuiEntryList::addEntry(name, value);

    // Replace the auto-added default position with our custom position.
    if (index >= 0 && index < static_cast<int>(tick_positions.size()))
    {
        if (checkTickCollision(position, index))
            LOG(Warning, "GuiToggleSlider: Tick collision detected at position ", position, " for entry " + name);

        tick_positions[index].position = position;
    }

    rebuildTicks();
    return this;
}

void GuiToggleSlider::removeEntry(int index)
{
    if (index < 0 || index >= static_cast<int>(tick_positions.size())) return;

    tick_positions.erase(tick_positions.begin() + index);
    GuiEntryList::removeEntry(index);
    rebuildTicks();
}

void GuiToggleSlider::clear()
{
    tick_positions.clear();
    GuiEntryList::clear();
    rebuildTicks();
}

GuiToggleSlider* GuiToggleSlider::setSelectionIndex(int index)
{
    GuiEntryList::setSelectionIndex(index);
    updateSliderFromSelection();
    return this;
}

GuiToggleSlider* GuiToggleSlider::setEntryPosition(int index, float position)
{
    if (index < 0 || index >= static_cast<int>(tick_positions.size())) return this;

    // Clamp position to valid range.
    if (position < 0.0f)
    {
        position = 0.0f;
        LOG(Warning, "GuiToggleSlider: Changed entry ", index, " has invalid position value ", position);
    }
    if (position > 1.0f)
    {
        position = 1.0f;
        LOG(Warning, "GuiToggleSlider: Changed entry ", index, " has invalid position value ", position);
    }

    if (checkTickCollision(position, index))
        LOG(Warning, "GuiToggleSlider: Tick collision detected at position ", position, " for entry " + index);

    tick_positions[index].position = position;
    rebuildTicks();
    return this;
}

float GuiToggleSlider::getEntryPosition(int index) const
{
    if (index < 0 || index >= (int)tick_positions.size())
        return 0.0f;
    return tick_positions[index].position;
}

void GuiToggleSlider::rebuildTicks()
{
    // Clear existing snap points.
    slider->clearSnapValues();

    // Update slider range based on number of entries.
    if (entries.size() > 0)
    {
        const float max_range = std::max(1.0f, static_cast<float>(entries.size() - 1));
        slider->setRange(0.0f, max_range);

        // Add snap point for each option with a range that ensures snapping.
        for (size_t i = 0; i < tick_positions.size(); i++)
            slider->addSnapValue(tick_positions[i].position * max_range, max_range * 0.05f);
    }

    updateSliderFromSelection();
}

void GuiToggleSlider::updateSliderFromSelection()
{
    if (selection_index >= 0 && selection_index < static_cast<int>(tick_positions.size()))
    {
        const float max_range = std::max(1.0f, static_cast<float>(entries.size() - 1));
        slider->setValue(tick_positions[selection_index].position * max_range);
    }
}

void GuiToggleSlider::updateSelectionFromSlider(float slider_value)
{
    if (entries.empty()) return;

    // Snap to the closest tick position from the slider value.
    float normalized_value = slider_value / std::max(1.0f, static_cast<float>(entries.size() - 1));

    int closest_index = 0;
    float closest_distance = std::abs(tick_positions[0].position - normalized_value);

    for (size_t i = 1; i < tick_positions.size(); i++)
    {
        float distance = std::abs(tick_positions[i].position - normalized_value);
        if (distance < closest_distance)
        {
            closest_distance = distance;
            closest_index = i;
        }
    }

    // Update selection if it changed.
    if (selection_index != closest_index)
    {
        selection_index = closest_index;
        callback();
    }
}

bool GuiToggleSlider::checkTickCollision(float position, int exclude_index)
{
    for (size_t i = 0; i < tick_positions.size(); i++)
    {
        if (static_cast<int>(i) == exclude_index) continue;

        if (std::abs(tick_positions[i].position - position) < collision_threshold)
            return true;
    }

    return false;
}

float GuiToggleSlider::calculateDefaultPosition(int index) const
{
    if (entries.size() <= 1) return 0.0f;

    // Evenly space positions from 0.0 to 1.0.
    return static_cast<float>(index) / static_cast<float>(entries.size() - 1);
}

void GuiToggleSlider::entriesChanged()
{
    // Resize tick positions to match entries.
    tick_positions.resize(entries.size());

    // Recalculate all tick positions based on final entry count.
    for (size_t i = 0; i < tick_positions.size(); i++)
        tick_positions[i].position = calculateDefaultPosition(i);

    rebuildTicks();
}
