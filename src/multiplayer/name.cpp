#include "multiplayer/name.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(CallSignReplication, CallSign)
    // Config field: 1Hz
    CONFIG_REPLICATION_FIELD(callsign);
}

BASIC_REPLICATION_IMPL(TypeNameReplication, TypeName)
    // Config fields: 1Hz
    CONFIG_REPLICATION_FIELD(type_name);
    CONFIG_REPLICATION_FIELD(localized);
}
