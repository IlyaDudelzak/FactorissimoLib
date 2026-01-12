# Alternatives & Patching API

The Alternatives system provides a flexible way to modify factory prototypes dynamically. It is used to ensure compatibility with other mods or to change data based on startup settings without overwriting the core logic.

## Functions

### `add_patch(category, patch_data, cond_type, cond_args, priority)`
Applies a partial update to an existing category.
* **category** (string): The unique ID of the target (e.g., factory name).
* **patch_data** (table): A table containing only the fields you wish to change. Uses deep recursive merging.
* **cond_type** (string): One of `"mod"`, `"setting"`, or `"always"`.
* **cond_args** (any): Arguments for the condition (e.g., `"space-age"` for mod check).
* **priority** (number): Default is `50`. Higher priority patches are applied later, allowing them to overwrite lower priority patches.

### `add_override(category, data, cond_type, cond_args, priority)`
Replaces the entire data object.
* If multiple overrides are valid, only the one with the **highest priority** is used.

## Condition Reference
| Type | Description | Argument Example |
| :--- | :--- | :--- |
| `"always"` | Always returns true. | `nil` or `{}` |
| `"mod"` | True if the mod is active. | `"space-age"` |
| `"setting"` | True if a startup setting is enabled. | `"my-mod-hard-mode"` |

# Extending the Condition System

The library allows developers to register custom condition types. This is useful when you need more complex logic than simple mod or setting checks.

## `register_condition_type(name, func)`
Registers a new logic handler for the Alternatives system.
* **name** (string): The unique identifier for your condition.
* **func** (function): A function that must return `true` or `false`. It receives arguments passed via `cond_args`.

### Example: Checking for a specific Game Version
If you want to apply a patch only for Factorio 2.0 or higher:

```lua
local Alt = require("lib.alternatives")

-- 1. Register the new condition
Alt.register_condition_type("min-version", function(required_version)
    local current = core.version -- Example version source
    return current >= required_version
end)

-- 2. Use it in a patch
Alt.add_patch("factory-1", 
    { technology = { hidden = true } }, 
    "min-version", 
    "2.0.0", 
    100
)

Complex Logic
You can also pass tables as arguments to create complex filters:

```lua

Alt.register_condition_type("multiple-mods", function(mod_list)
    for _, mod_name in ipairs(mod_list) do
        if not mods[mod_name] then return false end
    end
    return true
end)

-- Applies only if BOTH mods are present

```lua
Alt.add_patch("factory-1", data, "multiple-mods", {"mod-a", "mod-b"}, 50)