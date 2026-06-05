---
title: "feat: Q55 native indoor MOD export default"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q54-next-indoor-native-build-parity
phase: Q55
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-021-feat-q48-indoor-mod-builder-plan.md
  - docs/plans/2026-05-29-030-feat-q25-indoor-mod-export-plan.md
---

# Q55: Native Indoor MOD Export Default

## Summary

Promote Q48 native MOD assembly to the primary **Export .mod** path in Indoor Builder via `KotorIndoorNativeExporter`, and retain PyKotor CLI export as an explicit fallback action.

---

## Problem Frame

Q43–Q48 shipped native LYT/IFO/VIS/ARE/GIT writers and MOD assembly. Q50 added embedded-component assets. The toolbar **Export .mod** still invokes PyKotor `indoor-build`, requiring external CLI and game install path. Native build parity means modders can export a playable `.mod` without PyKotor when layout validation passes.

---

## Scope Boundaries

### In scope

- `resources/indoor/kotor_indoor_native_exporter.gd` — preflight (layout + kits + output, no CLI/game) and `export_indoor_to_mod` delegating to `KotorIndoorModBuilder.write_to_path`
- Indoor Builder: **Export .mod** uses native exporter; **Export .mod (PyKotor)…** retains Q25 CLI path
- Remove redundant **Export Native MOD Preview** toolbar button (primary export replaces it)
- Headless `tests/editor/test_indoor_native_exporter.gd`
- Execution queue + parity matrix Q55 entry

### Deferred

- Install-to-override from Indoor Builder
- `--implicit-kit` / module-kit mode
- Removing PyKotor CLI bridge entirely

### Out of scope

- Module Designer changes
- Additional native writers beyond Q48 chain

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Native preflight validates layout, kits path (when kit rooms present), output path; does not require PyKotor CLI or game path | Unit test |
| R2 | Native export writes `.mod` with core resources via `KotorIndoorModBuilder` | Unit test |
| R3 | Embedded-only layouts export without kits path when validation passes | Unit test |
| R4 | Indoor Builder **Export .mod** uses native exporter | Wiring |
| R5 | PyKotor CLI export remains available as secondary toolbar action | Wiring |
| R6 | Docs mark Q55 shipped | Doc diff |

---

## Implementation Units

### U1. Native exporter facade

**Goal:** Headless native export API mirroring `KotorIndoorModExporter` config shape minus CLI/game requirements.

**Files:** `resources/indoor/kotor_indoor_native_exporter.gd`, `tests/editor/test_indoor_native_exporter.gd`

**Approach:** `validate_preflight` runs `KotorIndoorLayoutValidator`; require kits path only when any room uses a non-embedded kit; delegate export to `KotorIndoorModBuilder.write_to_path`.

**Test scenarios:**
- Preflight fails with empty module and no rooms
- Preflight passes embedded-only layout without game/CLI config
- Preflight requires kits path when kit rooms present
- Export writes file containing five core module resources

### U2. Indoor Builder wiring

**Goal:** Primary export uses native path; CLI fallback preserved.

**Files:** `ui/workspace/editors/indoor_builder_workspace_editor.gd`

**Approach:** Wire **Export .mod** to native exporter dialog; add **Export .mod (PyKotor)…** for Q25 path; remove **Export Native MOD Preview** button.

### U3. Docs

**Goal:** Record Q55 in execution queue and parity matrix.

**Files:** `docs/50-execution/godot-capability-execution-queue.md`, `docs/30-gap-analysis/openkotor-parity-matrix.md`

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_indoor_native_exporter.gd
godot --headless --path . --script tests/editor/test_indoor_mod_builder.gd
godot --headless --path . --script tests/editor/test_indoor_mod_export.gd
```
