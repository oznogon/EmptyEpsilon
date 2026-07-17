# The directory `scripts`

The Lua files are used in different ways.

## Hard-coded usage

The following files are loaded via hard-coded definitions and required only on the server. Their definitions are synchronized to clients.

- `factionInfo.lua` (faction definitions)
- `model_data.lua` (3D model definitions)
- `science_db.lua` (science database)
- `luax.lua` (Lua standard library extensions)
- `shipTemplates.lua`, which loads ship template class files in the `shiptemplates` directory
- `api/all.lua`, which loads EmptyEpsilon ECS entity definitions in the `api` directory

## Useful scripts to include

These files are useful to include on the server, but aren't required:

- `ee.lua` (EmptyEpsilon constants)
- `utils.lua` (EmptyEpsilon utility functions)
- `perlin_noise.lua`

## Scenarios

Scenario filenames follow a naming convention of `scenario_XX_name.lua`, where `XX` is a two-digit numeric ID. This ID follows these conventions:

- 00-04: Basic scenarios
- 05-79: Missions
  - 47-79: Xansta's scenarios
- 80-89: Player vs. player
- 90-9X: Development and testing scenarios

### Scripts for scenarios

- `border_defend_station.lua`: Station defense fleet AI (used by scenario_59_border.lua)
- `comms_scenario_utility.lua`: Comms helper for scenarios
- `control_code_scenario_utility.lua`: Helper functions for control codes
- `cpu_ship_diversification_scenario_utility.lua`: Manages CPU ship creation in scenarios
- `generate_call_sign_scenario_utility.lua`
- `place_station_scenario_utility.lua`: Station placement helper
- `player_ship_upgrade_downgrade_path_scenario_utility.lua`: Manages ship upgrades in some scenarios
- `spawn_ships_scenario_utility.lua`: Spawns ships in some scenarios
- `supply_drop.lua`
  - uses `comms_supply_drop.lua`
- `util_random_transports.lua`: Spawns random transport ships
- `utils_customElements.lua`: Custom UI element wrapper

## Tutorials

Tutorials are located in the `tutorial` directory and implemented in the monolithic `99_all.lua` script. The individual tutorial files invoke the corresponding tutorials.

The `tutorialUtils.lua` script provides supporting functions for tutorials.

## Communication

The default communication scripts for each created ship or station.

- `comms_ship.lua` (hard-coded default for ships)
- `comms_station.lua` (hard-coded default for stations)
  - uses `supply_drop.lua`
- `comms_supply_drop.lua` (used by `supply_drop.lua`)

They can be replaced in a scenario with custom scripts or functions by calling `obj:setCommsScript(filename)` or `obj:setCommsFunction(callback)`, where `obj` is an entity in the scenario.

## Localization

- `locale/` directory: PO file translations — auto-loaded alongside scripts

## Configuration files

- `.gitignore`: Prevents files from being added using git
- `.stylua.toml`: Defines style rules for autoformatting with [StyLua](https://github.com/JohnnyMorganz/StyLua)
