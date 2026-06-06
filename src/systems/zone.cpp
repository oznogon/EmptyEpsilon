#include "systems/zone.h"
#include "main.h"


void ZoneSystem::update(float delta)
{
}

void ZoneSystem::renderOnRadar(sp::RenderTarget& renderer, sp::ecs::Entity e, glm::vec2 screen_position, float scale, float rotation, Zone& zone)
{
    // Don't draw invisible zones.
    if ((zone.color.a == 0 && zone.fill_color.a == 0) || zone.outline.empty())
        return;

    // Collect zone outline points in a vector.
    std::vector<glm::vec2> outline_points;
    for (auto p : zone.outline)
        outline_points.push_back(screen_position + rotateVec2(p * scale, -rotation));

    // Draw the fill and outline.
    if (zone.fill_color.a > 0)
        renderer.drawTriangles(outline_points, zone.triangles, zone.fill_color);

    outline_points.push_back(screen_position + rotateVec2(zone.outline[0] * scale, -rotation));
    if (zone.color.a > 0)
        renderer.drawLine(outline_points, 4.0f, zone.color);

    // If the zone has a label, draw it at the center of the zone polygon.
    if (zone.label.length() > 0)
    {
        auto label_pos = screen_position + zone.label_offset * scale;
        float font_size = zone.radius * scale / zone.label.length();
        renderer.drawText(sp::Rect(label_pos.x, label_pos.y, 0, 0), zone.label, sp::Alignment::Center, font_size, main_font, zone.color);
    }

    // On GM radar, draw a small circle at the zone's transform position (center)
    // to visualize the selectable center point without using a RadarTrace component.
    if (RadarRenderSystem::current_flags & RadarRenderSystem::FlagGM)
        renderer.drawCircleOutline(screen_position, 5.0f, 2.0f, glm::u8vec4(255, 255, 255, 64));
}
