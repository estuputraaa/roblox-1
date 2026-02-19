---
phase: 01-core-economy-loop
plan: "02"
subsystem: economy
tags: [luau, economy, balancing, monetization]
requires:
  - phase: 01-01
    provides: runtime day-cycle foundation and fail-state surface
provides:
  - economy baseline policy (start cash + flat operational cost)
  - risk-tier mini-game reward and contextual penalties
  - continue pricing policy with per-player usage tracking
affects: [phase-01-plan-03, phase-06]
tech-stack:
  added: [none]
  patterns: [policy-driven economy tuning, server-authoritative continue pricing]
key-files:
  created:
    - src/ReplicatedStorage/Shared/Config/MiniGameConfig.lua
    - src/ReplicatedStorage/Shared/Config/MonetizationConfig.lua
    - src/ServerScriptService/Services/MonetizationService.lua
  modified:
    - src/ServerScriptService/Services/EconomyManager.lua
key-decisions:
  - "Starting cash dikunci ke Rp150 dengan biaya operasional flat."
  - "Penalty kegagalan anomali dibuat lebih berat via multiplier kontekstual."
  - "Harga continue dihitung linear-cap dari config agar mudah dituning."
patterns-established:
  - "Balancing utama dipusatkan pada module config."
  - "Counter continue usage disimpan per pemain di EconomyManager."
duration: 24min
completed: 2026-02-19
---

# Phase 1 Plan 02: Economy Policy Summary

**Economy policy is now locked to player decisions, including risk-tier rewards and linear-capped continue pricing.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-02-19T04:13:00Z
- **Completed:** 2026-02-19T04:37:00Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- Mengubah baseline ekonomi agar player mulai dengan Rp150 dan biaya operasional harian flat.
- Menyetel mini-game reward/penalty berdasarkan risk tier (mie rendah, repair sedang, anomali tinggi).
- Menambah policy continue linear-cap (20 +20, cap 120) dan tracking usage per player.

## Task Commits

Each task was committed atomically:

1. **Task 1: Kunci baseline ekonomi awal dan biaya operasional flat** - `86e83e6` (feat)
2. **Task 2: Terapkan risk-tier reward dan contextual penalty** - `512c5f4` (feat)
3. **Task 3: Implement continue pricing policy linear dengan cap** - `a122689` (feat)

## Files Created/Modified
- `src/ServerScriptService/Services/EconomyManager.lua` - baseline ekonomi, penalty kontekstual, counter continue.
- `src/ReplicatedStorage/Shared/Config/MiniGameConfig.lua` - konfigurasi reward/penalty mini-game berbasis risiko.
- `src/ReplicatedStorage/Shared/Config/MonetizationConfig.lua` - policy continue + placeholder product.
- `src/ServerScriptService/Services/MonetizationService.lua` - kalkulasi harga continue dan hook purchase flow.

## Decisions Made
- Biaya operasional dibuat flat untuk menjaga prediktabilitas tekanan ekonomi awal.
- Continue pricing dipisahkan ke config agar iterasi balancing tidak perlu refactor service.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Fail/recover flow bisa memakai continue pricing dan usage counter yang sudah tersedia.
- Konfigurasi monetisasi placeholder siap dihubungkan ke flow fail real-time.

## Self-Check: PASSED

- Key files created and present on disk.
- Task commit hashes found in git history.

---
*Phase: 01-core-economy-loop*
*Completed: 2026-02-19*
