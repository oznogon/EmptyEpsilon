#include "databaseView.h"
#include <i18n.h>
#include "ecs/query.h"
#include "playerInfo.h"

#include "gui/gui2_button.h"
#include "gui/gui2_image.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_listbox.h"
#include "gui/gui2_scrollcontainer.h"
#include "gui/gui2_scrolltextcontainer.h"

#include "screenComponents/rotatingModelView.h"

#include "components/database.h"
#include "components/rendering.h"

DatabaseViewComponent::DatabaseViewComponent(GuiContainer* owner)
: GuiElement(owner, "DATABASE_VIEW")
{
    setAttribute("layout", "horizontal");

    // Setup the navigation bar.
    navigation_element = new GuiElement(this, "DB_NAV_BAR");
    navigation_element
        ->setSize(navigation_width, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    navigation_element
        ->setAttribute("margin", "0, 20, 0, 0");

    back_button = new GuiButton(navigation_element, "DB_BACK_BUTTON", tr("databaseView", "Back"),
        [this]()
        {
            selected_entry = sp::ecs::Entity::fromString(back_entry);
            display();
        }
    );
    back_button
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->hide()
        ->setAttribute("margin", "0, 0, 0, 20");

    item_list = new GuiListbox(navigation_element, "DB_ITEM_LIST",
        [this](int index, string value)
        {
            selected_entry = sp::ecs::Entity::fromString(value);
            item_list->clearSearch();
            display();
        }
    );
    item_list
        ->addSearch([this](string) { fillListBox(); })
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    keyvalue_container = new GuiScrollContainer(this, "DB_KV_CONTAINER");
    keyvalue_container
        ->setSize(400.0f, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    details_container = new GuiElement(this, "DB_DETAILS_CONTAINER");
    details_container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    details_container
        ->setAttribute("margin", "20, 0, 0, 0");

    visual_element = new GuiElement(details_container, "DB_VISUAL_ELEMENT");
    visual_element
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide();

    description_text = new GuiScrollFormattedText(details_container, "DB_LONG_DESCRIPTION", "");
    description_text
        ->setTextSize(24.0f)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    display();
}

bool DatabaseViewComponent::findAndDisplayEntry(string name)
{
    for (auto [entity, database] : sp::ecs::Query<Database>())
    {
        if (database.name == name)
        {
            selected_entry = entity;
            display();
            return true;
        }
    }

    return false;
}

DatabaseViewComponent* DatabaseViewComponent::setDetailsPadding(int padding)
{
    details_padding = std::max(0, padding);
    return this;
}

DatabaseViewComponent* DatabaseViewComponent::setItemsPadding(int padding)
{
    items_padding = std::max(0, padding);
    return this;
}

void DatabaseViewComponent::fillListBox()
{
    // Reset the listbox item list.
    item_list
        ->setOptions({})
        ->setSelectionIndex(-1);

    // Handle and filter any search text.
    string search_text = item_list->getSearchText();
    if (!search_text.empty())
    {
        back_button->hide();

        std::vector<std::pair<sp::ecs::Entity, Database*>> matches;
        for (auto [entity, database] : sp::ecs::Query<Database>())
        {
            if (database.name.lower().find(search_text) >= 0)
                matches.push_back({entity, &database});
        }

        // Alphabetize by lowercased name.
        sort(matches.begin(), matches.end(),
            [](const auto& A, const auto& B)
            {
                return A.second->name.lower() < B.second->name.lower();
            }
        );

        // Populate the list and select the selected entry.
        for (auto [entity, database] : matches)
        {
            int idx = item_list->addEntry(database->name, entity.toString());
            if (selected_entry && selected_entry.getComponent<Database>() == database)
                item_list->setSelectionIndex(idx);
        }

        // Exit early; search results are separate from the tree.
        return;
    }

    // Indices of child or sibling pages in the science_databases vector.
    std::vector<std::pair<sp::ecs::Entity, Database*>> children;
    std::vector<std::pair<sp::ecs::Entity, Database*>> siblings;
    auto selected_database = selected_entry.getComponent<Database>();
    Database* parent_entry = nullptr;

    // Walk every Database component in the ECS world and sort each entity into
    // one of three buckets based on its relationship to the selected entry.
    for (auto [entity, database] : sp::ecs::Query<Database>())
    {
        if (selected_database)
        {
            // Parent of the selected entry.
            if (entity == selected_database->parent)
                parent_entry = &database;
            // Siblings of the selected entry.
            if (database.parent == selected_database->parent)
                siblings.push_back({entity, &database});
            // Immediate children of the selected entry.
            if (database.parent == selected_entry)
                children.push_back({entity, &database});
        }
        // No entry is selected, so collect top-level entries.
        else
            if (!database.parent) siblings.push_back({entity, &database});
    }

    // Show or hide the Back button based on where the user is in the tree.
    if (selected_database)
    {
        // If the selected entry has children, show the Back button and set its
        // target to the selected entry's parent.
        if (children.size() != 0)
        {
            back_button->show();
            back_entry = selected_database->parent.toString();
        }
        // If there are no children but the selected entry has a parent, set the
        // Back button to the grandparent so the user goes back up two levels.
        else if (parent_entry)
        {
            back_button->show();
            back_entry = parent_entry->parent.toString();
        }
    }
    else
    {
        // At the root level, hide the Back button.
        back_button->hide();
        back_entry = "";
    }

    // Entry indices we actually want to display.
    auto& display = children.size() > 0 ? children : siblings;

    // Alphabetize by lowercased name.
    sort(display.begin(), display.end(),
        [](const auto& A, const auto& B) -> bool
        {
            return A.second->name.lower() < B.second->name.lower();
        }
    );

    // Populate the list and select the selected entry.
    for (auto [entity, database] : display)
    {
        int item_list_idx = item_list->addEntry(database->name, entity.toString());
        if (selected_entry && selected_entry.getComponent<Database>() == database)
            item_list->setSelectionIndex(item_list_idx);
    }
}

void DatabaseViewComponent::display()
{
    // Reset the key-value container children.
    for (auto& child_ptr : keyvalue_container->getChildren())
    {
        if (child_ptr->getID() != "DB_KV_CONTAINER_SCROLLBAR_V")
            child_ptr->destroy();
    }
    cleanTree();

    // Set container padding.
    details_container
        ->setAttribute("padding", "0, 0, " + static_cast<string>(details_padding) + ", 0");

    navigation_element
        ->setAttribute("padding", "0, 0, 0, " + static_cast<string>(items_padding));

    // Populate the list box based on current state.
    fillListBox();

    // Hide everything and return early if there's no database.
    auto database = selected_entry.getComponent<Database>();
    if (!database)
    {
        keyvalue_container->hide();
        visual_element->hide();
        description_text->hide();
        return;
    }

    // Define whether the selected entry has contents for each container.
    auto mrc = selected_entry.getComponent<MeshRenderComponent>();
    bool has_key_values = database->key_values.size() > 0;
    bool has_image_or_model = mrc || database->image != "";
    bool has_text = database->description.length() > 0;

    if (has_image_or_model)
    {
        visual_element->show();

        // Destroy any previous image or model elements.
        for (auto& child_ptr : visual_element->getChildren())
            child_ptr->destroy();
        cleanTree();

        // Manage visual elements. Show a rotating model view if a model is
        // defined, and show an image if an image is defined. If both a model
        // and an image are defined, assume the image is a radar trace (32x32).
        // Images use GuiImageContain to scale with column widths if necessary.
        if (mrc)
        {
            model_view = new GuiRotatingModelView(visual_element, "DB_MODEL_VIEW", selected_entry);
            model_view->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

            if (database->image != "")
            {
                image_element = new GuiImageContain(visual_element, "DB_IMAGE", database->image);
                image_element->setSize(32.0f, 32.0f);
            }
        }
        else if (database->image != "")
        {
            image_element = new GuiImageContain(visual_element, "DB_IMAGE", database->image);
            image_element->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
        }
    }
    else visual_element->hide();

    // Populate the entry's description text, if present.
    // If not, empty the text contents but preserve visibility to retain scroll
    // state.
    description_text
        ->setText(has_text ? database->description : "")
        ->show();

    // Populate key-value pairs.
    if (has_key_values)
    {
        for (auto& kv : database->key_values)
        {
            (new GuiKeyValueDisplay(keyvalue_container, "", 0.37f, kv.key, kv.value))
                ->setSize(GuiElement::GuiSizeMax, 40.0f);
        }

        keyvalue_container->show();
    }
    else keyvalue_container->hide();

    // Force the key-value container to update its layout.
    keyvalue_container->updateLayout(keyvalue_container->getRect());
}
