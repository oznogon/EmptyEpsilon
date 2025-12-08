#include "entityInfoPanel.h"

#include "soundManager.h"

#include "renderedModelSprite.h"
#include "gui/theme.h"
#include "gui/gui2_image.h"
#include "gui/gui2_button.h"

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
        ->setSize(GuiElement::GuiSizeMax, 20.0f)
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
    model_view = new GuiRenderedModelSprite(this, id + "_MODEL_VIEW", this->entity);
    model_view
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopCenter)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    model_view->setCameraZoomFactor(0.45f);
    model_view->setCameraRotation(45.0f);
    model_view->setCameraHeight(5.0f);

    // Create labels for callsign and type
    callsign_label = new GuiLabel(this, id + "_CALLSIGN", "", 25.0f);
    callsign_label->setSize(GuiElement::GuiSizeMax, 25.0f);

    type_label = new GuiLabel(this, id + "_TYPE", "", 20.0f);
    type_label->setSize(GuiElement::GuiSizeMax, 20.0f);
}

void GuiEntityInfoPanel::onDraw(sp::RenderTarget& renderer)
{
    hover = false;

    const GuiThemeStyle* back_style = getBackStyle();
    const auto& back = back_style->get(getPanelState());

    // Draw the panel background clipped to the grid's rect
    renderer.drawStretchedHV(rect, back.size, back.texture, back.color);

    const GuiThemeStyle* front = getFrontStyle();

    callsign_label->setFrontStyle(front);
    type_label->setFrontStyle(front);

    for (auto i = 0; i < 4; i++)
    {
        custom_labels[i]->setFrontStyle(front);
        custom_icons[i]->setColor(front->get(getState()).color);
    }
}

float GuiEntityInfoPanel::getBackSize() const
{
    const auto& back = getBackStyle()->get(getState());
    return back.size;
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
: GuiElement(owner, id), entities(entities), func(func), index_func(nullptr), scroll_position(0), scroll_accumulator(0.0f)
{
    setAttribute("layout", "vertical");

    // Scroll up
    scroll_up_button = new GuiButton(this, id + "_SCROLL_UP", "",
        [this]()
        {
            float panel_height = GuiEntityInfoPanel::default_panel_size;
            // Find the previous fully visible row
            int current_row = static_cast<int>(scroll_position / panel_height);
            // If not aligned, we're showing a partial row, go to the one above
            if (scroll_position % static_cast<int>(panel_height) != 0) current_row++;
            int target_row = std::max(0, current_row - 1);

            scroll_position = static_cast<int>(target_row * panel_height);

            updateScrollButtons();
        }
    );
    scroll_up_button
        ->setIcon("gui/widget/SelectorArrow.png", sp::Alignment::Center, 90.0f)
        ->setSize(GuiElement::GuiSizeMax, 40.0f);

    // Scrolling content container for rows
    content_container = new GuiElement(this, id + "_CONTENT");
    content_container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    // Scroll down
    scroll_down_button = new GuiButton(this, id + "_SCROLL_DOWN", "",
        [this]()
        {
            float panel_height = GuiEntityInfoPanel::default_panel_size;
            float visible_height = rect.size.y;
            // Find the next fully visible row
            int current_row = static_cast<int>(scroll_position / panel_height);
            int target_row = current_row + 1;
            int target_position = static_cast<int>(target_row * panel_height);

            // Make sure the last row can be fully visible
            float total_height = (cached_rows.size() + 1) * panel_height;
            int max_scroll = std::max(0, static_cast<int>(std::ceil(total_height - visible_height)));
            scroll_position = std::min(max_scroll, target_position);
            updateScrollButtons();
        }
    );
    scroll_down_button
        ->setIcon("gui/widget/SelectorArrow.png", sp::Alignment::Center, -90.0f)
        ->setSize(GuiElement::GuiSizeMax, 40.0f);
}

GuiEntityInfoPanelGrid::GuiEntityInfoPanelGrid(GuiContainer* owner, string id, std::vector<sp::ecs::Entity> entities, index_func_t func)
: GuiElement(owner, id), entities(entities), func(nullptr), index_func(func), scroll_position(0), scroll_accumulator(0.0f)
{
    setAttribute("layout", "vertical");

    // Scroll up
    scroll_up_button = new GuiButton(this, id + "_SCROLL_UP", "",
        [this]()
        {
            float panel_height = GuiEntityInfoPanel::default_panel_size;
            // Find the previous fully visible row
            int current_row = static_cast<int>(scroll_position / panel_height);
            // If not aligned, we're showing a partial row, go to the one above
            if (scroll_position % static_cast<int>(panel_height) != 0) current_row++;
            int target_row = std::max(0, current_row - 1);

            scroll_position = static_cast<int>(target_row * panel_height);

            updateScrollButtons();
        }
    );
    scroll_up_button
        ->setIcon("gui/widget/SelectorArrow.png", sp::Alignment::Center, 90.0f)
        ->setSize(GuiElement::GuiSizeMax, 40.0f);

    // Scrolling content container for rows
    content_container = new GuiElement(this, id + "_CONTENT");
    content_container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    // Scroll down
    scroll_down_button = new GuiButton(this, id + "_SCROLL_DOWN", "",
        [this]()
        {
            float panel_height = GuiEntityInfoPanel::default_panel_size;
            float visible_height = rect.size.y;
            // Find the next fully visible row
            int current_row = static_cast<int>(scroll_position / panel_height);
            int target_row = current_row + 1;
            int target_position = static_cast<int>(target_row * panel_height);

            // Make sure the last row can be fully visible
            float total_height = (cached_rows.size() + 1) * panel_height;
            int max_scroll = std::max(0, static_cast<int>(std::ceil(total_height - visible_height)));
            scroll_position = std::min(max_scroll, target_position);
            updateScrollButtons();
        }
    );
    scroll_down_button
        ->setIcon("gui/widget/SelectorArrow.png", sp::Alignment::Center, -90.0f)
        ->setSize(GuiElement::GuiSizeMax, 40.0f);
}

bool GuiEntityInfoPanelGrid::onMouseWheelScroll(glm::vec2 position, float value)
{
    // Accumulate scroll delta to reduce sensitivity
    // Require multiple scroll events before moving one row
    const float scroll_threshold = 3.0f;

    scroll_accumulator += value;

    // Scroll only if accumulator exceeds threshold
    if (std::abs(scroll_accumulator) < scroll_threshold) return true;

    // Determine scroll direction
    bool scroll_up = scroll_accumulator > 0;

    // Reset accumulator (keep remainder for smoother scrolling)
    scroll_accumulator = std::fmod(scroll_accumulator, scroll_threshold);

    // Scroll by one row at a time, aligning rows to the top of the viewport
    float panel_height = GuiEntityInfoPanel::default_panel_size;
    float total_height = (cached_rows.size() + 1) * panel_height;
    float visible_height = rect.size.y;
    int max_scroll = std::max(0, static_cast<int>(std::ceil(total_height - visible_height)));

    // Scroll up (+) or down (-)
    if (scroll_up)
    {
        int current_row = static_cast<int>(scroll_position / panel_height);
        if (scroll_position % static_cast<int>(panel_height) != 0)
            current_row++;
        int target_row = std::max(0, current_row - 1);
        scroll_position = static_cast<int>(target_row * panel_height);
    }
    else
    {
        int current_row = static_cast<int>(scroll_position / panel_height);
        int target_row = current_row + 1;
        int target_position = static_cast<int>(target_row * panel_height);
        scroll_position = std::min(max_scroll, target_position);
    }

    updateScrollButtons();

    return true;
}

/*
void GuiEntityInfoPanelGrid::onDraw(sp::RenderTarget& renderer)
{
    for (auto panel : cached_panels)
    {
        if (!panel->isVisible()) continue;

        auto panel_rect = panel->getRect();
        auto back_style = panel->getBackStyle();
        const auto& back = back_style->get(panel->getPanelState());

        // Draw the panel background clipped to the grid's rect
        renderer.drawStretchedHVClipped(panel_rect, rect, back.size, back.texture, back.color);
    }
}
*/

void GuiEntityInfoPanelGrid::onUpdate()
{
    int max_cols = std::max(1, static_cast<int>(rect.size.x / GuiEntityInfoPanel::default_panel_size));

    // Update row visibility based on scroll position
    float panel_size = GuiEntityInfoPanel::default_panel_size;

    // Account for button space (40px top button + 40px bottom button)
    const float button_height = 40.0f;
    float content_top = rect.position.y + button_height;
    float content_bottom = rect.position.y + rect.size.y - button_height;

    for (size_t row_index = 0; row_index < cached_rows.size(); row_index++)
    {
        // Calculate expected row position
        float row_y = content_top + (row_index * panel_size) - scroll_position;

        // Check if entire row is completely within the visible content area
        bool is_visible = (row_y >= content_top) &&
                         (row_y + panel_size <= content_bottom);

        cached_rows[row_index]->setVisible(is_visible);
    }

    // Rebuild the grid only if entities or rect size changed
    if (entities == cached_entities && rect.size == cached_rect_size)
    {
        updateScrollButtons();
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
        scroll_up_button->disable();
        scroll_down_button->disable();
        return;
    }

    // Build new grid with at least 1 column
    int col = 0;
    int row = 0;
    int panel_idx = 0;
    GuiElement* current_row = nullptr;

    // Populate a berth panel for each entity
    for (auto& entity : entities)
    {
        // Create a new layout row on the first column
        if (col == 0 || col >= max_cols)
        {
            row++;

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
        else panel_callback = func;

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

    // Update scroll buttons
    updateScrollButtons();
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

void GuiEntityInfoPanelGrid::updateScrollButtons()
{
    // Calculate total content height
    float total_height = (cached_rows.size() + 1) * GuiEntityInfoPanel::default_panel_size;
    float visible_height = rect.size.y;
    int max_scroll = std::max(0, static_cast<int>(std::ceil(total_height - visible_height)));

    // Show/hide buttons based on whether the content needs scrolling
    if (total_height > visible_height)
    {
        // Disable up button if at top
        scroll_up_button->setEnable(scroll_position > 0);

        // Disable down button if at bottom
        scroll_down_button->setEnable(scroll_position < max_scroll);

        // Adjust content container width to account for buttons
        content_container->setSize(rect.size.x - 40.0f, GuiElement::GuiSizeMax);
    }
    else
    {
        scroll_up_button->disable();
        scroll_down_button->disable();
        scroll_position = 0;
        content_container->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
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
