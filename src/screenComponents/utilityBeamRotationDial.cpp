#include "utilityBeamRotationDial.h"
#include "playerInfo.h"
#include "screenComponents/radarView.h"
#include "components/mounts.h"
#include "gui/theme.h"

#include <algorithm>
#include <cmath>

GuiUtilityBeamRotationDial::GuiUtilityBeamRotationDial(GuiContainer* owner, string id, GuiRadarView* radar)
: GuiRotationDial(owner, id, 0.0f, 360.0f, 0.0f, 0.0f, 20.0f, [radar](float value)
{
    if (!my_spaceship) return;

    auto mounts = my_spaceship.getComponent<Mounts>();
    if (!mounts) return;

    Mount* ub_mount = nullptr;
    for (auto& m : mounts->mounts)
    {
        if (m.type == MountType::UtilityBeam && m.turret_arc > 0.0f)
        {
            ub_mount = &m;
            break;
        }
    }
    if (!ub_mount) return;

    auto my_transform = my_spaceship.getComponent<sp::Transform>();
    if (!my_transform) return;

    // Rotate handle command with ship radar.
    float new_value = value - my_transform->getRotation() + radar->getViewRotation() - 90.0f;

    // Normalize the dial's full-circle value to a signed bearing within the
    // turret's allowed aim range, matching the turret slider.
    const float aim_swing = std::max(0.0f, (ub_mount->turret_arc - ub_mount->arc) * 0.5f);
    const float low = ub_mount->turret_direction - aim_swing;
    const float high = ub_mount->turret_direction + aim_swing;
    const float center = (low + high) * 0.5f;

    new_value = std::fmod(std::fmod(new_value, 360.0f) + 360.0f, 360.0f);
    new_value = center + std::fmod(new_value - center + 360.0f, 360.0f);
    if (new_value - center > 180.0f) new_value -= 360.0f;
    new_value = std::clamp(new_value, low, high);

    my_player_info->commandSetUtilityBeamDirection(new_value);
}), radar(radar)
{
    // Fetch styles.
    dial_style = theme->getStyle("utilitybeamdial");
    back_style = theme->getStyle("utilitybeamdial.back");
    front_style = theme->getStyle("utilitybeamdial.front");
    texture_style = theme->getStyle("utilitybeamdial.front.texture");
    handle_style = theme->getStyle("utilitybeamdial.front.handle");
}

void GuiUtilityBeamRotationDial::onDraw(sp::RenderTarget& renderer)
{
    if (!my_spaceship) return;

    auto mounts = my_spaceship.getComponent<Mounts>();
    if (!mounts) return;

    const Mount* ub_mount = nullptr;
    for (auto& m : mounts->mounts)
    {
        if (m.type == MountType::UtilityBeam)
        {
            ub_mount = &m;
            break;
        }
    }
    if (!ub_mount) return;

    // The dial rotates only if the mount is an unlocked turret.
    if (ub_mount->turret_arc <= 0.0f || !ub_mount->turret_locked) return;

    // Rotate handle with ship radar.
    if (auto my_transform = my_spaceship.getComponent<sp::Transform>())
        setValue(ub_mount->direction + my_transform->getRotation() - radar->getViewRotation() + 90.0f);

    // Sync handle properties to state.
    setHandleArc(ub_mount->arc);
    handle_color = ub_mount->arc_color;

    GuiRotationDial::onDraw(renderer);
}

bool GuiUtilityBeamRotationDial::onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    if (!my_spaceship) return false;

    auto mounts = my_spaceship.getComponent<Mounts>();
    if (!mounts) return false;

    // Handle setting rotation by clicking the dial.
    for (auto& m : mounts->mounts)
    {
        if (m.type == MountType::UtilityBeam)
        {
            return m.turret_arc > 0.0f
                ? GuiRotationDial::onMouseDown(button, position, id)
                : false;
        }
    }

    return false;
}
