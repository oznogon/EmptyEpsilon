#include "soundManager.h"
#include "entityInfoPanel.h"
#include "rotatingModelView.h"
#include "components/name.h"

GuiEntityInfoPanel::GuiEntityInfoPanel(GuiContainer* owner, string id, sp::ecs::Entity entity, func_t func)
: GuiPanel(owner, id), entity(entity), func(func)
{
    setAttribute("layout", "vertical");
    setAttribute("padding", "20, 20, 0, 20");
    setSize(default_panel_size, default_panel_size);

    // Create the 3D model view
    model_view = new GuiRotatingModelView(this, id + "_MODEL_VIEW", this->entity);
    model_view->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    model_view->setZoomFactor(0.5f);
    model_view->setAngle(90.0f);
    model_view->is_rotating = false;

    // Create labels for callsign and type
    callsign_label = new GuiLabel(this, id + "_CALLSIGN", "", 25.0f);
    callsign_label->setSize(GuiElement::GuiSizeMax, 25.0f);

    type_label = new GuiLabel(this, id + "_TYPE", "", 20.0f);
    type_label->setSize(GuiElement::GuiSizeMax, 20.0f);
}

void GuiEntityInfoPanel::onUpdate()
{
    if (!entity)
    {
        callsign_label->setText("");
        type_label->setText("");
        return;
    }

    // Update callsign
    if (auto callsign = entity.getComponent<CallSign>())
        callsign_label->setText(callsign->callsign);
    else
        callsign_label->setText("");

    // Update type name
    if (auto type_name = entity.getComponent<TypeName>())
        type_label->setText(type_name->localized.empty() ? type_name->type_name : type_name->localized);
    else
        type_label->setText("");
}

GuiEntityInfoPanel* GuiEntityInfoPanel::setEntity(sp::ecs::Entity new_entity)
{
    entity = new_entity;
    return this;
}

bool GuiEntityInfoPanel::onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    return true;
}

void GuiEntityInfoPanel::onMouseUp(glm::vec2 position, sp::io::Pointer::ID id)
{
    if (rect.contains(position))
    {
        soundManager->playSound("sfx/button.wav");
        if (func)
        {
            func_t f = func;
            f(entity);
        }
    }
}

GuiEntityInfoPanelGrid::GuiEntityInfoPanelGrid(GuiContainer* owner, string id, std::vector<sp::ecs::Entity> entities, func_t func)
: GuiElement(owner, id), entities(entities), func(func)
{
    setAttribute("layout", "vertical");
}

void GuiEntityInfoPanelGrid::onUpdate()
{
    // Rebuild only if entities actually changed
    if (entities == cached_entities) return;

    // Destroy old panels and rows (do we actually need to destroy rows?)
    for (auto panel : cached_panels) if (panel) panel->destroy();
    cached_panels.clear();

    for (auto row : cached_rows) if (row) row->destroy();
    cached_rows.clear();

    if (entities.empty())
    {
        cached_entities.clear();
        return;
    }

    // Build new grid with at least 1 column
    int max_cols = std::max(1, static_cast<int>(rect.size.x / GuiEntityInfoPanel::default_panel_size));

    int col = 0;
    GuiElement* current_row = nullptr;

    // Add a panel for each entity
    for (auto entity : entities)
    {
        if (!entity) continue;

        // Create a new layout row on the first column
        if (col == 0 || col >= max_cols)
        {
            current_row = new GuiElement(this, "");
            current_row
                ->setSize(GuiElement::GuiSizeMax, GuiEntityInfoPanel::default_panel_size)
                ->setAttribute("layout", "horizontal");
            cached_rows.push_back(current_row);
            col = 0;
        }

        // Populate this column
        auto panel = new GuiEntityInfoPanel(current_row, "", entity, func);
        panel->setSize(GuiEntityInfoPanel::default_panel_size,
                      GuiEntityInfoPanel::default_panel_size);
        cached_panels.push_back(panel);
        col++;
    }

    // Update entity cache
    cached_entities = entities;
}

GuiEntityInfoPanelGrid* GuiEntityInfoPanelGrid::setEntities(std::vector<sp::ecs::Entity> new_entities)
{
    entities = new_entities;
    return this;
}
