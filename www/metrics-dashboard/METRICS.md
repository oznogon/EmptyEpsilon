# EmptyEpsilon Metrics Setup Guide

EmptyEpsilon exposes a [Prometheus](https://prometheus.io/) metrics endpoint when running as a server. This guide covers enabling the endpoint, configuring Prometheus to scrape it, and visualizing the data in Grafana using the included sample dashboard.

## Overview

When the metrics server is enabled with `metrics_server=<port>`, EmptyEpsilon serves a Prometheus-format text endpoint at `http://<host>:<port>/metrics`. Prometheus scrapes this endpoint on a configured interval and stores the data in its time-series database. Grafana queries Prometheus and renders the data as gauges, graphs, and tables.

All three services can run on the same system. If they don't, you must expose the relevant port on the EmptyEpsilon server for Prometheus to scrape metrics.

## Enable the EmptyEpsilon Metrics Endpoint

### Configure options.ini

When you run EmptyEpsilon, it creates a [Preferences File](https://github.com/daid/EmptyEpsilon/wiki/Preferences_File) (`options.ini`) in a location determined by your operating system and configuration. On Windows, this is typically the same directory as `EmptyEpsilon.exe`. On other operating systems, this is typically `~/.emptyepsilon/options.ini`.

Add the following line to `options.ini`, choosing any unused TCP port of 1024 or greater (80 or greater if not running as root):

```ini
metrics_server=9100
```

Alternatively, define the setting as a command-line option:

```
./EmptyEpsilon metrics_server=9100
```

> **Note:** All other examples in this documentation assume this is set to `metrics_server=9100`.

When you run EmptyEpsilon as a server, it starts serving the metrics endpoint on that port. Set `metrics_server=0` or omit the line to disable the endpoint entirely. Any provided port number under 80 is automatically rounded up to 80.

The metrics endpoint is not available when running EmptyEpsilon as a client, even when `metrics_server` is set. You can enable or disable the metrics endpoint independently of EmptyEpsilon's HTTP API server.

### Verify the endpoint

Start EmptyEpsilon as a server with the metrics server endpoint set to a port. After the server initialises, access `http://localhost:9100/metrics` in a browser, or run:

```bash
curl http://localhost:9100/metrics
```

You should see output beginning with:

```
# EmptyEpsilon Prometheus Metrics
# Version <number>

# HELP ee_game_speed Current game speed multiplier (0 = paused)
# TYPE ee_game_speed gauge
ee_game_speed 1
...
```

If the endpoint is unreachable, confirm that the server's firewall isn't blocking port and that no other process is using it.

### Available metrics

| Metric | Description |
|--------|-------------|
| `ee_game_speed` | Current game speed multiplier (0 = paused) |
| `ee_elapsed_time_seconds` | Total in-game seconds elapsed |
| `ee_entity_count` | Number of active ECS entities |
| `ee_update_duration_seconds{phase}` | Per-subsystem update wall time in seconds |
| `ee_server_send_bytes_per_second` | Total network send rate in bytes/s |
| `ee_server_send_bytes_per_second_per_client` | Per-client network send rate in bytes/s |
| `ee_server_update_duration_seconds` | Time spent in the server update cycle |
| `ee_server_client_count` | Number of connected game clients |
| `ee_server_client_ping_milliseconds{client_id}` | Round-trip time per client in milliseconds |
| `ee_server_master_server_state` | Master server registration state (0–4) |
| `ee_scenario_info{scenario,server_name,version}` | Scenario metadata; value is always 1 |
| `ee_mission_time_info{mission_time}` | Mission clock as `HH:MM:SS`; value is always 1 |
| `ee_player_connection{client_id,name,ship,positions}` | One row per connected player; value is always 1 |
| `ee_player_ship_count` | Number of entities with a PlayerControl component |
| `ee_player_ship_info{ship,password}` | One row per player ship; value is always 1 |
| `ee_player_ship_hull_ratio{ship}` | Hull integrity as a fraction (0.0–1.0) |
| `ee_player_ship_energy{ship}` | Reactor energy level |
| `ee_player_ship_shield_ratio{ship,index}` | Per-face shield level as a fraction (0.0–1.0) |
| `ee_server_network_bytes{component}` | Per-component network bytes (1-second window) |
| `ee_kills_total{instigator}` | Entities destroyed by damage per instigator (session total) |
| `ee_debug_pobject_count` | Active PObject count (debug builds only) |

> **Note:** `ee_server_network_bytes` and the per-subsystem detail in `ee_update_duration_seconds` are collected only when `metrics_server` is set to a non-zero port. They incur a small performance overhead and are disabled when the metrics server is off.

## Install and configure Prometheus

### Install Prometheus

The best guide to installing Prometheus is in [its documentation](https://prometheus.io/docs/prometheus/latest/installation/).

### Configure Prometheus

[Create or edit `prometheus.yml`](https://prometheus.io/docs/prometheus/latest/configuration/configuration/) (likely `/etc/prometheus/prometheus.yml` if installed via package). The key section is the `scrape_configs` block:

```yaml
global:
  scrape_interval: 5s      # How often to scrape targets
  evaluation_interval: 5s  # How often to evaluate rules

scrape_configs:
  - job_name: 'emptyepsilon'
    static_configs:
      - targets:
          - 'localhost:9100'   # Replace with the host and port from options.ini
```

If EmptyEpsilon is running on a different system, replace `localhost` with that system's hostname or IP address.

To monitor multiple simultaneous servers, add each as a separate target:

```yaml
    static_configs:
      - targets:
          - 'server1.example.com:9100'
          - 'server2.example.com:9100'
```

### 2.3 Start Prometheus

**Binary:**

```bash
./prometheus --config.file=prometheus.yml
```

**Systemd service (if installed via package manager):**

```bash
# Edit /etc/prometheus/prometheus.yml with the scrape config above, then:
sudo systemctl restart prometheus
sudo systemctl enable prometheus
```

### 2.4 Verify Prometheus is scraping

Open `http://localhost:9090` in a browser. Go to **Status > Targets**. The `emptyepsilon` job should appear with state **UP**. If the state is **DOWN**, check:

- EmptyEpsilon is running as a server with `metrics_server` set
- The host and port in `prometheus.yml` match the server's IP or hostname and `metrics_server` port value
- No firewall is blocking the connection

You can also query the data. In the Prometheus UI, enter `ee_game_speed` in the expression bar and click **Execute**. A result of `0` or `1` means Prometheus has successfully scraped the metric.

## Step 3: Install and Configure Grafana

### 3.1 Install Grafana

The best guide to installing Grafana is in [its documentation](https://grafana.com/docs/grafana/latest/setup-grafana/installation/).

### 3.2 Log in to Grafana

Open `http://localhost:3000` in a browser. The default credentials are username `admin`/password `admin`. Grafana will prompt you to change the password on first login.

### 3.3 Add Prometheus as a data source

1. In the left sidebar, click **Connections** > **Data sources**.
2. Click **Add new data source**.
3. Select **Prometheus**.
4. Set **Prometheus server URL** to `http://localhost:9090`. Adjust if Prometheus is on another host.
5. Leave all other settings at their defaults.
6. Click **Save & test**. Grafana should report "Successfully queried the Prometheus API."

## Step 4: Import the Dashboard

The EmptyEpsilon repository includes a pre-built Grafana dashboard in `www/metrics-dashboard/grafana-dashboard.json`.

To [import it in Grafana](https://grafana.com/docs/grafana/latest/visualizations/dashboards/build-dashboards/import-dashboards/):

1. In the left sidebar, click **Dashboards** > **Import**.
2. Click **Upload dashboard JSON file**.
3. Select `grafana-dashboard.json` from the repository root.
4. When prompted, select the Prometheus data source you added in Step 3.3.
5. Click **Import**.

## Dashboard Reference

The dashboard is divided into four collapsible rows.

### Game Overview

| Panel | Description |
|-------|-------------|
| Game Speed | Current speed multiplier; red when paused (0), green when running |
| Elapsed Time | Accumulated in-game seconds |
| Mission Time | Formatted `HH:MM:SS` clock from the scenario |
| Entities | Count of active ECS entities |
| Player Ships | Count of entities with a PlayerControl component |
| Scenario | Name of the running scenario |

### Server Performance

| Panel | Description |
|-------|-------------|
| Update Phase Duration | Stacked and heatmap time series showing how long each subsystem's `update()` call takes per tick |
| Server Update Duration | Time spent in the multiplayer server update cycle |
| Network Send Rate | Total and per-client bytes sent per second |
| Per-Component Network Bytes | Stacked relative and percentile slices of Bytes attributed to each ECS component type over the last second |

### Client Connections

| Panel | Description |
|-------|-------------|
| Connected Clients | Number of authenticated clients |
| Master Server State | Registration state with the public master server |
| Client Ping | Round-trip time per client over time |
| Players | Table of every connected player: client ID, name, player ship (if any), and active crew positions (if any) |

### Player Ships

| Panel | Description |
|-------|-------------|
| Hull Integrity | One hull health gauge per ship, as a fraction of maximum |
| Shield Status | One shield level gauge per shield segment, as a fraction of maximum |
| Reactor Energy | Energy level per ship over time |
| Hull History | Hull integrity time series for all player ships |
| Shield History | Shield level time series for all player ships |
| Player Ship Access | Table of active player ships and their access passwords |

> Hull Integrity and Shield Status use instant queries. Gauges disappear as soon as a ship is destroyed rather than lingering until Prometheus's staleness timeout.

### Game Stats

| Panel | Description |
|-------|-------------|
| Kills by Instigator | Bar chart of entities destroyed by damage by the damage's instigator, if defined; instigators are keyed by callsign |

### Debug

| Panel | Description |
|-------|-------------|
| PObject Count | Active legacy ref-counted objects (debug builds only; always empty in release) |
| Network Bytes by Component | Bar chart of the top 15 components by bandwidth, snapped to the current instant |

## Updating the Dashboard

After modifying `grafana-dashboard.json`, re-run `import-grafana-dashboard.sh` to push the updated definition to Grafana. The script uses `overwrite: true`, so it replaces the existing dashboard by UID without creating a duplicate.

## Adding New Metrics

All metrics are served from `src/prometheusMetrics.cpp`. There are two patterns:

- **Gauges** read game state at scrape time
- **Counters** accumulate events and return a running total

### Gauge metrics

A gauge is sampled fresh on every scrape. Add a `collectXxxMetrics(string& output)` function and call it from the handler in `PrometheusMetricsServer::PrometheusMetricsServer`.

Use the `writeGaugeMetric` helper:

```cpp
static void writeGaugeMetric(string& output, const string& name, const string& help, const string& value_line);
```

`value_line` is the raw Prometheus text — one or more lines of the form `metric_name{label="value"} 42`. For a single unlabelled value:

```cpp
static void collectMyMetric(string& output)
{
    // Guard if the data source may be null
    if (!gameGlobalInfo) return;

    writeGaugeMetric(
        output,
        "ee_my_metric",
        "Brief description of what this measures",
        "ee_my_metric " + formatFloat(gameGlobalInfo->someValue())
    );
}
```

For metrics with one row per label value, build the value string in a loop:

```cpp
string lines;
for (auto& item : items)
    lines += "ee_my_metric{name=\"" + escapeLabelValue(item.name) + "\"} " + formatInt(item.count) + "\n";

if (!lines.empty())
    writeGaugeMetric(output, "ee_my_metric", "Help text", lines);
```

Then call your function from the handler:

```cpp
PrometheusMetricsServer::PrometheusMetricsServer(int port)
: server(port)
{
    server.addURLHandler("/metrics", [](const sp::io::http::Server::Request& request) -> string
    {
        string output;
        // ...existing collect calls...
        collectMyMetric(output);
        return output;
    }, "text/plain; version=0.0.4; charset=utf-8");
}
```

### Counter metrics

A counter is a session-total that only ever increases. Unlike a gauge, it must be accumulated as events happen.

1. Declare a static map (or other accumulator) in `prometheusMetrics.cpp`:

   ```cpp
   static std::unordered_map<string, int> my_event_counts;
   ```
2. Expose a static recording function on `PrometheusMetricsServer`. Add the declaration to `prometheusMetrics.h`:

   ```cpp
   static void recordMyEvent(const string& label_value);
   ```

   And the implementation in `prometheusMetrics.cpp`:

   ```cpp
   void PrometheusMetricsServer::recordMyEvent(const string& label_value)
   {
       my_event_counts[label_value]++;
   }
   ```
3. Call `recordMyEvent` from the game code wherever the event occurs. The recording is safe to call whether or not the metrics server is enabled.
4. Add a collect function that outputs the counter using `writeCounterMetric`:

   ```cpp
   static void collectMyEventMetrics(string& output)
   {
       if (my_event_counts.empty())
           return;

       string lines;
       for (auto& [label, count] : my_event_counts)
           lines += "ee_my_event_total{label=\"" + escapeLabelValue(label) + "\"} " + formatInt(count) + "\n";

       writeCounterMetric(output, "ee_my_event_total", "Help text", lines);
   }
   ```

   Then call it from the handler alongside the other collect functions.

#### Example: ee_kills_total

The `ee_kills_total{instigator}` counter metric counts entities destroyed by damage, keyed by the instigator's callsign. The counter is incremented in `DamageSystem::destroyedByDamage` (`src/systems/damage.cpp`) whenever `info.instigator` is valid. It resolves the instigator's display name from the `CallSign` component, and falls back to `TypeName` or a raw entity ID string.

### Adding a Grafana panel

1. Open `grafana-dashboard.json` in a text editor.
2. At the end of the `"panels"` array, add a row object (if you want a new section heading) followed by the panel object.
3. Assign each object a unique integer `"id"` (increment from the highest existing `id`).
4. Set `"gridPos"` so the panel fits below the last existing panel. The `y` coordinate of your row must be at least `y + h` of the last panel above it.

   Row template:
   
   ```json
   {
     "collapsed": false,
     "gridPos": { "h": 1, "w": 24, "x": 0, "y": <Y> },
     "id": <ID>,
     "panels": [],
     "title": "My Section",
     "type": "row"
   }
   ```
   
   Panel template (bar chart, instant query):
   
   ```json
   {
     "datasource": { "type": "prometheus", "uid": "${DS_PROMETHEUS}" },
     "description": "Human-readable description.",
     "fieldConfig": {
       "defaults": {
         "color": { "mode": "palette-classic" },
         "custom": { "fillOpacity": 80, "gradientMode": "none", "lineWidth": 1,
                     "scaleDistribution": { "type": "linear" },
                     "thresholdsStyle": { "mode": "off" } },
         "mappings": [],
         "thresholds": { "mode": "absolute",
                         "steps": [{ "color": "green", "value": 0 }] },
         "unit": "short"
       },
       "overrides": []
     },
     "gridPos": { "h": 8, "w": 12, "x": 0, "y": <Y+1> },
     "id": <ID+1>,
     "options": {
       "barRadius": 0, "barWidth": 0.97, "groupWidth": 0.7,
       "legend": { "calcs": [], "displayMode": "list", "placement": "bottom", "showLegend": true },
       "orientation": "auto", "showValue": "auto", "stacking": "none",
       "tooltip": { "hideZeros": false, "mode": "single", "sort": "none" },
       "xField": "Metric"
     },
     "pluginVersion": "12.4.2",
     "targets": [
       {
         "expr": "ee_my_event_total",
         "instant": true,
         "legendFormat": "{{label}}",
         "refId": "A",
         "datasource": { "type": "prometheus", "uid": "${DS_PROMETHEUS}" }
       }
     ],
     "transformations": [
       { "id": "seriesToRows", "options": {} },
       { "id": "filterFieldsByName", "options": { "include": { "names": ["Metric", "Value"] } } }
     ],
     "title": "My Panel Title",
     "type": "barchart"
   }
   ```
5. After editing `grafana-dashboard.json`, run `import-grafana-dashboard.sh` (see **Updating the Dashboard** below) to push the changes to Grafana.

## Troubleshooting

### Metrics endpoint returns nothing, or connection refused

- Confirm `metrics_server=<port>` was passed as a command-line option or is in `options.ini`, and that EmptyEpsilon is running as a server, not a client.
- Confirm the port is not already in use: `ss -tlnp | grep <port>`.

### Prometheus target is DOWN

- Check Prometheus logs (`journalctl -u prometheus` or the terminal output).
- Verify the `targets` entry in `prometheus.yml` matches the host and port in `options.ini`.
- Test connectivity directly: `curl http://<target>:<port>/metrics`

### Dashboard shows "No data"

- In Grafana, verify the Prometheus data source is configured and passes the connection test.
- Check the dashboard's time range. Try setting it to **Last 5 minutes**.
- Confirm Prometheus has scraped at least one data point by querying `ee_game_speed` in the Prometheus UI.

### Mission Time or Scenario panels show template literals (`{{mission_time}}`, `{{scenario}}`)

- These panels use `textMode: name` and require Grafana 9.3 or later.
- Confirm the Prometheus data source is correctly selected for the dashboard.
- If Grafana is version 9.2 or earlier, upgrade Grafana.

### Player Ships panels are empty even though ships exist

Ships are tracked only when their entity has a `PlayerControl` component. Even if a ship otherwise has player ship properties, if it lacks `PlayerControl`, it won't be listed.
