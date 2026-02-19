# Phase 2: NPC Spawn and Behavior - Research

**Researched:** 2026-02-19
**Domain:** Roblox Luau NPC orchestration (spawn weighting, behavior routing, animation hooks)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Spawn System
- Gunakan dua tingkat weighted random:
  - Level 1: pilih kelas NPC (`normal`, `anomaly`, `meme`) dari `SpawnProfile`.
  - Level 2: pilih NPC spesifik dari pool kelas sesuai `spawnWeight`.
- `SpawnProfile` wajib mendukung minimal:
  - `Day`
  - `Night`
  - `EventAnomaly`
- Spawn malam harus tetap di kategori **balanced** untuk normal vs anomali (anomali naik, tapi tidak mendominasi ekstrem).

### NPC Config and Schema
- Gunakan satu config utama (`NPCBehaviorConfig`) untuk:
  - identitas NPC
  - class
  - weight
  - modelName
  - animation ids
  - behavior payload
- Tambahkan validator schema server-side sebelum runtime spawn aktif.
- Invalid config harus di-skip aman dengan warning jelas, bukan crash loop.

### Behavior Runtime
- Behavior dieksekusi via router/runner berdasarkan `behavior.type`, bukan hardcoded if-else tersebar.
- Semua NPC minimal punya hook animasi:
  - idle
  - walk/move
  - emote/aksi khas
- Untuk Phase 2, behavior boleh baseline/simple selama kontrak kategori sudah berjalan:
  - normal: aktivitas rutin warnet
  - anomali: gangguan/tekanan
  - meme: interaksi komedi/event ringan

### Performance and Safety
- Batasi jumlah NPC aktif global untuk mencegah over-spawn.
- Tambahkan cooldown spawn per profile/class agar ritme stabil.
- Semua authority spawn/behavior tetap di server.

### Claude's Discretion
- Detail angka tuning spawn weight antar-NPC boleh disesuaikan selama menjaga intent kategori.
- Implementasi teknis animation playback (Animator/AnimationTrack lifecycle) bebas dipilih, asalkan robust dan tidak spam track.
- Struktur internal behavior modules boleh dipilih (folder per-class atau per-behavior-type) selama tetap modular.

### Deferred Ideas (OUT OF SCOPE)
- Mekanik mini-game anomali detail dibahas di Phase 3.
- Branching ending/easter egg detail dibahas di Phase 4.
- UI polish interaksi NPC dibahas di Phase 5.
</user_constraints>

## Summary

Fondasi Phase 2 paling aman dibuat dalam tiga lapis: validasi data config di awal, core spawn engine dengan constraint runtime (cooldown + active caps), lalu behavior runtime yang modular dan animation-safe. Pendekatan ini menjaga sistem tetap data-driven dan menghindari hardcode yang sulit ditune.

Codebase saat ini sudah punya `NPCBehaviorConfig` dan `NPCSpawner` awal, sehingga fokus implementasi adalah menutup gap reliability (schema validation, profile guard), behavior execution pipeline, serta integrasi animation hook pada model NPC yang valid.

**Primary recommendation:** implement `NPCConfigValidator` + `NPCBehaviorRunner`, lalu hubungkan keduanya ke `NPCSpawner` sebagai dependency injection.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Roblox Luau Modules | Built-in | Service modularity | Pattern standar server Roblox |
| Animator + AnimationTrack | Built-in | Playback animasi NPC | Integrasi native model humanoid |
| Random.new | Built-in | Weighted random deterministic | Cukup untuk spawn balancing runtime |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Attributes API | Built-in | Tag state npc/behavior | Debugging dan telemetry ringan |
| CollectionService (optional) | Built-in | Tagging NPC groups | Jika nanti butuh query per kategori |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Single config validator service | Inline checks di spawner | Lebih cepat awal, tapi validation logic tersebar |
| Behavior modules per-class | Single giant behavior switch | Giant switch cepat awal, tapi cepat menjadi sulit dirawat |

## Architecture Patterns

### Recommended Project Structure
```
src/ServerScriptService/Services/
|-- NPCConfigValidator.lua
|-- NPCBehaviorRunner.lua
|-- NPCBehaviors/
|   |-- NormalBehaviors.lua
|   |-- AnomalyBehaviors.lua
|   `-- MemeBehaviors.lua
`-- NPCSpawner.lua
```

### Pattern 1: Validate-Then-Run
**What:** Config divalidasi sekali saat init/spawn service, simpan hasil normalized.
**When to use:** Data-driven spawn dengan banyak entry NPC.
**Why:** Mencegah crash runtime karena typo config.

### Pattern 2: Behavior Router by Type
**What:** `behavior.type` dipetakan ke handler function modular.
**When to use:** Banyak variasi perilaku lintas kategori.
**Why:** Tambah behavior baru tanpa ubah core spawner.

### Anti-Patterns to Avoid
- Menjalankan spawn sebelum config validation selesai.
- Menjalankan animation load setiap frame (harus one-time per spawn).
- Menggabungkan logic spawn, behavior, dan effect ke satu file monolitik.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Animation runtime state machine penuh | Custom frame scheduler kompleks | Animator + track cache sederhana | MVP butuh reliable playback, bukan custom engine |
| Path planner kompleks di phase 2 | Full nav abstraction baru | Placeholder movement + existing Roblox primitives | Bukan scope inti phase ini |
| External balancing backend | Remote config service | Shared config module lokal | Iterasi cepat tanpa dependency eksternal |

## Common Pitfalls

### Pitfall 1: Weight distribution bias karena data invalid
**What goes wrong:** NPC tertentu tidak pernah spawn atau terlalu dominan.
**How to avoid:** Validator cek `spawnWeight > 0` dan profile totals.

### Pitfall 2: Over-spawn saat event transition
**What goes wrong:** NPC aktif melonjak saat profile berganti.
**How to avoid:** Global cap + per-profile cooldown gate.

### Pitfall 3: Animasi gagal silent
**What goes wrong:** NPC static karena track gagal load.
**How to avoid:** pcall load animation + fallback warning + continue behavior.

## Code Examples

### Weighted class pick
```lua
local className = weightedPickFromMap(rng, profile.classWeights)
local npcData = weightedPickFromArray(rng, pools[className])
```

### Safe animation hook
```lua
local ok, track = pcall(function()
	return animator:LoadAnimation(animation)
end)
if ok and track then track:Play() end
```

## Open Questions

1. **Spawn point strategy per profile**
   - What we know: phase 2 butuh spawn control.
   - What's unclear: apakah pakai fixed nodes atau random area.
   - Recommendation: pakai fixed nodes dulu untuk reliability.

2. **Behavior tick frequency**
   - What we know: behavior harus ringan.
   - What's unclear: interval ideal per behavior.
   - Recommendation: event-driven + fallback timer 0.5-1.0s.

## Sources

### Primary (HIGH confidence)
- Existing project code: `NPCBehaviorConfig.lua`, `NPCSpawner.lua`
- Existing project schema notes: `docs/GAME_SCHEMA.md`
- Existing phase context: `02-CONTEXT.md`

### Secondary (MEDIUM confidence)
- Existing architecture docs in `.planning/research/ARCHITECTURE.md`

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Spawn architecture: HIGH
- Behavior routing: HIGH
- Animation hooks: MEDIUM (needs runtime playtest)

**Research date:** 2026-02-19
**Valid until:** 2026-03-21
