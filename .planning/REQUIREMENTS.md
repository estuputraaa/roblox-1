# Requirements: Jaga Warnet (Roblox)

**Defined:** 2026-02-19
**Core Value:** Pemain merasakan loop "kerja warnet yang chaos tapi lucu" yang konsisten seru setiap hari.

## v1 Requirements

### Core Loop

- [x] **CORE-01**: Player dapat memulai hari, menjalankan shift, dan menutup hari secara jelas.
- [x] **CORE-02**: Game melacak progress hari dari hari 1 sampai hari 7.
- [x] **CORE-03**: Player gagal jika kondisi kritis (mis. ekonomi/chaos) melewati batas yang didefinisikan.

### NPC System

- [ ] **NPC-01**: Server memilih kategori NPC dengan weighted random per `SpawnProfile`.
- [ ] **NPC-02**: Server memilih NPC spesifik dengan weighted random dari tabel config.
- [ ] **NPC-03**: Tiap NPC menjalankan behavior berdasarkan config (normal/anomali/meme).
- [ ] **NPC-04**: Semua NPC memiliki animasi lucu minimal idle + move + emote.

### Mini-Game

- [ ] **MINI-01**: Player dapat memainkan mini-game memasak mie dengan hasil sukses/gagal.
- [ ] **MINI-02**: Player dapat memainkan mini-game memperbaiki komputer dengan hasil sukses/gagal.
- [ ] **MINI-03**: Player dapat menjalani mini-game/respons event anomali saat trigger aktif.

### Economy

- [x] **ECO-01**: Player memiliki saldo uang yang bertambah/berkurang dari aktivitas game.
- [x] **ECO-02**: Hasil mini-game memengaruhi reward/penalty ekonomi.
- [x] **ECO-03**: Sistem memberi reward survive harian yang dapat dituning.

### Ending

- [ ] **END-01**: Main ending aktif ketika player bertahan sampai hari ke-7.
- [ ] **END-02**: Easter egg ending aktif jika syarat khusus terpenuhi (mis. dipukul TungTung Sahur).
- [ ] **END-03**: Easter egg ending alternatif aktif jika player masuk portal tersembunyi.

### UI

- [ ] **UI-01**: HUD menampilkan hari aktif, saldo, dan status objective.
- [ ] **UI-02**: UI menampilkan warning/event feed saat anomali terjadi.

### Monetization Placeholder

- [x] **MON-01**: Placeholder GamePass terdaftar dan bisa dicek kepemilikannya di server.
- [x] **MON-02**: Placeholder DevProduct dapat dipicu dan memberi reward dummy aman.

## v2 Requirements

### Expansion

- **EXP-01**: NPC relation/affinity system antar karakter.
- **EXP-02**: Dynamic weather + day modifiers.
- **EXP-03**: Side quest open world yang lebih panjang.
- **EXP-04**: Cosmetic shop terintegrasi penuh.

## Out of Scope

| Feature | Reason |
|---------|--------|
| PvP ranked mode | Tidak selaras dengan core fantasy simulasi chaos solo/co-op ringan |
| Voice acted cutscene penuh | Biaya produksi tinggi untuk v1 |
| Fully procedural city generation | Kompleksitas tinggi, bukan blocker validasi fun loop |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CORE-01 | Phase 1 | Complete |
| CORE-02 | Phase 1 | Complete |
| CORE-03 | Phase 1 | Complete |
| ECO-01 | Phase 1 | Complete |
| ECO-02 | Phase 1 | Complete |
| ECO-03 | Phase 1 | Complete |
| NPC-01 | Phase 2 | Pending |
| NPC-02 | Phase 2 | Pending |
| NPC-03 | Phase 2 | Pending |
| NPC-04 | Phase 2 | Pending |
| MINI-01 | Phase 3 | Pending |
| MINI-02 | Phase 3 | Pending |
| MINI-03 | Phase 3 | Pending |
| END-01 | Phase 4 | Pending |
| END-02 | Phase 4 | Pending |
| END-03 | Phase 4 | Pending |
| UI-01 | Phase 5 | Pending |
| UI-02 | Phase 5 | Pending |
| MON-01 | Phase 6 | Complete |
| MON-02 | Phase 6 | Complete |

**Coverage:**
- v1 requirements: 20 total
- Mapped to phases: 20
- Unmapped: 0

---
*Requirements defined: 2026-02-19*
*Last updated: 2026-02-19 after phase 6 execution*
