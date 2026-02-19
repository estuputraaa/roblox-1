# Phase 2: NPC Spawn and Behavior - Context

**Gathered:** 2026-02-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase ini fokus membangun sistem NPC data-driven yang menghasilkan spawn terkontrol (weighted class + weighted NPC) dan menjalankan behavior berbeda untuk kategori normal, anomali, dan meme. Scope berhenti pada fondasi spawn/behavior/animasi dasar, bukan mini-game atau ending lanjutan.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<specifics>
## Specific Ideas

- NPC anomali wajib terasa berbeda secara movement/aksi dari NPC biasa.
- NPC meme Indonesia harus punya gaya animasi lucu agar tone komedi tetap kuat.
- Sistem ini harus siap jadi fondasi event anomali di Phase 3.

</specifics>

<deferred>
## Deferred Ideas

- Mekanik mini-game anomali detail dibahas di Phase 3.
- Branching ending/easter egg detail dibahas di Phase 4.
- UI polish interaksi NPC dibahas di Phase 5.

</deferred>

---

*Phase: 02-npc-spawn-and-behavior*
*Context gathered: 2026-02-19*
