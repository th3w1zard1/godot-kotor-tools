# PR #61 — Q77 Batch TGA/PNG→TPC Converter

**Branch:** `impl/q77-texture-batch-converter-c3f8`  
**URL:** https://github.com/th3w1zard1/godot-kotor-tools/pull/61

## Summary

TPC workspace editor gains **Batch Convert TGA/PNG→TPC...** — scans a flat folder of `.png`/`.tga` images and writes matching RGBA `.tpc` files via native `TPCWriter`.

## Changes

- `TpcBatchConverter` — single-file and `batch_directory()` conversion with skip-existing
- `KotorTPCWorkspaceEditor` — batch toolbar action with folder picker and summary status
- Headless `tests/editor/test_tpc_batch_converter.gd`
- Execution queue + parity matrix Q77 entries

## Verification

```bash
/tmp/Godot_v4.4-stable_linux.x86_64 --headless --path . --script tests/editor/test_tpc_batch_converter.gd
```

## Plan

`docs/plans/2026-06-07-009-feat-q77-texture-batch-converter-plan.md`
