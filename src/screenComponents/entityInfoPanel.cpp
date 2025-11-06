#include "entityInfoPanel.h"

#include "soundManager.h"

#include "rotatingModelView.h"
#include "gui/theme.h"
#include "gui/gui2_image.h"
#include "gui/gui2_scrollbar.h"

#include "components/name.h"

GuiEntityInfoPanel::GuiEntityInfoPanel(GuiContainer* owner, string id, sp::ecs::Entity entity, func_t func)
: GuiPanel(owner, id), entity(entity), func(func), selected(false)
{
    back_style = theme->getStyle("entityinfopanel.back");
    front_style = theme->getStyle("entityinfopanel.front");
    back_selected_style = theme->getStyle("entityinfopanel.selected.back");
    front_selected_style = theme->getStyle("entityinfopanel.selected.front");

    setAttribute("layout", "vertical");
    setAttribute("padding", "10");
    setSize(default_panel_size, default_panel_size);

    // Create custom elements for text or icon IDs
    custom_label_row = new GuiElement(this, id + "_CUSTOM_LABELS");
    custom_label_row
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopCenter)
        ->setSize(default_panel_size - 40.0f, 20.0f)
        ->setAttribute("layout", "horizontal");

    for (auto i = 0; i < 4; i++)
    {
        custom_labels[i] = new GuiLabel(custom_label_row, "", "", 20.0f);
        custom_labels[i]
            ->setAlignment(sp::Alignment::Center)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
            ->hide();
        custom_icons[i] = new GuiImage(custom_label_row, "", "");
        custom_icons[i]
            ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
            ->setSize(GuiElement::GuiSizeMax, 25.0f)
            ->hide();
    }

    // Create the 3D model view
    model_view = new GuiRotatingModelView(this, id + "_MODEL_VIEW", this->entity);
    model_view
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopCenter)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    model_view->setCameraZoomFactor(0.45f);
    model_view->setCameraRotation(45.0f);
    model_view->setCameraHeight(5.0f);
    model_view->is_rotating = false;

    // Create labels for callsign and type
    callsign_label = new GuiLabel(this, id + "_CALLSIGN", "", 25.0f);
    callsign_label->setSize(GuiElement::GuiSizeMax, 25.0f);

    type_label = new GuiLabel(this, id + "_TYPE", "", 20.0f);
    type_label->setSize(GuiElement::GuiSizeMax, 20.0f);
}

void GuiEntityInfoPanel::onDraw(sp::RenderTarget& renderer)
{
    hover = false;
    const auto& back = back_style->get(getState());
    const auto& back_hover = back_style->get(State::Hover);
    const auto& back_selected = back_selected_style->get(getState());
    const auto& back_selected_hover = back_selected_style->get(State::Hover);

    auto* b = rect.contains(hover_coordinates) ? &back_hover : &back;
    const GuiThemeStyle* f = front_style;

    // If this is the selected button, change the back and foreground.
    if (selected)
    {
        b = rect.contains(hover_coordinates) ? &back_selected_hover : &back_selected;
        f = front_selected_style;
    }

    renderer.drawStretchedHV(rect, b->size, b->texture, b->color);
    callsign_label->setFrontStyle(f);
    type_label->setFrontStyle(f);

    for (auto i = 0; i < 4; i++)
    {
        custom_labels[i]->setFrontStyle(f);
        custom_icons[i]->setColor(f->get(getState()).color);
    }
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

GuiEntityInfoPanel* GuiEntityInfoPanel::setCustomLabel(int index, string new_label)
{
    custom_icons[index]
        ->setImage("")
        ->hide();
    custom_labels[index]
        ->setText(new_label)
        ->show();

    return this;
}

GuiEntityInfoPanel* GuiEntityInfoPanel::setCustomIcon(int index, string new_image)
{
    custom_icons[index]
        ->setImage(new_image)
        ->show();
    custom_labels[index]
        ->setText("")
        ->hide();

    return this;
}

GuiEntityInfoPanel* GuiEntityInfoPanel::clearCustomLabels()
{
    for (auto i = 0; i < 4; i++)
    {
        custom_icons[i]
            ->setImage("")
            ->hide();
        custom_labels[i]
            ->setText("")
            ->hide();
    }

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
: GuiElement(owner, id), entities(entities), func(func), index_func(nullptr)
{
    // Create a content container that will hold all the rows
    content_container = new GuiElement(this, id + "_CONTENT");
    content_container
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopLeft)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    // Create scrollbar on the right side
    scrollbar = new GuiScrollbar(this, id + "_SCROLL", 0, 0, 0, [this](int value) {
        // Update content container position based on scroll value
        content_container->setPosition(0.0f, -value, sp::Alignment::TopLeft);
    });
    scrollbar
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopRight)
        ->setSize(40.0f, GuiElement::GuiSizeMax)
        ->hide();
    scrollbar->setClickChange(static_cast<int>(GuiEntityInfoPanel::default_panel_size));
}

GuiEntityInfoPanelGrid::GuiEntityInfoPanelGrid(GuiContainer* owner, string id, std::vector<sp::ecs::Entity> entities, index_func_t func)
: GuiElement(owner, id), entities(entities), func(nullptr), index_func(func)
{
    // Create a content container that will hold all the rows
    content_container = new GuiElement(this, id + "_CONTENT");
    content_container
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopLeft)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    // Create scrollbar on the right side
    scrollbar = new GuiScrollbar(this, id + "_SCROLL", 0, 0, 0, [this](int value) {
        // Update content container position based on scroll value
        content_container->setPosition(0.0f, -value, sp::Alignment::TopLeft);
    });
    scrollbar
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopRight)
        ->setSize(40.0f, GuiElement::GuiSizeMax)
        ->hide();
    scrollbar->setClickChange(static_cast<int>(GuiEntityInfoPanel::default_panel_size));
}

bool GuiEntityInfoPanelGrid::onMouseWheelScroll(glm::vec2 position, float value)
{
    float range = scrollbar->getCorrectedMax() - scrollbar->getMin();
    scrollbar->setValue((scrollbar->getValue() - value * range / 25.0f) );
    return true;
}

void GuiEntityInfoPanelGrid::onUpdate()
{
    int max_cols = std::max(1, static_cast<int>(rect.size.x / GuiEntityInfoPanel::default_panel_size));
    int max_rows = std::max(1, static_cast<int>(rect.size.y / GuiEntityInfoPanel::default_panel_size));

    // Rebuild the grid only if entities or rect size changed
    if (entities == cached_entities && rect.size == cached_rect_size)
    {
        updateScrollbar();
        return;
    }

    // Destroy old panels and rows
    for (auto panel : cached_panels) if (panel) panel->destroy();
    cached_panels.clear();

    for (auto row : cached_rows) if (row) row->destroy();
    cached_rows.clear();

    if (entities.empty())
    {
        cached_entities.clear();
        scrollbar->hide();
        return;
    }

    // Build new grid with at least 1 column
    int col = 0;
    int row = 0;
    int panel_idx = 0;
    GuiElement* current_row = nullptr;

    // Populate a berth panel for each entity
    for (auto entity : entities)
    {
        // Create a new layout row on the first column
        if (col == 0 || col >= max_cols)
        {
            row++;
            if (row > max_rows)
                LOG(Debug, "There are more rows in the list than can be shown at once");

            current_row = new GuiElement(content_container, "");
            current_row
                ->setSize(GuiElement::GuiSizeMax, GuiEntityInfoPanel::default_panel_size)
                ->setAttribute("layout", "horizontal");

            cached_rows.push_back(current_row);
            col = 0;
        }

        // Create callback for this panel
        GuiEntityInfoPanel::func_t panel_callback;
        if (index_func)
        {
            // Capture the panel index for index-based callback
            int captured_index = panel_idx;
            panel_callback = [this, captured_index](sp::ecs::Entity) {
                index_func(captured_index);
            };
        }
        else
        {
            panel_callback = func;
        }

        // Populate this column
        auto panel = new GuiEntityInfoPanel(current_row, "", entity, panel_callback);
        panel->setSize(GuiEntityInfoPanel::default_panel_size,
                      GuiEntityInfoPanel::default_panel_size);
        panel->panel_index = panel_idx;
        cached_panels.push_back(panel);
        col++;
        panel_idx++;
    }

    // Update entity and rect size caches
    cached_entities = entities;
    cached_rect_size = rect.size;

    // Update scrollbar
    updateScrollbar();
}

void GuiEntityInfoPanelGrid::selectEntityPanel(sp::ecs::Entity selected_entity)
{
    for (auto panel : cached_panels)
        panel->selected = panel->getEntity() == selected_entity;
}

void GuiEntityInfoPanelGrid::selectPanelByIndex(int index)
{
    for (int i = 0; i < static_cast<int>(cached_panels.size()); i++)
        cached_panels[i]->selected = (i == index);
}

int GuiEntityInfoPanelGrid::getSelectedEntityPanelIndex()
{
    for (int i = 0; i < static_cast<int>(cached_panels.size()); i++)
        if (cached_panels[i]->selected) return i;

    return -1;
}

void GuiEntityInfoPanelGrid::updateScrollbar()
{
    // Calculate total content height
    float total_height = cached_rows.size() * GuiEntityInfoPanel::default_panel_size;
    float visible_height = rect.size.y;

    // Set scrollbar range
    scrollbar->setValueSize(static_cast<int>(visible_height));
    scrollbar->setRange(0, static_cast<int>(total_height));

    // Show/hide scrollbar based on whether the content fits
    if (total_height > visible_height)
    {
        scrollbar->show();
        // Adjust content container width to account for scrollbar
        content_container->setSize(rect.size.x - scrollbar->getRect().size.x, GuiElement::GuiSizeMax);
    }
    else
    {
        scrollbar->hide();
        scrollbar->setValue(0);
        content_container->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
        content_container->setPosition(0, 0, sp::Alignment::TopLeft);
    }
}

GuiEntityInfoPanelGrid* GuiEntityInfoPanelGrid::setEntities(std::vector<sp::ecs::Entity> new_entities)
{
    entities = new_entities;
    return this;
}

GuiEntityInfoPanelGrid* GuiEntityInfoPanelGrid::setCustomLabel(int panel_index, int label_index, string new_label)
{
    const int cached_panels_size = static_cast<int>(cached_panels.size());
    if (cached_panels_size > 0 && panel_index >= 0 && panel_index < cached_panels_size)
    {
        cached_panels[panel_index]->setCustomLabel(label_index, new_label);
    }
    
    return this;
}

GuiEntityInfoPanelGrid* GuiEntityInfoPanelGrid::setCustomIcon(int panel_index, int icon_index, string new_image)
{
    const int cached_panels_size = static_cast<int>(cached_panels.size());
    if (cached_panels_size > 0 && panel_index >= 0 && panel_index < cached_panels_size)
    {
        cached_panels[panel_index]->setCustomIcon(icon_index, new_image);
    }
    
    return this;
}

GuiEntityInfoPanelGrid* GuiEntityInfoPanelGrid::clearCustomLabels(int panel_index)
{
    const int cached_panels_size = static_cast<int>(cached_panels.size());
    if (cached_panels_size > 0 && panel_index >= 0 && panel_index < cached_panels_size)
        cached_panels[panel_index]->clearCustomLabels();

    return this;
}

GuiEntityInfoPanelGrid* GuiEntityInfoPanelGrid::clearCustomLabels()
{
    for (auto& panel : cached_panels)
        panel->clearCustomLabels();

    return this;
}
