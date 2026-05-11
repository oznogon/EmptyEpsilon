#include "damcon.h"

#include "i18n.h"
#include "playerInfo.h"

#include "gui/hotkeyConfig.h"
#include "gui/theme.h"
#include "gui/gui2_image.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_progressbar.h"

#include "screenComponents/shieldFreqencySelect.h"
#include "screenComponents/shipInternalView.h"
#include "screenComponents/customShipFunctions.h"

#include "components/coolant.h"
#include "components/hull.h"
#include "components/internalrooms.h"
#include "components/reactor.h"

#include <glm/geometric.hpp>
#include <algorithm>
#include <cmath>

DamageControlScreen::DamageControlScreen(GuiContainer* owner)
: GuiOverlay(owner, "DAMCON_SCREEN", GuiTheme::getColor("background"))
{
    internal_view = new GuiShipInternalView(this, "SHIP_INTERNAL_VIEW", room_size);
    internal_view
        ->setShip(my_spaceship)
        ->setPosition(300.0f, 0, sp::Alignment::TopLeft)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    auto system_health_layout = new GuiElement(this, "DAMCON_LAYOUT");
    system_health_layout
        ->setPosition(0.0f, 0.0f, sp::Alignment::CenterLeft)
        ->setSize(300.0f, 600.0f)
        ->setAttribute("layout", "vertical");

    hull_display = new GuiKeyValueDisplay(system_health_layout, "HULL", 0.8f, tr("damagecontrol", "Hull"), "0%");
    hull_display->setSize(GuiElement::GuiSizeMax, 40.0f);

    energy_display = new GuiKeyValueDisplay(system_health_layout, "ENERGY", 0.8f, tr("damagecontrol", "Energy"), "0");
    energy_display->setSize(GuiElement::GuiSizeMax, 40.0f);

    // Ship system group containers
    for (int n = 0; n < ShipSystem::COUNT; n++)
    {
        system_group[n] = new GuiElement(system_health_layout, "DAMCON_GROUP_" + string(n));
        system_group[n]
            ->setSize(GuiElement::GuiSizeMax, 68.0f)
            ->setAttribute("layout", "vertical");

        // Systen name and health indicator
        system_health[n] = new GuiKeyValueDisplay(system_group[n], "DAMCON_HEALTH_" + string(n), 0.8f, getLocaleSystemName(ShipSystem::Type(n)), "0%");
        system_health[n]->setSize(GuiElement::GuiSizeMax, 40.0f);

        auto bar_row = new GuiElement(system_group[n], "DAMCON_BARS_" + string(n));
        bar_row
            ->setSize(GuiElement::GuiSizeMax, 24.0f)
            ->setAttribute("layout", "horizontal");
        bar_row
            ->setAttribute("margin", "0, 0, -5, 10");

        // System health bar with icon.
        health_bar[n] = new GuiProgressbar(bar_row, "DAMCON_HEALTH_" + string(n), 0.0f, 1.0f, 0.0f);
        health_bar[n]
            ->setColor(glm::u8vec4(64, 128, 64, 192))
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        (new GuiImage(health_bar[n], "", "gui/icons/system_health"))
            ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
            ->setSize(GuiElement::GuiSizeMatchHeight, GuiElement::GuiSizeMax);

        // System heat bar with icon.
        heat_bar[n] = new GuiProgressbar(bar_row, "DAMCON_HEAT_" + string(n), 0.0f, 1.0f, 0.0f);
        heat_bar[n]
            ->setColor(glm::u8vec4(128, 128, 32, 192))
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        (new GuiImage(heat_bar[n], "", "gui/icons/status_overheat"))
            ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
            ->setSize(GuiElement::GuiSizeMatchHeight, GuiElement::GuiSizeMax);

        power_bar[n] = new GuiProgressbar(bar_row, "DAMCON_POWER_" + string(n), 0.0f, 3.0f, 0.0f);
        power_bar[n]
            ->setColor(glm::u8vec4(192, 192, 32, 192))
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        (new GuiImage(power_bar[n], "", "gui/icons/energy"))
            ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
            ->setSize(GuiElement::GuiSizeMatchHeight, GuiElement::GuiSizeMax);

        coolant_bar[n] = new GuiProgressbar(bar_row, "DAMCON_COOLANT_" + string(n), 0.0f, 10.0f, 0.0f);
        coolant_bar[n]
            ->setColor(glm::u8vec4(32, 128, 128, 192))
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        (new GuiImage(coolant_bar[n], "", "gui/icons/coolant"))
            ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
            ->setSize(GuiElement::GuiSizeMatchHeight, GuiElement::GuiSizeMax);
    }

    // TODO: Fix overlap with some ships 
    (new GuiCustomShipFunctions(this, CrewPosition::damageControl, ""))
        ->setPosition(-20.0f, 120.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, 150.0f);
}

void DamageControlScreen::onDraw(sp::RenderTarget& renderer)
{
    if (keys.damcon_toggle_detail_lines.getDown())
        line_mode = (line_mode + 1) % 3;

    GuiOverlay::onDraw(renderer);

    if (my_spaceship)
    {
        if (auto hull = my_spaceship.getComponent<Hull>())
        {
            const float hull_fraction = hull->current / hull->max;
            hull_display->setValue(string(static_cast<int>(100.0f * hull_fraction)) + "%");
            if (hull_fraction <= 0.25f)
                hull_display->setBackColor(glm::u8vec4(255, 0, 0, 255));
            else
                hull_display->setBackColor(glm::u8vec4{255, 255, 255, 255});
        }

        if (auto reactor = my_spaceship.getComponent<Reactor>())
        {
            const float energy = reactor->energy;
            const float energy_fraction = energy / reactor->max_energy;
            energy_display->setValue(string(static_cast<int>(energy)));
            if (energy_fraction <= 0.25f)
                energy_display->setBackColor(glm::u8vec4(255, 0, 0, 255));
            else
                energy_display->setBackColor(glm::u8vec4{255, 255, 255, 255});
        }

        for (int n = 0; n < ShipSystem::COUNT; n++)
        {
            auto sys = ShipSystem::get(my_spaceship, ShipSystem::Type(n));
            system_group[n]->setVisible(sys);
            if (sys)
            {
                const float health = sys->health;
                system_health[n]->setValue(string(int(sys->getSystemEffectiveness() * 100)) + "%");
                if (health < 0.0f)
                    system_health[n]->setBackColor(glm::u8vec4(255, 0, 0, 255));
                else if (sys->health_max < 1.0f)
                    system_health[n]->setBackColor(glm::u8vec4(255, 255, 0, 255));
                else
                    system_health[n]->setBackColor(glm::u8vec4{255, 255, 255, 255});

                power_bar[n]->setValue(sys->power_level);

                if (health < 0.0f)
                    health_bar[n]
                        ->setValue(-health)
                        ->setColor(glm::u8vec4(128, 32, 32, 192));
                else
                    health_bar[n]
                        ->setValue(health)
                        ->setColor(glm::u8vec4(64, static_cast<uint8_t>(128.0f * health), static_cast<uint8_t>(64.0f * health), 192));

                if (my_spaceship.hasComponent<Coolant>())
                {
                    if (my_spaceship.hasComponent<Reactor>())
                    {
                        const float heat = sys->heat_level;
                        heat_bar[n]
                            ->setValue(heat)
                            ->setColor(glm::u8vec4(128, static_cast<uint8_t>(32.0f + 96.0f * (1.0f - heat)), 32, 192))
                            ->show();
                    }
                    else heat_bar[n]->hide();

                    coolant_bar[n]
                        ->setValue(sys->coolant_level)
                        ->show();
                }
                else
                {
                    heat_bar[n]->hide();
                    coolant_bar[n]->hide();
                }
            }
        }
    }
}

static void drawThickPolyline(sp::RenderTarget& renderer, const std::vector<glm::vec2>& polyline, float width, glm::u8vec4 color, float lateral_offset = 0.0f)
{
    if (polyline.size() < 2) return;

    std::vector<glm::vec2> strip;
    strip.reserve(polyline.size() * 2);

    float half = width * 0.5f;

    for (size_t i = 0; i < polyline.size(); i++)
    {
        glm::vec2 normal;
        if (i == 0)
        {
            glm::vec2 d = glm::normalize(polyline[1] - polyline[0]);
            normal = glm::vec2(-d.y, d.x);
        }
        else if (i == polyline.size() - 1)
        {
            glm::vec2 d = glm::normalize(polyline[i] - polyline[i - 1]);
            normal = glm::vec2(-d.y, d.x);
        }
        else
        {
            glm::vec2 din = glm::normalize(polyline[i] - polyline[i - 1]);
            glm::vec2 dout = glm::normalize(polyline[i + 1] - polyline[i]);
            glm::vec2 tangent = din + dout;
            float tlen = glm::length(tangent);
            if (tlen < 0.001f)
                normal = glm::vec2(-din.y, din.x);
            else
            {
                tangent /= tlen;
                glm::vec2 n(-tangent.y, tangent.x);
                float dot = glm::dot(n, glm::vec2(-din.y, din.x));
                if (std::abs(dot) < 0.001f)
                    normal = glm::vec2(-din.y, din.x);
                else
                    normal = n / dot;
            }
        }

        glm::vec2 center = polyline[i] + normal * lateral_offset;
        strip.push_back(center + normal * half);
        strip.push_back(center - normal * half);
    }

    renderer.drawTriangleStrip(strip, color);
}

void DamageControlScreen::drawElements(glm::vec2 mouse_position, GuiElement* hovered_element, sp::RenderTarget& renderer)
{
    GuiContainer::drawElements(mouse_position, hovered_element, renderer);

    if (!my_spaceship) return;
    auto ir = my_spaceship.getComponent<InternalRooms>();
    if (!ir) return;

    auto room_min = ir->roomMin();
    auto room_max = ir->roomMax();
    auto total_size = room_max - room_min;
    const sp::Rect& iv_rect = internal_view->getRect();
    glm::vec2 room_container_size = glm::vec2(total_size) * room_size;
    glm::vec2 room_container_origin = iv_rect.position + (iv_rect.size - room_container_size) * 0.5f;

    std::vector<LineInfo> lines;

    for (int n = 0; n < ShipSystem::COUNT; n++)
    {
        if (!system_group[n]->isVisible()) continue;

        glm::vec2 room_center(-1.0f, -1.0f);
        for (const auto& room : ir->rooms)
        {
            if (room.system == ShipSystem::Type(n))
            {
                room_center = room_container_origin + (glm::vec2(room.position - room_min) + glm::vec2(room.size) * 0.5f) * room_size;
                break;
            }
        }
        if (room_center.x < 0.0f) continue;

        const sp::Rect& kv_rect = system_health[n]->getRect();
        glm::vec2 start(kv_rect.position.x + kv_rect.size.x, kv_rect.position.y + kv_rect.size.y * 0.5f);

        auto sys = ShipSystem::get(my_spaceship, ShipSystem::Type(n));
        glm::u8vec4 color;
        if (sys && sys->health < 0)
            color = glm::u8vec4(255, 0, 0, 128);
        else if (sys && sys->health_max < 1.0f)
            color = glm::u8vec4(255, 255, 0, 128);
        else
            color = glm::u8vec4(255, 255, 255, 128);

        lines.push_back({static_cast<unsigned int>(n), room_center, start, color});
    }

    // Group lines by shared room Y level and assign spread offsets so their
    // horizontal approach segments don't overlap.
    const float y_tolerance = 2.0f; // floating-point drift only; same grid Y = same screen Y
    const float line_spacing = 8.0f; // wider than the 5px line

    std::vector<bool> assigned(lines.size(), false);
    for (size_t i = 0; i < lines.size(); i++)
    {
        if (assigned[i]) continue;

        std::vector<size_t> group = {i};
        for (size_t j = i + 1; j < lines.size(); j++)
        {
            if (!assigned[j] && std::abs(lines[j].room_center.y - lines[i].room_center.y) < y_tolerance)
                group.push_back(j);
        }

        // Sort within group by source Y so offsets follow the panel order visually.
        std::sort(group.begin(), group.end(), [&](size_t a, size_t b) {
            return lines[a].start.y < lines[b].start.y;
        });

        float base = -line_spacing * static_cast<float>(group.size() - 1) * 0.5f;
        for (size_t k = 0; k < group.size(); k++)
        {
            lines[group[k]].y_offset = base + line_spacing * static_cast<float>(k);
            assigned[group[k]] = true;
        }
    }

    for (const auto& li : lines)
    {
        glm::vec2 start = li.start;
        glm::vec2 end = {li.room_center.x, li.room_center.y + li.y_offset};

        float dx = end.x - start.x;
        float dy = end.y - start.y;
        float abs_dy = std::abs(dy);
        float sign_dy = (dy >= 0.0f) ? 1.0f : -1.0f;

        std::vector<glm::vec2> polyline;
        if (dx >= abs_dy + 1.0f)
        {
            float half_h = (dx - abs_dy) * 0.95f;
            polyline = {
                start,
                {start.x + half_h, start.y},
                {start.x + half_h + abs_dy, end.y},
                end
            };
        }
        else if (dx > 0.0f)
        {
            polyline = {
                start,
                {end.x, start.y + sign_dy * dx},
                end
            };
        }
        else polyline = {start, end};

        if (line_mode == 2) continue;

        if (std::abs(li.y_offset) > 0.5f)
            polyline.push_back(li.room_center);

        if (line_mode == 0)
        {
            drawThickPolyline(renderer, polyline, 5.0f, li.color);
            continue;
        }

        auto sys = ShipSystem::get(my_spaceship, ShipSystem::Type(li.system_idx));
        if (!sys) continue;

        {
            float dev = 1.0f - sys->health;
            float norm = std::clamp(dev / 2.0f, 0.0f, 1.0f);
            uint8_t alpha = 26 + static_cast<uint8_t>(norm * 204.0f);
            glm::u8vec4 color = sys->health < 0.9f
                ? glm::u8vec4(255, 0, 0, alpha)
                : glm::u8vec4(64, 128, 64, alpha);
            drawThickPolyline(renderer, polyline, 4.0f, color, -9.0f);
        }

        {
            float dev, norm;
            if (sys->power_level < 1.0f)
            {
                dev = 1.0f - sys->power_level;
                norm = std::clamp(dev, 0.0f, 1.0f);
            }
            else
            {
                dev = sys->power_level - 1.0f;
                norm = std::clamp(dev / 2.0f, 0.0f, 1.0f);
            }
            uint8_t alpha = 26 + static_cast<uint8_t>(norm * 204.0f);
            glm::u8vec4 color;
            if (sys->power_level <= 1.0f)
            {
                color = glm::u8vec4(139, 69, 19, alpha);
            }
            else
            {
                float t = std::clamp(dev / 2.0f, 0.0f, 1.0f);
                uint8_t r = static_cast<uint8_t>(192 + (255 - 192) * t);
                uint8_t g = static_cast<uint8_t>(192 + (255 - 192) * t);
                uint8_t b = static_cast<uint8_t>(32 + (0 - 32) * t);
                color = glm::u8vec4(r, g, b, alpha);
            }
            drawThickPolyline(renderer, polyline, 4.0f, color, -3.0f);
        }

        {
            float norm = std::clamp(sys->coolant_level / 10.0f, 0.0f, 1.0f);
            uint8_t alpha = 26 + static_cast<uint8_t>(norm * 204.0f);
            drawThickPolyline(renderer, polyline, 4.0f, glm::u8vec4(32, 128, 128, alpha), 3.0f);
        }

        {
            float norm = std::clamp(sys->heat_level, 0.0f, 1.0f);
            uint8_t alpha = 26 + static_cast<uint8_t>(norm * 204.0f);
            drawThickPolyline(renderer, polyline, 4.0f, glm::u8vec4(255, 128, 0, alpha), 9.0f);
        }
    }
}
