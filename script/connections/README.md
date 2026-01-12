# Factorissimo Connection System (v2.0 Optimization)

This module serves as the core logic for Factorissimo, managing the transfer of resources, fluids, heat, and circuit signals between the exterior factory building and its interior surface.

---

## 🏗 Architecture & Performance (UPS)

The primary goal of this rewrite is to minimize CPU overhead (Updates Per Second) as the factory scales.

### 1. Cyclic Buffer Scheduling
Instead of checking every active connection every single tick, we use a distributed queue with a **600-slot buffer**:
* **Load Balancing:** If you have 600 heat pipes, the script processes only **one** pipe per tick rather than all 600 at once.
* **Granular Control:** Update frequency is determined by the `CONNECTION_UPDATE_RATE` (default: 5 ticks) and specific connection delays.
* **UPS Efficiency:** This prevents "script spikes" and ensures a smooth gameplay experience even with thousands of factory buildings.



### 2. Unified Logic Interface (`c_logic`)
We have deprecated the use of multiple fragmented metadata tables. Every connection type (belt, fluid, heat, etc.) now provides a standardized functional interface. This allows the core `connections.lua` engine to call methods directly, reducing `if-else` branching and memory lookups.



---

## 🔌 Connection Types

### 💧 Fluids
Utilizes the **Native Linked Fluidboxes** feature of Factorio 2.0.
* **Mechanism:** Interior and exterior pumps are linked at the engine level (C++), behaving as a single distributed fluid container.
* **Result:** Zero Lua overhead during resource transfer. The script is only invoked during connection initialization or rotation.



### ♨️ Heat
Since Factorio does not support "Linked Heat Pipes" natively, we implement a scripted thermal equilibrium:
* **Balance Formula:** Temperatures are averaged based on the following formula:
  $$T_{average} = \frac{T_{outside} + T_{inside}}{2}$$
* **Safety:** The logic respects the `max_temperature` of each prototype to prevent pipe damage.
* **Customization:** Players can adjust the update delay (5, 10, 30, or 120 ticks) to balance precision vs. performance.

### 📦 Chests
Supports inventory balancing between surfaces. Optimized in v2.0 to handle bulk stack transfers, allowing for efficient logistics network integration between the "inside" and "outside" worlds.

### 🚥 Circuit Networks
Leverages the new **Control Sections** API from Factorio 2.0. Signals are synchronized between ports (combinators) with minimal latency, enabling complex automation across factory boundaries.

---

## 🛠 Developer Guide

To add a new connection type, create a module (e.g., `power.lua`) that returns a table with the following interface:

| Method | Description |
| :--- | :--- |
| `connect` | Initializes the link and creates auxiliary entities. |
| `recheck` | Validates that entities still exist and are functional. |
| `tick` | Core transfer logic (called via the Cyclic Buffer). |
| `rotate` | Handles the "Rotate" (R) interaction. |
| `adjust` | Handles "Increase/Decrease" (Settings) interactions. |
| `destroy` | Cleans up auxiliary entities and links. |

**Registration Example:**
Add the following to the end of `connections.lua`:
```lua
register_connection_type("my_type", require("my_type"))

✅ Key Fixes & Improvements in v2.0
Orientation Logic: Correctly calculates collision_box for entities with non-standard rotations (crucial for Loaders and specialized belts).

Storage API Migration: All global states moved from the old global table to the modern storage API.

Quality Support: All created connectors (pumps, ports, etc.) inherit the Quality level of the factory building itself.

Memory Leak Prevention: Fixed a race condition where "delayed checks" could crash the game if an entity was destroyed in the same tick the check was queued.