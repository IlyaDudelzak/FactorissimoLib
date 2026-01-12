# Tile Creation API

Automatically manages unique floor and wall tiles for factory interiors.

## `createColoredTile(type, color)`
Generates a tile name based on the provided color.
* **type**: `"factory-wall"` or `"factory-floor"`.
* **color**: RGB table `{r, g, b}`.
* **Returns**: A unique string ID (e.g., `factory-floor-a1b2c3`).

## `addToData()`
Must be called in the `data.lua` stage. It iterates through all requested tile colors and creates the actual Factorio tile prototypes with the correct tints.