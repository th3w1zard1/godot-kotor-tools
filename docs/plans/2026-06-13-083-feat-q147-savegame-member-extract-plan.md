---
title: "feat: Q147 savegame member extract to override"
type: feat
status: completed
date: 2026-06-13
origin: docs/30-gap-analysis/godot-support-gaps.md
phase: Q147
track: OpenKotOR Parity
parent: docs/plans/2026-06-12-063-feat-q132-savegame-inspector-plan.md
related:
  - ui/workspace/editors/savegame_workspace_editor.gd
  - ui/workspace/editors/erf_workspace_editor.gd
  - tests/editor/test_savegame_workspace_editor.gd
---

# Q147: Savegame Member Extract to Override

## Summary

Extend the Savegame Inspector with **Extract to Override** for a selected SAV member, mirroring the ERF Archive Browser install path. First bounded savegame write-back slice.

## Problem Frame

Q132 shipped read-only `.sav` inspection and member open routing. Gap audit lists **savegame write-back** as Open P2. Full save mutation is out of scope; extracting embedded GFF/resources to `override/` matches existing mutation pipeline patterns.

## Requirements Trace

| ID | Requirement | Plan coverage |
| --- | --- | --- |
| R1 | `install_selected_member_to_override()` installs selected member bytes via `KotorMutationService` | U1 |
| R2 | Toolbar **Extract to Override** button wired to install path | U1 |
| R3 | GameFS refresh after successful install | U1 |
| R4 | Headless test with `_skip_preflight_for_testing` verifies override file write | U2 |
| R5 | Execution queue + gap audit note partial savegame write-back | U3 |

## Implementation Units

### U1. Savegame editor install path

**Files:** `ui/workspace/editors/savegame_workspace_editor.gd`

Mirror ERF `install_entry_to_override` using `get_entry_payload`, `resref.extension` file naming, `_resolve_mutation_service`, `_resolve_gamefs`, `_skip_preflight_for_testing`.

### U2. Tests

**Files:** `tests/editor/test_savegame_workspace_editor.gd`

Add `_test_extract_member_to_override` with temp install root + `savenfo.res` member.

### U3. Doc authority

**Files:** `docs/50-execution/godot-capability-execution-queue.md`, `docs/30-gap-analysis/godot-support-gaps.md`

## Verification

```bash
godot --headless --path . --script tests/editor/test_savegame_workspace_editor.gd
```

## Out of Scope

- Full `.sav` save/write-back
- Extract all members batch
- Savegame member replace inside SAV container
