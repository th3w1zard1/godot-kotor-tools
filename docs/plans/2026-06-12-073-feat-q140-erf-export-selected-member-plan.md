---
title: "feat: Q140 ERF export selected member to file"
type: feat
status: completed
date: 2026-06-12
origin: docs/50-execution/godot-capability-execution-queue.md
phase: Q140
track: OpenKotOR Parity
parent: docs/plans/2026-06-12-070-feat-q139-erf-extract-all-folder-plan.md
related:
  - ui/kotor_dock.gd
  - ui/workspace/editors/erf_workspace_editor.gd
---

# Q140: Export Selected Archive Member to File

## Summary

Add **Export Selected...** in Archive Browser to write the selected member to a user-chosen filesystem path — workspace parity with legacy dock `_export_selected_erf_entry`.

---

## Problem Frame

Q139 shipped batch folder export. Modders still need single-member export without batch dialogs — already supported in the legacy dock via mutation preflight.

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `export_selected_member_to_path(path)` writes selected member bytes | `test_erf_workspace_editor.gd` |
| R2 | No selection returns actionable error | Unit test |
| R3 | Toolbar **Export Selected...** opens save dialog | Wiring |
| R4 | Q139 batch behaviors unchanged | Existing tests pass |
| R5 | Docs mark Q140 shipped | Doc sync |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_erf_workspace_editor.gd
```
