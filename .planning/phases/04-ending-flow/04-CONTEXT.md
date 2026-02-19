# Phase 4: Ending Flow - Context

**Gathered:** 2026-02-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase ini fokus menentukan dan mengintegrasikan jalur ending game: main ending setelah survive 7 hari, dan easter egg endings dari kondisi spesifik gameplay. Scope berhenti pada resolver ending + flag tracking + wiring trigger dari NPC/event ke ending system, bukan UI cinematic final.

</domain>

<decisions>
## Implementation Decisions

### Ending Resolver
- `EndingService` menjadi pusat aturan ending.
- Prioritas ending wajib:
  1. Easter egg `EASTER_TUNGTUNG`
  2. Easter egg `EASTER_PORTAL`
  3. `MAIN_ENDING` (day >= 7, bukan game over)
- Resolver harus deterministic dan aman dipanggil berulang.

### Flag Tracking
- Flag ending disimpan per player via economy flags.
- Flag minimum yang harus didukung:
  - `wasHitByTungTung`
  - `enteredHiddenPortal`
  - `lastEndingCode`
- Saat ending terselesaikan, service menandai unlock ending agar bisa diinspeksi service lain.

### Trigger Integration
- Trigger `wasHitByTungTung` berasal dari behavior NPC meme `TungTung Sahur`.
- Trigger `enteredHiddenPortal` berasal dari pipeline event anomali (portal tersembunyi chance/condition).
- GameDirector tetap menentukan timing evaluasi ending utama pada transisi end-of-day.

### Runtime Safety
- Unknown/missing flag tidak boleh menyebabkan crash.
- Notifikasi ending ke client bersifat best-effort (remote optional, fail-safe).
- Resolver harus menghindari spam notifikasi berulang untuk ending yang sama pada sesi yang sama.

### Claude's Discretion
- Format metadata ending (title/description/type/priority) boleh ditentukan modular selama mudah diperluas.
- Cara portal hidden dipicu dari anomaly boleh probabilistik sederhana untuk skeleton fase ini.

</decisions>

<specifics>
## Specific Ideas

- Easter egg "dipukul TungTung Sahur" harus benar-benar terhubung ke behavior meme, bukan flag manual.
- Easter egg portal harus terasa rahasia tapi tetap bisa terjadi secara valid saat run aktif.

</specifics>

<deferred>
## Deferred Ideas

- Cutscene/animasi ending final dibahas pada phase UI polish.
- Koleksi gallery ending/unlock UI dibahas setelah remote UI phase 5 stabil.

</deferred>

---

*Phase: 04-ending-flow*
*Context gathered: 2026-02-19*
