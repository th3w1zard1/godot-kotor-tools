---
title: "feat: Q62 Module Designer VIS preview export"
type: feat
status: completed
date: 2026-06-05
origin: lfg-next-after-q61-auto-selected
phase: Q62
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-05-034-feat-q61-lyt-preview-export-plan.md
  - docs/plans/2026-06-04-032-feat-q59-vis-install-override-plan.md
---

# Q62: Module Designer VIS Preview Export

## Summary

Add **Export VIS Preview…** in Module Designer so modders can save the loaded area visibility graph to a filesystem `.vis` file for inspection or external tooling.

---

## Problem Frame

Q59 shipped `VISWriter` and install-to-override, and Q61 shipped LYT preview export. Module Designer still lacks the non-destructive export path for the currently loaded visibility graph, leaving install as the only VIS write-back workflow on this surface.

---

## Scope Boundaries

### In scope

- Module Designer **Export VIS Preview…** toolbar action and write helper
- Headless `tests/editor/test_module_designer_vis_export.gd`
- Execution queue + parity matrix Q62 entry

### Deferred

- PTH preview export in Module Designer
- VIS editing UI
- Visibility overlay visualization changes

### Out of scope

- Indoor Builder VIS export changes
- VIS serializer changes beyond existing `VISWriter`
- Install-to-override behavior changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Export fails when no VIS is loaded | Unit test |
| R2 | Export writes the loaded visibility graph to a `.vis` file, adding the extension when omitted | Unit test |
| R3 | Exported text round-trips through `VISParser` with matching room visibility groups | Unit test |
| R4 | Toolbar **Export VIS Preview…** is wired in Module Designer | Wiring |
| R5 | Docs mark Q62 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_module_designer_vis_export.gd
godot --headless --path . --script tests/editor/test_vis_writer.gd
```
