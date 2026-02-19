# Phase 3: Mini-Game and Anomaly Events - Context

**Gathered:** 2026-02-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase ini fokus menghubungkan tiga mini-game inti (`CookNoodle`, `RepairComputer`, `AnomalyResponse`) ke runtime game sehingga hasilnya berdampak ke ekonomi dan state dunia secara konsisten. Scope berhenti pada pipeline server-side gameplay loop mini-game + event anomali, bukan UI polish akhir atau ending resolver final.

</domain>

<decisions>
## Implementation Decisions

### Mini-Game Contract
- Gunakan satu service registry (`MiniGameService`) untuk semua mini-game inti.
- Semua mini-game harus mengembalikan kontrak hasil seragam:
  - `miniGameId`
  - `score` (0-100)
  - `success`
  - `rewardApplied`
  - `penaltyApplied`
  - `tags` (mis. `anomalyHandled`, `repairFailed`)
- Jalur `CookNoodle` dan `RepairComputer` harus tersedia eksplisit sebagai mini-game berbeda (bukan alias event umum).

### Anomaly Event Pipeline
- Event anomali dipicu server-side secara terjadwal/acak selama run aktif.
- Trigger anomali harus mematuhi budget phase (`GameDirector:ConsumeEventBudget`) agar tidak spam.
- Saat anomali aktif, world state harus sinkron:
  - profile spawn bisa dipaksa ke `EventAnomaly` secara sementara
  - mini-game `AnomalyResponse` dieksekusi sebagai challenge
  - event feed dipublish ke client (placeholder remote aman)

### Economy Integration
- Hasil mini-game wajib jadi sumber reward/penalty utama phase ini.
- `EconomyManager` menyimpan statistik mini-game per pemain agar balancing bisa dipantau.
- Integrasi ekonomi harus tetap fail-safe: result invalid tidak boleh crash run.

### Performance and Safety
- Seluruh trigger mini-game dan anomali tetap server-authoritative.
- Cooldown event anomali dan guard re-entrancy wajib aktif untuk mencegah event overlap.
- Unknown mini-game id harus ditolak aman dengan warning terstruktur.

### Claude's Discretion
- Simulasi skor mini-game boleh tetap server-side RNG untuk skeleton phase 3, selama masing-masing mini-game punya profil logic berbeda.
- Detail payload event feed boleh sederhana selama kontrak remote konsisten.
- Nilai tuning cooldown/chance anomali boleh disesuaikan agar pacing awal stabil.

</decisions>

<specifics>
## Specific Ideas

- Mini-game memasak mie harus terasa "quick task" berhadiah lebih kecil.
- Mini-game repair komputer harus lebih berisiko dibanding memasak mie.
- Anomaly response harus memberi dampak ekonomi paling tinggi (reward/penalty terbesar).

</specifics>

<deferred>
## Deferred Ideas

- Visual/UX mini-game interaktif penuh dibahas lebih jauh di Phase 5.
- Ending trigger detail dari event anomali dibahas di Phase 4.
- Balancing ekonomi final berdasarkan telemetry ditunda setelah phase 3 stabil.

</deferred>

---

*Phase: 03-mini-game-and-anomaly-events*
*Context gathered: 2026-02-19*
