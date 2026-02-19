# Phase 6: Monetization Placeholder - Research

**Researched:** 2026-02-19
**Domain:** Roblox MarketplaceService placeholder monetization flow
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Placeholder katalog monetisasi harus fail-safe saat ID belum diisi.
- Continue bisa dipakai unlimited dengan harga display yang meningkat.
- Reward monetisasi tidak boleh mematahkan balancing core loop.
- Server authoritative untuk check ownership dan grant reward.

### Claude's Discretion
- Menambah helper status/payload monetisasi untuk feedback UI.
- Menambah guard tambahan di service selama kompatibel.

### Deferred Ideas (OUT OF SCOPE)
- Storefront UI penuh
- Analytics production + durable receipt ledger lintas server
</user_constraints>

## Summary

`MonetizationService` sudah memiliki skeleton prompt + `ProcessReceipt`, tetapi masih ada gap penting:
1. belum ada validator katalog/ID,
2. receipt belum idempotent terhadap `PurchaseId`,
3. bonus gamepass/devproduct selain EmergencyCash dan Continue belum terstruktur,
4. runtime belum mengirim detail monetisasi (mis. continue display price) ke UI.

Rekomendasi dua plan:
- 06-01: rapikan config katalog dan policy pricing continue.
- 06-02: harden service runtime (receipt dedupe, gamepass cache, reward guards) + integrasi payload continue ke feedback pipeline.

## Architecture Recommendations

### Pattern 1: Config-driven Catalog + Policy Helpers
- `MonetizationConfig` jadi sumber tunggal untuk gamepass/devproduct metadata.
- Tambahkan helper pure function untuk hitung continue display price berdasarkan usage count.

### Pattern 2: Idempotent Receipt Processing
- Track `PurchaseId` yang sudah diproses di memori sesi.
- Untuk receipt yang sudah pernah diproses, langsung `PurchaseGranted` tanpa grant ulang.

### Pattern 3: Graceful Runtime Guards
- API Marketplace dibungkus `pcall`.
- Invalid key/disabled product hanya warning dan return fail-safe.
- Grant reward dibatasi (cap/floor) agar non-breaking.

## Pitfalls and Safeguards

### Pitfall 1: Double grant karena receipt callback berulang
- Safeguard: `_processedReceipts[purchaseId] = true` sebelum return granted.

### Pitfall 2: Ownership check spam
- Safeguard: cache ownership per player per pass key dengan TTL ringan.

### Pitfall 3: Continue pricing mismatch dengan dashboard Roblox
- Safeguard: eksplisitkan bahwa harga adalah display policy in-game, bukan sumber harga marketplace.

## Metadata

**Confidence breakdown:**
- Marketplace placeholder flow: HIGH
- Service hardening: HIGH
- Gameplay balance safety: HIGH

**Research date:** 2026-02-19
**Valid until:** 2026-03-21
