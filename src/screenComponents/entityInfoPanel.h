#pragma once

#include "gui/gui2_panel.h"
#include "gui/gui2_label.h"
#include "ecs/entity.h"

class GuiRotatingModelView;
class GuiScrollbar;

class GuiEntityInfoPanel : public GuiPanel
{
public:
    typedef std::function<void(sp::ecs::Entity entity)> func_t;

private:
    sp::ecs::Entity entity;
    GuiRotatingModelView* model_view;
    GuiLabel* callsign_label;
    GuiLabel* type_label;
    func_t func;

    const GuiThemeStyle* back_style;
    const GuiThemeStyle* front_style;
    const GuiThemeStyle* back_selected_style;
    const GuiThemeStyle* front_selected_style;

public:
    GuiEntityInfoPanel(GuiContainer* owner, string id, sp::ecs::Entity entity, func_t func);

    static constexpr float default_panel_size = 200.0f;
    bool selected;

    virtual void onDraw(sp::RenderTarget& renderer) override;
    virtual void onUpdate() override;
    virtual bool onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id) override;
    virtual void onMouseUp(glm::vec2 position, sp::io::Pointer::ID id) override;

    GuiEntityInfoPanel* setEntity(sp::ecs::Entity new_entity);
    sp::ecs::Entity getEntity() const { return entity; }
};

class GuiEntityInfoPanelGrid : public GuiElement
{
public:
    typedef std::function<void(sp::ecs::Entity entity)> func_t;

private:
    std::vector<sp::ecs::Entity> entities;
    std::vector<sp::ecs::Entity> cached_entities;
    std::vector<GuiEntityInfoPanel*> cached_panels;
    std::vector<GuiElement*> cached_rows;
    glm::vec2 cached_rect_size;
    func_t func;

    GuiElement* content_container;
    GuiScrollbar* scrollbar;

    void updateScrollbar();

public:
    GuiEntityInfoPanelGrid(GuiContainer* owner, string id, std::vector<sp::ecs::Entity> entities, func_t func);

    virtual void onUpdate() override;
    virtual bool onMouseWheelScroll(glm::vec2 position, float value) override;

    void selectEntityPanel(sp::ecs::Entity selected_entity);
    GuiEntityInfoPanelGrid* setEntities(std::vector<sp::ecs::Entity> new_entities);
    std::vector<sp::ecs::Entity> getEntities() const { return entities; }
};
