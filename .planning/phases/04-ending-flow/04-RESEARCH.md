# Phase 4: Ending Flow - Research

**Researched:** 2026-02-19
**Domain:** Roblox Luau ending resolver + trigger wiring from NPC and anomaly events
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Ending resolver tersentral di `EndingService`.
- Prioritas ending: `EASTER_TUNGTUNG` > `EASTER_PORTAL` > `MAIN_ENDING`.
- Flag utama: `wasHitByTungTung`, `enteredHiddenPortal`, `lastEndingCode`.
- Trigger TungTung berasal dari behavior NPC meme.
- Trigger portal tersembunyi berasal dari pipeline event anomali.

### Claude's Discretion
- Struktur metadata ending boleh modular/extensible.
- Trigger portal boleh probabilistik untuk skeleton phase.

### Deferred Ideas (OUT OF SCOPE)
- UI/cutscene ending final
- Ending gallery UI
</user_constraints>

## Summary

Fondasi codebase sudah mendukung ending dasar (`EndingService.ResolveEnding`) tetapi belum ada integrasi trigger nyata dari gameplay runtime. Gap phase 4 ada di:
1. metadata ending + tracking unlock belum eksplisit,
2. flag trigger dari meme/anomaly belum ditulis ke economy,
3. notifikasi ending ke client belum ada wiring remote.

Pendekatan paling aman adalah dua plan:
- 04-01: harden `EndingService` + flag/unlock tracking.
- 04-02: integrasi trigger dari `MemeBehaviors` + `AnomalyEventService` + notifikasi remote.

## Architecture Recommendations

### Pattern 1: Declarative Ending Definitions
- Simpan daftar ending dalam table metadata (`code`, `priority`, `title`, `description`, `resolver`).
- Resolver memilih kode pertama berdasarkan prioritas.

### Pattern 2: Service-level Flag Bridge
- `EndingService:RecordFlag(player, flagName, value)` sebagai entry point tunggal.
- Di belakang layar tetap memakai `EconomyManager:SetFlag`.

### Pattern 3: Best-effort Event Notification
- Ending trigger mengirim `RemoteEvent` jika tersedia.
- Jika remote tidak tersedia, logging warning tanpa menghentikan loop game.

## Pitfalls and Safeguards

### Pitfall 1: Flag tidak pernah terset dari runtime
- Safeguard: injeksikan helper `setPlayerFlag` ke behavior context pada runner.

### Pitfall 2: Ending notifikasi berulang
- Safeguard: cache sesi per player pada `EndingService` untuk dedupe notifikasi.

### Pitfall 3: Portal flag terlalu sering aktif
- Safeguard: apply chance gate + hanya set sekali jika belum pernah unlock.

## Metadata

**Confidence breakdown:**
- Resolver logic: HIGH
- Runtime trigger integration: HIGH
- Remote notification fallback: HIGH

**Research date:** 2026-02-19
**Valid until:** 2026-03-21
