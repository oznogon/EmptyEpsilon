#include "prometheusMetrics.h"

#include "config.h"
#include "P.h"
#include "engine.h"
#include "multiplayer_server.h"
#include "gameGlobalInfo.h"
#include "ecs/entity.h"

#include "components/hull.h"
#include "components/shields.h"
#include "components/reactor.h"
#include "components/name.h"
#include "components/player.h"

#include "ecs/query.h"
#include "playerInfo.h"
#include "crewPosition.h"

#include <cstdio>
#include <unordered_map>

static std::unordered_map<string, int> kill_counts;

static string escapeLabelValue(const string& value)
{
    string result;

    for (auto c : value)
    {
        if (c == '\\') result += "\\\\";
        else if (c == '"') result += "\\\"";
        else if (c == '\n') result += "\\n";
        else result += c;
    }

    return result;
}

static string formatFloat(float value)
{
    char buf[32];
    std::snprintf(buf, sizeof(buf), "%.6g", static_cast<double>(value));
    return string(buf);
}

static string formatInt(int value)
{
    return string(value);
}

static void writeGaugeMetric(string& output, const string& name, const string& help, const string& value_line)
{
    output += "# HELP " + name + " " + help + "\n";
    output += "# TYPE " + name + " gauge\n";
    output += value_line + "\n";
}

static void writeCounterMetric(string& output, const string& name, const string& help, const string& value_line)
{
    output += "# HELP " + name + " " + help + "\n";
    output += "# TYPE " + name + " counter\n";
    output += value_line + "\n";
}

static void collectEngineMetrics(string& output)
{
    if (!engine) return;

    writeGaugeMetric(
        output,
        "ee_game_speed",
        "Current game speed multiplier (0 = paused)",
        "ee_game_speed " + formatFloat(engine->getGameSpeed())
    );

    writeGaugeMetric(
        output,
        "ee_elapsed_time_seconds",
        "Total game time elapsed",
        "ee_elapsed_time_seconds " + formatFloat(engine->getElapsedTime())
    );

    writeGaugeMetric(
        output,
        "ee_entity_count",
        "Number of active ECS entities",
        "ee_entity_count " + formatFloat(static_cast<float>(sp::ecs::Entity::getActiveCount()))
    );

    auto timing = engine->getEngineTiming();
    if (timing.empty()) return;

    string timing_lines;
    for (auto& [key, value] : timing)
        timing_lines += "ee_update_duration_seconds{phase=\"" + escapeLabelValue(key) + "\"} " + formatFloat(value) + "\n";
    writeGaugeMetric(
        output,
        "ee_update_duration_seconds",
        "Time spent in each update phase (seconds)",
        timing_lines
    );
}

static void collectServerMetrics(string& output)
{
    if (!game_server.isAlive()) return;

    writeGaugeMetric(
        output,
        "ee_server_send_bytes_per_second",
        "Total network send rate in bytes per second (per-client rate multiplied by client count)",
        "ee_server_send_bytes_per_second " + formatFloat(game_server->getSendDataRatePerClient() * static_cast<float>(game_server->getClientCount()))
    );

    writeGaugeMetric(
        output,
        "ee_server_send_bytes_per_second_per_client",
        "Per-client network send rate in bytes per second",
        "ee_server_send_bytes_per_second_per_client " + formatFloat(game_server->getSendDataRatePerClient())
    );

    writeGaugeMetric(
        output,
        "ee_server_update_duration_seconds",
        "Time spent in server update cycle (seconds)",
        "ee_server_update_duration_seconds " + formatFloat(game_server->getUpdateTime())
    );

    int client_count = game_server->getClientCount();
    writeGaugeMetric(
        output,
        "ee_server_client_count",
        "Number of connected game clients",
        "ee_server_client_count " + formatInt(client_count)
    );

    if (client_count > 0)
    {
        string ping_lines;

        for (auto& [client_id, ping] : game_server->getClientPings())
            ping_lines += "ee_server_client_ping_milliseconds{client_id=\"" + formatInt(client_id) + "\"} " + formatInt(ping) + "\n";
        writeGaugeMetric(
            output,
            "ee_server_client_ping_milliseconds",
            "Round-trip time to each client in milliseconds",
            ping_lines
        );
    }

    writeGaugeMetric(
        output,
        "ee_server_master_server_state",
        "Master server registration state (0 = Disabled, 1 = Registering, 2 = Success, 3 = FailedToReach, 4 = FailedPortForwarding)",
        "ee_server_master_server_state " + formatInt(static_cast<int>(game_server->getMasterServerState()))
    );
}

static void collectGameMetrics(string& output)
{
    if (!gameGlobalInfo) return;

    string scenario = gameGlobalInfo->scenario;
    string server_name = game_server
        ? game_server->getServerName()
        : "";

    writeGaugeMetric(
        output,
        "ee_scenario_info",
        "Scenario metadata (always 1)",
        "ee_scenario_info{scenario=\"" + escapeLabelValue(scenario)
        + "\",server_name=\"" + escapeLabelValue(server_name)
        + "\",version=\"" + formatInt(VERSION_NUMBER) + "\"} 1"
    );

    string mission_time = gameGlobalInfo->getMissionTime();
    writeGaugeMetric(
        output,
        "ee_mission_time_info",
        "Mission time as formatted HH:MM:SS string (always 1, use label)",
        "ee_mission_time_info{mission_time=\"" + escapeLabelValue(mission_time) + "\"} 1"
    );

    // Player connections: one row per PlayerInfo (connected client)
    string connection_lines;
    foreach (PlayerInfo, pi, player_info_list)
    {
        string ship_name;
        if (pi->ship)
        {
            auto callsign = pi->ship.getComponent<CallSign>();
            auto type_name = pi->ship.getComponent<TypeName>();
            if (callsign && !callsign->callsign.empty())
                ship_name = callsign->callsign;
            else if (type_name && !type_name->type_name.empty())
                ship_name = type_name->type_name;
            else
                ship_name = "ship_" + pi->ship.toString();
        }

        CrewPositions all_positions;
        for (auto& cps : pi->crew_positions) all_positions.mask |= cps.mask;

        string positions_str;
        for (auto cp : all_positions)
        {
            if (!positions_str.empty()) positions_str += ",";
            positions_str += crewPositionToString(cp);
        }

        connection_lines +=
            "ee_player_connection{client_id=\"" + formatInt(pi->client_id)
            + "\",name=\"" + escapeLabelValue(pi->name)
            + "\",ship=\"" + escapeLabelValue(ship_name)
            + "\",positions=\"" + escapeLabelValue(positions_str)
            + "\"} 1\n";
    }

    if (!connection_lines.empty())
    {
        writeGaugeMetric(output, "ee_player_connection",
            "Connected players with their name, ship, and crew positions (always 1)",
            connection_lines);
    }

    // Player ships: one row per PlayerControl entity
    int player_ship_count = 0;
    string hull_lines;
    string energy_lines;
    string shield_lines;
    string ship_info_lines;

    for (auto [entity, pc] : sp::ecs::Query<PlayerControl>())
    {
        string ship_name;
        auto callsign = entity.getComponent<CallSign>();
        auto type_name = entity.getComponent<TypeName>();

        if (callsign && !callsign->callsign.empty())
            ship_name = callsign->callsign;
        else if (type_name && !type_name->type_name.empty())
            ship_name = type_name->type_name;
        else
            ship_name = "ship_" + entity.toString();

        string escaped_name = escapeLabelValue(ship_name);

        ship_info_lines += "ee_player_ship_info{ship=\"" + escaped_name
            + "\",password=\"" + escapeLabelValue(pc.control_code)
            + "\"} 1\n";

        auto hull = entity.getComponent<Hull>();
        if (hull && hull->max > 0)
            hull_lines += "ee_player_ship_hull_ratio{ship=\"" + escaped_name + "\"} " + formatFloat(hull->current / hull->max) + "\n";

        if (auto reactor = entity.getComponent<Reactor>())
            energy_lines += "ee_player_ship_energy{ship=\"" + escaped_name + "\"} " + formatFloat(reactor->energy) + "\n";

        if (auto shields = entity.getComponent<Shields>())
        {
            for (size_t idx = 0; idx < shields->entries.size(); idx++)
            {
                float ratio = 0.0f;
                if (shields->entries[idx].max > 0)
                    ratio = shields->entries[idx].level / shields->entries[idx].max;
                shield_lines += "ee_player_ship_shield_ratio{ship=\"" + escaped_name + "\",index=\"" + formatInt(static_cast<int>(idx)) + "\"} " + formatFloat(ratio) + "\n";
            }
        }

        player_ship_count++;
    }

    if (!ship_info_lines.empty())
        writeGaugeMetric(output, "ee_player_ship_info",
            "Active player ship name and access password (always 1)",
            ship_info_lines);

    writeGaugeMetric(
        output,
        "ee_player_ship_count",
        "Number of entities with a PlayerControl component",
        "ee_player_ship_count " + formatInt(player_ship_count)
    );

    if (!hull_lines.empty())
    {
        writeGaugeMetric(
            output,
            "ee_player_ship_hull_ratio",
            "Player ship hull as fraction of maximum (0.0 to 1.0)",
            hull_lines
        );
    }

    if (!energy_lines.empty())
    {
        writeGaugeMetric(
            output,
            "ee_player_ship_energy",
            "Player ship reactor energy level",
            energy_lines
        );
    }

    if (!shield_lines.empty())
    {
        writeGaugeMetric(
           output,
            "ee_player_ship_shield_ratio",
            "Player ship shield level as fraction of maximum (0.0 to 1.0)",
            shield_lines
        );
    }
}

static void collectDebugMetrics(string& output)
{
    if (!game_server.isAlive()) return;

#ifdef DEBUG
    writeGaugeMetric(
        output,
        "ee_debug_pobject_count",
        "Number of active PObject instances (debug builds only)",
        "ee_debug_pobject_count " + formatInt(DEBUG_PobjCount)
    );
#endif

    auto& stats = game_server->getNetworkStatsSnapshot();
    if (stats.empty()) return;

    string stats_lines;

    for (auto& [key, bytes] : stats)
        stats_lines += "ee_server_network_bytes{component=\"" + escapeLabelValue(key) + "\"} " + formatInt(bytes) + "\n";

    writeGaugeMetric(
        output,
        "ee_server_network_bytes",
        "Per-component-type network bandwidth in bytes (accumulated over ~1 second interval)",
        stats_lines
    );
}

static void collectKillMetrics(string& output)
{
    if (kill_counts.empty()) return;

    string kill_lines;
    for (auto& [instigator, count] : kill_counts)
        kill_lines += "ee_kills_total{instigator=\"" + escapeLabelValue(instigator) + "\"} " + formatInt(count) + "\n";

    writeCounterMetric(
        output,
        "ee_kills_total",
        "Number of entities destroyed by damage caused by each instigator, keyed by callsign",
        kill_lines
    );
}

PrometheusMetricsServer::PrometheusMetricsServer(int port)
: server(port)
{
    // Enable engine timing collection.
    engine->collectEngineTiming();
    // Add a /metrics endpoint and produce Prometheus-compatible metrics.
    server.addURLHandler("/metrics", [](const sp::io::http::Server::Request& request) -> string
    {
        string output;

        output += "# EmptyEpsilon Prometheus Metrics\n";
        output += "# Version " + formatInt(VERSION_NUMBER) + "\n\n";

        collectEngineMetrics(output);
        output += "\n";
        collectServerMetrics(output);
        output += "\n";
        collectGameMetrics(output);
        output += "\n";
        collectKillMetrics(output);
        output += "\n";
        collectDebugMetrics(output);

        return output;
    }, "text/plain; version=0.0.4; charset=utf-8");
}

void PrometheusMetricsServer::recordKill(const string& instigator_callsign)
{
    kill_counts[instigator_callsign]++;
}
