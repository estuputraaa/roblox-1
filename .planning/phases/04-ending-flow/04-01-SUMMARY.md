---
phase: 04-ending-flow
plan: "01"
subsystem: ending-resolver
tags: [luau, ending, resolver, flags]
requires:
  - phase: 03-03
    provides: runtime mini-game/event stats and stable game loop
provides:
  - declarative ending definitions dengan priority resolver
  - flag bridge API untuk ending trigger integration
  - unlock tracking dan last ending metadata per pemain
affects: [phase-04, phase-05]
tech-stack:
  added: [none]
  patterns: [declarative rules, fail-safe remote notify, economy flag bridge]
key-files:
  created: []
  modified:
    - src/ServerScriptService/Services/EndingService.lua
    - src/ServerScriptService/Services/GameDirector.lua
key-decisions:
  - "Resolver ending dipindah ke tabel definisi terprioritas agar mudah diperluas."
  - "Unlock ending disimpan sebagai flag `endingUnlocked:<code>` dan `lastEndingCode`."
patterns-established:
  - "Notifikasi ending bersifat best-effort dengan dedupe per pemain di sesi aktif."
  - "API RecordFlag/GetFlag di EndingService jadi bridge standar untuk trigger eksternal."
duration: 25min
completed: 2026-02-19
---

# Phase 4 Plan 01: Ending Resolver Foundation Summary

**Ending service sekarang punya resolver terstruktur, tracking unlock, dan bridge flag yang siap dipakai runtime trigger.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-02-19T09:20:00Z
- **Completed:** 2026-02-19T09:45:00Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments
- Refactor `EndingService` dari if-chain ke declarative ending definitions dengan priority.
- Menambahkan API `RecordFlag`, `GetFlag`, `GetEndingDefinition`, dan `GetUnlockedEndings`.
- Menambahkan jalur unlock tracking + last ending metadata dan mempertahankan kompatibilitas dengan `GameDirector`.

## Task Commit

1. **Task 1-3: ending resolver + flag tracking foundation** - `3a4fa84` (feat)

## Files Created/Modified
- `src/ServerScriptService/Services/EndingService.lua` - ending definitions, resolver, unlock tracking, notifikasi dedupe.
- `src/ServerScriptService/Services/GameDirector.lua` - pass context source saat resolve ending end-of-day.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Next Phase Readiness
- Trigger runtime dari behavior/anomaly bisa menulis flag ending lewat API service yang sama.
- UI feedback dapat konsumsi payload ending trigger tanpa mengubah resolver core.

## Self-Check: PASSED

- Resolver ending membaca prioritas easter egg di atas main ending.
- Flag unlock dan last ending tercatat melalui bridge economy flag.

---
*Phase: 04-ending-flow*
*Completed: 2026-02-19*
