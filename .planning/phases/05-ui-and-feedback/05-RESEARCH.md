# Phase 5: UI and Feedback - Research

**Researched:** 2026-02-19
**Domain:** Roblox Luau server-client feedback remotes + HUD controller
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- HUD menampilkan day, phase, cash, objective, dan timer phase.
- Event feed menampilkan warning anomaly + status penting run.
- Hint ending conditions harus terlihat namun tetap terukur.
- Server authoritative; client render only.

### Claude's Discretion
- Interval update HUD bebas dituning agar efisien.
- Layout boleh sederhana asalkan readable multi-device.

### Deferred Ideas (OUT OF SCOPE)
- UI cinematic/polish final
- Quest log kompleks
</user_constraints>

## Summary

Fondasi remote sudah ada (`RemoteNames`, `Main` ensure remotes) tapi belum dipakai untuk update HUD terstruktur. `UIController` masih static dan belum subscribe remote. Gap utama phase 5:
1. server belum broadcast HUD/timer/phase/day updates,
2. event feed belum terkonsolidasi,
3. client belum punya parser payload fail-safe.

Rekomendasi implementasi dua plan:
- 05-01: server feedback pipeline dan remote updates.
- 05-02: client HUD controller subscribe + render event feed/hints.

## Architecture Recommendations

### Pattern 1: Server Feedback Broadcaster
- Tambah helper broadcast di `Main.server`.
- Kirim `HUDUpdate` interval tetap (0.5s) + kirim event on change (state/day/phase).

### Pattern 2: Event Payload Convention
- Gunakan payload table standar:
  - `type`
  - `message`
  - `level`
  - `timestamp`
- Client render berdasarkan fallback default jika field hilang.

### Pattern 3: Client-side Defensive Render
- Semua listener remote dibungkus fallback parser.
- Missing label/UI element tidak menyebabkan crash script client.

## Pitfalls and Safeguards

### Pitfall 1: Remote spam dari heartbeat
- Safeguard: accumulator interval untuk HUD/timer updates.

### Pitfall 2: UI stale saat phase/day berubah
- Safeguard: trigger immediate push on transition selain interval periodic.

### Pitfall 3: Payload mismatch antar service
- Safeguard: centralize keys dan defaults di UIController.

## Metadata

**Confidence breakdown:**
- Remote feedback architecture: HIGH
- UI controller integration: HIGH
- Performance safety: HIGH

**Research date:** 2026-02-19
**Valid until:** 2026-03-21
