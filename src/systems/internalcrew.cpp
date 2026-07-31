#include "systems/internalcrew.h"
#include "components/internalrooms.h"
#include "ecs/query.h"
#include "multiplayer_server.h"
#include "random.h"

#include <glm/gtx/hash.hpp>
#include "astar.h"

static InternalRooms* pathfind_rooms;

static std::vector<std::pair<glm::ivec2, float>> astarGetNeighbors(glm::ivec2 pos) {
    std::vector<std::pair<glm::ivec2, float>> result;
    for(auto& room : pathfind_rooms->rooms) {
        if (pos.x >= room.position.x && pos.x < room.position.x + room.size.x && pos.y >= room.position.y && pos.y < room.position.y + room.size.y) {
            if (pos.x > room.position.x) result.push_back({pos + glm::ivec2{-1, 0}, 1.0f});
            if (pos.x < room.position.x + room.size.x - 1) result.push_back({pos + glm::ivec2{1, 0}, 1.0f});
            if (pos.y > room.position.y) result.push_back({pos + glm::ivec2{0, -1}, 1.0f});
            if (pos.y < room.position.y + room.size.y - 1) result.push_back({pos + glm::ivec2{0, 1}, 1.0f});
            break;
        }
    }
    for(auto& door : pathfind_rooms->doors) {
        if (door.horizontal) {
            if (door.position == pos) result.push_back({pos + glm::ivec2{0, -1}, 1.1f});
            if (door.position == pos + glm::ivec2{0, 1}) result.push_back({pos + glm::ivec2{0, 1}, 1.1f});
        } else {
            if (door.position == pos) result.push_back({pos + glm::ivec2{-1, 0}, 1.1f});
            if (door.position == pos + glm::ivec2{1, 0}) result.push_back({pos + glm::ivec2{1, 0}, 1.1f});
        }
    }
    return result;
}

static float astarGetDistance(glm::ivec2 a, glm::ivec2 b) { return glm::length(glm::vec2(b - a)); }

bool internalCrewIsCellOccupied(sp::ecs::Entity ship, glm::ivec2 cell, sp::ecs::Entity self)
{
    for (auto [entity, ic] : sp::ecs::Query<InternalCrew>())
    {
        if (entity == self || ic.ship != ship) continue;

        if (ic.position.x >= -0.5f)
        {
            glm::ivec2 current(ic.position.x + 0.5f, ic.position.y + 0.5f);
            if (current == cell) return true;
        }

        if (ic.target_position == cell) return true;
    }

    return false;
}

void InternalCrewSystem::update(float delta)
{
    for(auto [entity, ic] : sp::ecs::Query<InternalCrew>()) {
        if (game_server && !ic.ship)
        {
            entity.destroy();
            continue;
        }

        auto ir = ic.ship.getComponent<InternalRooms>();
        if (!ir) continue;

        if (ir->rooms.size() == 0)
        {
            if (game_server.isAlive()) entity.destroy();
            continue;
        }

        if (ic.position.x < -0.5f)
        {
            std::vector<glm::ivec2> free_positions;

            for (const auto& room : ir->rooms)
            {
                for (int x = room.position.x; x < room.position.x + room.size.x; x++)
                {
                    for (int y = room.position.y; y < room.position.y + room.size.y; y++)
                    {
                        if (!internalCrewIsCellOccupied(ic.ship, {x, y}, entity))
                            free_positions.emplace_back(x, y);
                    }
                }
            }

            if (!free_positions.empty())
            {
                auto pos = free_positions[irandom(0, int(free_positions.size()) - 1)];
                ic.position = glm::vec2(pos);
                ic.target_position = pos;
            }
        }

        ic.action_delay -= delta;
        glm::ivec2 pos = glm::ivec2(ic.position.x + 0.5f, ic.position.y + 0.5f);
        switch(ic.action)
        {
        case InternalCrew::Action::Idle:
            {
                ic.action_delay = 1.0f / ic.move_speed;
                if (pos != ic.target_position)
                {
                    pathfind_rooms = ir;
                    auto path = astar(pos, ic.target_position, astarGetNeighbors, astarGetDistance);
                    if (path.size() > 0) {
                        ic.action = InternalCrew::Action::Move;
                        if (path[0].x > pos.x) ic.direction = InternalCrew::Direction::Right;
                        if (path[0].x < pos.x) ic.direction = InternalCrew::Direction::Left;
                        if (path[0].y > pos.y) ic.direction = InternalCrew::Direction::Down;
                        if (path[0].y < pos.y) ic.direction = InternalCrew::Direction::Up;
                    }
                }
                ic.position = glm::vec2{pos.x, pos.y};

                if (auto irc = entity.getComponent<InternalRepairCrew>()) {
                    auto system = ShipSystem::get(ic.ship, ir->getSystemAtRoom(pos));
                    if (system)
                    {
                        system->health += irc->repair_per_second * delta;
                        if (system->health > 1.0f)
                            system->health = 1.0;
                        system->hacked_level -= irc->unhack_per_second * delta;
                        if (system->hacked_level < 0.0f)
                            system->hacked_level = 0.0;
                    }
                    if (ir->auto_repair_enabled && pos == ic.target_position && (!system || system->health >= system->health_max))
                    {
                        int n=irandom(0, ShipSystem::COUNT - 1);

                        system = ShipSystem::get(ic.ship, ShipSystem::Type(n));
                        if (system && system->health < system->health_max)
                        {
                            std::vector<glm::ivec2> candidates;

                            for (unsigned int idx = 0; idx < ir->rooms.size(); idx++)
                            {
                                if (ir->rooms[idx].system == ShipSystem::Type(n))
                                {
                                    for (int x = ir->rooms[idx].position.x; x < ir->rooms[idx].position.x + ir->rooms[idx].size.x; x++)
                                    {
                                        for (int y = ir->rooms[idx].position.y; y < ir->rooms[idx].position.y + ir->rooms[idx].size.y; y++)
                                        {
                                            if (glm::ivec2(x, y) != pos && !internalCrewIsCellOccupied(ic.ship, {x, y}, entity))
                                                candidates.emplace_back(x, y);
                                        }
                                    }
                                }
                            }

                            if (!candidates.empty())
                                ic.target_position = candidates[irandom(0, int(candidates.size()) - 1)];
                        }
                    }
                }
            }
            break;
        case InternalCrew::Action::Move:
            switch(ic.direction)
            {
            case InternalCrew::Direction::None: break;
            case InternalCrew::Direction::Left: ic.position.x -= delta * ic.move_speed; break;
            case InternalCrew::Direction::Right: ic.position.x += delta * ic.move_speed; break;
            case InternalCrew::Direction::Up: ic.position.y -= delta * ic.move_speed; break;
            case InternalCrew::Direction::Down: ic.position.y += delta * ic.move_speed; break;
            }
            if (ic.action_delay < 0.0f)
                ic.action = InternalCrew::Action::Idle;
            break;
        }
    }
}
