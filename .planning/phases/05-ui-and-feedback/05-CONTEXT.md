# Phase 5: UI and Feedback - Context

**Gathered:** 2026-02-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase ini fokus pada visibilitas status game untuk pemain: HUD runtime (day/cash/objective), warning feed event anomali, dan hint kondisi ending secara terukur. Scope berhenti di pipeline feedback dasar server-client dan UI controller client; tidak mencakup polish visual final atau cutscene.

</domain>

<decisions>
## Implementation Decisions

### HUD Runtime
- HUD wajib menampilkan minimal:
  - day aktif
  - phase (Morning/Night)
  - cash
  - objective text
  - timer phase
- Data HUD dikirim dari server via remote update berkala.

### Event Feed
- Event feed harus menerima warning dari pipeline anomaly dan status penting (phase/day transition, fail, continue, ending).
- Event feed cukup berbasis text feed sederhana, yang penting jelas dibaca.

### Ending Hint Visibility
- Objective/hint perlu memberi petunjuk ringan tentang ending conditions:
  - survive sampai day 7
  - easter egg dari TungTung / portal
- Hint tidak boleh membocorkan semua mekanik rahasia secara eksplisit detail.

### Runtime Safety
- Remote feedback bersifat best-effort; jika data payload tidak lengkap UI tidak boleh crash.
- Server tetap source-of-truth; client hanya render state.

### Claude's Discretion
- Frekuensi update HUD boleh dituning (mis. 0.5-1.0s) agar tidak spam.
- Layout HUD boleh tetap programmatic minimal selama readable desktop dan mobile.

</decisions>

<specifics>
## Specific Ideas

- Event feed sebaiknya pakai level/severity (`info`, `warning`, `critical`) untuk cepat dipahami.
- Saat ending trigger aktif, UI harus menampilkan pesan yang jelas supaya pemain sadar run selesai.

</specifics>

<deferred>
## Deferred Ideas

- Visual polish tematik UI (font/skin/cinematic overlay) ditunda.
- Sistem quest log/hint panel lanjutan ditunda ke phase berikut.

</deferred>

---

*Phase: 05-ui-and-feedback*
*Context gathered: 2026-02-19*
