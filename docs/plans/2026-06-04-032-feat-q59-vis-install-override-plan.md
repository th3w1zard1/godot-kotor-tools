---
title: "feat: Q59 Module Designer VIS install to override"
type: feat
status: active
date: 2026-06-04
origin: lfg-q58-next-module-designer-vis-install
phase: Q59
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-031-feat-q58-lyt-install-override-plan.md
  - docs/plans/2026-06-04-018-feat-q45-indoor-vis-builder-plan.md
---

# Q59: Module Designer VIS Install to Override

## Summary

Add `VISWriter` for ASCII `.vis` round-trip and **Install VIS to Override** in Module Designer via the mutation preflight path.

---

## Problem Frame

Q45 shipped indoor VIS generation; `VISParser` reads module visibility files. Q58 added LYT install. Module visibility write-back completes the VIS side of override-first module editing.

---

## Scope Boundaries

### In scope

- `formats/vis_writer.gd` (+ refactor `KotorIndoorVisBuilder.build_text` to delegate)
- `KotorModuleContext.load_parsed_visibility()` + summary helper
- Module Designer visibility load, summary, install API, toolbar button
- Headless `tests/editor/test_vis_writer.gd`, `tests/editor/test_module_designer_vis_install.gd`
- Execution queue + parity matrix Q59 entry

### Deferred

- VIS editing UI
- PTH install
- Export VIS Preview in Module Designer

### Out of scope

- Indoor builder VIS changes
- Semantic VIS compare

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | VISWriter round-trips VISParser output | Unit test |
| R2 | Module bundle loads parsed visibility | Unit test |
| R3 | Install fails without loaded VIS | Unit test |
| R4 | Install writes `{module}.vis` to override via mutation service | Unit test |
| R5 | Toolbar **Install VIS to Override** wired | Wiring |
| R6 | Docs mark Q59 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_vis_writer.gd
godot --headless --path . --script tests/editor/test_module_designer_vis_install.gd
godot --headless --path . --script tests/editor/test_indoor_vis_builder.gd
```
