# PR #62 — Q78 ModuleKit Loader

**Branch:** `impl/q78-modulekit-loader-c3f8`  
**URL:** https://github.com/th3w1zard1/godot-kotor-tools/pull/62

## Summary

Indoor Builder gains PyKotor-style **ModuleKit** support — discover install modules with LYT data, synthesize kit-compatible room components, and place module rooms into `.indoor` layouts.

## Changes

- `KotorModuleKitLoader` — `discover_module_roots()` + `load_module_kit()`
- `KotorIndoorKitLibrary.register_module_kits_from_gamefs()` — merges module kits into picker
- Indoor Builder **Refresh Module Kits** action + auto-refresh on kit library load
- Headless `tests/editor/test_module_kit_loader.gd`

## Verification

```bash
/tmp/Godot_v4.4-stable_linux.x86_64 --headless --path . --script tests/editor/test_module_kit_loader.gd
```

## Plan

`docs/plans/2026-06-07-010-feat-q78-modulekit-loader-plan.md`
