# Architecture Research - Jaga Warnet (Roblox)

## Suggested Components

- **GameDirector (Server)**: State machine hari, transisi fase (siang/malam/event/end).
- **NPCSpawner (Server)**: Weighted random class + weighted random NPC + lifecycle NPC.
- **BehaviorController (Server)**: Menjalankan behavior spesifik berdasarkan config.
- **MiniGameService (Server)**: Registrasi mini-game, skor, hasil reward/penalty.
- **EconomyManager (Server)**: Mata uang, reward, biaya operasional, payout harian.
- **AnomalyEventService (Server)**: Trigger event anomali, escalation, cleanup.
- **EndingService (Server)**: Cek syarat ending utama dan easter egg.
- **MonetizationService (Server)**: Placeholder GamePass/DevProduct hooks.
- **UIController (Client)**: HUD, objective text, event feed.

## Data Flow

1. `GameDirector` menentukan `SpawnProfile` sesuai waktu/hari.
2. `NPCSpawner` memilih NPC via weighted random dari `NPCBehaviorConfig`.
3. NPC menjalankan behavior; beberapa behavior memicu mini-game/event.
4. `MiniGameService` mengirim hasil ke `EconomyManager`.
5. `AnomalyEventService` dan `NPCSpawner` set flags untuk `EndingService`.
6. `UIController` menerima update state lewat remotes.

## Build Order

1. Config + schema + remotes
2. EconomyManager + day loop dasar
3. NPCSpawner + weighted random
4. Mini-game service skeleton
5. Anomaly event + ending logic
6. UI dan monetization placeholders
