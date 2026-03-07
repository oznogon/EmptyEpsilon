#pragma once

#include "gui/gui2_panel.h"
#include "ecs/entity.h"

class GuiButton;
class GuiListbox;
class GuiScrollContainer;
class GuiScrollText;
class GuiTextEntry;

// A GuiElement containing controls to modify an entity's component's
// properties.
class GuiTweakPage : public GuiElement
{
public:
    GuiTweakPage(GuiContainer* owner);

    // Run when opening this tweak page, passing an entity (should be the GM
    // selection) being tweaked.
    void open(sp::ecs::Entity);
    virtual void onDraw(sp::RenderTarget& target) override;

    // Callback that returns true if this page has the tweak page's relevant
    // component.
    std::function<bool(sp::ecs::Entity)> has_component;
    // Callback run when adding the tweak page's relevant component.
    std::function<void(sp::ecs::Entity)> add_component;
    // Callback run when removing the tweak page's relevant component.
    std::function<void(sp::ecs::Entity)> remove_component;

    // Button to add or remove this tweak page's component to the selected
    // entity.
    GuiButton* add_remove_button;
    // Scrolling container for tweak properties (center column).
    GuiScrollContainer* tweaks;
    // A summary of the component's function and its notable properties
    // (right column).
    string description;
    // Callbacks run when applying changes to the tweak page.
    std::vector<std::function<void()>> apply_functions;

    // Entity selected for tweaking.
    sp::ecs::Entity entity;
};

// A GuiPanel for containing and navigating GuiTweakPages.
class GuiEntityTweak : public GuiPanel
{
public:
    GuiEntityTweak(GuiContainer* owner);

    void open(sp::ecs::Entity target, string select_component = "");

private:
    // Show top-level tweak page groups.
    void showGroups();
    // Show component tweak pages related to the given group.
    void showGroupComponents(int group_index);
    // Show component tweak pages related to the given search query.
    void showSearchResults(const string& query);
    // Show the description for the given tweak page.
    void showPageDescription(int page_index);

    // Groupings of tweak pages by index.
    struct ComponentGroup
    {
        // Name of the group, as displayed in the component_list when in_group_view.
        string name;
        // Indices of tweak pages that belong to this group.
        std::vector<int> page_indices;
    };

    // Entity selected for tweaking.
    sp::ecs::Entity entity;
    GuiElement* content;
    // All tweak pages.
    std::vector<GuiTweakPage*> pages;
    // Labels associated with each tweak page.
    // TODO: Move to GuiTweakPage?
    std::vector<string> page_labels;
    // Groups of components to organize tweak page navigation.
    std::vector<ComponentGroup> component_groups;
    // Search field for selecting a component's tweak page.
    GuiTextEntry* search_filter;
    // List of components, populated by the group or search results.
    GuiListbox* component_list;
    // A text area to display the component's description.
    GuiScrollText* component_description;
    // Tweak page indices that match the search result.
    std::vector<int> search_result_indices;
    // Flags for view modes.
    // TODO: Should be a flag or single bool instead of two bools?
    bool in_group_view = true;
    bool in_search_view = false;
    // Index of the selected ComponentGroup.
    int current_group_index = -1;
};
