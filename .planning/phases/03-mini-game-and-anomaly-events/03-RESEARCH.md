# Phase 3: Mini-Game and Anomaly Events - Research

**Researched:** 2026-02-19
**Domain:** Roblox Luau mini-game orchestration + anomaly scheduler + economy impact
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Gunakan service registry tunggal untuk `CookNoodle`, `RepairComputer`, `AnomalyResponse`.
- Semua mini-game menghasilkan kontrak output seragam (`score/success/reward/penalty/tags`).
- Event anomali harus server-side, terjadwal/acak, dan mematuhi event budget phase.
- State dunia saat anomali aktif harus sinkron dengan spawn profile `EventAnomaly`.
- Hasil mini-game harus langsung memengaruhi ekonomi dan tercatat untuk balancing.

### Claude's Discretion
- Boleh gunakan simulasi RNG server-side untuk skeleton gameplay.
- Payload remote event feed boleh sederhana.
- Tuning cooldown/chance anomali boleh disesuaikan selama tidak spam.

### Deferred Ideas (OUT OF SCOPE)
- UI mini-game interaktif final
- Final ending branching dari event
- Balancing telemetry produksi
</user_constraints>

## Summary

Codebase saat ini sudah punya fondasi penting: `GameDirector` dengan event budget per phase, `NPCSpawner` profile-aware, dan `EconomyManager` dengan `ApplyMiniGameResult`. Gap phase 3 ada di tiga area:
1. kontrak mini-game masih terlalu generik,
2. event anomali belum punya scheduler runtime,
3. ekonomi belum menyimpan statistik mini-game yang kaya.

Rekomendasi implementasi terbaik adalah memecah phase 3 menjadi tiga plan berurutan:
- Plan 03-01: kontrak mini-game + registry handlers,
- Plan 03-02: anomaly trigger pipeline terjadwal,
- Plan 03-03: integrasi ekonomi lanjutan + telemetry stats.

## Architecture Patterns

### Pattern 1: Registry Handler per Mini-Game
- Simpan handler function per `miniGameId`.
- `RunMiniGame` jadi facade tunggal.
- Unknown ID -> warning + return nil (no crash).

### Pattern 2: Event Scheduler Tick
- `AnomalyEventService:Tick(deltaTime, context)` dipanggil dari heartbeat.
- Scheduler menghormati cooldown min/max + chance + budget phase.
- Re-entrancy guard mencegah trigger overlap.

### Pattern 3: Economy Result Envelope
- Economy menerima result object terstruktur.
- Hitung delta cash dan simpan statistik per mini-game.
- Return ringkasan impact ke caller untuk logging/UI feed.

## Pitfalls and Safeguards

### Pitfall 1: Event anomali spam di heartbeat
- Safeguard: cooldown timer + budget check + chance gate.

### Pitfall 2: Mini-game result shape tidak konsisten
- Safeguard: normalisasi result object di `MiniGameService` sebelum kirim ke economy.

### Pitfall 3: Ekonomi tidak punya jejak source perubahan
- Safeguard: tambah mini-game stats dan last mini-game summary per player.

## Implementation Notes

- Gunakan API `GameDirector:GetActivePlayer()` (ditambahkan bila belum ada) agar scheduler punya target player tunggal yang sedang run.
- Publish event feed via RemoteEvent placeholder; bila folder/remote belum ada, fail-safe tanpa throw.
- Pertahankan komentar modul agar konsisten dengan standar project.

## Metadata

**Confidence breakdown:**
- MiniGame registry: HIGH
- Anomaly scheduler: HIGH
- Economy integration: HIGH

**Research date:** 2026-02-19
**Valid until:** 2026-03-21
