---
title: "feat: Holocron parity K2/TSL track (Q200+)"
type: feat
status: deferred
date: 2026-06-13
origin: holocron-parity-backlog-roadmap
phase: Q200+
track: OpenKotOR Parity
parent: docs/50-execution/holocron-parity-backlog-roadmap.md
related:
  - docs/30-gap-analysis/openkotor-parity-matrix.md
  - gamefs/kotor_gamefs.gd
---

# K2/TSL Parity Track (Q200+)

## Summary

Deferred until K1 Holocron functional parity audit completes (waves B–I, ~Q151–Q190). Opens explicit Q200+ slices for TSL-specific Holocron deltas.

## Entry gate

- [openkotor-parity-matrix.md](../30-gap-analysis/openkotor-parity-matrix.md) K1 rows at **Shipped** or **Strong** for P1 families
- Waves B–I plan docs executed or explicitly waived
- User/product confirms K2 track priority

## Holocron K2/TSL deltas

| Area | Delta vs K1 |
| --- | --- |
| DLG | TSL-only fields, alternate struct layouts |
| Install profiles | Separate K2 paths, `tslpatchdata` defaults |
| 2DA/TLK | K2 table variants, strref conventions |
| Blueprints | K2 appearance/feat tables |
| TSLPatcher | K2 patch workflows more central |

## Proposed slice outline

| Slice | Scope |
| --- | --- |
| Q200 | K2 install profile + GameFS roots |
| Q201 | K2 2DA/TLK variant handling |
| Q202 | DLG TSL field panels |
| Q203 | K2 blueprint field tables (UTC/UTP) |
| Q204 | TSLPatcher K2 authoring workflows |
| Q205+ | Matrix-driven gap fill from K1 audit |

## Matrix integration

Add **K2/TSL** section to `openkotor-parity-matrix.md` with per-family rows mirroring K1 structure. Status starts **Deferred** until Q200 gate passes.

## Verification

Each Q200+ slice follows standard gates:

```bash
godot --headless --path . --script tests/editor/test_<surface>.gd
```

K2 fixtures under `tests/fixtures/k2/` (create when track opens).

## Non-goals

- Dual-game UI clone
- PyKotor Python runtime in Godot
