#include "debugRenderer.h"
#include "multiplayer_server.h"
#include "hotkeyConfig.h"
#include "threatLevelEstimate.h"

static glm::u8vec4 line_colors[] = {
    {126, 178, 109, 255},   // #7EB26D green
    {234, 184, 57, 255},    // #EAB839 yellow
    {110, 208, 224, 255},   // #6ED0E0 cyan
    {239, 132, 60, 255},    // #EF843C orange
    {226, 77, 66, 255},     // #E24D42 red
    {31, 120, 193, 255},    // #1F78C1 blue
    {186, 67, 169, 255},    // #BA43A9 purple
    {112, 93, 160, 255},    // #705DA0 indigo
    {80, 134, 66, 255},     // #508642 dark green
    {204, 163, 0, 255},     // #CCA300 dark yellow
    {68, 126, 188, 255},    // #447EBC steel blue
    {193, 92, 23, 255},     // #C15C17 brown orange
    {137, 15, 2, 255},      // #890F02 dark red
    {10, 67, 124, 255},     // #0A437C navy
    {109, 31, 98, 255},     // #6D1F62 dark magenta
    {88, 68, 119, 255},     // #584477 dark purple
    {183, 219, 171, 255},   // #B7DBAB light green
    {244, 213, 152, 255},   // #F4D598 light yellow
    {112, 219, 237, 255},   // #70DBED light cyan
    {249, 186, 143, 255},   // #F9BA8F light orange
};

static constexpr size_t line_color_count = sizeof(line_colors) / sizeof(line_colors[0]);

static glm::u8vec4 colorForSeries(const string& name)
{
    return line_colors[std::hash<string>{}(name) % line_color_count];
}


DebugRenderer::DebugRenderer(RenderLayer* renderLayer)
: Renderable(renderLayer)
{
    fps = 0.0;
    fps_counter = 0;

    show_fps = false;
    show_datarate = false;
    show_timing_graph = false;

#ifdef DEBUG
    show_fps = show_datarate = true;
#endif
}

void DebugRenderer::render(sp::RenderTarget& renderer)
{
    if (keys.debug_show_fps.getDown())
    {
        show_fps = !show_fps;
        show_datarate = !show_datarate;
    }
    if (keys.debug_show_timing.getDown())
    {
        show_timing_graph = !show_timing_graph;
        timing_graph_points.clear();
        engine->setCollectEngineTiming(!engine->isCollectingEngineTiming());
    }

    fps_counter++;
    if (fps_counter > 30)
    {
        fps = fps_counter / fps_timer.restart();
        fps_counter = 0;
    }
    string text = "";
    if (show_fps)
    {
        text = text + "FPS: " + string(fps) + "\n";
        text = text + "Threat: raw=" + string(ThreatLevelEstimate::debug_max_threat, 1) + " smoothed=" + string(ThreatLevelEstimate::debug_smoothed_threat, 1);
        if (ThreatLevelEstimate::debug_threat_high)
            text = text + " [COMBAT]";
        text = text + "\n";
    }

    if (show_datarate && game_server)
    {
        text = text + string(game_server->getSendDataRate() / 1000, 1) + " kb per second\n";
        text = text + string(game_server->getSendDataRatePerClient() / 1000, 1) + " kb per client\n";
        text = text + (game_server->simulate_high_latency ? "[ON] " : "[OFF] ") + "High Latency (+250ms)\n";
        text = text + (game_server->simulate_random_latency ? "[ON] " : "[OFF] ") + "Random Latency (0-250ms)\n";
    }

    if (show_timing_graph)
    {
        auto window_size = renderer.getVirtualSize();
        size_t max_size = 0;
        for(auto it : timing_graph_points)
            max_size = std::max(it.second.size(), max_size);
        if (max_size > size_t(window_size.x)) {
            timing_graph_points.clear();
            max_size = 0;
        }
        for(auto [key, value] : engine->getEngineTiming()) {
            if (timing_graph_points[key].size() < max_size)
                timing_graph_points[key].resize(max_size, 0.0f);
            timing_graph_points[key].push_back(value);
        }

        key_order.clear();
        std::map<string, float> total;
        for(auto& [key, data] : timing_graph_points) {
            float sum = 0;
            for(auto value : data)
                sum += value;
            total[key] = sum;
            key_order.push_back(key);
        }
        std::sort(key_order.begin(), key_order.end(), [&total](const auto& a, const auto& b) { return total[a] > total[b]; });

        std::vector<glm::vec2> points;
        for (unsigned int n=0; n<max_size; n++)
            points.emplace_back(float(n), window_size.y);

        int index = 0;
        bool skip = false;
        for (const auto& key : key_order) {
            auto entry = timing_graph_enabled.find(key);
            if (entry != timing_graph_enabled.end() && !entry->second)
                continue;

            // if this line would be less than 1px above the previous line on average, skip drawing the rest of the lines
            if (total[key] * scale * 1000.0f < max_size)
                skip = true;

            for (unsigned int n=0; n<max_size; n++)
                points[n].y -= scale * 1000.0f * timing_graph_points[key][n];

            if (!skip)
            {
                renderer.drawLine(points, 1.0f, colorForSeries(key));
                index += 1;
            }
        }
        // If we skipped any lines, draw a white line at the top for the total.
        if (skip) renderer.drawLine(points, 1.0f, {255, 255, 255, 255});

        // 60 FPS line
        renderer.drawLine({0, window_size.y - 16.6f * scale}, {window_size.x, window_size.y - 16.6f * scale}, 2.0f, glm::u8vec4{255, 255, 255, 128});

        if (keys.debug_modifier.get())
            renderer.drawText(sp::Rect(0, 0, 0, 80), "(scale: " + string(scale, 1) + " px/ms)", sp::Alignment::BottomLeft, 16, nullptr, {255,255,255,255});

        index = 0;
        for (const auto& key : key_order)
        {
            auto color = colorForSeries(key);
            auto entry = timing_graph_enabled.find(key);
            if (entry != timing_graph_enabled.end() && !entry->second)
                color = {192,192,192,255};

            renderer.drawText(
                sp::Rect(0, 0, 0, 96 + 16 * index),
                key + ": " + string(timing_graph_points[key].back() * 1000, 5) + "ms",
                sp::Alignment::BottomLeft, 16, nullptr, color);
            index += 1;
        }
    }
    renderer.drawText(sp::Rect(0, 0, 0, 0), text, sp::Alignment::TopLeft, 18);
}

bool DebugRenderer::onPointerDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id) {
    if (show_datarate && game_server && button == sp::io::Pointer::Button::Left)
    {
        int line = int(position.y / 22.0f);
        int offset = show_fps ? 3 : 2;
        if (line == offset)
        {
            game_server->simulate_high_latency = !game_server->simulate_high_latency;
            return true;
        }
        if (line == offset + 1)
        {
            game_server->simulate_random_latency = !game_server->simulate_random_latency;
            return true;
        }
    }

    if (!show_timing_graph || !keys.debug_modifier.get())
        return false;

    auto idx = std::floor((position.y - 96.0f) / 16.0f);
    if (idx < -1 || idx > key_order.size())
        return false;

    if (idx == -1) {
        // Clicked on the scale text; adjust scale accordingly.
        switch(button) {
        case sp::io::Pointer::Button::Left:
            scale *= 2.0f;
            return true;
        case sp::io::Pointer::Button::Middle:
            scale = 10.0f;
            return true;
        case sp::io::Pointer::Button::Right:
            scale /= 2.0f;
            return true;
        default:
            return false;
        }
    }

    auto key = key_order[idx];

    switch (button) {
    case sp::io::Pointer::Button::Left:
        // Left button: toggle target entry
        {
            auto entry = timing_graph_enabled.find(key);
            if (entry != timing_graph_enabled.end())
                entry->second = !entry->second;
            else
                timing_graph_enabled.insert({key, false});
        }
        return true;

    case sp::io::Pointer::Button::Right:
        // Right button: toggle target entry and set all entries to match the new value
        {
            auto entry = timing_graph_enabled.find(key);
            bool target;

            if (entry != timing_graph_enabled.end())
                target = !entry->second;
            else
                target = false;

            if (target)
                timing_graph_enabled.clear();
            else
                for (auto entry : key_order)
                    timing_graph_enabled.insert_or_assign(entry, target);
        }
        return true;

    default:
        return false;
    }
}
