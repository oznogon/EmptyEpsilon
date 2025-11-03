#pragma once

#include "gui/gui2_panel.h"
#include "gui/gui2_label.h"
#include "ecs/entity.h"

class GuiEntityInfoPanel : public GuiPanel
{
public:
    typedef std::function<void(sp::ecs::Entity entity)> func_t;

private:
    sp::ecs::Entity entity;
    GuiElement* model_view_container;
    GuiLabel* callsign_label;
    GuiLabel* type_label;
    func_t func;

public:
    GuiEntityInfoPanel(GuiContainer* owner, string id, sp::ecs::Entity entity, func_t func);

    virtual void onDraw(sp::RenderTarget& target) override;
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
    func_t func;

public:
    GuiEntityInfoPanelGrid(GuiContainer* owner, string id, std::vector<sp::ecs::Entity> entities, func_t func);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;

    GuiEntityInfoPanelGrid* setEntities(std::vector<sp::ecs::Entity> new_entities);
    std::vector<sp::ecs::Entity> getEntities() const { return entities; }
};
