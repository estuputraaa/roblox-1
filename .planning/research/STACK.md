# Stack Research - Jaga Warnet (Roblox)

## Recommended Core Stack

- **Engine**: Roblox Studio + Luau
- **Project Sync (optional but recommended)**: Rojo
- **Package Manager (optional)**: Wally
- **Code Quality (optional)**: Selene + StyLua (for team consistency)
- **Data persistence**: Roblox DataStoreService
- **Server communication**: RemoteEvent / RemoteFunction
- **Pathfinding NPC**: PathfindingService (fallback to simple waypoint movement)

## Why This Stack

- Native Roblox stack minimizes compatibility risk.
- Luau modules + config-driven data keeps balancing fast for gameplay iteration.
- Rojo and lint tools help maintain clean folder and predictable diffs.

## What Not To Use (Now)

- Heavy custom ECS framework for MVP - overkill before loop validation.
- Overly complex networking abstraction layer - direct remotes are enough for first milestone.
- Paid external backend for economy sync - defer until retention proof exists.

## Confidence

- Core Roblox stack: High
- Tooling choices (Rojo/Wally/lint): Medium (depends on team workflow)
- Pathfinding for all NPCs: Medium (anomaly behavior may need custom movement)
