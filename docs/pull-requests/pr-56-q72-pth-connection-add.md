# PR #56 — Q72 PTH Connection Add

**Branch:** `impl/q72-pth-connection-add-c3f8`  
**URL:** https://github.com/th3w1zard1/godot-kotor-tools/pull/56

## Summary

Adds append-only path connection editing in Module Designer so modders can create new edges between path points without raw GFF editing.

## Changes

- `KotorPTHDocument.add_connection()` with topology rebuild
- Toolbar **Add Path Connection** armed flow: select source → click target
- Snapshot undo via workspace orchestration
- Headless test and parity docs

## Verification

```bash
/tmp/Godot_v4.4-stable_linux.x86_64 --headless --path . --script tests/editor/test_module_designer_pth_connection_add.gd
```
