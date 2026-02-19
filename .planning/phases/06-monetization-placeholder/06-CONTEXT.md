# Phase 6: Monetization Placeholder - Context

**Gathered:** 2026-02-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase ini fokus pada placeholder monetisasi yang aman: konfigurasi ID GamePass/DevProduct, jalur server untuk ownership check + receipt processing, dan hook continue berbayar yang tidak merusak balancing utama. Scope berhenti di placeholder/guard rails; tidak mencakup balancing final, storefront UI lengkap, atau live ops analytics production.

</domain>

<decisions>
## Implementation Decisions

### Monetization Catalog
- Semua entitas monetisasi dipusatkan di `MonetizationConfig`.
- ID default tetap placeholder (`0`) dan harus fail-safe (tidak crash, tidak grant reward liar).
- Setiap entry punya metadata minimum (id, enabled, notes) untuk memudahkan replace saat publish.

### Continue Policy
- Continue tetap bisa digunakan berkali-kali (unlimited attempts).
- Harga continue naik berdasarkan jumlah continue yang sudah dipakai dalam run, lalu di-cap sesuai policy untuk menjaga fairness.
- Karena Roblox DevProduct harga riil ditetapkan di dashboard, sistem game menyimpan `display price` sebagai guidance/hint dan tetap pakai product key `ContinueRun` untuk prompt.

### Reward Safety
- Bonus monetisasi placeholder harus non-breaking:
  - EmergencyCash diberi cap tambahan.
  - ChaosShield dan pass bonus diekspresikan sebagai buff flag/bonus ringan.
- Semua grant reward harus idempotent terhadap receipt ID yang sama.

### Runtime Safety
- Kegagalan API Marketplace tidak boleh menghentikan loop game.
- Invalid config atau ID 0 hanya menghasilkan warning terkontrol.
- Server tetap source-of-truth untuk grant reward.

### Claude's Discretion
- Boleh menambah payload remote untuk visibilitas status continue/price.
- Boleh menambah helper API di `MonetizationService` selama backward-compatible.

</decisions>

<specifics>
## Specific Ideas

- Tambahkan cache ownership gamepass sederhana untuk mengurangi call berulang.
- Simpan receipt yang sudah diproses di memori sesi untuk mencegah double-grant saat callback ulang.
- Tambahkan helper `GetMonetizationStatus(player)` untuk dipakai HUD/event feed.

</specifics>

<deferred>
## Deferred Ideas

- Storefront UI pembelian langsung dari client.
- A/B pricing dan event monetisasi musiman.
- DataStore durable log untuk processed receipts lintas server.

</deferred>

---

*Phase: 06-monetization-placeholder*
*Context gathered: 2026-02-19*
