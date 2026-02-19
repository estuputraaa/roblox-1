---
phase: 02-npc-spawn-and-behavior
plan: "02"
subsystem: npc-runtime-spawn
tags: [luau, weighted-random, spawn-throttle, day-night]
requires:
  - phase: 02-01
    provides: validated and normalized NPC config
provides:
  - weighted class selection dengan runtime caps/cooldown guards
  - profile-aware spawn resolution dari state pagi/malam/event
  - heartbeat spawn scheduler terkendali di bootstrap server
affects: [phase-02, phase-03]
tech-stack:
  added: [none]
  patterns: [two-stage weighted selection, global throttle guard, state-driven profile mapping]
key-files:
  created: []
  modified:
    - src/ReplicatedStorage/Shared/Config/NPCBehaviorConfig.lua
    - src/ServerScriptService/Services/NPCConfigValidator.lua
    - src/ServerScriptService/Services/NPCSpawner.lua
    - src/ServerScriptService/Services/GameDirector.lua
    - src/ServerScriptService/Main.server.lua
key-decisions:
  - "Pemilihan spawn tetap dua tahap: pilih class (profile weight) lalu pilih NPC (spawnWeight)."
  - "Global throttle + class cooldown + class cap dipasang sebelum clone model dipanggil."
  - "Mapping profile spawn diambil dari GameDirector supaya sinkron dengan state Morning/Night/Event."
patterns-established:
  - "Spawner menyimpan timestamp per class untuk mencegah burst spawn di heartbeat tinggi."
  - "Main loop melakukan guard state + interval sebelum mencoba spawn."
duration: 33min
completed: 2026-02-19
---

# Phase 2 Plan 02: Runtime Spawn Constraints Summary

**Engine spawn sekarang profile-aware dan memiliki guard runtime untuk mencegah over-spawn.**

## Performance

- **Duration:** 33 min
- **Started:** 2026-02-19T06:15:00Z
- **Completed:** 2026-02-19T06:48:00Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Menambahkan kebijakan spawn runtime: global cap, cap per class, throttle global, dan cooldown class per profile.
- Menambahkan jalur resolve profile dari `GameDirector` (`Day`/`Night`/`EventAnomaly`) agar komposisi spawn sinkron dengan state game.
- Menghubungkan spawn attempt otomatis ke `RunService.Heartbeat` dengan guard interval dan state check.

## Task Commits

1. **Task 1-2: cooldown/cap policy + profile-aware scheduler** - `9ad6d06` (feat)
2. **Task 3: wire spawn attempts di main heartbeat loop** - `207a6d5` (feat)

## Files Created/Modified
- `src/ReplicatedStorage/Shared/Config/NPCBehaviorConfig.lua` - policy throttle/cooldown per profile.
- `src/ServerScriptService/Services/NPCConfigValidator.lua` - normalisasi policy runtime spawn.
- `src/ServerScriptService/Services/NPCSpawner.lua` - guard caps/cooldown/throttle + resolve profile state-aware.
- `src/ServerScriptService/Services/GameDirector.lua` - helper profile mapping dari phase dan event state.
- `src/ServerScriptService/Main.server.lua` - spawn loop heartbeat dengan interval guard.

## Decisions Made
- Guard spawn dipusatkan di spawner agar caller tetap ringan dan aman.
- Spawn profile didelegasikan ke game director supaya satu sumber state authority.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external setup needed.

## Next Phase Readiness
- Fondasi spawn siap menerima behavior runner class-specific.
- Jalur event anomali bisa memaksa profile tanpa mengubah core spawner.

## Self-Check: PASSED

- Guard runtime terlihat di jalur sebelum clone model.
- Main loop memicu spawn attempt berkala dengan state/cooldown guard.

---
*Phase: 02-npc-spawn-and-behavior*
*Completed: 2026-02-19*
