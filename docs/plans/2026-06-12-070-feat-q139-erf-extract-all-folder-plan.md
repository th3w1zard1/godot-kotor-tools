---
title: "feat: Q139 ERF extract all members to folder"
type: feat
status: completed
date: 2026-06-12
origin: docs/50-execution/godot-capability-execution-queue.md
phase: Q139
track: OpenKotOR Parity
parent: docs/plans/2026-06-12-069-feat-q138-erf-extract-all-override-plan.md
related:
  - ui/kotor_dock.gd
  - formats/erf_parser.gd
---

# Q139: Extract All Members to Folder

## Summary

Add **Extract All to Folder...** in Archive Browser to write every archive member to a user-selected directory on disk — workspace parity with the legacy dock `_extract_erf_all` path (`ERFParser.extract_all`).

## Problem Frame

Q138 shipped batch install to game Override. Modders auditing or diffing archives still need filesystem export without touching the install tree — the dock already supports this; the workspace editor does not.

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `extract_all_members_to_folder(dest_dir)` writes `{resref}.{ext}` for each valid member | `test_erf_workspace_editor.gd` |
| R2 | Empty/invalid resref members skipped with summary counts | Workspace editor test |
| R3 | Toolbar **Extract All to Folder...** opens directory picker and invokes API | Manual; API covered by test |
| R4 | Q138 override batch behavior unchanged | Existing tests still pass |
| R5 | Queue marks Q139 shipped; active slice advances | Doc sync |

## Key Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Data source | `KotorErfDocument.get_entry_payload` loop | Document is source of truth after add/replace mutations |
| Invalid members | Skip and report | Matches Q138 batch override semantics |
| Dialog | `EditorFileDialog` OPEN_DIR | Matches dock extract-all UX |

## Implementation Units

### U1. Folder extract API + toolbar

- `ui/workspace/editors/erf_workspace_editor.gd` — `extract_all_members_to_folder`, `_extract_all_to_folder_dialog`, toolbar button

### U2. Tests + docs

- `tests/editor/test_erf_workspace_editor.gd`
- `docs/50-execution/godot-capability-execution-queue.md`
- `STRATEGY.md`

## Verification

```bash
godot --headless --path . --script tests/editor/test_erf_workspace_editor.gd
```
