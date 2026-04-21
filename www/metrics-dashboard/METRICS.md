# EmptyEpsilon Metrics Setup Guide

EmptyEpsilon exposes a [Prometheus](https://prometheus.io/) metrics endpoint when running as a server. This guide covers enabling the endpoint, configuring Prometheus to scrape it, and visualizing the data in Grafana using the included dashboard.

## Overview

When the metrics server is enabled, EmptyEpsilon serves a Prometheus-format text endpoint at `http://<host>:<port>/metrics`. Prometheus scrapes this endpoint on a configured interval and stores the data in its time-series database. Grafana queries Prometheus and renders the data as gauges, graphs, and tables.

All three services can run on the same system. If they don't, you must expose the relevant port on the EmptyEpsilon server for Prometheus to scrape metrics.

## Enable the EmptyEpsilon Metrics Endpoint

### Configure options.ini

When you run EmptyEpsilon, it creates a [Preferences File](https://github.com/daid/EmptyEpsilon/wiki/Preferences_File) (`options.ini`) in a location determined by your operating system and configuration. On Windows, this is typically the same directory as `EmptyEpsilon.exe`. On other operating systems, this is typically `~/.emptyepsilon/options.ini`.

Add the following line to `options.ini`, choosing any unused TCP port of 1024 or greater (80 or greater if not running as root):

```ini
metricsserver=9100
```

> **Note:** All other examples in this documentation assume this is set to `metricsserver=9100`.

When you run EmptyEpsilon as a server, it starts the metrics endpoint on that port. Set `metricsserver=0` or omit the line to disable the endpoint entirely. The metrics endpoint is not available when running EmptyEpsilon as a client, even when `metricsserver` is set.

### Verify the endpoint

Start EmptyEpsilon as a server. After the server initialises, access `http://localhost:9100/metrics` in a browser, or run:

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

> **Note:** `ee_server_network_bytes` and the per-subsystem detail in `ee_update_duration_seconds` are only collected when `metricsserver` is set to a non-zero port. They incur a small overhead and are disabled when the metrics server is off.

## Install and configure Prometheus

### Install Prometheus

The best guide to installing Prometheus is in [its documentation](https://prometheus.io/docs/prometheus/latest/installation/). The following examples are only a quick reference.

#### Linux (binary)

```bash
# Download the latest release from https://prometheus.io/download/
# Example for Linux amd64:
wget https://github.com/prometheus/prometheus/releases/download/v2.53.0/prometheus-2.53.0.linux-amd64.tar.gz
tar xzf prometheus-2.53.0.linux-amd64.tar.gz
cd prometheus-2.53.0.linux-amd64
```

#### Package manager (Debian/Ubuntu)

```bash
sudo apt-get install prometheus
```

#### Package manager (Fedora/RHEL)

```bash
sudo dnf install prometheus
```

#### Windows

Download the Windows zip from the [Prometheus releases page](https://github.com/prometheus/prometheus/releases), extract it, and run `prometheus.exe`.

#### Docker

```bash
docker run -d --name prometheus -p 9090:9090 \
  -v /path/to/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus
```

### Configure Prometheus

Create or edit `prometheus.yml`. The key section is the `scrape_configs` block:

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

If EmptyEpsilon is running on a different machine, replace `localhost` with that machine's hostname or IP address.

If you want to monitor multiple simultaneous servers, add each as a separate target:

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

Open `http://localhost:9090` in a browser. Navigate to **Status → Targets**. The `emptyepsilon` job should appear with state **UP**. If the state is **DOWN**, check:

- EmptyEpsilon is running as a server with `metricsserver` set
- The host and port in `prometheus.yml` match `options.ini`
- No firewall is blocking the connection

You can also run a quick query: in the Prometheus UI, enter `ee_game_speed` in the expression bar and click **Execute**. A result of `1` means Prometheus has successfully scraped the metric.

---

## Step 3: Install and Configure Grafana

### 3.1 Install Grafana

**Linux (binary):**

Download from [grafana.com/grafana/download](https://grafana.com/grafana/download) and follow the installation instructions for your distribution.

**Package manager (Debian/Ubuntu):**

```bash
sudo apt-get install grafana
```

**Package manager (Fedora/RHEL):**

```bash
sudo dnf install grafana
```

**Systemd:**

```bash
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
```

**Docker:**

```bash
docker run -d --name grafana -p 3000:3000 grafana/grafana
```

### 3.2 Log in to Grafana

Open `http://localhost:3000` in a browser. The default credentials are:

- Username: `admin`
- Password: `admin`

Grafana will prompt you to change the password on first login.

### 3.3 Add Prometheus as a data source

1. In the left sidebar, click **Connections** → **Data sources**.
2. Click **Add new data source**.
3. Select **Prometheus**.
4. Set **Prometheus server URL** to `http://localhost:9090` (adjust if Prometheus is on another host).
5. Leave all other settings at their defaults.
6. Click **Save & test**. Grafana should report "Successfully queried the Prometheus API."

---

## Step 4: Import the Dashboard

The repository includes a pre-built Grafana dashboard in `grafana-dashboard.json`. Import it using the provided script or manually through the Grafana UI.

### Option A: Import using the script (recommended)

From the repository root, run:

```bash
./import-grafana-dashboard.sh
```

By default, the script connects to `http://localhost:3000` with credentials `admin:admin`. Override with environment variables if needed:

```bash
GRAFANA_URL=http://grafana.example.com:3000 \
GRAFANA_USER=admin \
GRAFANA_PASS=yourpassword \
./import-grafana-dashboard.sh
```

On success, the script prints the dashboard URL:

```
Dashboard imported successfully.
Open: http://localhost:3000/d/emptyepsilon
```

The script requires `curl` and `python3`, which are available on most Linux systems.

### Option B: Import through the Grafana UI

1. In the left sidebar, click **Dashboards** → **Import**.
2. Click **Upload dashboard JSON file**.
3. Select `grafana-dashboard.json` from the repository root.
4. When prompted, select the Prometheus data source you added in Step 3.3.
5. Click **Import**.

### 4.1 Open the dashboard

Navigate to `http://localhost:3000/d/emptyepsilon` or find it under **Dashboards** → **EmptyEpsilon Server**.

---

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
| Update Phase Duration | Stacked time series showing how long each subsystem's `update()` call takes per tick |
| Server Update Duration | Time spent in the multiplayer server update cycle |
| Network Send Rate | Total and per-client bytes sent per second |
| Per-Component Network Bytes | Bytes attributed to each ECS component type over the last ~1 second |

> Per-component network bytes are only populated when `metricsserver` is set.

### Client Connections

| Panel | Description |
|-------|-------------|
| Connected Clients | Number of authenticated clients |
| Master Server State | Registration state with the public master server |
| Client Ping | Round-trip time per client over time |
| Players | Table of every connected player: client ID, name, ship, and active crew positions |

### Player Ships

| Panel | Description |
|-------|-------------|
| Hull Integrity | Gauge per ship: hull health as a fraction of maximum |
| Shield Status | Gauge per ship face: shield level as a fraction of maximum |
| Reactor Energy | Energy level per ship over time |
| Hull History | Hull integrity time series for all player ships |
| Shield History | Shield level time series for all player ships |
| Player Ship Access | Table of active player ships and their access passwords |

> Hull Integrity and Shield Status use instant queries — gauges disappear as soon as a ship is destroyed rather than lingering until Prometheus's staleness timeout.

### Game Stats

| Panel | Description |
|-------|-------------|
| Kills by Instigator | Horizontal bar chart of entities destroyed by damage per instigator, keyed by callsign; snapped to the current session total |

### Debug

| Panel | Description |
|-------|-------------|
| PObject Count | Active legacy ref-counted objects (debug builds only; always empty in release) |
| Network Bytes by Component | Bar chart of the top 15 components by bandwidth, snapped to the current instant |

---

## Updating the Dashboard

After modifying `grafana-dashboard.json`, re-run `import-grafana-dashboard.sh` to push the updated definition to Grafana. The script uses `overwrite: true`, so it replaces the existing dashboard by UID without creating a duplicate.

---

## Adding New Metrics

All metrics are served from `src/prometheusMetrics.cpp`. There are two patterns: **gauge** (reads game state at scrape time) and **counter** (accumulated by events and returned as a running total).

### Gauge metrics

A gauge is sampled fresh on every scrape. Add a `collectXxxMetrics(string& output)` function and call it from the handler in `PrometheusMetricsServer::PrometheusMetricsServer`.

Use the `writeMetric` helper:

```cpp
static void writeMetric(string& output, const string& name, const string& help, const string& value_line);
```

`value_line` is the raw Prometheus text — one or more lines of the form `metric_name{label="value"} 42`. For a single unlabelled value:

```cpp
static void collectMyMetric(string& output)
{
    // Guard if the data source may be null
    if (!gameGlobalInfo) return;

    writeMetric(
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
    writeMetric(output, "ee_my_metric", "Help text", lines);
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

A counter is a session-total that only ever increases. Unlike a gauge it cannot be resampled — it must be accumulated as events happen.

**Step 1** — declare a static map (or other accumulator) in `prometheusMetrics.cpp`:

```cpp
static std::unordered_map<string, int> my_event_counts;
```

**Step 2** — expose a static recording function on `PrometheusMetricsServer`. Add the declaration to `prometheusMetrics.h`:

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

**Step 3** — call `recordMyEvent` from the game code wherever the event occurs. The recording is safe to call whether or not the metrics server is enabled.

**Step 4** — add a collect function that outputs the counter using `writeCounter`:

```cpp
static void collectMyEventMetrics(string& output)
{
    if (my_event_counts.empty())
        return;

    string lines;
    for (auto& [label, count] : my_event_counts)
        lines += "ee_my_event_total{label=\"" + escapeLabelValue(label) + "\"} " + formatInt(count) + "\n";

    writeCounter(output, "ee_my_event_total", "Help text", lines);
}
```

Then call it from the handler alongside the other collect functions.

#### Example: `ee_kills_total`

`ee_kills_total{instigator}` counts entities destroyed by damage, keyed by the instigator's callsign. The counter is incremented in `DamageSystem::destroyedByDamage` (`src/systems/damage.cpp`) whenever `info.instigator` is valid. It resolves the instigator's display name from the `CallSign` component, falls back to `TypeName`, and falls back to a raw entity ID string.

### Adding a Grafana panel

1. Open `grafana-dashboard.json` in a text editor.
2. At the end of the `"panels"` array, add a row object (if you want a new section heading) followed by the panel object.
3. Assign each object a unique integer `"id"` (increment from the highest existing `id`).
4. Set `"gridPos"` so the panel fits below the last existing panel. The `y` coordinate of your row must be at least `y + h` of the last panel above it.

**Row template:**

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

**Panel template (bar chart, instant query):**

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

After editing `grafana-dashboard.json`, run `import-grafana-dashboard.sh` (see **Updating the Dashboard** below) to push the changes to Grafana.

---

## Troubleshooting

**Metrics endpoint returns nothing / connection refused**
- Confirm `metricsserver=<port>` is in `options.ini` and EmptyEpsilon is running as a server, not a client.
- Confirm the port is not already in use: `ss -tlnp | grep <port>`.

**Prometheus target is DOWN**
- Check Prometheus logs: `journalctl -u prometheus` or the terminal output.
- Verify the `targets` entry in `prometheus.yml` matches the host and port in `options.ini`.
- Test connectivity directly: `curl http://<target>:<port>/metrics`.

**Dashboard shows "No data"**
- In Grafana, verify the Prometheus data source is configured and passes the connection test.
- Check the dashboard's time range (top right); set it to **Last 5 minutes**.
- Confirm Prometheus has scraped at least one data point: query `ee_game_speed` in the Prometheus UI.

**Mission Time or Scenario panels show template literals (`{{mission_time}}`, `{{scenario}}`)**
- These panels use `textMode: name` and require Grafana 9.3 or later.
- Confirm the Prometheus data source is correctly selected for the dashboard.
- If Grafana is version 9.2 or earlier, upgrade Grafana.

**`ee_server_network_bytes` is always empty**
- This metric is only collected when `metricsserver` is set to a non-zero port. Verify `options.ini`.

**Player Ships panels are empty even though ships exist**
- Ships are counted when their entity has a `PlayerControl` component. Ships spawned purely via script without `PlayerControl` will not appear.
