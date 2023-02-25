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
        if (game_server)
            selected_entry = game_server->getObjectById(value.toInt());
        else
            selected_entry = game_client->getObjectById(value.toInt());
        // LOG(INFO) << "HVC button index " << index << ", value " << value;
        display();
    });
    setAttribute("layout", "horizontal");
    item_list->setMargins(20, 20, 20, 120)->setSize(navigation_width, GuiElement::GuiSizeMax);
    display();
}

void HangarViewComponent::fillListBox()
{
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

    if (!selected_entry)
        return;
    /*

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

    fillListBox();
}
