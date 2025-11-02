#include "dockingBayScreen.h"

#include "components/docking.h"
#include "gui/gui2_listbox.h"
#include "screenComponents/customShipFunctions.h"

DockingBayScreen::DockingBayScreen(GuiContainer* owner)
: GuiOverlay(owner, "DOCKING_BAY_SCREEN", colorConfig.background)
{
    // Layout elements
    GuiElement* layout = new GuiElement(this, "DOCKING_BAY_LAYOUT");
    layout
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");
    layout->setAttribute("padding", "20");

    left_column = new GuiElement(layout, "DOCKING_BAY_LEFT_COLUMN");
    left_column
        ->setSize(250.0f, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    right_column = new GuiElement(layout, "DOCKING_BAY_RIGHT_COLUMN");
    right_column
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    // Left column: Docking bay controls
    docking_bay_controls = new GuiListbox(left_column, "DOCKING_BAY_CONTROLS",
        [](int index, string value)
        {
            LOG(Info, "docking_bay_controls index ", index, ", value ", value);
        }
    );
    docking_bay_controls->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Right column: Docked ship, cargo selection
    docking_bay_ships = new GuiListbox(right_column, "DOCKING_BAY_SHIPS",
        [](int index, string value)
        {
            LOG(Info, "docking_bay_ships ", index, ", value ", value);
        }
    );
    docking_bay_ships->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Custom ship functions
    (new GuiCustomShipFunctions(this, CrewPosition::dockingBay, "DOCKING_BAY_CSF"))
        ->setPosition(-20.0f, 120.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, GuiElement::GuiSizeMax);
}

void DockingBayScreen::onDraw(sp::RenderTarget& target)
{
}

void DockingBayScreen::onUpdate()
{
    if (!my_spaceship) return;

    if (auto bay = my_spaceship.getComponent<DockingBay>())
    {
        auto docked_entities = bay->docked_entities;

        for (auto entity : docked_entities)
        {
            LOG(Info, "docked_entities onUpdate: ", entity.toString());
        }

        if (!docked_entities.empty())
        {
            std::vector<string> docked_entities_str;
            for (auto docked_entity: docked_entities) docked_entities_str.emplace_back(docked_entity.toString());
            docking_bay_ships->setOptions(docked_entities_str);
        }
    }
}
