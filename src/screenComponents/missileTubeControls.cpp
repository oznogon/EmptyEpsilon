#include "missileTubeControls.h"
#include "i18n.h"
#include "playerInfo.h"
#include "powerDamageIndicator.h"

#include "components/collision.h"
#include "components/missiletubes.h"
#include "components/mounts.h"
#include "components/missileWeaponTarget.h"
#include "components/target.h"
#include "components/warpdrive.h"

#include "systems/missilesystem.h"

#include "gui/gui2_button.h"
#include "gui/gui2_label.h"
#include "gui/gui2_progressbar.h"
#include "gui/gui2_togglebutton.h"

GuiMissileTubeControls::GuiMissileTubeControls(GuiContainer* owner, string id)
: GuiElement(owner, id)
{
    setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    setAttribute("layout", "verticalbottom");

    tube_rows_layout = new GuiElement(this, "TUBE_ROWS_LAYOUT");
    tube_rows_layout->setAttribute("layout", "vertical");

    for (int n = MW_MaxTypes-1; n >= 0; n--)
    {
        load_type_rows[n].layout = new GuiElement(this, id + "_ROW_" + string(n));
        load_type_rows[n].layout
            ->setSize(GuiElement::GuiSizeMax, 40.0f)
            ->setAttribute("layout", "horizontal");

        load_type_rows[n].button = new GuiToggleButton(load_type_rows[n].layout, id + "_MW_" + string(n), MissileWeaponDataRegistry::instance().getNameForIndex(n),
            [this, n](bool value)
            {
                if (value) load_type = n;
                else load_type = MW_None;

                for (int idx = 0; idx < MW_MaxTypes; idx++)
                    load_type_rows[idx].button->setValue(idx == load_type);
            }
        );
        load_type_rows[n].button
            ->setTextSize(28.0f)
            ->setSize(200.0f, 40.0f);
    }
}

static string getTubeName(float direction)
{
    if (std::abs(angleDifference(0.0f, direction)) <= 45)
        return tr("tube", "Front");

    if (std::abs(angleDifference(90.0f, direction)) < 45)
        return tr("tube", "Right");

    if (std::abs(angleDifference(-90.0f, direction)) < 45)
        return tr("tube", "Left");

    if (std::abs(angleDifference(180.0f, direction)) <= 45)
        return tr("tube", "Rear");

    return "?" + string(direction);
}

void GuiMissileTubeControls::onUpdate()
{
    if (!my_spaceship || !isEffectivelyVisible()) return;

    auto tubes = my_spaceship.getComponent<MissileTubes>();
    auto mounts = my_spaceship.getComponent<Mounts>();
    if (!tubes || !mounts)
    {
        for (int n = 0; n < MW_MaxTypes; n++) load_type_rows[n].layout->hide();
        for (auto& row : rows) row.layout->hide();
        return;
    }

    auto sys = ShipSystem::get(my_spaceship, ShipSystem::Type::MissileSystem);
    float health = sys->health;
    float power_level = sys->power_level;

    for (int n = 0; n < MW_MaxTypes; n++)
    {
        auto& registry = MissileWeaponDataRegistry::instance();
        load_type_rows[n].button->setText(registry.getNameForIndex(n) + " [" + string(tubes->storage[n]) + "/" + string(tubes->storage_max[n]) + "]");
        load_type_rows[n].layout->setVisible(tubes->storage_max[n] > 0 && registry.isPlayerWeapon(n));

        auto icon = registry.getIcon(n);
        if (!icon.empty()) load_type_rows[n].button->setIcon(icon);
    }

    unsigned int n = 0;
    for (auto& mount : mounts->mounts)
    {
        if (mount.type != MountType::MissileWeapon) continue;
        if (rows.size() <= n) createTubeRow();
        rows[n].layout->show();
        auto& registry = MissileWeaponDataRegistry::instance();

        if (mount.type_loaded >= 0)
        {
            auto icon = registry.getIcon(mount.type_loaded);
            if (!icon.empty())
                rows[n].fire_button->setIcon(icon, sp::Alignment::CenterLeft);
            else
                rows[n].fire_button->setIcon("gui/icons/missile", sp::Alignment::CenterLeft, mount.direction);
        }
        else
            rows[n].fire_button->setIcon("gui/icons/missile", sp::Alignment::CenterLeft, mount.direction);

        switch (mount.state)
        {
        case MountState::Empty:
            rows[n].load_button
                ->setText(tr("missile", "Load"))
                ->setEnable(mount.canLoad(load_type));

            if (health <= 0) rows[n].load_button->disable();

            rows[n].fire_button
                ->setText(getTubeName(mount.direction) + ": " + tr("missile", "Empty"))
                ->disable()
                ->show();

            rows[n].loading_bar->hide();
            break;
        case MountState::Loaded:
            rows[n].load_button->setText(tr("missile","Unload"));

            if ((health <= 0) || (power_level <= 0))
            {
                rows[n].fire_button
                    ->disable()
                    ->show();
                rows[n].load_button
                    ->disable()
                    ->show();
            }
            else
            {
                rows[n].fire_button
                    ->enable()
                    ->show();
                rows[n].load_button
                    ->enable()
                    ->show();
            }

            rows[n].fire_button->setText(getTubeName(mount.direction) + ": " + MissileWeaponDataRegistry::instance().getNameForIndex(mount.type_loaded));
            rows[n].loading_bar->hide();
            break;
        case MountState::Loading:
            rows[n].load_button
                ->setText(tr("missile", "Load"))
                ->disable();

            rows[n].fire_button
                ->setText(getTubeName(mount.direction) + ": " + MissileWeaponDataRegistry::instance().getNameForIndex(mount.type_loaded))
                ->hide();

            rows[n].loading_bar
                ->setValue(1.0f - mount.delay / mount.load_time)
                ->show();

            rows[n].loading_label->setText(tr("missile", "Loading"));
            break;
        case MountState::Unloading:
            rows[n].load_button
                ->setText(tr("missile", "Unload"))
                ->disable();

            rows[n].fire_button
                ->setText(MissileWeaponDataRegistry::instance().getNameForIndex(mount.type_loaded))
                ->hide();

            rows[n].loading_bar
                ->setValue(mount.delay / mount.load_time)
                ->show();

            rows[n].loading_label->setText(tr("missile", "Unloading"));
            break;
        case MountState::Firing:
            rows[n].load_button
                ->setText(tr("missile", "Load"))
                ->disable();

            rows[n].fire_button
                ->setText(tr("missile", "Firing"))
                ->disable()
                ->show();

            rows[n].loading_bar->hide();
        }

        auto warp = my_spaceship.getComponent<WarpDrive>();
        if (warp && warp->current > 0.0f) rows[n].fire_button->disable();
        n++;
    }

    while (rows.size() > n) removeTubeRow();

    // Handle hotkeys for default missile types.
    // TODO: Either make these hotkeys match by missile type string, or make
    // them select by index instead of missile type.
    if (keys.weapons_select_homing.getDown()) selectMissileWeapon(0);
    if (keys.weapons_select_nuke.getDown()) selectMissileWeapon(1);
    if (keys.weapons_select_mine.getDown()) selectMissileWeapon(2);
    if (keys.weapons_select_emp.getDown()) selectMissileWeapon(3);
    if (keys.weapons_select_hvli.getDown()) selectMissileWeapon(4);

    unsigned int missile_count = n;
    for (unsigned int hn = 0; hn < std::min(missile_count, 16U); hn++)
    {
        Mount* mnt = nullptr;
        {
            unsigned int idx = 0;
            for (auto& m : mounts->mounts)
            {
                if (m.type != MountType::MissileWeapon) continue;
                if (idx == hn) { mnt = &m; break; }
                idx++;
            }
        }
        if (!mnt) continue;
        if (keys.weapons_load_tube[hn].getDown())
            my_player_info->commandLoadTube(hn, load_type);
        if (keys.weapons_unload_tube[hn].getDown())
            my_player_info->commandUnloadTube(hn);
        if (keys.weapons_fire_tube[hn].getDown())
        {
            float target_angle = missile_target_angle;
            if (!manual_aim)
            {
                sp::ecs::Entity target_entity;
                if (auto tgt = my_spaceship.getComponent<MissileWeaponTarget>())
                    target_entity = tgt->entity;
                else if (auto tgt = my_spaceship.getComponent<Target>())
                    target_entity = tgt->entity;

                target_angle = MissileSystem::calculateFiringSolution(my_spaceship, *mnt, target_entity);
                if (target_angle == std::numeric_limits<float>::infinity())
                {
                    auto transform = my_spaceship.getComponent<sp::Transform>();
                    target_angle = (transform ? transform->getRotation() : 0.0f) + mnt->direction;
                }
            }
            my_player_info->commandFireTube(hn, target_angle);
        }
    }
}

void GuiMissileTubeControls::setMissileTargetAngle(float angle)
{
    missile_target_angle = angle;
}

float GuiMissileTubeControls::getMissileTargetAngle()
{
    return missile_target_angle;
}

void GuiMissileTubeControls::setManualAim(bool manual)
{
    manual_aim = manual;
}

bool GuiMissileTubeControls::getManualAim()
{
    return manual_aim;
}

void GuiMissileTubeControls::createTubeRow()
{
    int n = static_cast<int>(rows.size());

    TubeRow row;
    row.layout = new GuiElement(tube_rows_layout, id + "_ROW_" + string(n));
    row.layout->setAttribute("layout", "horizontal");

    row.load_button = new GuiButton(row.layout, id + "_" + string(n) + "_LOAD_BUTTON", tr("Load"),
        [this, n]()
        {
            if (!my_spaceship) return;

            auto mounts = my_spaceship.getComponent<Mounts>();
            if (!mounts) return;

            Mount* mnt = nullptr;
            {
                unsigned int idx = 0;
                for (auto& m : mounts->mounts)
                {
                    if (m.type != MountType::MissileWeapon) continue;
                    if (idx == static_cast<unsigned int>(n)) { mnt = &m; break; }
                    idx++;
                }
            }
            if (!mnt) return;

            if (mnt->state == MountState::Empty)
            {
                if (load_type != MW_None)
                    my_player_info->commandLoadTube(n, load_type);
            }
            else my_player_info->commandUnloadTube(n);
        }
    );
    row.load_button->setSize(130.0f, GuiElement::GuiSizeRow);

    row.fire_button = new GuiButton(row.layout, id + "_" + string(n) + "_FIRE_BUTTON", tr("Fire"),
        [this, n]()
        {
            if (!my_spaceship) return;

            auto mounts = my_spaceship.getComponent<Mounts>();
            if (!mounts) return;

            Mount* mnt = nullptr;
            {
                unsigned int idx = 0;
                for (auto& m : mounts->mounts)
                {
                    if (m.type != MountType::MissileWeapon) continue;
                    if (idx == static_cast<unsigned int>(n)) { mnt = &m; break; }
                    idx++;
                }
            }
            if (!mnt) return;

            if (mnt->state == MountState::Loaded)
            {
                float target_angle = missile_target_angle;

                if (!manual_aim)
                {
                    sp::ecs::Entity target_entity;

                    if (auto tgt = my_spaceship.getComponent<MissileWeaponTarget>())
                        target_entity = tgt->entity;
                    else if (auto tgt = my_spaceship.getComponent<Target>())
                        target_entity = tgt->entity;

                    target_angle = MissileSystem::calculateFiringSolution(my_spaceship, *mnt, target_entity);
                    if (target_angle == std::numeric_limits<float>::infinity())
                    {
                        auto transform = my_spaceship.getComponent<sp::Transform>();
                        target_angle = (transform ? transform->getRotation() : 0.0f) + mnt->direction;
                    }
                }
                my_player_info->commandFireTube(n, target_angle);
            }
        }
    );
    row.fire_button->setSize(200.0f, GuiElement::GuiSizeRow);

    (new GuiPowerDamageIndicator(row.load_button, id + "_" + string(n) + "_PDI", ShipSystem::Type::MissileSystem, sp::Alignment::CenterRight))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    row.loading_bar = new GuiProgressbar(row.layout, id + "_" + string(n) + "_PROGRESS", 0, 1.0, 0);
    row.loading_bar
        ->setColor(glm::u8vec4(128, 128, 128, 255))
        ->setSize(200.0f, GuiElement::GuiSizeRow);

    row.loading_label = new GuiLabel(row.loading_bar, id + "_" + string(n) + "_PROGRESS_LABEL", "Loading", 35.0f);
    row.loading_label->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    rows.push_back(row);
}

void GuiMissileTubeControls::removeTubeRow()
{
    rows.back().layout->destroy();
    rows.pop_back();
}

void GuiMissileTubeControls::selectMissileWeapon(int type)
{
    load_type = type;

    for (int idx = 0; idx < MW_MaxTypes; idx++)
        load_type_rows[idx].button->setValue(idx == type);
}
