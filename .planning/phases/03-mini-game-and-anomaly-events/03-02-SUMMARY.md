---
phase: 03-mini-game-and-anomaly-events
plan: "02"
subsystem: anomaly-runtime
tags: [luau, anomaly-event, scheduler, heartbeat]
requires:
  - phase: 03-01
    provides: mini-game AnomalyResponse contract
provides:
  - anomaly scheduler otomatis berbasis cooldown/chance
  - budget-gated anomaly trigger per phase
  - sinkronisasi world profile EventAnomaly saat event aktif
affects: [phase-03, phase-04, phase-05]
tech-stack:
  added: [none]
  patterns: [heartbeat scheduler tick, budget gate, transient spawn profile override]
key-files:
  created: []
  modified:
    - src/ServerScriptService/Services/AnomalyEventService.lua
    - src/ServerScriptService/Services/GameDirector.lua
    - src/ServerScriptService/Main.server.lua
key-decisions:
  - "Event anomali ditrigger dari scheduler `Tick` dengan cooldown + chance, bukan trigger ad-hoc manual."
  - "Budget phase dikonsumsi hanya saat event benar-benar akan dipicu."
patterns-established:
  - "Anomaly service publish warning payload ke remote channel non-fatal."
  - "Main heartbeat tetap fail-safe: anomaly tick tetap jalan walau regular NPC spawn tertahan guard."
duration: 31min
completed: 2026-02-19
---

# Phase 3 Plan 02: Anomaly Trigger Pipeline Summary

**Event anomali kini berjalan otomatis, terkontrol budget, dan sinkron dengan state spawn dunia.**

## Performance

- **Duration:** 31 min
- **Started:** 2026-02-19T08:09:00Z
- **Completed:** 2026-02-19T08:40:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Menambahkan scheduler `Tick` pada `AnomalyEventService` dengan cooldown, random chance, dan re-entrancy guard.
- Mengintegrasikan phase event budget (`GameDirector:ConsumeEventBudget`) serta temporary profile override `EventAnomaly`.
- Menyambungkan anomaly scheduler ke heartbeat runtime di `Main.server` dan remote warning channel.

## Task Commit

1. **Task 1-3: anomaly scheduler + runtime integration** - `9fa3b9b` (feat)

## Files Created/Modified
- `src/ServerScriptService/Services/AnomalyEventService.lua` - scheduler, trigger pipeline, warning publisher.
- `src/ServerScriptService/Services/GameDirector.lua` - helper `GetActivePlayer` untuk context scheduler.
- `src/ServerScriptService/Main.server.lua` - runtime wiring remote + anomaly tick integration.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Next Phase Readiness
- Economy pipeline siap menerima frekuensi event anomali yang lebih realistis.
- UI/event feed phase berikutnya bisa konsumsi payload warning yang sudah terstruktur.

## Self-Check: PASSED

- Scheduler anomaly aktif di heartbeat dan terlindung dari overlap event.
- Trigger event menghormati budget phase sebelum eksekusi challenge.

---
*Phase: 03-mini-game-and-anomaly-events*
*Completed: 2026-02-19*
