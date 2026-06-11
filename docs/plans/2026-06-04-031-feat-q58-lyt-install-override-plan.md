---
title: "feat: Q58 Module Designer LYT install to override"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q57-next-module-designer-lyt-install
phase: Q58
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-029-feat-q56-walkmesh-install-override-plan.md
  - docs/plans/2026-06-04-026-feat-q53-lyt-depth-overlay-plan.md
---

# Q58: Module Designer LYT Install to Override

## Summary

Add **Install LYT to Override** in Module Designer so modders can write the loaded area `.lyt` back to the game install via `LYTWriter` and the mutation preflight path.

---

## Problem Frame

Q53 shipped LYT parsing, 3D markers, and `LYTWriter`. Q56 added walkmesh install-to-override. Module layout write-back completes the LYT side of override-first module editing.

---

## Scope Boundaries

### In scope

- `install_layout_to_override()` + helpers on Module Designer editor
- Toolbar **Install LYT to Override**
- Headless `tests/editor/test_module_designer_lyt_install.gd`
- Execution queue + parity matrix Q58 entry

### Deferred

- LYT editing in viewport
- Export LYT Preview dialog in Module Designer
- VIS/PTH install

### Out of scope

- Indoor builder LYT changes
- Native LYT generation from indoor layouts (Q43)

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Install fails when no LYT is loaded | Unit test |
| R2 | Install serializes via `LYTWriter` and writes `{module}.lyt` to override | Unit test |
| R3 | Install uses mutation service preflight/apply | Unit test |
| R4 | Toolbar button triggers install flow | Wiring |
| R5 | Docs mark Q58 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_module_designer_lyt_install.gd
godot --headless --path . --script tests/editor/test_lyt_writer.gd
```
