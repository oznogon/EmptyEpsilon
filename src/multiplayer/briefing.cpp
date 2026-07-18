#include "multiplayer/briefing.h"
#include "multiplayer.h"

BASIC_REPLICATION_IMPL(BriefingReplication, Briefing)
    BASIC_REPLICATION_VECTOR(pages)
        VECTOR_REPLICATION_FIELD(caption);
        VECTOR_REPLICATION_FIELD(image);
        VECTOR_REPLICATION_FIELD(audio);
        VECTOR_REPLICATION_FIELD(duration);

        // Map data replication
        {
            switch(BRR) {
            case BasicReplicationRequest::SendAll:
                vector_flags |= vector_flag;
                vector_tmp << vector_target->map_data.duration;
                vector_tmp << vector_target->map_data.keyframes.size();
                break;
            case BasicReplicationRequest::Update:
                if (vector_target->map_data.duration != vector_backup->map_data.duration
                    || vector_target->map_data.keyframes.size() != vector_backup->map_data.keyframes.size())
                {
                    vector_flags |= vector_flag;
                    vector_tmp << vector_target->map_data.duration;
                    vector_tmp << vector_target->map_data.keyframes.size();
                    vector_backup->map_data.duration = vector_target->map_data.duration;
                    vector_backup->map_data.keyframes.resize(vector_target->map_data.keyframes.size());
                }
                break;
            case BasicReplicationRequest::Receive:
                if (vector_flags & vector_flag)
                {
                    packet >> vector_target->map_data.duration;
                    size_t kf_count;
                    packet >> kf_count;
                    vector_target->map_data.keyframes.resize(kf_count);
                }
                break;
            }
            vector_flag <<= 1;
        }

        for (size_t kf_idx = 0;
             (BRR == BasicReplicationRequest::Receive)
                || kf_idx < vector_target->map_data.keyframes.size();
             kf_idx++)
        {
            uint32_t kf_flags = 0;
            if (BRR == BasicReplicationRequest::Receive)
            {
                packet >> kf_flags;
                if (kf_flags == 0) break;
                packet >> kf_idx;
                if (kf_idx >= vector_target->map_data.keyframes.size())
                {
                    LOG(Warning, "Briefing map keyframe replication index out of range");
                    break;
                }
            }

            auto kf_target = &vector_target->map_data.keyframes[kf_idx];
            auto kf_backup = (vector_backup && kf_idx < vector_backup->map_data.keyframes.size())
                ? &vector_backup->map_data.keyframes[kf_idx] : nullptr;
            sp::io::DataBuffer kf_tmp;
            uint32_t kf_flag = 1;

            switch(BRR) {
            case BasicReplicationRequest::SendAll:
                kf_flags |= kf_flag; kf_tmp << kf_target->timestamp; break;
            case BasicReplicationRequest::Update:
                if (kf_target->timestamp != kf_backup->timestamp)
                    { kf_flags |= kf_flag; kf_tmp << kf_target->timestamp; kf_backup->timestamp = kf_target->timestamp; }
                break;
            case BasicReplicationRequest::Receive:
            {
                if (kf_flags & kf_flag) packet >> kf_target->timestamp;
                break;
            }
            }
            kf_flag <<= 1;

            switch(BRR) {
            case BasicReplicationRequest::SendAll:
                kf_flags |= kf_flag; kf_tmp << kf_target->camera_position.x; kf_tmp << kf_target->camera_position.y; break;
            case BasicReplicationRequest::Update:
                if (kf_target->camera_position != kf_backup->camera_position)
                    { kf_flags |= kf_flag; kf_tmp << kf_target->camera_position.x; kf_tmp << kf_target->camera_position.y; kf_backup->camera_position = kf_target->camera_position; }
                break;
            case BasicReplicationRequest::Receive:
            {
                if (kf_flags & kf_flag) packet >> kf_target->camera_position.x >> kf_target->camera_position.y;
                break;
            }
            }
            kf_flag <<= 1;

            switch(BRR) {
            case BasicReplicationRequest::SendAll:
                kf_flags |= kf_flag; kf_tmp << kf_target->zoom; break;
            case BasicReplicationRequest::Update:
                if (kf_target->zoom != kf_backup->zoom)
                    { kf_flags |= kf_flag; kf_tmp << kf_target->zoom; kf_backup->zoom = kf_target->zoom; }
                break;
            case BasicReplicationRequest::Receive:
            {
                if (kf_flags & kf_flag) packet >> kf_target->zoom;
                break;
            }
            }
            kf_flag <<= 1;

            // Entities count
            switch(BRR) {
            case BasicReplicationRequest::SendAll:
                kf_flags |= kf_flag; kf_tmp << kf_target->entities.size(); break;
            case BasicReplicationRequest::Update:
                if (kf_target->entities.size() != kf_backup->entities.size())
                    { kf_flags |= kf_flag; kf_tmp << kf_target->entities.size(); kf_backup->entities.resize(kf_target->entities.size()); }
                break;
            case BasicReplicationRequest::Receive:
                if (kf_flags & kf_flag)
                {
                    size_t ent_count;
                    packet >> ent_count;
                    kf_target->entities.resize(ent_count);
                }
                break;
            }
            kf_flag <<= 1;

            for (size_t ent_idx = 0;
                 (BRR == BasicReplicationRequest::Receive) || ent_idx < kf_target->entities.size();
                 ent_idx++)
            {
                uint32_t ent_flags = 0;
                if (BRR == BasicReplicationRequest::Receive)
                {
                    packet >> ent_flags;
                    if (ent_flags == 0) break;
                    packet >> ent_idx;
                    if (ent_idx >= kf_target->entities.size())
                    {
                        LOG(Warning, "Briefing map entity replication index out of range");
                        break;
                    }
                }

                auto ent_target = &kf_target->entities[ent_idx];
                auto ent_backup = (kf_backup && ent_idx < kf_backup->entities.size())
                    ? &kf_backup->entities[ent_idx] : nullptr;
                sp::io::DataBuffer ent_tmp;
                uint32_t ent_flag = 1;

                #define REPLICATE_FIELD(FIELD) \
                    switch(BRR) { \
                    case BasicReplicationRequest::SendAll: \
                        ent_flags |= ent_flag; ent_tmp << ent_target->FIELD; break; \
                    case BasicReplicationRequest::Update: \
                        if (ent_target->FIELD != ent_backup->FIELD) \
                            { ent_flags |= ent_flag; ent_tmp << ent_target->FIELD; ent_backup->FIELD = ent_target->FIELD; } \
                        break; \
                    case BasicReplicationRequest::Receive: \
                    { \
                        if (ent_flags & ent_flag) packet >> ent_target->FIELD; \
                        break; \
                    } \
                    } \
                    ent_flag <<= 1;

                REPLICATE_FIELD(id);
                REPLICATE_FIELD(position);
                REPLICATE_FIELD(rotation);
                REPLICATE_FIELD(world_size);
                REPLICATE_FIELD(radar_trace_image);
                REPLICATE_FIELD(color);
                REPLICATE_FIELD(visible);
                REPLICATE_FIELD(label);

                #undef REPLICATE_FIELD

                if (ent_tmp.getDataSize() > 0)
                    kf_tmp.write(ent_flags, ent_idx, ent_tmp);
            }

            if (BRR != BasicReplicationRequest::Receive && kf_tmp.getDataSize() > 0)
                kf_tmp.write(uint32_t(0));

            if (kf_tmp.getDataSize() > 0)
                vector_tmp.write(kf_flags, kf_idx, kf_tmp);
        }

        if (BRR != BasicReplicationRequest::Receive)
        {
            sp::io::DataBuffer end_marker;
            end_marker << uint32_t(0);
            if (vector_tmp.getDataSize() > 0)
                vector_tmp.write(uint32_t(0), size_t(0), end_marker);
        }

    VECTOR_REPLICATION_END();
}
