---
title: "feat: Q130 NSS compile-to-override UX"
type: feat
status: completed
date: 2026-06-11
origin: docs/plans/2026-06-11-060-feat-q129-post-q128-parity-wave-plan.md
phase: Q130
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-05-29-031-feat-q26-nss-ncs-script-tools-plan.md
  - docs/50-execution/godot-capability-execution-queue.md
---

# Q130: NSS Compile-to-Override UX

## Summary

Close the NSS modding loop: after a successful PyKotor `assemble`, offer one-click install of the compiled `.ncs` to the game Override with the existing mutation preflight/rollback path.

## Problem Frame

Q26 ships Compile/Decompile/Disassemble in the Script tab, but `_install_script_to_override()` rejects NCS with a stale message. Modders must manually copy compiled bytecode out of the temp cache.

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Install NCS bytes to Override via `KotorMutationService` + preflight | Headless dock test |
| R2 | NSS install-to-override behavior unchanged | Existing mutation tests |
| R3 | After successful compile, auto-offer NCS install (preflight dialog) | Compile success callback |
| R4 | Script toolbar enables install for loaded NCS when bytes present | `_refresh_script_tool_buttons` |
| R5 | Execution queue + parity docs mark Q130 shipped | Doc sync |
| R6 | Workspace script editor installs NCS bytes to override | Headless workspace test in `test_script_compile_install.gd` |

## Implementation Units

### U1. NCS install path in `kotor_dock.gd`

**Files:** `ui/kotor_dock.gd`

- Extend `_install_script_to_override()` for `ncs` extension using `_script_bytes` as `PackedByteArray`.
- Resolve override file name from resref (`{basename}.ncs`).
- Store `_script_install_btn` reference; refresh label/disabled state in `_refresh_script_tool_buttons()`.
- On compile success, invoke `_install_script_to_override()` after loading compiled bytes.

**Patterns:** `_install_dlg_to_override`, `test_text_table_editors.gd` NCS install via mutation service.

### U2. Headless contract test

**Files:** `tests/editor/test_script_compile_install.gd`

**Scenarios:**

1. Load NCS bytes in dock → install to override → file exists.
2. NSS install still applies text payload.
3. Install button disabled when no script loaded.

```bash
godot --headless --path . --script tests/editor/test_script_compile_install.gd
```

### U4. Workspace script editor NCS install

**Files:** `ui/workspace/editors/script_workspace_editor.gd`, `resources/documents/kotor_script_document.gd`

- Mirror dock NCS install path in `install_document_to_override()`.
- Refresh install button label/disabled state for NSS vs NCS payloads.

### U3. Documentation authority

**Files:**

- `docs/50-execution/godot-capability-execution-queue.md` — ship Q130, active → Q131
- `docs/30-gap-analysis/openkotor-parity-matrix.md` — NSS row note
- `STRATEGY.md` — shipped slice line

## Explicit Non-Goals

- Batch compile trees
- Auto-install NSS source alongside NCS (separate user action)
- Workspace shell script editor routing changes

## Verification

```bash
godot --headless --path . --script tests/editor/test_script_compile_install.gd
godot --headless --path . --script tests/editor/test_script_tool_bridge.gd
godot --headless --path . --script tests/editor/test_mutation_service.gd
```
