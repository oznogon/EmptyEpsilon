#ifndef SCREEN_GM_TWEAK_H
#define SCREEN_GM_TWEAK_H

#include "gui/gui2_panel.h"
#include "ecs/entity.h"


class GuiButton;
class GuiListbox;
class GuiTextEntry;
class GuiTweakPage : public GuiElement
{
public:
    GuiTweakPage(GuiContainer* owner);

    void open(sp::ecs::Entity);
    virtual void onDraw(sp::RenderTarget& target) override;

    std::function<bool(sp::ecs::Entity)> has_component;
    std::function<void(sp::ecs::Entity)> add_component;
    std::function<void(sp::ecs::Entity)> remove_component;

    GuiButton* add_remove_button;
    GuiElement* tweaks;

    sp::ecs::Entity entity;
};

class GuiEntityTweak : public GuiPanel
{
public:
    GuiEntityTweak(GuiContainer* owner);

    void open(sp::ecs::Entity target, string select_component = "");

private:
    void showGroups();
    void showGroupComponents(int group_index);
    void showSearchResults(const string& query);

    struct ComponentGroup
    {
        string name;
        std::vector<int> page_indices;
    };

    sp::ecs::Entity entity;
    GuiElement* content;
    std::vector<GuiTweakPage*> pages;
    std::vector<string> page_labels;
    std::vector<ComponentGroup> component_groups;
    GuiTextEntry* search_filter;
    GuiListbox* component_list;
    std::vector<int> search_result_indices;
    bool in_group_view = true;
    bool in_search_view = false;
    int current_group_index = -1;
};

#endif//SCREEN_GM_TWEAK_H
