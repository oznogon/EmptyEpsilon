#pragma once

#include "io/http/server.h"
#include <stringImproved.h>

class PrometheusMetricsServer
{
public:
    PrometheusMetricsServer(int port);

    // Record a kill attributed to an instigator. Safe to call regardless of
    // whether the metrics server is running. The counter accumulates for the
    // session.
    static void recordKill(const string& instigator_callsign);
private:
    sp::io::http::Server server;
};
