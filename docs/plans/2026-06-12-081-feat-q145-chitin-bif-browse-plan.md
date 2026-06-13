---
title: "feat: Q145 chitin BIF catalog browse foundations"
type: feat
status: completed
date: 2026-06-12
origin: docs/30-gap-analysis/godot-support-gaps.md
phase: Q145
track: OpenKotOR Parity
related:
  - gamefs/kotor_gamefs.gd
  - editor/workspace/kotor_target_context.gd
  - ui/workspace/panels/resource_browser_panel.gd
  - formats/key_bif_parser.gd
  - tests/editor/test_key_bif_parser.gd
  - tests/editor/test_gamefs_chitin_catalog.gd
---

# Q145: Chitin BIF Catalog Browse Foundations

## Summary

Close the P1 **BIF/KEY archive browsing** gap with install-scoped BIF catalog listing, chitin source filtering in the resource browser, and headless parser/GameFS tests using synthetic KEY/BIF fixtures.

## Problem Frame

`KEYBIFParser` and `KotorGameFS` already index `chitin.key` resources, but modders cannot browse BIF containers or filter the resource browser to chitin-only entries. Gap audit lists BIF/KEY browsing as **Open** P1. Zero open PRs; Q145 is the first post-Q144 slice.

## Requirements Trace

| ID | Requirement | Plan coverage |
| --- | --- | --- |
| R1 | `KotorGameFS.list_chitin_bif_catalog()` returns BIF filename, path, size, key-entry count | U1 |
| R2 | `KotorTargetContext` passes `source` to `list_core_resources` and exposes catalog API | U2 |
| R3 | Resource browser source filter + optional BIF catalog tree mode | U3 |
| R4 | Headless KEY/BIF parser tests with synthetic fixtures | U4 |
| R5 | Headless GameFS catalog + chitin load tests | U5 |
| R6 | Execution queue + gap audit mark Q145 shipped | U6 |

## Implementation Units

### U1. GameFS BIF catalog API

**Files:** `gamefs/kotor_gamefs.gd`

Add `list_chitin_bif_catalog() -> Array[Dictionary]` aggregating `key_index` BIF entries with per-BIF key-entry counts from `_bif_path_cache`.

### U2. Target context source filter

**Files:** `editor/workspace/kotor_target_context.gd`

Extend `list_resources_filtered(query, resource_type, source, limit)` to forward `source` to `gamefs.list_core_resources`. Add `list_chitin_bif_catalog()` delegate.

### U3. Resource browser UX

**Files:** `ui/workspace/panels/resource_browser_panel.gd`

- Source `OptionButton`: All / override / chitin.key / modules
- `CheckButton` "BIF catalog" (enabled when source is chitin.key)
- Catalog mode lists BIF rows; resource mode filters by selected `bif_index` when a catalog row is selected

### U4. KEY/BIF parser tests

**Files:** `tests/editor/test_key_bif_parser.gd`

Synthetic KEY + BIF bytes; verify parse, `find_key_entry`, `extract_resource`.

### U5. GameFS catalog tests

**Files:** `tests/editor/test_gamefs_chitin_catalog.gd`

Temp install with `chitin.key` + `data/test.bif`; verify `list_chitin_bif_catalog`, source filter, byte load.

### U6. Doc authority

**Files:** `docs/50-execution/godot-capability-execution-queue.md`, `docs/30-gap-analysis/godot-support-gaps.md`, `docs/30-gap-analysis/openkotor-parity-matrix.md`

## Verification

```bash
godot --headless --path . --script tests/editor/test_key_bif_parser.gd
godot --headless --path . --script tests/editor/test_gamefs_chitin_catalog.gd
```

## Out of Scope

- Full BIF editor or in-place BIF mutation
- DLG graph depth, savegame write-back, MDL geometry
- GitHub Actions CI (P3)
