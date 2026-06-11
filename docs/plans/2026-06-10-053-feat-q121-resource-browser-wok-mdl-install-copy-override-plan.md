---
title: "feat: Q121 resource browser WOK/MDL install copy to override"
type: feat
status: active
date: 2026-06-10
origin: lfg-next-after-q120-auto-selected
phase: Q121
track: Module/Model Tools
parent: docs/plans/2026-06-10-052-feat-q120-wok-mdl-install-batch-copy-override-plan.md
related:
  - ui/workspace/panels/resource_browser_panel.gd
  - formats/bwm_gamefs_batch_importer.gd
  - formats/mdl_gamefs_batch_importer.gd
---

# Q121: Resource Browser WOK/MDL Install Copy to Override

## Summary

Expose **Batch Copy Install WOK to Override...** and **Batch Copy Install MDL to Override...** in the resource browser, completing Q120's deferred browser parity.

---

## Problem Frame

Q120 added one-click install→override copy in Module Designer and Model Editor. The resource browser still only offers install export for WOK/MDL — modders browsing the install index must switch editors to bulk-copy assets into override.

---

## Scope Boundaries

### In scope

- Resource browser toolbar buttons wired to `batch_install_to_override`
- GameFS refresh + tree reindex after successful copy when target context supports it
- Headless button wiring tests (reuse exporter test files)
- Execution queue + parity matrix Q121 entry

### Deferred

- Source-filter picker UI
- Folder-picker import actions in resource browser

### Out of scope

- New importer/exporter logic

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Resource browser exposes WOK install-copy button | `test_bwm_gamefs_batch_exporter.gd` |
| R2 | Resource browser exposes MDL install-copy button | `test_mdl_gamefs_batch_exporter.gd` |
| R3 | Handlers call `batch_install_to_override` | Source wiring |
| R4 | Docs mark Q121 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_bwm_gamefs_batch_exporter.gd
godot --headless --path . --script tests/editor/test_mdl_gamefs_batch_exporter.gd
```
