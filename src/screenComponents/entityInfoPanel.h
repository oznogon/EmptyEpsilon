#pragma once

#include "gui/gui2_panel.h"
#include "gui/gui2_label.h"
#include "ecs/entity.h"

class GuiRenderedModelSprite;
class GuiScrollbar;
class GuiImage;

class GuiEntityInfoPanel : public GuiPanel
{
public:
    typedef std::function<void(sp::ecs::Entity entity)> func_t;

private:
    sp::ecs::Entity entity;
    GuiRenderedModelSprite* model_view;
    GuiElement* custom_label_row;
    GuiLabel* custom_labels[4];
    GuiImage* custom_icons[4];
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
    int panel_index = -1; // Index of this panel in the grid

    virtual void onDraw(sp::RenderTarget& renderer) override;
    virtual void onUpdate() override;
    virtual bool onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id) override;
    virtual void onMouseUp(glm::vec2 position, sp::io::Pointer::ID id) override;

    GuiEntityInfoPanel* setEntity(sp::ecs::Entity new_entity);
    sp::ecs::Entity getEntity() const { return entity; }
    GuiEntityInfoPanel* setCustomLabel(int index, string new_label);
    GuiEntityInfoPanel* setCustomIcon(int index, string new_image);
    GuiEntityInfoPanel* clearCustomLabels();

    // Allow grid to access styling info for clipped rendering
    const GuiThemeStyle* getBackStyle() const { return selected ? back_selected_style : back_style; }
    const GuiThemeStyle* getFrontStyle() const { return selected ? front_selected_style : front_style; }
    State getPanelState() const { return getState(); }
    float getBackSize() const;
};

class GuiEntityInfoPanelGrid : public GuiElement
{
public:
    typedef std::function<void(sp::ecs::Entity entity)> func_t;
    typedef std::function<void(int index)> index_func_t;

private:
    std::vector<sp::ecs::Entity> entities;
    std::vector<sp::ecs::Entity> cached_entities;
    std::vector<GuiEntityInfoPanel*> cached_panels;
    std::vector<GuiElement*> cached_rows;
    glm::vec2 cached_rect_size;
    func_t func;
    index_func_t index_func;

    GuiElement* content_container;
    GuiScrollbar* scrollbar;

    void updateScrollbar();

public:
    GuiEntityInfoPanelGrid(GuiContainer* owner, string id, std::vector<sp::ecs::Entity> entities, func_t func);
    GuiEntityInfoPanelGrid(GuiContainer* owner, string id, std::vector<sp::ecs::Entity> entities, index_func_t func);

    // virtual void onDraw(sp::RenderTarget& renderer) override;
    virtual void onUpdate() override;
    virtual bool onMouseWheelScroll(glm::vec2 position, float value) override;

    void selectEntityPanel(sp::ecs::Entity selected_entity);
    void selectPanelByIndex(int index);
    int getSelectedEntityPanelIndex();
    GuiEntityInfoPanelGrid* setEntities(std::vector<sp::ecs::Entity> new_entities);
    std::vector<sp::ecs::Entity> getEntities() const { return entities; }
    size_t getSize() const { return cached_entities.size(); }
    GuiEntityInfoPanelGrid* setCustomLabel(int panel_index, int label_index, string new_label);
    GuiEntityInfoPanelGrid* setCustomIcon(int panel_index, int icon_index, string new_image);
    GuiEntityInfoPanelGrid* clearCustomLabels(int panel_index);
    GuiEntityInfoPanelGrid* clearCustomLabels();
};
