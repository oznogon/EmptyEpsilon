#ifndef SCREEN_GM_TWEAK_H
#define SCREEN_GM_TWEAK_H

#include "gui/gui2_panel.h"
#include "ecs/entity.h"


class GuiButton;
class GuiListbox;
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
    GuiListbox* component_list;
    bool in_group_view = true;
    int current_group_index = -1;
};

#endif//SCREEN_GM_TWEAK_H
