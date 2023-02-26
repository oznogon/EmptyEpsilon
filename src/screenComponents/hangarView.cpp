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
        int32_t id = std::stoul(value, nullptr, 10);

        if (game_server)
            selected_entry = game_server->getObjectById(id);
        else
            selected_entry = game_client->getObjectById(id);

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

    item_list->setOptions(docked_labels, docked_ids);
}

void HangarViewComponent::display()
{
    if (keyvalue_container)
        keyvalue_container->destroy();
    if (details_container)
        details_container->destroy();
    if (selection_container)
        selection_container->destroy();

    /*
    +---------------------------------------+    +----------------------------------------+ 
    | (  SHIP  )  3d-model-view  ( undock ) |    | 3D-MODEL 3d-model 3d-model  ( undock ) |
    | (  ship  )  3d-model-view  ( energy ) |    | 3D-MODEL 3d-model 3d-model  ( energy ) |
    | (  ship  )  3d-model-view  ( repair ) |    | 3D-MODEL 3d-model 3d-model  ( repair ) |
    | (  ship  )  3d-model-view  ( weapon ) |    |                             ( weapon ) |
    | (  ship  )  3d-model-view  ( probes ) |    | 3d-model 3d-model 3d-model  ( probes ) |
    | (  ship  )                            | OR | 3d-model 3d-model 3d-model             |
    | (  ship  )  === k: v === === k: v === |    | 3d-model 3d-model 3d-model  == k: v == |
    | (  ship  )  === k: v === === k: v === |    |                             == k: v == |
    | (  ship  )  === k: v === === k: v === |    | 3d-model 3d-model 3d-model  == k: v == |
    | (  ship  )  === k: v === === k: v === |    | 3d-model 3d-model 3d-model  == k: v == |
    | (  ship  )  === k: v === === k: v === |    | 3d-model 3d-model 3d-model  == k: v == |
    +---------------------------------------+    +----------------------------------------+
    */

    selection_container = new GuiElement(this, "SELECTION_CONTAINER");
    selection_container->setMargins(20)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)->setAttribute("layout", "vertical");

    details_container = new GuiElement(selection_container, "DETAILS_CONTAINER");
    details_container->setMargins(0)->setSize(GuiElement::GuiSizeMax, 400)->setAttribute("layout", "horizontal");

    keyvalue_container = new GuiElement(selection_container, "KEY_VALUE_CONTAINER");
    keyvalue_container->setMargins(0)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)->setAttribute("layout", "vertical");

    fillListBox();

    if (!selected_entry)
        return;

    // Details container (horizontal)
    // Model view
    (new GuiRotatingModelView(details_container, "HANGAR_MODEL_VIEW", selected_entry->ship_template->model_data))->setRotationRate(0.0f)->rotateTo(90.0f)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Key/value container (vertical)
    // Key/value list
    if (selected_entry->getDockedStyle() == DockStyle::Internal)
        (new GuiKeyValueDisplay(keyvalue_container, "", 0.37, tr("Docked"), "In hangar"))->setSize(GuiElement::GuiSizeMax, 40);
    else
        (new GuiKeyValueDisplay(keyvalue_container, "", 0.37, tr("Docked"), "At airlock"))->setSize(GuiElement::GuiSizeMax, 40);

    // GMInfo is a shortcut to k/v content we want
    std::unordered_map<string, string> gm_info = selected_entry->getGMInfo();

    // - Hull
    (new GuiKeyValueDisplay(keyvalue_container, "", 0.37, tr("gm_info", "Hull"), gm_info[trMark("gm_info", "Hull")]))->setSize(GuiElement::GuiSizeMax, 40);

    // - Shield segments
    for (int n = 0; n < selected_entry->shield_count; n++)
        (new GuiKeyValueDisplay(keyvalue_container, "", 0.37, tr("gm_info", "Shield") + " " + string(n + 1), gm_info[trMark("gm_info", "Shield") + string(n + 1)]))->setSize(GuiElement::GuiSizeMax, 40);

    // - Systems status
    // - Weapons storage
}

void HangarViewComponent::onDraw(sp::RenderTarget& window)
{
    fillListBox();
}
