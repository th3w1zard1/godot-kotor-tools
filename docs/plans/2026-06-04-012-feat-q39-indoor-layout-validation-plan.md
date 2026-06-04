---
title: "feat: Q39 indoor layout validation before mod export"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q38-next-indoor-slice
phase: Q39
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-05-29-030-feat-q25-indoor-mod-export-plan.md
  - docs/plans/2026-06-04-011-feat-q38-wav-semantic-compare-plan.md
---

# Q39: Indoor Layout Validation

## Summary

Add headless indoor layout validation that checks module identity, room kit/component references, and open door hooks before PyKotor `indoor-build` export. Wire validation into `KotorIndoorModExporter.validate_preflight`.

---

## Problem Frame

Q25 shipped `.mod` export via PyKotor CLI with preflight for paths, CLI, and room count. Layouts can still reference missing kit components or lack module IDs, failing late in CLI with opaque errors. Native indoor build is deferred; validation is the first bounded slice toward module/area designer parity.

---

## Scope Boundaries

### In scope

- `resources/indoor/kotor_indoor_layout_validator.gd`
- `KotorIndoorDocument.has_embedded_component()` and `get_kit_library()` helpers
- `KotorIndoorModExporter.validate_preflight` integration
- Headless `tests/editor/test_indoor_layout_validator.gd`
- Execution queue + parity matrix Q39 entry

### Deferred

- Native `IndoorMap.build()` port
- 3D rotate gizmo / LYT depth
- KotorDiff UI

### Out of scope

- Indoor Builder UI changes beyond export preflight messaging
- PyKotor CLI behavior changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Validator errors when warp and module_id are both empty | Unit test |
| R2 | Validator errors when a room lacks kit or component | Unit test |
| R3 | Validator errors on unknown kit/component (library loaded) | Unit test |
| R4 | Validator errors on missing embedded component reference | Unit test |
| R5 | Validator warns when open door hooks remain | Unit test |
| R6 | `validate_preflight` merges layout errors/warnings | Unit test |
| R7 | Docs mark Q39 shipped | Doc diff |

---

## Implementation Units

### U1. Layout validator — `resources/indoor/kotor_indoor_layout_validator.gd`

Static `validate(document, kit_library)` returning `{ok, errors, warnings}`.

### U2. Document helpers — `resources/documents/kotor_indoor_document.gd`

`has_embedded_component(component_id)` and `get_kit_library()`.

### U3. Exporter integration — `resources/indoor/kotor_indoor_mod_exporter.gd`

Resolve kit library from config or document; merge validator output in preflight.

### U4. Tests + docs — `tests/editor/test_indoor_layout_validator.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_indoor_layout_validator.gd
godot --headless --path . --script tests/editor/test_indoor_mod_export.gd
```
