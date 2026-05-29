---
title: Q14 Blueprint Field-Depth Parity
type: feat
status: shipped
date: 2026-05-29
origin: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
phase: Q14
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
---

# Q14: Blueprint Field-Depth Parity

## Summary

Extend typed GFF blueprint documents and workspace field helpers so Holocron’s high-value blueprint panels—**script hooks**, **trap mechanics**, **map notes**, and **appearance IDs**—are first-class in the Godot workspace: ResRef pickers on script fields, trap DC/type summaries, enum labels from install 2DA, and editable `TrapList` arrays.

## Problem frame

Q13 completed typed factory coverage for all Holocron blueprint families. Documents still expose only identity/template summary lines. Holocron editors surface dozens of script ResRefs and trap fields per type; modders must hunt the raw GFF tree for `OnClick`, `ScriptHeartbeat`, `TrapDetectDC`, etc.

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | KotOR script hook fields (`On*`, `Script*`) are treated as NSS ResRefs in GFF tree (picker + validation) | `test_resref_picker.gd`, `test_blueprint_field_depth.gd` |
| R2 | UTT typed document summarizes trap flags, DCs, type, and script hooks | Factory/summary tests |
| R3 | UTC/UTD/UTP typed documents summarize script hooks; UTC includes appearance | Summary tests |
| R4 | `TrapType` resolves labels from `traps.2da` when GameFS indexed | Enum registry test |
| R5 | `TrapList` struct array supports add/remove defaults in GFF workspace | GFF tree populator + workspace editor default struct |
| R6 | Parity matrix + execution queue mark Q14 shipped | Doc sync |

## Implementation units

### U1 — Script ResRef detection (`typed_field_helpers.gd`)

- Extend `is_resref_field()` for `On*` and `Script*` scalar fields (Holocron/PyKotor script hooks).
- Ensure `get_resref_type_hint()` returns `nss` for those fields.

### U2 — Trap enum registry (`kotor_enum_registry.gd`)

- Map `TrapType` → `traps` 2DA table.

### U3 — Blueprint document depth (typed documents)

- Shared helpers on `kotor_gff_document.gd` for script/trap summary append.
- Enrich `get_summary_lines()` on `KotorUTTDocument`, `KotorUTCDocument`, `KotorUTDDocument`, `KotorUTPDocument`, `KotorUTWDocument`, `KotorAREDocument`.

### U4 — TrapList array editing (`gff_tree_populator.gd`, `gff_workspace_editor.gd`)

- Add `TrapList` to editable struct arrays and default trap struct template.

### U5 — Tests + docs

- `tests/editor/test_blueprint_field_depth.gd`
- Extend `test_resref_picker.gd` for `OnClick` / `ScriptHeartbeat`
- Update parity matrix and execution queue

## Verification

```bash
godot --headless --path . --script tests/editor/test_blueprint_field_depth.gd
godot --headless --path . --script tests/editor/test_resref_picker.gd
godot --headless --path . --script tests/editor/test_gff_resource_factory.gd
```

## Explicit non-goals (Q14)

- Full Holocron panel UI clone (Qt tabs per blueprint).
- Module designer / 3D GIT editing (Q15+).
- Dynamic script hook schema code generation from PyKotor.

## Success criteria

- [x] All verification commands pass
- [x] Script fields open NSS ResRef picker from GFF tree context menu
- [x] UTT summary shows trap + script depth
- [x] Docs reflect Q14 shipped
