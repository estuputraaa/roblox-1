# Phase 1: Core Economy Loop - Research

**Researched:** 2026-02-19
**Domain:** Roblox Luau server game loop + economy balancing
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### Deferred Ideas (OUT OF SCOPE)
- Detail mekanik dan trigger ending easter egg dibahas di **Phase 4 (Ending Flow)**, bukan di Phase 1.
</user_constraints>

## Summary

Phase 1 paling aman dibangun dengan tiga lapis: (1) game-day state machine deterministic, (2) economy policy yang mengeksekusi keputusan user secara eksplisit, dan (3) fail/continue integration yang menghubungkan loop permainan dengan monetization placeholder.

Untuk Roblox, pattern paling stabil adalah service-based modules di server dengan state tersimpan sebagai in-memory table per player + attribute/leaderstats sebagai tampilan. Data persistence cukup disiapkan sebagai hook placeholder pada phase ini agar risiko kehilangan scope tetap rendah.

**Primary recommendation:** eksekusi phase 1 dalam 3 plan: `day-state foundation`, `economy policy`, lalu `fail+continue integration`.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Roblox Engine Services | Built-in | Runtime game loop dan monetization | Native API, low friction |
| Luau Modules | Built-in | Service architecture dan data policy | Pattern standar Roblox server-side |
| DataStoreService | Built-in | Persistence pemain (placeholder hook) | Official storage mechanism |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| MarketplaceService | Built-in | Continue via DevProduct | Saat purchase recovery dipicu |
| RunService/Heartbeat | Built-in | Tick loop deterministic | Untuk timer/transition per phase |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Tick loop internal GameDirector | Distributed timers per service | Lebih fleksibel tapi sulit sinkronisasi global |
| Flat operational cost (locked decision) | Dynamic inflation | Lebih realistis tapi melanggar locked decision |

## Architecture Patterns

### Recommended Project Structure
```
src/
|-- ReplicatedStorage/Shared/Config/   # Policy config dan balancing knobs
|-- ServerScriptService/Services/      # Stateful server services
`-- ServerScriptService/Main.server.lua # Wiring dependencies
```

### Pattern 1: Deterministic Day State Machine
**What:** `GameDirector` menyimpan state `Morning -> Night -> EndDay` berbasis timer.
**When to use:** Saat phase split waktu memengaruhi event/economy.
**Example:** single transition authority di satu service (hindari multi-timer liar).

### Pattern 2: Policy-Driven Economy
**What:** Semua angka ekonomi diletakkan di config atau function policy, bukan hardcode tersebar.
**When to use:** Saat balancing sering berubah selama playtest.
**Example:** continue pricing function linear (base+step+cap) dipanggil dari service, bukan inline di banyak file.

### Anti-Patterns to Avoid
- **Global mutable state lintas service tanpa kontrak:** bikin race condition pada fail trigger.
- **Logic monetization langsung di UI client:** rawan exploit, harus diproses server.
- **Campur ending logic ke phase 1:** melanggar scope deferred.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Purchase verification | Custom client-confirmation flow | `MarketplaceService.ProcessReceipt` | Server-authoritative dan anti-spoof |
| Long-term player storage | File/local custom store | `DataStoreService` | Native persistence standard Roblox |
| State sync UI | Polling custom loop | RemoteEvent updates from server | Lebih ringan dan deterministic |

**Key insight:** Phase 1 butuh determinisme dan kejelasan policy, bukan kompleksitas framework.

## Common Pitfalls

### Pitfall 1: Timer drift antar service
**What goes wrong:** Pagi/malam/event timer tidak sinkron.
**Why it happens:** Banyak service punya timer independen.
**How to avoid:** Satu sumber waktu di `GameDirector`.
**Warning signs:** UI day phase berbeda dengan trigger event.

### Pitfall 2: Continue economy jadi exploit
**What goes wrong:** Continue bisa spam untuk bypass semua tekanan.
**Why it happens:** Tidak ada pricing escalation/cap server-side.
**How to avoid:** Formula linear + cap diproses di server.
**Warning signs:** Run panjang tanpa risiko ekonomi nyata.

### Pitfall 3: Fail condition lambat terdeteksi
**What goes wrong:** Cash <= 0 tapi pemain masih lanjut.
**Why it happens:** Hanya cek fail di akhir hari.
**How to avoid:** Immediate guard pada setiap mutation saldo.
**Warning signs:** Negative cash persisten beberapa detik.

## Code Examples

### Immediate fail guard pada mutation saldo
```lua
local newBalance = data.balance + delta
data.balance = newBalance
if newBalance <= 0 then
    gameDirector:TriggerFail(player, "cash_depleted")
end
```

### Continue pricing linear + cap
```lua
local function getContinuePrice(count)
    local base = 20
    local step = 20
    local cap = 120
    return math.min(base + (count * step), cap)
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Client-heavy game flow checks | Server-authoritative state machine | Ongoing best practice | Kurangi exploit dan race |
| Hardcoded balancing | Config/policy-driven balancing | Ongoing best practice | Iterasi tuning lebih cepat |

## Open Questions

1. **Persistence granularity untuk phase 1**
   - What we know: persistence diminta sebagai placeholder.
   - What's unclear: save setiap phase transition atau hanya end-day.
   - Recommendation: implement hook + default save di end-day.

2. **Objective pressure formula harian**
   - What we know: harus random wave dan hari 7 puncak.
   - What's unclear: bobot exact per parameter.
   - Recommendation: expose table `DifficultyProfileByDay` agar tuning non-breaking.

## Sources

### Primary (HIGH confidence)
- Roblox Creator Docs - DataStoreService reference
- Roblox Creator Docs - MarketplaceService reference
- Roblox Creator Docs - RemoteEvent reference

### Secondary (MEDIUM confidence)
- Existing workspace architecture: `docs/GAME_SCHEMA.md`
- Existing service skeleton in `src/ServerScriptService/Services/*.lua`

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - native Roblox APIs
- Architecture: HIGH - selaras dengan codebase saat ini
- Pitfalls: MEDIUM - butuh validasi lewat playtest

**Research date:** 2026-02-19
**Valid until:** 2026-03-21
