---
phase: 03-mini-game-and-anomaly-events
plan: "01"
subsystem: mini-game-contract
tags: [luau, mini-game, registry, gameplay-loop]
requires:
  - phase: 02-03
    provides: npc behavior runtime and stable server bootstrap
provides:
  - registry mini-game handler per tipe gameplay
  - contract result mini-game seragam lintas mode
  - helper API mini-game untuk integrasi service lain
affects: [phase-03, phase-05]
tech-stack:
  added: [none]
  patterns: [handler registry, normalized result envelope, server-authoritative simulation]
key-files:
  created: []
  modified:
    - src/ServerScriptService/Services/MiniGameService.lua
    - src/ReplicatedStorage/Shared/Config/MiniGameConfig.lua
    - src/ReplicatedStorage/Shared/Remotes/RemoteNames.lua
key-decisions:
  - "CookNoodle, RepairComputer, AnomalyResponse dipisah lewat handler registry, bukan random generic tunggal."
  - "Result mini-game distandarkan ke envelope `score/success/reward/penalty/tags/duration`."
patterns-established:
  - "Unknown miniGameId ditolak aman (warning + nil) tanpa memutus runtime."
  - "MiniGameService menyediakan helper `HasMiniGame/GetMiniGameConfig/ListMiniGames`."
duration: 28min
completed: 2026-02-19
---

# Phase 3 Plan 01: Mini-Game Registry Contract Summary

**Mini-game core sekarang terstruktur per handler dan mengembalikan contract hasil yang konsisten.**

## Performance

- **Duration:** 28 min
- **Started:** 2026-02-19T07:40:00Z
- **Completed:** 2026-02-19T08:08:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Refactor `MiniGameService` ke model registry handler untuk tiga mini-game wajib.
- Menstandarkan result object mini-game menjadi envelope seragam dengan key wajib.
- Menambah parameter threshold/range di config dan remote name placeholder untuk result/warning.

## Task Commit

1. **Task 1-3: mini-game registry + contract normalization** - `567de0f` (feat)

## Files Created/Modified
- `src/ServerScriptService/Services/MiniGameService.lua` - registry handler + contract envelope.
- `src/ReplicatedStorage/Shared/Config/MiniGameConfig.lua` - threshold dan score range per mini-game.
- `src/ReplicatedStorage/Shared/Remotes/RemoteNames.lua` - placeholder remote `MiniGameResult` + `AnomalyWarning`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Next Phase Readiness
- `AnomalyEventService` bisa memanggil `AnomalyResponse` dengan payload context yang konsisten.
- Economy integration bisa langsung konsumsi envelope result tanpa adapter tambahan.

## Self-Check: PASSED

- Handler mini-game terpisah untuk CookNoodle/RepairComputer/AnomalyResponse.
- Result contract konsisten dan tervalidasi pada jalur `RunMiniGame`.

---
*Phase: 03-mini-game-and-anomaly-events*
*Completed: 2026-02-19*
