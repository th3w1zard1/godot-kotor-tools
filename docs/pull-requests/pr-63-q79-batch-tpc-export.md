# PR #63 — Q79 Batch TPC→TGA Export

**Branch:** `impl/q79-batch-tpc-export-c3f8`  
**URL:** https://github.com/th3w1zard1/godot-kotor-tools/pull/63

## Summary

TPC workspace editor gains **Batch Export TGA...** — scans a flat folder of `.tpc` files and exports matching `.tga` files via PyKotor `texture-convert`.

## Changes

- `TpcBatchExporter` — `batch_directory()` with skip-existing and dry-run support
- `KotorTPCWorkspaceEditor` — batch toolbar action with folder picker and summary status
- Headless `tests/editor/test_tpc_batch_exporter.gd`
- Execution queue + parity matrix Q79 entries

## Verification

```bash
/tmp/Godot_v4.4-stable_linux.x86_64 --headless --path . --script tests/editor/test_tpc_batch_exporter.gd
```

## Plan

`docs/plans/2026-06-07-011-feat-q79-batch-tpc-export-plan.md`
