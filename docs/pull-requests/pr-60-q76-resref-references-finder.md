# PR #60 — Q76 ResRef References Finder

**Branch:** `impl/q76-resref-references-finder-c3f8`  
**URL:** https://github.com/th3w1zard1/godot-kotor-tools/pull/60

## Summary

Workspace resource browser gains **Find References** — override-scoped scan of indexed GFF and NSS files for a selected resref, with formatted field-path hit reports in the detail pane.

## Changes

- `KotorResRefReferenceScanner` — GFF recursive walk + NSS text scan, `format_report()`
- `KotorResourceBrowserPanel` — **Find References** button, `references_requested` signal
- `KotorTargetContext.get_gamefs()` — exposes gamefs for scanner
- Headless `tests/editor/test_resref_reference_scanner.gd`
- Execution queue + parity matrix Q76 entries

## Verification

```bash
/tmp/Godot_v4.4-stable_linux.x86_64 --headless --path . --script tests/editor/test_resref_reference_scanner.gd
```

## Plan

`docs/plans/2026-06-07-008-feat-q76-resref-references-finder-plan.md`
