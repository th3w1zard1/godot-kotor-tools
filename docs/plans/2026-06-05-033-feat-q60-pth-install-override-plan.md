---
title: "feat: Q60 Module Designer PTH install to override"
type: feat
status: completed
date: 2026-06-05
origin: lfg-next-after-q59-auto-selected
phase: Q60
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-032-feat-q59-vis-install-override-plan.md
  - docs/plans/2026-06-04-031-feat-q58-lyt-install-override-plan.md
---

# Q60: Module Designer PTH Install to Override

## Summary

Add **Install PTH to Override** in Module Designer so modders can write the loaded area path graph back to the game install via the mutation preflight path.

---

## Problem Frame

Typed `PTH` support already exists in the GFF resource/document layer, and the module bundle already indexes `{module}.pth` alongside `lyt` and `vis`. The remaining gap is editor workflow parity: Module Designer does not currently load, summarize, or install the area path graph even though adjacent layout/visibility/write-back flows already exist.

---

## Scope Boundaries

### In scope

- `KotorModuleContext` helper(s) to load parsed/typed PTH data from the module bundle and summarize it
- Module Designer path data load, summary, install API, and toolbar button
- Headless `tests/editor/test_module_designer_pth_install.gd`
- Execution queue + parity matrix Q60 entry

### Deferred

- PTH editing UI
- Path-node/edge visualization in 2D or 3D
- Export PTH Preview in Module Designer

### Out of scope

- Generic GFF workspace PTH editing changes
- Save/export saver-registry expansion outside the module-designer install path
- Semantic PTH compare

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Module bundle loads typed/parsed PTH data when `{module}.pth` exists | Unit test |
| R2 | Module Designer summary reflects loaded path graph metadata | Unit test |
| R3 | Install fails when no PTH is loaded | Unit test |
| R4 | Install writes `{module}.pth` to override via mutation service preflight/apply | Unit test |
| R5 | Toolbar **Install PTH to Override** is wired in Module Designer | Wiring |
| R6 | Docs mark Q60 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_module_designer_pth_install.gd
godot --headless --path . --script tests/editor/test_gff_resource_factory.gd
```
