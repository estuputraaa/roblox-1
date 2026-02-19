# Jaga Warnet (Roblox)

## What This Is

Game simulasi-komedi bertema "jaga warnet" dengan format semi open world di Roblox. Pemain menjaga operasional warnet harian sambil menghadapi NPC normal, NPC anomali horor lokal, dan NPC meme Indonesia. Progress utama berbasis bertahan 7 hari, dengan ending tambahan dari kondisi easter egg.

## Core Value

Pemain merasakan loop "kerja warnet yang chaos tapi lucu" yang konsisten seru setiap hari.

## Requirements

### Validated

(None yet - ship to validate)

### Active

- [ ] Loop harian warnet (buka-jaga-tutup) berjalan stabil sampai hari ke-7.
- [ ] NPC spawn dengan weighted random dan behavior sesuai tipe (normal/anomali/meme).
- [ ] Mini-game inti (memasak mie, perbaikan komputer, anomali event) memengaruhi hasil ekonomi.
- [ ] Ending utama + easter egg ending bisa tercapai dengan syarat jelas.
- [ ] UI dasar menampilkan status kritikal (hari, uang, event, objective).
- [ ] Placeholder monetisasi (GamePass/DevProduct) terintegrasi aman.

### Out of Scope

- Multiplayer PvP kompetitif - tidak mendukung core fantasy "jaga warnet naratif-chaotic".
- Sistem ekonomi live-ops kompleks (inflasi dinamis, marketplace) - ditunda sampai loop inti tervalidasi.
- Voice acting penuh - biaya tinggi untuk fase awal.

## Context

- Domain: Roblox + Luau, desain modular berbasis service dan config.
- Tema: komedi lokal Indonesia + elemen anomali horor.
- NPC spesifik dari ide pengguna:
  - Anomali: pocong, kuntilanak, suster ngesot, genderuwo
  - Meme: TungTung Sahur, Kelapa Sawit, Prabowo, Gibran, Jokowi, Mas Anies
- Mekanik wajib:
  - Weighted spawn dan tabel config NPC
  - Behavior per NPC
  - Mini-game: memasak mie, memperbaiki komputer, event anomali
  - Main ending (bertahan 7 hari)
  - Easter egg ending (contoh: dipukul TungTung Sahur / masuk portal tersembunyi)
- Kebutuhan teknis dari pengguna:
  - Struktur folder bersih
  - Komentar di setiap module
  - Skeleton kode untuk `NPCSpawner`, `EconomyManager`, dan contoh config behavior NPC
  - UI dasar dan monetisasi placeholder

## Constraints

- **Platform**: Roblox + Luau - harus kompatibel runtime Roblox dan pola folder service Roblox.
- **Architecture**: Modular - data-driven config untuk NPC/mini-game/monetisasi agar mudah tuning.
- **Content Safety**: Konten meme/politik diposisikan sebagai karakter parodi in-game, tanpa klaim faktual.
- **Audio**: Backsound bebas copyright - harus menggunakan aset berlisensi aman.
- **Delivery Scope**: Fokus ke blueprint + skeleton implementasi, bukan gameplay final polished.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Gunakan sistem spawn berbasis `SpawnProfile` + weighted class + weighted NPC | Memisahkan balancing global dari balancing per karakter | Pending |
| Simpan behavior NPC sebagai config data (`NPCBehaviorConfig`) | Mengurangi hardcode, memudahkan iterasi desain | Pending |
| Struktur server pakai service modules (`NPCSpawner`, `EconomyManager`, `MiniGameService`, dll) | Menjaga separation of concerns dan testability | Pending |
| Main progression memakai `daySurvived` | Selaras dengan requirement ending "bertahan 7 hari" | Pending |
| Easter egg dicatat sebagai flags per pemain (`wasHitByTungTung`, `enteredHiddenPortal`) | Mudah dicek oleh `EndingService` | Pending |

---
*Last updated: 2026-02-19 after initialization*
