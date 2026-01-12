# Factorissimo 3: Space Factory Library

A modular Lua library designed for the **Factorissimo 3** ecosystem in Factorio. This library simplifies the creation of interior factory buildings, space platform hubs, and complex prototype variations with built-in support for cross-mod compatibility.

## Key Features

* **Modular Architecture**: Separated logic for entities, items, recipes, and technologies.
* **Advanced Patching System**: Modify factory prototypes dynamically based on active mods or settings without overwriting the entire object.
* **Space Age Ready**: Native support for `space-platform-hub` types and quality-based connections.
* **Dynamic Tiling**: Automatic generation of colored floor and wall tiles for different factory tiers.
* **Priority-based Alternatives**: Robust system to handle multiple mod conflicts by using weighted priorities.

## Project Structure

* `library.lua`: The main entry point and stage manager (Settings/Data/Control).
* `lib/factory/`: Core logic for factory prototype generation.
* `lib/alternatives.lua`: The engine for patches, overrides, and conditions.
* `lib/base-prototypes.lua`: Skeleton templates for all mod entities.

## Installation

This library is intended to be used as a dependency for Factorissimo 3 sub-mods.