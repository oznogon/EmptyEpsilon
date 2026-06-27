#pragma once

#include "io/http/server.h"

class EEHttpServer
{
public:
    EEHttpServer(int port, string static_file_path);

private:
    sp::io::http::Server server;
};
