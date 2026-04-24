#include <i18n.h>
#include "playerInfo.h"
#include "droneDockingButton.h"
#include "gui/gui2_button.h"
#include "gui/gui2_listbox.h"
#include "gui/gui2_panel.h"
#include "systems/collision.h"
#include "systems/docking.h"
#include "components/collision.h"
#include "components/docking.h"
#include "components/drone.h"
#include "components/faction.h"
#include "components/name.h"
#include "ecs/query.h"

GuiDroneDockingButton::GuiDroneDockingButton(GuiContainer* owner, string id)
: GuiElement(owner, id)
{
    background_panel = new GuiPanel(this, id + "_BG");
    background_panel
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopLeft)
        ->hide();

    action_button = new GuiButton(this, id + "_BTN", tr("Request dock"),
        [this]()
        {
            if (!my_spaceship || !my_player_info) return;
            auto dl = my_spaceship.getComponent<DroneLink>();
            if (!dl || !dl->linked_drone) return;
            auto port = dl->linked_drone.getComponent<DockingPort>();
            if (!port) return;

            switch (port->state)
            {
            case DockingPort::State::NotDocking:
                dock_targets = findDockingTargets();
                // Expand list if it has more than one entry.
                // Otherwise, just dock.
                if (dock_targets.size() == 1)
                    my_player_info->commandDroneDock(dock_targets[0]);
                else if (dock_targets.size() > 1) expanded = true;
                break;
            case DockingPort::State::Docking:
                my_player_info->commandDroneAbortDock();
                break;
            case DockingPort::State::Docked:
                my_player_info->commandDroneUndock();
                break;
            }
        }
    );
    action_button
        ->setIcon("gui/icons/docking")
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopLeft);

    target_list = new GuiListbox(this, id + "_LIST",
        [this](int index, string value)
        {
            if (!my_player_info) return;
            expanded = false;
            if (value == "cancel") return;
            int idx = value.toInt();
            if (idx >= 0 && idx < static_cast<int>(dock_targets.size()))
                my_player_info->commandDroneDock(dock_targets[idx]);

        }
    );
    target_list
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopLeft)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide();
}

void GuiDroneDockingButton::onUpdate()
{
    if (!my_spaceship)
    {
        hide();
        return;
    }
    auto dl = my_spaceship.getComponent<DroneLink>();
    if (!dl || !dl->linked_drone)
    {
        hide();
        return;
    }
    auto port = dl->linked_drone.getComponent<DockingPort>();
    setVisible(port != nullptr);
    if (!port) return;

    // Collapse the listbox when docking state changes away from NotDocking.
    if (port->state != DockingPort::State::NotDocking) expanded = false;

    // Update the docking list if it's expanded.
    if (expanded)
    {
        dock_targets = findDockingTargets();
        if (dock_targets.empty()) expanded = false;
        else
        {
            target_list->clear();
            for (int i = 0; i < static_cast<int>(dock_targets.size()); i++)
            {
                // Use the callsign if available for the entry name.
                string name = tr("Unknown");
                if (auto cs = dock_targets[i].getComponent<CallSign>())
                    name = cs->callsign;
                target_list->addEntry(name, string(i));
            }
            target_list->addEntry(tr("Cancel"), "cancel");

            // Expand height to fit all entries.
            layout.size.y = (dock_targets.size() + 1) * item_height;
            background_panel->show();
            action_button->hide();
            target_list->show();
            return;
        }
    }

    // If collapsed, just show the action button.
    layout.size.y = item_height;
    background_panel->hide();
    target_list->hide();
    action_button->show();

    switch (port->state)
    {
    case DockingPort::State::NotDocking:
        dock_targets = findDockingTargets();
        action_button
            ->setText(tr("Request dock"))
            ->setEnable(DockingSystem::canStartDocking(dl->linked_drone) && !dock_targets.empty());
        break;
    case DockingPort::State::Docking:
        action_button
            ->setText(tr("Cancel docking"))
            ->enable();
        break;
    case DockingPort::State::Docked:
        action_button
            ->setText(tr("Undock"))
            ->enable();
        break;
    }
}

std::vector<sp::ecs::Entity> GuiDroneDockingButton::findDockingTargets()
{
    std::vector<sp::ecs::Entity> targets;
    if (!my_spaceship) return targets;
    auto dl = my_spaceship.getComponent<DroneLink>();
    if (!dl || !dl->linked_drone) return targets;
    auto port = dl->linked_drone.getComponent<DockingPort>();
    if (!port) return targets;
    auto my_transform = dl->linked_drone.getComponent<sp::Transform>();
    if (!my_transform) return targets;

    for (auto [entity, bay, transform, physics] : sp::ecs::Query<DockingBay, sp::Transform, sp::Physics>())
    {
        if (entity == dl->linked_drone) continue;
        if (Faction::getRelation(dl->linked_drone, entity) == FactionRelation::Enemy) continue;
        if (port->canDockOn(bay) == DockingStyle::None) continue;
        if (glm::length(transform.getPosition() - my_transform->getPosition()) > 1000.0f + std::max(physics.getSize().x, physics.getSize().y)) continue;
        targets.push_back(entity);
    }

    return targets;
}
