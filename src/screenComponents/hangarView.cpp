#include <algorithm>

#include <i18n.h>
#include "multiplayer_client.h"
#include "hangarView.h"
#include "playerInfo.h"
#include "spaceObjects/playerSpaceship.h"

#include "gui/gui2_listbox.h"
#include "gui/gui2_image.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_scrolltext.h"

#include "screenComponents/rotatingModelView.h"

HangarViewComponent::HangarViewComponent(GuiContainer* owner)
: GuiElement(owner, "HANGAR_VIEW")
{
    item_list = new GuiListbox(this, "HANGAR_ITEM_LIST", [this](int index, string value) {
        // P<ScienceDatabase> entry;

        // int32_t id = std::stoul(value, nullptr, 10);
        // selected_entry = findEntryById(id);
        LOG(INFO) << "HVC button index " << index << ", value " << value;
        display();
    });
    setAttribute("layout", "horizontal");
    item_list->setMargins(20, 20, 20, 120)->setSize(navigation_width, GuiElement::GuiSizeMax);
    display();
}

bool HangarViewComponent::findAndDisplayEntry(string name)
{
/*
    for(auto sd : ScienceDatabase::science_databases)
    {
        if (!sd) continue;
        if (sd->getName() == name)
        {
            selected_entry = sd;
            display();
            return true;
        }
    }
*/
    return false;
}

void HangarViewComponent::fillListBox()
{
    /*
    item_list->setOptions({});
    item_list->setSelectionIndex(-1);

    if (my_spaceship)
    {
        LOG(INFO) << "HVC::fillListBox(): my_spaceship " << my_spaceship->getCallSign();

        for (auto& ship : my_spaceship->ships_docked_externally)
        {
            //item_list->addEntry("x " + ship->getCallSign(), std::to_string(ship->getMultiplayerId()));
        }

        for (auto& ship : my_spaceship->ships_docked_internally)
        {
            item_list->addEntry("i " + ship->getCallSign(), std::to_string(ship->getMultiplayerId()));
        }
    }
    */
    /*
    // indices of child or sibling pages in the science_databases vector
    std::vector<unsigned> children_idx;
    std::vector<unsigned> siblings_idx;
    P<ScienceDatabase> parent_entry;

    for (unsigned idx=0; idx<ScienceDatabase::science_databases.size(); idx++)
    {
        P<ScienceDatabase> sd = ScienceDatabase::science_databases[idx];
        if (!sd) continue;

        if(selected_entry)
        {
            if(sd->getId() == selected_entry->getParentId())
            {
                parent_entry = sd;
            }
            if(sd->getParentId() == selected_entry->getParentId())
            {
                siblings_idx.push_back(idx);
            }
            if(sd->getParentId() == selected_entry->getId())
            {
                children_idx.push_back(idx);
            }
        }
        else
        {
            if(sd->getParentId() == 0)
            {
                siblings_idx.push_back(idx);
            }
        }
    }

    if(selected_entry)
    {
        if (children_idx.size() != 0)
        {
            item_list->addEntry(tr("button", "Back"), std::to_string(selected_entry->getParentId()));
        }
        else if(parent_entry)
        {
            item_list->addEntry(tr("button", "Back"), std::to_string(parent_entry->getParentId()));
        }
    }

    // the indices we actually want to display
    std::vector<unsigned> display_idx = children_idx.size() > 0 ? children_idx : siblings_idx;

    sort(display_idx.begin(), display_idx.end(), [](unsigned idxA, unsigned idxB) -> bool {
        return ScienceDatabase::science_databases[idxA] < ScienceDatabase::science_databases[idxB];
    });

    for (auto idx : display_idx)
    {
        P<ScienceDatabase> sd = ScienceDatabase::science_databases[idx];
        int item_list_idx = item_list->addEntry(sd->getName(), std::to_string(sd->getId()));
        if (selected_entry && selected_entry->getId() == sd->getId())
        {
            item_list->setSelectionIndex(item_list_idx);
        }
    }
    */
}

void HangarViewComponent::display()
{
    if (keyvalue_container)
        keyvalue_container->destroy();
    if (details_container)
        details_container->destroy();

    keyvalue_container = new GuiElement(this, "KEY_VALUE_CONTAINER");
    keyvalue_container->setMargins(20)->setSize(400, GuiElement::GuiSizeMax)->setAttribute("layout", "vertical");

    details_container = new GuiElement(this, "DETAILS_CONTAINER");
    details_container->setMargins(20)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)->setAttribute("layout", "vertical");
    details_container->layout.padding.top = 50;

    fillListBox();
    /*
    if (!selected_entry)
        return;

    bool has_key_values = selected_entry->keyValuePairs.size() > 0;
    bool has_image_or_model = selected_entry->hasModelData() || selected_entry->getImage() != "";
    bool has_text = selected_entry->getLongDescription().length() > 0;

    if (has_image_or_model)
    {
        GuiElement* visual = (new GuiElement(details_container, "HANGAR_VISUAL_ELEMENT"))->setMargins(0, 0, 0, 40)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        if (selected_entry->hasModelData())
        {
            (new GuiRotatingModelView(visual, "HANGAR_MODEL_VIEW", selected_entry->getModelData()))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
            if(selected_entry->getImage() != "")
            {
                (new GuiImage(visual, "HANGAR_IMAGE", selected_entry->image))->setMargins(0)->setSize(32, 32);
            }
        }
        else if(selected_entry->getImage() != "")
        {
            auto image = new GuiImage(visual, "HANGAR_IMAGE", selected_entry->image);
            image->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
        }
    }

    if (has_text)
    {
        (new GuiScrollText(details_container, "HANGAR_LONG_DESCRIPTION", selected_entry->getLongDescription()))->setTextSize(24)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    }

    if (has_key_values)
    {
        for (unsigned int n=0; n<selected_entry->keyValuePairs.size(); n++)
        {
            (new GuiKeyValueDisplay(keyvalue_container, "", 0.37, selected_entry->keyValuePairs[n].key, selected_entry->keyValuePairs[n].value))->setSize(GuiElement::GuiSizeMax, 40);
        }
    } else {
        keyvalue_container->destroy();
        keyvalue_container = nullptr;
    }
    */
}

void HangarViewComponent::onDraw(sp::RenderTarget& window)
{
    // REFACTOR ME
    // - designate internal or external

    std::vector<string> docked_labels, docked_ids;

    if (game_server)
    {
        for (auto& object_id : my_spaceship->docked_object_ids)
        {
            P<ShipTemplateBasedObject> ship = game_server->getObjectById(object_id);
            if (ship)
            {
                string ship_label = ship->getTypeName() + " " + ship->getCallSign();
                docked_labels.push_back(ship_label);
                docked_ids.push_back(string(object_id));
            }
        }
    }
    else
    {
        for (auto& object_id : my_spaceship->docked_object_ids)
        {
            P<ShipTemplateBasedObject> ship = game_client->getObjectById(object_id);
            if (ship)
            {
                string ship_label = ship->getTypeName() + " " + ship->getCallSign();
                docked_labels.push_back(ship_label);
                docked_ids.push_back(string(object_id));
            }
        }
    }

    // Flip the list so newly docked ships appear at the bottom.
    std::reverse(docked_labels.begin(), docked_labels.end());
    std::reverse(docked_ids.begin(), docked_ids.end());

    item_list->setOptions(docked_labels, docked_ids);
}
