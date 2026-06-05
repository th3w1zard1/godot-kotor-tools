---
title: "feat: Q54 BWM writer and walkmesh export preview"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q53-next-walkmesh-writeback-slice
phase: Q54
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-05-29-022-feat-q17-module-designer-bwm-walkmesh-plan.md
  - docs/plans/2026-06-04-026-feat-q53-lyt-depth-overlay-plan.md
---

# Q54: BWM Writer and Walkmesh Export Preview

## Summary

Add `BWMWriter` for BWM/WOK binary round-trip from parsed walkmesh data and expose **Export Walkmesh Preview…** in Module Designer.

---

## Problem Frame

Q17 added read-only BWM parsing and 3D overlay. Q53 deferred walkmesh write-back. Modders need a serializer foundation and a way to export the loaded area walkmesh for inspection or external tooling.

---

## Scope Boundaries

### In scope

- `formats/bwm_writer.gd`
- Module Designer **Export Walkmesh Preview…** toolbar action
- Headless `tests/editor/test_bwm_writer.gd`
- Update `tests/editor/test_bwm_parser.gd` to build fixtures via `BWMWriter`
- Execution queue + parity matrix Q54 entry

### Deferred

- Walkmesh editing in viewport
- AABB/adjacency table serialization
- Install walkmesh to override

### Out of scope

- LYT write-back from Module Designer
- Indoor builder walkmesh generation

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | BWMWriter serializes vertices/faces/materials | Unit test |
| R2 | Parse → write → parse round-trip preserves geometry | Unit test |
| R3 | Module Designer exports loaded walkmesh to `.wok` | Wiring |
| R4 | Docs mark Q54 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_bwm_writer.gd
godot --headless --path . --script tests/editor/test_bwm_parser.gd
```
