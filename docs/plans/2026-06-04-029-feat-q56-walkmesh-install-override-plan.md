---
title: "feat: Q56 Module Designer walkmesh install to override"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q55-next-module-designer-install-slice
phase: Q56
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-027-feat-q54-bwm-writer-walkmesh-export-plan.md
  - docs/plans/2026-05-29-022-feat-q17-module-designer-bwm-walkmesh-plan.md
---

# Q56: Module Designer Walkmesh Install to Override

## Summary

Add **Install Walkmesh to Override** in Module Designer so modders can write the loaded area `.wok` back to the game install via the existing mutation preflight/rollback path.

---

## Problem Frame

Q54 shipped walkmesh export preview to arbitrary paths. Q54 deferred install-to-override. Module Designer already installs edited `.git` files; walkmesh write-back completes the area walkmesh edit loop for override-first modding.

---

## Scope Boundaries

### In scope

- `install_walkmesh_to_override()` on Module Designer editor
- Toolbar **Install Walkmesh to Override** with preflight dialog
- Headless `tests/editor/test_module_designer_walkmesh_install.gd`
- Execution queue + parity matrix Q56 entry

### Deferred

- Walkmesh geometry editing in viewport
- Indoor Builder MOD install to `modules/`
- LYT install to override

### Out of scope

- BWM compare semantic diff
- AABB/adjacency serialization

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Install fails when no walkmesh is loaded | Unit test |
| R2 | Install serializes via `BWMWriter` and writes `{module}.wok` to override | Unit test |
| R3 | Install uses mutation service preflight/apply (rollback metadata) | Unit test |
| R4 | Toolbar button triggers install flow | Wiring |
| R5 | Docs mark Q56 shipped | Doc diff |

---

## Implementation Units

### U1. Walkmesh install API + UI

**Goal:** Public install method and toolbar wiring with preflight.

**Files:** `ui/workspace/editors/module_designer_workspace_editor.gd`, `tests/editor/test_module_designer_walkmesh_install.gd`

**Test scenarios:**
- No walkmesh loaded returns error
- Install after removing override `.wok` recreates file with valid BWM header
- Preflight preview reports install kind when `_skip_preflight_for_testing` is false (optional smoke)

### U2. Docs

**Files:** `docs/50-execution/godot-capability-execution-queue.md`, `docs/30-gap-analysis/openkotor-parity-matrix.md`

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_module_designer_walkmesh_install.gd
godot --headless --path . --script tests/editor/test_bwm_writer.gd
```
