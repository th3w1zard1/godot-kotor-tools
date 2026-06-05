---
title: "feat: Q53 Module Designer LYT depth overlay and writer"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q52-next-lyt-walkmesh-slice
phase: Q53
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-05-29-021-feat-q16-module-designer-3d-viewport-plan.md
  - docs/plans/2026-06-04-016-feat-q43-indoor-lyt-builder-plan.md
---

# Q53: Module Designer LYT Depth Overlay and Writer

## Summary

Add `LYTWriter` for ASCII layout round-trip, render LYT tracks/obstacles/doorhooks in the Module Designer 3D viewport, and expose layout depth in the module summary.

---

## Problem Frame

Q16–Q18 visualize LYT room models only. Parsed layouts also contain tracks, obstacles, and doorhooks that modders need for spatial context. There is no shared LYT serializer for round-trip or export workflows.

---

## Scope Boundaries

### In scope

- `formats/lyt_writer.gd`
- `KotorModuleContext.format_layout_summary()`
- Module Designer 3D markers for tracks, obstacles, doorhooks
- Module Designer summary shows LYT depth counts
- Headless `tests/editor/test_lyt_writer.gd`

### Deferred

- LYT edit/write-back from Module Designer
- Per-room walkmesh (.wok) loading
- Walkmesh write-back

### Out of scope

- Indoor builder changes beyond optional LYTWriter reuse
- BWM format extensions

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | LYTWriter serializes rooms/tracks/obstacles/doorhooks | Unit test |
| R2 | Parse → write → parse round-trip preserves counts | Unit test |
| R3 | Viewport renders non-room LYT entries | Viewport test |
| R4 | Module summary includes layout depth line | Wiring |
| R5 | Docs mark Q53 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_lyt_writer.gd
godot --headless --path . --script tests/editor/test_module_designer_viewport_3d.gd
```
