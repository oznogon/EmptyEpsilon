#include "utilityBeamRotationDial.h"
#include "playerInfo.h"
#include "screenComponents/radarView.h"
#include "components/mounts.h"
#include "gui/theme.h"

GuiUtilityBeamRotationDial::GuiUtilityBeamRotationDial(GuiContainer* owner, string id, GuiRadarView* radar)
: GuiRotationDial(owner, id, 0.0f, 360.0f, 0.0f, 0.0f, 20.0f, [radar](float value)
{
    if (!my_spaceship) return;

    auto mounts = my_spaceship.getComponent<Mounts>();
    if (!mounts) return;

    bool has_ub = false;
    for (auto& m : mounts->mounts)
    {
        if (m.type == MountType::UtilityBeam) { has_ub = true; break; }
    }
    if (!has_ub) return;

    auto my_transform = my_spaceship.getComponent<sp::Transform>();
    if (!my_transform) return;

    // Rotate handle command with ship radar.
    float new_value = value - my_transform->getRotation() + radar->getViewRotation() - 90.0f;
    while (new_value < 0.0f) new_value += 360.0f;
    while (new_value > 360.0f) new_value -= 360.0f;
    my_player_info->commandSetUtilityBeamBearing(new_value);
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
        if (m.type == MountType::UtilityBeam) { ub_mount = &m; break; }
    }
    if (!ub_mount) return;

    // Rotate handle with ship radar.
    if (auto my_transform = my_spaceship.getComponent<sp::Transform>())
        setValue(ub_mount->bearing + my_transform->getRotation() - radar->getViewRotation() + 90.0f);

    // Sync handle properties to state.
    setHandleArc(ub_mount->arc);
    handle_color = ub_mount->arc_color;

    GuiRotationDial::onDraw(renderer);
}
