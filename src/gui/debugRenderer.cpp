#include "debugRenderer.h"
#include <i18n.h>
#include "multiplayer_server.h"
#include "hotkeyConfig.h"
#include "threatLevelEstimate.h"
#include "graphics/renderTarget.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_togglebutton.h"
#include "gui/gui2_button.h"
#include "gui/gui2_slider.h"
#include "gui/gui2_label.h"

static glm::u8vec4 line_colors[] = {
    {126, 178, 109, 255}, // #7EB26D green
    {234, 184,  57, 255}, // #EAB839 yellow
    {110, 208, 224, 255}, // #6ED0E0 cyan
    {239, 132,  60, 255}, // #EF843C orange
    {226,  77,  66, 255}, // #E24D42 red
    { 31, 120, 193, 255}, // #1F78C1 blue
    {186,  67, 169, 255}, // #BA43A9 purple
    {112,  93, 160, 255}, // #705DA0 indigo
    { 80, 134,  66, 255}, // #508642 dark green
    {204, 163,   0, 255}, // #CCA300 dark yellow
    { 68, 126, 188, 255}, // #447EBC steel blue
    {193,  92,  23, 255}, // #C15C17 brown orange
    {137,  15,   2, 255}, // #890F02 dark red
    { 10,  67, 124, 255}, // #0A437C navy
    {109,  31,  98, 255}, // #6D1F62 dark magenta
    { 88,  68, 119, 255}, // #584477 dark purple
    {183, 219, 171, 255}, // #B7DBAB light green
    {244, 213, 152, 255}, // #F4D598 light yellow
    {112, 219, 237, 255}, // #70DBED light cyan
    {249, 186, 143, 255}, // #F9BA8F light orange
};

static constexpr size_t line_color_count = sizeof(line_colors) / sizeof(line_colors[0]);

static glm::u8vec4 colorForSeries(const string& name)
{
    return line_colors[std::hash<string>{}(name) % line_color_count];
}

DebugRenderer::DebugRenderer(GuiContainer* owner)
: GuiResizableDialog(owner, "DEBUG_RENDERER", tr("debug", "Debug"))
{
    fps_display = new GuiKeyValueDisplay(contents, "DEBUG_FPS", 0.3f, tr("debug", "FPS"), "");
    fps_display
        ->setTextSize(18.0f)
        ->setSize(GuiElement::GuiSizeMax, 25.0f);

    threat_display = new GuiKeyValueDisplay(contents, "DEBUG_THREAT", 0.3f, tr("debug", "Threat"), "");
    threat_display
        ->setTextSize(18.0f)
        ->setSize(GuiElement::GuiSizeMax, 25.0f);

    rate_display = new GuiKeyValueDisplay(contents, "DEBUG_RATE", 0.3f, tr("debug", "Data rate"), "");
    rate_display
        ->setTextSize(18.0f)
        ->setSize(GuiElement::GuiSizeMax, 25.0f);

    high_latency_button = new GuiToggleButton(contents, "DEBUG_HIGH_LATENCY", tr("debug", "Sim high latency (+250ms)"),
        [](bool value)
        { if (game_server) game_server->simulate_high_latency = value; }
    );
    high_latency_button
        ->setTextSize(18.0f)
        ->setSize(GuiElement::GuiSizeMax, 25.0f);

    random_latency_button = new GuiToggleButton(contents, "DEBUG_RANDOM_LATENCY", tr("debug", "Sim random latency (0-250ms)"),
        [](bool value)
        { if (game_server) game_server->simulate_random_latency = value; }
    );
    random_latency_button
        ->setTextSize(18.0f)
        ->setSize(GuiElement::GuiSizeMax, 25.0f);

    // Toolbar widgets
    toolbar = new GuiElement(this, "TOOLBAR");
    toolbar
        ->setSize(GuiElement::GuiSizeMax, 20.0f)
        ->setAttribute("layout", "horizontal");
    toolbar
        ->setAttribute("padding", "0, 20, 0, 0");

    pause_button = new GuiToggleButton(toolbar, "TIMING_PAUSE", "||" /* pause symbol */,
        [this](bool value) { timing_paused = value; }
    );
    pause_button
        ->setTextSize(14.0f)
        ->setSize(24.0f, GuiElement::GuiSizeMax);

    scale_down_button = new GuiButton(toolbar, "TIMING_SCALE_DOWN", "-",
        [this]()
        { scale = std::max(0.5f, scale * 0.5f); }
    );
    scale_down_button
        ->setTextSize(14.0f)
        ->setSize(18.0f, GuiElement::GuiSizeMax);

    scale_reset_button = new GuiButton(toolbar, "TIMING_SCALE_RESET", tr("debug", "Reset"),
        [this]()
        {
            scale_slider->setValue(10.0f);
            scale = 10.0f;
        }
    );
    scale_reset_button
        ->setTextSize(11.0f)
        ->setSize(32.0f, GuiElement::GuiSizeMax);

    scale_up_button = new GuiButton(toolbar, "TIMING_SCALE_UP", "+",
        [this]()
        { scale = std::min(100.0f, scale * 2.0f); }
    );
    scale_up_button
        ->setTextSize(14.0f)
        ->setSize(18.0f, GuiElement::GuiSizeMax);

    scale_slider = new GuiSlider(toolbar, "TIMING_SCALE", 0.5f, 100.0f, scale,
        [this](float value)
        { scale = value; }
    );
    scale_slider
        ->setSize(100.0f, GuiElement::GuiSizeMax);

    scale_label = new GuiLabel(scale_slider, "SCALE_LABEL", "", 12.0f);
    scale_label
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Spacer
    (new GuiElement(toolbar, ""))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    tw_down_button = new GuiButton(toolbar, "TIMING_TW_DOWN", "-",
        [this]()
        { time_window = std::max(120.0f, time_window - 60.0f); }
    );
    tw_down_button
        ->setTextSize(14.0f)
        ->setSize(18.0f, GuiElement::GuiSizeMax);

    tw_reset_button = new GuiButton(toolbar, "TIMING_TW_RESET", tr("debug", "Reset"),
        [this]()
        {
            time_window = 300.0f;
            tw_slider->setValue(300.0f);
        }
    );
    tw_reset_button
        ->setTextSize(11.0f)
        ->setSize(32.0f, GuiElement::GuiSizeMax);

    tw_up_button = new GuiButton(toolbar, "TIMING_TW_UP", "+",
        [this]()
        { time_window = std::min(static_cast<float>(MAX_TIMING_POINTS), time_window + 60.0f); }
    );
    tw_up_button
        ->setTextSize(14.0f)
        ->setSize(18.0f, GuiElement::GuiSizeMax);

    tw_slider = new GuiSlider(toolbar, "TIMING_WINDOW", 120.0f, static_cast<float>(MAX_TIMING_POINTS), time_window,
        [this](float value) { time_window = value; }
    );
    tw_slider
        ->addSnapValue(120.0f, 30.0f)
        ->addSnapValue(300.0f, 30.0f)
        ->addSnapValue(600.0f, 30.0f)
        ->addSnapValue(900.0f, 30.0f)
        ->addSnapValue(1200.0f, 30.0f)
        ->addSnapValue(1500.0f, 30.0f)
        ->addSnapValue(static_cast<float>(MAX_TIMING_POINTS), 30.0f)
        ->setSize(100.0f, GuiElement::GuiSizeMax);

    tw_label = new GuiLabel(tw_slider, "TW_LABEL", "", 12.0f);
    tw_label
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Spacer
    (new GuiElement(toolbar, ""))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    stack_button = new GuiToggleButton(toolbar, "TIMING_STACK", tr("debug", "Stack"),
        [this](bool value)
        { timing_graph_stacked = value; }
    );
    stack_button
        ->setTextSize(11.0f)
        ->setSize(50.0f, GuiElement::GuiSizeMax);

    // Default to small min_/max_size.
    min_size = max_size = glm::vec2(400.0f, 175.0f);
}

void DebugRenderer::onDraw(sp::RenderTarget& renderer)
{
    if (keys.debug_show_timing.isDiscreteStepDown())
    {
        show_timing_graph = !show_timing_graph;
        timing_graph_points.clear();
        engine->setCollectEngineTiming(!engine->isCollectingEngineTiming());
    }

    if (keys.debug_minimize.getDown())
        minimize(!isMinimized());

#ifdef DEBUG
    if (keys.debug_show_atlas.getDown())
        show_atlas = !show_atlas;
#endif

    fps_counter++;
    if (fps_counter > 30)
    {
        fps = fps_counter / fps_timer.restart();
        fps_counter = 0;
    }

    // Reset size constraints before minimize check so the dialog can collapse
    if (show_atlas)
    {
        max_size = glm::vec2(600.0f, 900.0f);
        min_size = max_size;
    }
    else if (show_timing_graph)
    {
        max_size = glm::vec2(1200.0f, 900.0f);
        min_size = glm::vec2{600.0f, 600.0f};
    }
    else min_size = max_size = glm::vec2{400.0f, 175.0f};

    if (isMinimized())
    {
        toolbar->hide();
        min_size.y = 30.0f;
        string title_monitor_string = tr("debug", "Debug")
            + " - "
            + tr("debug", "FPS: {fps}").format({{"fps", string(fps)}}
        );

        if (game_server)
        {
            title_monitor_string += " - "
                + tr("debug", "{send_per_second} kb/s, {send_per_client} kb/client").format({
                    {"send_per_second", string(game_server->getSendDataRate() / 1000, 1)},
                    {"send_per_client", string(game_server->getSendDataRatePerClient() / 1000, 1)}
            });
        }

        setTitle(title_monitor_string);
        GuiResizableDialog::onDraw(renderer);

        // Exit early if minimized.
        return;
    }

    setTitle(tr("debug", "Debug"));

    rate_display->setVisible(show_datarate && game_server);
    high_latency_button->setVisible(show_datarate && game_server);
    random_latency_button->setVisible(show_datarate && game_server);

    fps_display->setValue(string(fps));

    string threat_text = tr("debug", "R {raw}, S {smoothed}").format({
        {"raw", string(ThreatLevelEstimate::DEBUG_MAX_THREAT, 1)},
        {"smoothed", string(ThreatLevelEstimate::DEBUG_SMOOTHED_THREAD, 1)}
    });
    if (ThreatLevelEstimate::DEBUG_THREAT_HIGH)
        threat_text += " " + tr("debug", "[COMBAT]");
    threat_display->setValue(threat_text);

    if (game_server)
    {
        rate_display->setValue(
            tr("debug", "{send_per_second} kb/s, {send_per_client} kb/client").format({
                {"send_per_second", string(game_server->getSendDataRate() / 1000, 1)},
                {"send_per_client", string(game_server->getSendDataRatePerClient() / 1000, 1)}
            })
        );
        high_latency_button->setValue(game_server->simulate_high_latency);
        random_latency_button->setValue(game_server->simulate_random_latency);
    }

    auto contents_rect = contents->getRect();
    float widget_area_bottom = contents_rect.position.y;
    for (auto& child : contents->getChildren())
    {
        if (child->isVisible())
        {
            float child_bottom = child->getRect().position.y + child->getRect().size.y;
            if (child_bottom > widget_area_bottom)
                widget_area_bottom = child_bottom;
        }
    }

    const float legend_width = 200.0f;
    const float text_line_height = 18.0f;
    const float font_size = 14.0f;
    const float checkbox_width = 18.0f;

    auto graph_base_y = contents_rect.position.y + contents_rect.size.y - 30.0f;
    float graph_left = contents_rect.position.x + legend_width;
    float graph_width = std::max(50.0f, contents_rect.size.x - legend_width);
    unsigned int draw_count = static_cast<unsigned int>(std::max(graph_width, 1.0f));
    float toolbar_y = widget_area_bottom - rect.position.y;
    float clip_top = widget_area_bottom + 20.0f /* toolbar height */;

    float max_per_frame = 0.0f;
    float graph_pixel_height = 0.0f;
    std::map<string, float> total;
    size_t visible_points = (size_t)time_window;

    if (show_timing_graph)
    {
        toolbar
            ->setPosition(graph_left - rect.position.x, toolbar_y)
            ->show();

        pause_button
            ->setText(timing_paused
                ? "||" /* pause symbol */
                : ">" /* play symbol */
            );

        float slider_w = std::max(60.0f, graph_width * 0.15f);
        scale_slider->setSize(slider_w, GuiElement::GuiSizeMax);
        tw_slider->setSize(slider_w, GuiElement::GuiSizeMax);

        stack_button
            ->setText(timing_graph_stacked
                ? tr("debug", "Stack")
                : tr("debug", "Separate")
            );

        // Data collection (skipped when paused)
        if (!timing_paused)
        {
            std::unordered_set<string> updated_keys;
            for (auto [key, value] : engine->getEngineTiming())
            {
                auto& data = timing_graph_points[key];
                data.push_back(value);
                updated_keys.insert(key);
                while (data.size() > (size_t)time_window) data.pop_front();
            }

            // Zero-pad deques not updated this frame so they scroll left with
            // the active data instead of freezing in place.  This keeps all
            // series the same length, which is required for correct stacking.
            for (auto& [key, data] : timing_graph_points)
            {
                if (updated_keys.find(key) == updated_keys.end())
                {
                    data.push_back(0.0f);
                    while (data.size() > (size_t)time_window)
                        data.pop_front();
                }
            }
        }

        // Compute visible sample count (respecting time_window)
        size_t max_points = 0;
        for (auto it : timing_graph_points)
            max_points = std::max(it.second.size(), max_points);

        visible_points = std::min(max_points, (size_t)time_window);

        // Trim stale deques without zero-padding
        for (auto& [key, data] : timing_graph_points)
        {
            if (data.size() > (size_t)time_window)
            {
                auto trim = data.size() - (size_t)time_window;
                data.erase(data.begin(), data.begin() + trim);
            }
        }

        // Sort series by total time (descending)
        key_order.clear();
        for (auto& [key, data] : timing_graph_points)
        {
            float sum = 0.0f;
            for (auto value : data) sum += value;
            total[key] = sum;
            key_order.push_back(key);
        }

        std::sort(
            key_order.begin(),
            key_order.end(),
            [&total](const auto& a, const auto& b)
            { return total[a] > total[b]; }
        );

        // Compute max per-frame value among enabled series (for gridlines & clipping)
        max_per_frame = 0.0f;
        for (const auto& key : key_order)
        {
            auto entry = timing_graph_enabled.find(key);
            if (entry != timing_graph_enabled.end() && !entry->second) continue;
            for (auto v : timing_graph_points[key])
                if (v > max_per_frame) max_per_frame = v;
        }
        graph_pixel_height = max_per_frame * scale * 1000.0f;

        // Update toolbar label text
        scale_label->setText(tr("debug", "Y: {s} px/ms").format({
            {"s", string(scale, 1)}
        }));

        float total_sec = visible_points / std::max(fps, 5.0f);
        tw_label->setText(tr("debug", "X: Last {sec}s").format({
            {"sec", string(total_sec, 1)}
        }));
    }

    // Draw GUI elements before drawing the graph.
    GuiResizableDialog::onDraw(renderer);

    if (show_timing_graph)
    {
        // Legend with toggles
        {
            float legend_y = widget_area_bottom;

            // Compute how many items fit, reserving 1 slot for "+N more..." if needed
            int max_fit = static_cast<int>((graph_base_y - legend_y) / text_line_height);
            if (max_fit < 0) max_fit = 0;

            int display_count = static_cast<int>(key_order.size());
            if (display_count > max_fit)
                display_count = max_fit;

            // size_t overflow = key_order.size() - display_count;

            for (int idx = 0; idx < display_count && idx < static_cast<int>(key_order.size()); idx++)
            {
                const auto& key = key_order[idx];

                auto color = colorForSeries(key);
                auto entry = timing_graph_enabled.find(key);
                bool enabled = (entry == timing_graph_enabled.end() || entry->second);
                if (!enabled) color = {128, 128, 128, 255};

                // Checkbox glyph
                string check = enabled ? "[x]" : "[ ]";
                renderer.drawText(
                    sp::Rect(contents_rect.position.x, legend_y, checkbox_width, text_line_height),
                    check,
                    sp::Alignment::TopLeft,
                    font_size,
                    nullptr,
                    color
                );

                // Label + value
                renderer.drawText(
                    sp::Rect(
                        contents_rect.position.x + checkbox_width,
                        legend_y,
                        legend_width - checkbox_width,
                        text_line_height
                    ),
                    key + ": " + string(timing_graph_points[key].back() * 1000, 5) + "ms",
                    sp::Alignment::TopLeft,
                    font_size,
                    nullptr,
                    color
                );

                legend_y += text_line_height;
            }

            // Show "+N more..." only when items remain after reserving the slot
            size_t remaining = key_order.size() - display_count;
            if (remaining > 0)
            {
                renderer.drawText(
                    sp::Rect(contents_rect.position.x, legend_y, legend_width, text_line_height),
                    tr("debug", "+{n} more...").format({
                        {"n", string(static_cast<int>(remaining))}
                    }),
                    sp::Alignment::TopLeft,
                    font_size,
                    nullptr,
                    {128, 128, 128, 255}
                );
            }
        }

        // Y-axis gridlines + labels
        {
            if (graph_pixel_height > 0.0f)
            {
                float max_time_ms = max_per_frame * 1000.0f;
                float interval = 1.0f;
                float label_center_x = graph_left + graph_width * 0.5f;

                glm::u8vec4 grid_color{255, 255, 255, 32};
                glm::u8vec4 label_color{255, 255, 255, 64};

                for (float ms = interval; ms < max_time_ms; ms += interval)
                {
                    float y = graph_base_y - ms * scale;
                    if (y < graph_base_y - graph_pixel_height) break;

                    renderer.drawLine(
                        {graph_left, y},
                        {graph_left + graph_width, y},
                        1.0f,
                        grid_color
                    );

                    renderer.drawText(
                        sp::Rect(label_center_x - 50.0f, y - text_line_height * 0.5f, 100.0f, text_line_height),
                        string(ms, 1) + "ms",
                        sp::Alignment::Center,
                        font_size - 3.0f,
                        nullptr,
                        label_color
                    );
                }

                // 16.6ms (60 fps) reference line
                float y60 = graph_base_y - 16.6f * scale;
                renderer.drawLine(
                    {graph_left, y60},
                    {graph_left + graph_width, y60},
                    2.0f,
                    {255, 255, 255, 32}
                );
                renderer.drawText(
                    sp::Rect(label_center_x - 50.0f, y60 - text_line_height * 0.5f, 100.0f, text_line_height),
                    "16.6ms (60fps)",
                    sp::Alignment::Center,
                    font_size - 1.0f,
                    nullptr,
                    {255, 255, 255, 64}
                );

                // 50ms (20 fps) reference line
                float y50 = graph_base_y - 50.0f * scale;
                renderer.drawLine(
                    {graph_left, y50},
                    {graph_left + graph_width, y50},
                    1.0f,
                    {255, 255, 100, 64}
                );
                renderer.drawText(
                    sp::Rect(label_center_x - 50.0f, y50 - text_line_height * 0.5f, 100.0f, text_line_height),
                    "50ms (20fps)",
                    sp::Alignment::Center,
                    font_size - 1.0f,
                    nullptr,
                    {255, 255, 100, 64}
                );
            }
        }

        // Clip graph lines below toolbar
        {
            float clip_height = graph_base_y - clip_top;
            if (clip_height < 0.0f) clip_height = 0.0f;
            // Use GL line mode for thin 1px lines (7x less geometry than Quad,
            // no bevel joins, no quad_line_shader switch).
            auto saved_line_mode = sp::RenderTarget::getLineDrawingMode();
            sp::RenderTarget::setLineDrawingMode(sp::RenderTarget::LineDrawingMode::GL);

            // In stacked mode, clip fillRects to prevent bleeding into the toolbar.
            if (timing_graph_stacked)
                renderer.pushClipRegion(sp::Rect(graph_left, clip_top, graph_width, clip_height));

            // Draw graph lines (and fillRects in stacked mode) in a single pass.
            {
                std::vector<float> stack_base(draw_count, 0.0f);

                for (auto it = key_order.rbegin(); it != key_order.rend(); ++it)
                {
                    const auto& key = *it;
                    auto entry = timing_graph_enabled.find(key);
                    if (entry != timing_graph_enabled.end() && !entry->second) continue;

                    auto& data = timing_graph_points[key];
                    auto line_color = colorForSeries(key);

                    timing_graph_draw_points.clear();
                    timing_graph_draw_points.reserve(draw_count);
                    for (unsigned int n = 0; n < draw_count; n++)
                    {
                        int data_idx = static_cast<int>(static_cast<float>(n) * visible_points / draw_count);
                        if (data_idx >= static_cast<int>(visible_points))
                            data_idx = static_cast<int>(visible_points) - 1;
                        if (data_idx >= static_cast<int>(data.size()))
                            break;
                        float offset = timing_graph_stacked ? stack_base[n] : 0.0f;
                        float val = data[data_idx];
                        float y = graph_base_y - scale * 1000.0f * (val + offset);

                        if (timing_graph_stacked && val > 0.0f)
                        {
                            float base_y = graph_base_y - scale * 1000.0f * offset;
                            renderer.fillRect(
                                sp::Rect(graph_left + static_cast<float>(n), y, 1.0f, base_y - y),
                                glm::u8vec4{line_color.r, line_color.g, line_color.b, 40}
                            );
                        }

                        timing_graph_draw_points.emplace_back(
                            graph_left + static_cast<float>(n), y
                        );

                        if (timing_graph_stacked) stack_base[n] += val;
                    }

                    if (timing_graph_draw_points.size() > 1)
                        renderer.drawLine(timing_graph_draw_points, 1.0f, line_color);
                }
            }

            if (timing_graph_stacked) renderer.popClipRegion();

            sp::RenderTarget::setLineDrawingMode(saved_line_mode);
        }

        // X-axis labels
        {
            float time_per_sample = 1.0f / std::max(fps, 5.0f);
            float total_sec = visible_points * time_per_sample;
            float label_spacing_px = 80.0f;
            unsigned int step = std::max(1u, static_cast<unsigned int>(label_spacing_px));

            for (unsigned int n = 0; n < draw_count; n += step)
            {
                const float x = graph_left + static_cast<float>(n);
                const float t = static_cast<float>(n) / draw_count;
                const float sec = total_sec * (1.0f - t);

                renderer.drawText(
                    sp::Rect(x - 20.0f, graph_base_y + 2.0f, 40.0f, text_line_height),
                    tr("debug", "-{sec}s").format({
                        {"sec", string(sec, 1)}
                    }),
                    sp::Alignment::TopCenter,
                    12.0f,
                    nullptr,
                    {255, 255, 255, 32}
                );

                renderer.drawLine(
                    {x, graph_base_y},
                    {x, graph_base_y + 4.0f},
                    1.0f,
                    {255, 255, 255, 32}
                );
            }
        }

        // Hover tooltip
        {
            if (this->hover && this->hover_coordinates.x >= 0.0f)
            {
                float mx = this->hover_coordinates.x;
                float my = this->hover_coordinates.y;

                if (mx >= graph_left && mx < graph_left + graph_width
                    && my >= clip_top && my <= graph_base_y
                    && graph_pixel_height > 0.0f)
                {
                    auto col = static_cast<int>(mx - graph_left);
                    if (col >= 0 && col < (int)draw_count)
                    {
                        // Map pixel column to data index
                        int data_idx = static_cast<int>(static_cast<float>(col) * visible_points / draw_count);
                        if (data_idx >= static_cast<int>(visible_points))
                            data_idx = static_cast<int>(visible_points) - 1;

                        float cx = graph_left + static_cast<float>(col);

                        // Vertical crosshair
                        renderer.drawLine(
                            {cx, graph_base_y},
                            {cx, clip_top},
                            1.0f,
                            {255, 255, 255, 32}
                        );

                        // Build tooltip content (top 10 enabled series)
                        std::vector<std::pair<string, float>> tooltip_lines;
                        const int max_tooltip_items = 10;
                        int tooltip_count = 0;
                        for (const auto& key : key_order)
                        {
                            if (tooltip_count >= max_tooltip_items) break;
                            auto entry = timing_graph_enabled.find(key);
                            if (entry != timing_graph_enabled.end() && !entry->second) continue;

                            auto& tooltip_data = timing_graph_points[key];
                            if (data_idx >= static_cast<int>(tooltip_data.size())) continue;

                            const float val = tooltip_data[data_idx] * 1000.0f;
                            tooltip_lines.emplace_back(key, val);
                            tooltip_count++;
                        }

                        if (!tooltip_lines.empty())
                        {
                            const float tt_line_h = 16.0f;
                            const float tt_w = 260.0f;
                            const float tt_h = 8.0f + tooltip_lines.size() * tt_line_h;

                            float tt_x = std::max(
                                graph_left,
                                std::min(mx + 12.0f, graph_left + graph_width - tt_w)
                            );
                            float tt_y = std::max(
                                clip_top + 2.0f,
                                std::min(my - tt_h - 8.0f, graph_base_y - tt_h)
                            );

                            renderer.fillRect(
                                sp::Rect(tt_x, tt_y, tt_w, tt_h),
                                {10, 10, 10, 210}
                            );
                            renderer.drawRectOutline(
                                sp::Rect(tt_x, tt_y, tt_w, tt_h),
                                1.0f,
                                {255, 255, 255, 32}
                            );

                            float ty = tt_y + 4.0f;
                            for (const auto& [key, val] : tooltip_lines)
                            {
                                renderer.drawText(
                                    sp::Rect(tt_x + 6.0f, ty, tt_w - 12.0f, tt_line_h),
                                    tr("debug", "{key}: {val}ms").format({
                                        {"key", key},
                                        {"val", string(val, 5)}
                                    }),
                                    sp::Alignment::TopLeft, 11.0f, nullptr, colorForSeries(key)
                                );
                                ty += tt_line_h;
                            }
                        }
                    }
                }
            }
        }
    }
    else toolbar->hide();

    if (show_atlas)
    {
        auto atlas = sp::RenderTarget::getAtlasTexture();
        if (atlas)
        {
            auto atlas_size = sp::RenderTarget::getAtlasTextureSize();
            const float usage = sp::RenderTarget::getAtlasUsageRate();

            renderer.fillRect(contents_rect, glm::u8vec4{0, 0, 0, 200});

            float draw_size = std::min(contents_rect.size.x, contents_rect.size.y) * 0.7f;
            float x = contents_rect.position.x + (contents_rect.size.x - draw_size) * 0.5f;
            float y = contents_rect.position.y + (contents_rect.size.y - draw_size) * 0.5f;
            renderer.drawAtlasTexture(sp::Rect(x, y, draw_size, draw_size));

            renderer.drawText(
                sp::Rect(x, y, draw_size, draw_size),
                tr("debug", "Texture atlas\nSize: {width}x{height}\nUsage: {usage}%").format({
                    {"width", string(atlas_size.x)},
                    {"height", string(atlas_size.y)},
                    {"usage", string(usage * 100.0f, 1)}
                }),
                sp::Alignment::BottomRight,
                22
            );
        }
    }
}

bool DebugRenderer::onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    mouse_down_button = button;
    bool handled = GuiResizableDialog::onMouseDown(button, position, id);

    // onMouseDown is called twice: once during getClickElement's test callback
    // and once from onPointerDown for the real dispatch. Use scale_press_handled
    // flag to process only on the first call.
    if (!scale_press_handled && show_timing_graph)
    {
        scale_press_handled = true;

        // Graph body zoom (requires modifier key for backward compatibility)
        {
            auto cr = contents->getRect();
            const float legend_width = 200.0f;
            float graph_left = cr.position.x + legend_width;
            float graph_width = cr.size.x - legend_width;
            if (graph_width < 50.0f) graph_width = 50.0f;

            if (keys.debug_modifier.get()
                && position.x >= graph_left && position.x < graph_left + graph_width
                && position.y >= cr.position.y && position.y < cr.position.y + cr.size.y)
            {
                switch (button)
                {
                case sp::io::Pointer::Button::Left:
                    scale *= 2.0f;
                    return true;
                case sp::io::Pointer::Button::Middle:
                    scale = 10.0f;
                    return true;
                case sp::io::Pointer::Button::Right:
                    scale *= 0.5f;
                    return true;
                default:
                    break;
                }
            }
        }

        // Legend area click
        {
            auto cr = contents->getRect();
            const float legend_width = 200.0f;
            if (position.x >= cr.position.x && position.x < cr.position.x + legend_width
                && position.y >= cr.position.y && position.y < cr.position.y + cr.size.y)
            {
                return true;
            }
        }
    }

    return handled;
}

void DebugRenderer::onMouseUp(glm::vec2 position, sp::io::Pointer::ID id)
{
    scale_press_handled = false;

    if (!show_timing_graph) return;

    auto contents_rect = contents->getRect();

    float widget_area_bottom = contents_rect.position.y;
    for (auto& child : contents->getChildren())
    {
        if (child->isVisible())
        {
            float child_bottom = child->getRect().position.y + child->getRect().size.y;
            if (child_bottom > widget_area_bottom)
                widget_area_bottom = child_bottom;
        }
    }

    const float legend_width = 200.0f;
    const float text_line_height = 18.0f;
    float graph_base_y = contents_rect.position.y + contents_rect.size.y;

    if (position.x >= contents_rect.position.x && position.x < contents_rect.position.x + legend_width
        && position.y >= widget_area_bottom && position.y < graph_base_y)
    {
        auto idx = static_cast<int>(std::floor((position.y - widget_area_bottom) / text_line_height));
        if (idx >= 0 && idx < static_cast<int>(key_order.size()))
        {
            auto key = key_order[idx];

            switch (mouse_down_button)
            {
            case sp::io::Pointer::Button::Left:
                {
                    auto entry = timing_graph_enabled.find(key);
                    if (entry != timing_graph_enabled.end())
                        entry->second = !entry->second;
                    else timing_graph_enabled.insert({key, false});
                }
                return;

            case sp::io::Pointer::Button::Right:
                {
                    auto entry = timing_graph_enabled.find(key);
                    bool target;

                    if (entry != timing_graph_enabled.end()) target = !entry->second;
                    else target = false;

                    if (target) timing_graph_enabled.clear();
                    else
                    {
                        for (auto entry : key_order)
                            timing_graph_enabled.insert_or_assign(entry, target);
                    }
                }
                return;

            default:
                return;
            }
        }
    }
}

void DebugRenderer::onClose()
{
    hide();
}
