---
title: "feat: Q101 TPC compare TXI sidecar diff"
type: feat
status: completed
date: 2026-06-10
origin: lfg-next-after-q100-auto-selected
phase: Q101
track: OpenKotOR Parity
parent: docs/plans/2026-06-10-031-feat-q99-tpc-txi-sidecar-pairing-plan.md
related:
  - formats/tpc_compare.gd
  - formats/tpc_writer.gd
  - docs/plans/2026-06-04-010-feat-q37-tpc-semantic-compare-plan.md
---

# Q101: TPC Compare TXI Sidecar Diff

## Summary

Extend `TPCCompare` to report TXI tail differences — presence, size, and line-by-line text changes — closing the Q37-deferred gap now that Q99 writes TXI sidecars on import.

---

## Problem Frame

Q37 shipped header/payload TPC compare but deferred TXI text diff. Q99 now appends `.txi` tails on convert/import, so install compare must surface metadata-only overrides where mip payloads match.

---

## Scope Boundaries

### In scope

- `TPCCompare` TXI extraction via `TPCWriter.read_txi_bytes`
- Line-by-line TXI text diff with sample limit
- Presence/absence and binary TXI fallback summaries
- Fix payload diff to compare mip slices only (not whole file including TXI)
- Headless `tests/editor/test_tpc_compare.gd`
- Execution queue + parity matrix Q101 entry

### Deferred

- Per-pixel decoded image diff
- KotorDiff UI

### Out of scope

- TPC editor TXI editing UI

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | TXI line change reported when headers/payload match | Unit test |
| R2 | TXI presence change reported (absent ↔ present) | Unit test |
| R3 | Identical TPC including TXI yields empty report | Unit test |
| R4 | Payload-only diff still reported when TXI matches | Unit test |
| R5 | Docs mark Q101 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_compare.gd
```
