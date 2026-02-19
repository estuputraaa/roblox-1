# Roadmap: Jaga Warnet (Roblox)

## Overview

Roadmap ini memprioritaskan loop harian yang bisa dimainkan end-to-end terlebih dahulu, lalu memperkaya perilaku NPC, mini-game, ending, dan layer presentasi. Urutannya menjaga risiko: stabilitas core economy dan state game lebih dulu, variasi konten sesudah fondasi aman.

## Phases

- [ ] **Phase 1: Core Economy Loop** - Day loop, kondisi gagal, dan ekonomi dasar sampai hari ke-7.
- [ ] **Phase 2: NPC Spawn and Behavior** - Weighted spawn, config NPC, dan behavior runner.
- [ ] **Phase 3: Mini-Game and Anomaly Events** - Tiga mini-game utama terhubung ke ekonomi.
- [ ] **Phase 4: Ending Flow** - Main ending 7 hari + easter egg endings.
- [ ] **Phase 5: UI and Feedback** - HUD dasar, warning event, objective clarity.
- [ ] **Phase 6: Monetization Placeholder** - Hook GamePass/DevProduct aman untuk iterasi.

## Phase Details

### Phase 1: Core Economy Loop
**Goal**: Menyediakan loop harian lengkap yang bisa finish/fail secara deterministic.
**Depends on**: Nothing (first phase)
**Requirements**: [CORE-01, CORE-02, CORE-03, ECO-01, ECO-02, ECO-03]
**Success Criteria** (what must be TRUE):
1. Player dapat memainkan hari 1 sampai hari 7 tanpa error state.
2. Reward dan penalty ekonomi berubah sesuai aktivitas.
3. Kondisi gagal dan reset state bisa dipicu dan dipulihkan dengan benar.
**Plans**: 3 plans

Plans:
- [ ] 01-01-PLAN.md - Implement deterministic day-cycle state machine
- [ ] 01-02-PLAN.md - Lock economy policy and continue pricing
- [ ] 01-03-PLAN.md - Integrate fail flow, continue, and persistence hooks

### Phase 2: NPC Spawn and Behavior
**Goal**: Membuat sistem spawn NPC data-driven dengan weighted random dan behavior per tipe.
**Depends on**: Phase 1
**Requirements**: [NPC-01, NPC-02, NPC-03, NPC-04]
**Success Criteria** (what must be TRUE):
1. Spawn profile siang/malam menghasilkan distribusi NPC sesuai weight.
2. NPC normal, anomali, dan meme menjalankan behavior berbeda.
3. Animasi dasar NPC berjalan saat idle/move/interaksi.
**Plans**: 3 plans

Plans:
- [ ] 02-01: Buat `NPCBehaviorConfig` dan validator schema
- [ ] 02-02: Implement `NPCSpawner` weighted class + weighted NPC selection
- [ ] 02-03: Integrasi behavior runner + animation hooks

### Phase 3: Mini-Game and Anomaly Events
**Goal**: Menghubungkan mini-game gameplay ke ekonomi dan status dunia.
**Depends on**: Phase 2
**Requirements**: [MINI-01, MINI-02, MINI-03]
**Success Criteria** (what must be TRUE):
1. Mini-game memasak mie memberi output skor dan reward ekonomi.
2. Mini-game repair komputer memberi output skor dan penalty saat gagal.
3. Event anomali muncul terjadwal/acak dan memicu challenge respons.
**Plans**: 3 plans

Plans:
- [ ] 03-01: Implement `MiniGameService` contract dan registry
- [ ] 03-02: Implement anomali trigger pipeline
- [ ] 03-03: Integrasi mini-game result ke `EconomyManager`

### Phase 4: Ending Flow
**Goal**: Menentukan kondisi tamat utama dan cabang easter egg ending.
**Depends on**: Phase 3
**Requirements**: [END-01, END-02, END-03]
**Success Criteria** (what must be TRUE):
1. Main ending aktif otomatis saat day 7 complete.
2. Easter egg ending "dipukul TungTung Sahur" dapat dipicu secara valid.
3. Easter egg ending "portal tersembunyi" dapat dipicu secara valid.
**Plans**: 2 plans

Plans:
- [ ] 04-01: Implement `EndingService` dan flag tracking
- [ ] 04-02: Integrasi trigger dari NPC/event ke ending resolver

### Phase 5: UI and Feedback
**Goal**: Memberi visibilitas state game agar pemain memahami progres dan ancaman.
**Depends on**: Phase 4
**Requirements**: [UI-01, UI-02]
**Success Criteria** (what must be TRUE):
1. HUD menampilkan day, cash, dan objective real-time.
2. Event feed menampilkan warning anomali yang mudah dipahami.
3. Informasi ending conditions ditampilkan sebagai hint terukur.
**Plans**: 2 plans

Plans:
- [ ] 05-01: Implement remote events untuk HUD updates
- [ ] 05-02: Implement UI client controller dasar

### Phase 6: Monetization Placeholder
**Goal**: Menyediakan jalur monetisasi yang siap diisi tanpa merusak gameplay.
**Depends on**: Phase 5
**Requirements**: [MON-01, MON-02]
**Success Criteria** (what must be TRUE):
1. Server dapat mengecek ownership GamePass placeholder.
2. Developer Product placeholder dapat dipurchase dan diproses aman.
3. Semua bonus monetisasi bersifat non-breaking terhadap balancing awal.
**Plans**: 2 plans

Plans:
- [ ] 06-01: Buat config ID placeholder GamePass/DevProduct
- [ ] 06-02: Implement `MonetizationService` hooks + safety checks

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Core Economy Loop | 0/3 | Not started | - |
| 2. NPC Spawn and Behavior | 0/3 | Not started | - |
| 3. Mini-Game and Anomaly Events | 0/3 | Not started | - |
| 4. Ending Flow | 0/2 | Not started | - |
| 5. UI and Feedback | 0/2 | Not started | - |
| 6. Monetization Placeholder | 0/2 | Not started | - |
