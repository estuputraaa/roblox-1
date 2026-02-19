# Phase 1: Core Economy Loop - Context

**Gathered:** 2026-02-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase ini menetapkan loop ekonomi harian inti dari hari 1 sampai hari 7: pacing shift, tekanan ekonomi, aturan kalah/pulih, dan kurva difficulty. Fokusnya adalah bagaimana sistem ini berjalan stabil dan fair, bukan menambah capability di luar scope fase.

</domain>

<decisions>
## Implementation Decisions

### Pacing Hari
- Satu hari in-game berdurasi **10 menit**.
- Pembagian waktu: **5 menit pagi + 5 menit malam**.
- Transisi pagi ke malam **otomatis** saat timer 5 menit habis.
- Frekuensi event: **pagi 1 event**, **malam 2 event**.
- Spawn malam memakai komposisi **balanced** (anomali setara normal, tidak dominan ekstrem).

### Tekanan Ekonomi
- Starting cash hari 1: **Rp150**.
- Biaya operasional harian memakai model **flat** (tetap per hari).
- Reward mini-game memakai model **campuran berbasis risiko**:
  - Memasak mie: rendah
  - Repair komputer: sedang
  - Anomali: tinggi
- Penalti gagal mini-game **kontekstual**:
  - Gagal anomali: paling berat
  - Gagal mini-game lain: sedang

### Aturan Kalah dan Pulih
- Kondisi kalah utama: **cash <= 0 kapan pun saat shift**.
- Recovery tidak gratis; gunakan **continue via Robux**.
- Continue via Robux: **unlimited**, dengan harga **linear naik**:
  - Mulai 20 Robux, +20 tiap pemakaian, cap 120 Robux.
- Saat continue dipakai:
  - Cash diisi ke minimum aman **Rp100**
  - Tidak ada bonus tambahan lain
  - State lain tetap (tidak reset event/objective)
- Prompt continue muncul **instan** saat fail trigger.
- Jika pemain menolak continue: **langsung kembali ke lobby**.

### Kurva Difficulty 1-7
- Pola difficulty: **wave random** antar hari.
- Constraint wajib: **hari ke-7 selalu puncak difficulty**.
- Parameter yang dirandom-kan: **semua**:
  - spawn/event rate
  - penalti ekonomi
  - kompleksitas mini-game
  - objective pressure

### Claude's Discretion
- Nilai numerik detail untuk komposisi spawn malam (contoh rasio exact normal vs anomali) boleh ditentukan saat plan-phase selama tetap dalam kategori "balanced".
- Formula internal objective pressure harian dapat ditentukan di plan-phase selama konsisten dengan wave random + day-7 peak.

</decisions>

<specifics>
## Specific Ideas

- Nuansa pacing yang diinginkan: ritme harian singkat tapi padat, dengan eskalasi jelas saat malam.
- Recovery lewat Robux diinginkan sebagai opsi monetisasi yang tetap menjaga tensi survival.

</specifics>

<deferred>
## Deferred Ideas

- Detail mekanik dan trigger ending easter egg dibahas di **Phase 4 (Ending Flow)**, bukan di Phase 1.

</deferred>

---

*Phase: 01-core-economy-loop*
*Context gathered: 2026-02-19*
