# Factory Creation API

This module manages the definition and generation of factory buildings.

## `add_factory(factory_data)`
Registers a factory. Before processing, it automatically checks the Alternatives system for any applicable patches.

### Parameters
The `factory_data` table supports the following fields:

* **Basic Info**:
  * `type`: `"factory"` (standard) or `"space-platform-hub"`.
  * `name`: Internal name.
  * `tier`: Numerical tier (1, 2, 3...).
* **Geometry**:
  * `outside_size`: Size on the map (e.g., 8).
  * `inside_size`: Size of the interior (e.g., 30).
* **Visuals**:
  * `color`: Table `{r, g, b}`. Used for map color and tile tinting.
  * `graphics`: Table containing icons and entity pictures.
* **Logic**:
  * `recipe`: Table with `ingredients` and `energy_required`.
  * `technology`: Table with research requirements and costs.

## Prototype Generation
When `add_all_factory_prototypes(data)` is called, the library generates:
1. The **Entity** (The building itself).
2. The **Item** (Standard and "Instantiated/Packed" versions).
3. The **Recipe**.
4. The **Technology** to unlock the recipe.