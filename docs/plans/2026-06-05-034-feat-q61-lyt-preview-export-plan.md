---
title: "feat: Q61 Module Designer LYT preview export"
type: feat
status: completed
date: 2026-06-05
origin: lfg-next-after-q60-auto-selected
phase: Q61
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-05-033-feat-q60-pth-install-override-plan.md
  - docs/plans/2026-06-04-031-feat-q58-lyt-install-override-plan.md
  - docs/plans/2026-06-04-027-feat-q54-bwm-writer-walkmesh-export-plan.md
---

# Q61: Module Designer LYT Preview Export

## Summary

Add **Export LYT Preview…** in Module Designer so modders can save the loaded area layout to a filesystem `.lyt` file for inspection or external tooling.

---

## Problem Frame

Q53 shipped `LYTWriter`, Q54 shipped walkmesh preview export, and Q58 shipped layout install-to-override. Module Designer still lacks the non-destructive export path for the currently loaded layout, leaving install as the only write-back workflow on this surface.

---

## Scope Boundaries

### In scope

- Module Designer **Export LYT Preview…** toolbar action and write helper
- Headless `tests/editor/test_module_designer_lyt_export.gd`
- Execution queue + parity matrix Q61 entry

### Deferred

- VIS preview export in Module Designer
- PTH preview export in Module Designer
- LYT editing in viewport

### Out of scope

- Indoor Builder LYT export changes
- LYT serializer changes beyond existing `LYTWriter`
- Install-to-override behavior changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Export fails when no LYT is loaded | Unit test |
| R2 | Export writes the loaded layout to a `.lyt` file, adding the extension when omitted | Unit test |
| R3 | Exported bytes round-trip through `LYTParser` with matching room data | Unit test |
| R4 | Toolbar **Export LYT Preview…** is wired in Module Designer | Wiring |
| R5 | Docs mark Q61 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_module_designer_lyt_export.gd
godot --headless --path . --script tests/editor/test_lyt_writer.gd
```
