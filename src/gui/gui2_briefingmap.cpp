#include "gui/gui2_briefingmap.h"

#include "tween.h"
#include "gameGlobalInfo.h"
#include "main.h"
#include "vectorUtils.h"

#include <glm/gtc/type_precision.hpp>
#include <cmath>

GuiBriefingMap::GuiBriefingMap(GuiContainer* owner, string id)
: GuiElement(owner, id)
{
    // Theme the briefing map. Fall back to the default radar grid style.
    auto* theme = GuiTheme::getCurrentTheme();
    if (theme)
    {
        map_grid_style = theme->getStyle("briefing.map");
        if (!map_grid_style)
            map_grid_style = theme->getStyle("radar.sector_grid");
    }
}

GuiBriefingMap::~GuiBriefingMap()
{
}

glm::vec2 GuiBriefingMap::worldToScreen(glm::vec2 world_position)
{
    glm::vec2 map_center = rect.center();
    float scale = std::min(rect.size.x, rect.size.y) / 2.0f / zoom;
    return (world_position - camera_position) * scale + map_center;
}

void GuiBriefingMap::setMapData(const BriefingMapPage* data)
{
    map_data = data;
    map_duration = data ? data->duration : 0.0f;
    current_map_time = 0.0f;
    last_update_time = -1.0f;

    if (data && !data->keyframes.empty())
    {
        camera_position = data->keyframes[0].camera_position;
        zoom = data->keyframes[0].zoom;
        active_entities = data->keyframes[0].entities;
    }
    else
    {
        camera_position = {0.0f, 0.0f};
        zoom = 5000.0f;
        active_entities.clear();
    }
}

void GuiBriefingMap::clearMapData()
{
    setMapData(nullptr);
}

void GuiBriefingMap::tweenToTime(float time)
{
    if (!map_data || map_data->keyframes.empty()) return;

    const auto& kfs = map_data->keyframes;

    if (kfs.size() == 1)
    {
        camera_position = kfs[0].camera_position;
        zoom = kfs[0].zoom;
        active_entities = kfs[0].entities;
        return;
    }

    float clamped_time = std::clamp(time, 0.0f, map_duration);

    size_t idx_a = 0;
    size_t idx_b = 0;

    for (size_t i = 0; i < kfs.size(); i++)
    {
        if (kfs[i].timestamp <= clamped_time)
        {
            idx_a = i;
            idx_b = i;
        }

        if (kfs[i].timestamp > clamped_time)
        {
            idx_b = i;
            break;
        }
    }

    if (idx_a == idx_b)
    {
        camera_position = kfs[idx_a].camera_position;
        zoom = kfs[idx_a].zoom;
        active_entities = kfs[idx_a].entities;
        return;
    }

    const float time_a = kfs[idx_a].timestamp;
    const float time_b = kfs[idx_b].timestamp;

    // Camera tween
    camera_position = Tween<glm::vec2>::easeInOutSine(clamped_time, time_a, time_b,
        kfs[idx_a].camera_position, kfs[idx_b].camera_position);
    zoom = Tween<float>::easeInOutSine(clamped_time, time_a, time_b,
        kfs[idx_a].zoom, kfs[idx_b].zoom);

    // Entity tween: match by ID
    const auto& entities_a = kfs[idx_a].entities;
    const auto& entities_b = kfs[idx_b].entities;

    active_entities.clear();

    for (const auto& ea : entities_a)
    {
        BriefingMapEntity active = ea;

        for (const auto& eb : entities_b)
        {
            if (eb.id == ea.id)
            {
                active.position = Tween<glm::vec2>::easeInOutSine(
                    clamped_time,
                    time_a, time_b,
                    ea.position, eb.position
                );
                active.world_size = Tween<float>::easeInOutSine(
                    clamped_time,
                    time_a, time_b,
                    ea.world_size, eb.world_size
                );
                active.color = Tween<glm::u8vec4>::easeInOutSine(
                    clamped_time,
                    time_a, time_b,
                    ea.color, eb.color
                );

                // Rotation: shortest path
                float rot_a = ea.rotation;
                float rot_b = eb.rotation;
                float diff = fmodf(rot_b - rot_a + 180.0f, 360.0f) - 180.0f;
                rot_b = rot_a + diff;
                active.rotation = Tween<float>::easeInOutSine(
                    clamped_time,
                    time_a, time_b,
                    rot_a, rot_b
                );

                // Snap visibility and label at midpoint
                if (clamped_time >= (time_a + time_b) * 0.5f)
                {
                    active.visible = eb.visible;
                    active.label = eb.label;
                }
                break;
            }
        }

        active_entities.push_back(active);
    }

    // Add entities that only exist in keyframe B (fade in)
    for (const auto& eb : entities_b)
    {
        bool exists_in_a = false;
        for (const auto& ea : entities_a)
        {
            if (ea.id == eb.id)
            {
                exists_in_a = true;
                break;
            }
        }

        if (!exists_in_a)
        {
            BriefingMapEntity active = eb;
            if (clamped_time < (time_a + time_b) * 0.5f) active.visible = false;
            active_entities.push_back(active);
        }
    }
}

void GuiBriefingMap::onUpdate()
{
    if (!map_data || map_data->keyframes.empty()) return;

    float now = engine->getElapsedTime();

    if (last_update_time >= 0.0f)
        current_map_time += now - last_update_time;

    last_update_time = now;

    if (current_map_time > map_duration) current_map_time = map_duration;

    tweenToTime(current_map_time);
}

void GuiBriefingMap::onDraw(sp::RenderTarget& renderer)
{
    if (!map_data || map_data->keyframes.empty()) return;

    renderer.pushClipRegion(rect);

    // Background
    renderer.fillRect(rect, glm::u8vec4{20, 20, 20, 255});

    // Map grid, mimicking Relay map style.
    glm::u8vec4 grid_color = glm::u8vec4{64, 64, 128, 255};
    glm::u8vec4 subsector_grid_color = glm::u8vec4{64, 64, 128, 64};
    float grid_font_size = 24.0f;

    if (map_grid_style)
    {
        auto& grid_style = map_grid_style->get(getState());
        grid_color = grid_style.color;
        subsector_grid_color = glm::u8vec4{grid_color.r, grid_color.g, grid_color.b, static_cast<uint8_t>(grid_color.a / 2)};
        if (grid_style.size > 0.0f) grid_font_size = grid_style.size;
    }

    float sector_size = 20000.0f;
    const float super_sector_size = sector_size * 10.0f;
    if (zoom > super_sector_size) sector_size = super_sector_size;
    const float sub_sector_size = sector_size / 10.0f;

    glm::vec2 map_center = rect.center();
    const float scale = std::min(rect.size.x, rect.size.y) / 2.0f / zoom;

    // Visible bounds in world coordinates
    const int sector_x_min = static_cast<int>(std::floor((camera_position.x - (map_center.x - rect.position.x) / scale) / sector_size)) + 1;
    const int sector_x_max = static_cast<int>(std::floor((camera_position.x + (rect.position.x + rect.size.x - map_center.x) / scale) / sector_size));
    const int sector_y_min = static_cast<int>(std::floor((camera_position.y - (map_center.y - rect.position.y) / scale) / sector_size)) + 1;
    const int sector_y_max = static_cast<int>(std::floor((camera_position.y + (rect.position.y + rect.size.y - map_center.y) / scale) / sector_size));

    // Sector name labels
    if (zoom <= super_sector_size)
    {
        auto font = bold_font;
        if (map_grid_style)
        {
            auto& grid_style = map_grid_style->get(getState());
            if (grid_style.font) font = grid_style.font;
        }

        for (int sector_x = sector_x_min - 1; sector_x <= sector_x_max; sector_x++)
        {
            float x = sector_x * sector_size;
            for (int sector_y = sector_y_min - 1; sector_y <= sector_y_max; sector_y++)
            {
                float y = sector_y * sector_size;
                auto pos = worldToScreen(glm::vec2(x + (10.0f / scale), y + (10.0f / scale)));

                renderer.drawText(
                    sp::Rect(pos.x, pos.y, 0, 0),
                    getSectorName(glm::vec2(sector_x * sector_size + sub_sector_size, sector_y * sector_size + sub_sector_size)),
                    sp::Alignment::TopLeft,
                    grid_font_size,
                    font,
                    subsector_grid_color
                );
            }
        }
    }

    // Major grid lines
    for (int sector_x = sector_x_min; sector_x <= sector_x_max; sector_x++)
    {
        const float x = sector_x * sector_size;
        renderer.drawLine(
            worldToScreen(glm::vec2(x, (sector_y_min - 1) * sector_size)),
            worldToScreen(glm::vec2(x, (sector_y_max + 1) * sector_size)),
            1.0f,
            grid_color
        );
    }
    for (int sector_y = sector_y_min; sector_y <= sector_y_max; sector_y++)
    {
        const float y = sector_y * sector_size;
        renderer.drawLine(
            worldToScreen(glm::vec2((sector_x_min - 1) * sector_size, y)),
            worldToScreen(glm::vec2((sector_x_max + 1) * sector_size, y)),
            1.0f, grid_color
        );
    }

    // Sub-sector dots
    const int sub_sector_x_min = static_cast<int>(std::floor((camera_position.x - (map_center.x - rect.position.x) / scale) / sub_sector_size)) + 1;
    const int sub_sector_x_max = static_cast<int>(std::floor((camera_position.x + (rect.position.x + rect.size.x - map_center.x) / scale) / sub_sector_size));
    const int sub_sector_y_min = static_cast<int>(std::floor((camera_position.y - (map_center.y - rect.position.y) / scale) / sub_sector_size)) + 1;
    const int sub_sector_y_max = static_cast<int>(std::floor((camera_position.y + (rect.position.y + rect.size.y - map_center.y) / scale) / sub_sector_size));

    for (int sector_x = sub_sector_x_min; sector_x <= sub_sector_x_max; sector_x++)
    {
        const float x = sector_x * sub_sector_size;
        for (int sector_y = sub_sector_y_min; sector_y <= sub_sector_y_max; sector_y++)
        {
            renderer.drawPoint(
                worldToScreen(glm::vec2(x, sector_y * sub_sector_size)),
                grid_color
            );
        }
    }

    renderer.finish();

    // Entities
    for (const auto& entity : active_entities)
    {
        if (!entity.visible) continue;

        auto screen_pos = worldToScreen(entity.position);
        const float screen_size = entity.world_size * scale;

        if (!entity.radar_trace_image.empty())
        {
            renderer.drawRotatedSprite(
                entity.radar_trace_image,
                screen_pos,
                screen_size,
                entity.rotation,
                entity.color
            );
        }

        if (!entity.label.empty())
        {
            renderer.drawText(
                sp::Rect(screen_pos.x, screen_pos.y + screen_size * 0.5f, 0, 0),
                entity.label,
                sp::Alignment::TopCenter,
                18.0f,
                bold_font,
                entity.color
            );
        }
    }

    renderer.popClipRegion();
}
