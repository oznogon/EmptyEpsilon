#pragma once

#include "io/http/server.h"

class PrometheusMetricsServer
{
public:
    PrometheusMetricsServer(int port);
private:
    sp::io::http::Server server;
};
