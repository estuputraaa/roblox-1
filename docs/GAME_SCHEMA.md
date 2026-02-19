# Jaga Warnet - Complete Schema (Roblox)

## 1) High-Level System

- `GameDirector` mengatur hari, fase, dan game state global.
- `NPCSpawner` memilih NPC via weighted random dari config.
- `MiniGameService` menjalankan mini-game dan mengirim hasil ke ekonomi.
- `EconomyManager` mengelola saldo, reward, penalty, biaya operasional.
- `AnomalyEventService` memicu event anomali serta sinkronisasi warning UI.
- `EndingService` mengevaluasi syarat ending utama dan easter egg.
- `MonetizationService` menangani placeholder GamePass/DevProduct.
- `UIController` (client) merender HUD dan event feed.

## 2) Folder Structure

```text
src/
  ReplicatedStorage/
    Shared/
      Config/
        NPCBehaviorConfig.lua
        MiniGameConfig.lua
        MonetizationConfig.lua
      Remotes/
        RemoteNames.lua
  ServerScriptService/
    Services/
      NPCSpawner.lua
      EconomyManager.lua
      MiniGameService.lua
      AnomalyEventService.lua
      EndingService.lua
      MonetizationService.lua
      GameDirector.lua
  StarterPlayer/
    StarterPlayerScripts/
      UIController.client.lua
```

## 3) NPC Spawn Schema

- `SpawnProfiles`:
  - `Day`: normal dominan
  - `Night`: anomali naik
  - `EventAnomaly`: anomali dominan
- Dua tahap random:
  - Pilih class (`normal/anomaly/meme`) berdasarkan class weight profile
  - Pilih NPC spesifik berdasarkan `spawnWeight` di class itu
- Guardrails:
  - max active NPC total
  - cooldown spawn per class
  - throttle event saat FPS/perf drop (future)

## 4) Economy Schema

- Currency utama: `Rupiah`
- Source income:
  - mini-game success
  - survive day bonus
  - event completion bonus
- Source cost:
  - repair penalty
  - anomaly failure penalty
  - operational cost harian
- KPI tuning:
  - average cash day-3
  - bankruptcy rate sebelum day-5
  - recovery rate setelah event gagal

## 5) Mini-Game Schema

- `CookNoodle`: quick-timing/sequence mini-game
- `RepairPC`: wiring/pattern mini-game
- `AnomalyResponse`: decision + reaction mini-game
- Contract hasil:
  - `success` (bool)
  - `score` (0-100)
  - `reward` / `penalty`
  - `tags` (mis. `anomalyHandled`)

## 6) Ending Schema

- Main ending:
  - `daySurvived >= 7` dan tidak game over
- Easter egg ending:
  - `wasHitByTungTung == true`
  - `enteredHiddenPortal == true`
- Resolver priority:
  - Easter egg special > main ending > fail ending

## 7) Monetization Placeholder Schema

- `GamePass` placeholders:
  - FastRepair
  - LuckyShift
- `DevProduct` placeholders:
  - EmergencyCash
  - ChaosShield
- Rule:
  - No hard paywall untuk progress utama.
  - Bonus bersifat booster ringan / QoL.

## 8) UI Basic Schema

- Top-left:
  - Day counter
  - Cash display
  - Objective text
- Top-center:
  - Event warning ticker
- Bottom-right:
  - Mini-game prompt/action hint

## 9) Audio Schema (Copyright-Safe)

- Gunakan Roblox Creator Marketplace audio yang berlabel free-use atau asset internal milik Anda.
- Simpan daftar source audio dan license note di doc terpisah saat masuk produksi.
