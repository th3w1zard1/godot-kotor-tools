---
title: Q23 Indoor Kit Library and Placement
type: feat
status: complete
date: 2026-05-29
origin: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
phase: Q23
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
---

# Q23: Indoor Kit Library and Placement

## Summary

Load Holocron/PyKotor **on-disk indoor kits** from a configurable kits directory, expose kit/component pickers in the Indoor Builder, support **add room from kit** with undo, and route **`.indoor`** files from the resource browser into the Indoor Builder tab.

## Problem frame

Q22 established `.indoor` JSON editing with embedded components only. Holocron's indoor builder (`pykotor.tools.indoorkit`, `HolocronToolset/src/toolset/data/indoorkit/`) loads kit folders (`<kits>/<kit_id>.json` + `<kits>/<kit_id>/`) and places rooms referencing `kit` + `component` ids. Without kit library support, Godot cannot author maps from standard Holocron kits.

## Key technical decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Kit loader scope | v1 component kits only (`format_version != 2`) | Matches PyKotor `load_kits`; tile kits deferred |
| Component validity | Require `.wok`; `.mdl`/`.mdx` optional for placement UI | Footprint from BWM; full export needs models in later slice |
| Kits path | EditorSettings `kotor_tools/indoor_kits_path` | Parallel to `kotor_tools/game_path`; user points at Holocron `kits/` folder |
| Placement API | `KotorIndoorDocument.add_room_from_kit` | Appends PyKotor-shaped room dict; preserves unknown map keys |
| UX | Kit OptionButton + component ItemList + Add Room | Holocron list/combobox pattern without cursor-placement mode |

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `KotorIndoorKitLoader` parses kit JSON + component WOK footprints | Headless test with synthetic kit fixture |
| R2 | `KotorIndoorKitLibrary` refreshes from configured path | Test + editor wiring |
| R3 | `add_room_from_kit` mutates document and round-trips | Unit test |
| R4 | Indoor Builder UI: kits path, refresh, add room with undo | Manual/editor wiring |
| R5 | Resource browser opens `.indoor` in Indoor Builder | Shell routing |
| R6 | Parity matrix + execution queue mark Q23 shipped | Doc sync |

## Implementation units

### U1 — `resources/indoor/kotor_indoor_kit_loader.gd`

- `load_kits_from_directory(path) -> Dictionary` with `kits` and `missing` arrays
- Skip `format_version == 2`; parse doors metadata; load hooks from component JSON

### U2 — `resources/indoor/kotor_indoor_kit_library.gd`

- Holds loaded kits; `configure(path)`, `refresh()`, `get_kit_ids()`, `get_component_summaries(kit_id)`

### U3 — `resources/documents/kotor_indoor_document.gd`

- `add_room_from_kit(kit_id, component_id, position, rotation) -> int`
- Footprint resolution uses kit library metadata when not embedded

### U4 — `editor/core/kotor_editor_state.gd`

- `indoor_kits_path` setting get/set

### U5 — `ui/workspace/editors/indoor_builder_workspace_editor.gd`

- Kits path browse, refresh, kit/component pickers, Add Room + undo

### U6 — `ui/workspace/kotor_workspace_shell.gd`

- Route `extension == "indoor"` to indoor builder

### U7 — Tests + docs

- `tests/editor/test_indoor_kit_library.gd`
- Extend `test_indoor_builder_foundations.gd` for add_room_from_kit
- Update parity matrix and execution queue

## Explicit non-goals (Q23)

- Kit downloader / network fetch
- Hook connection UI and door insertion between rooms
- `IndoorMap.build()` → `.mod` export
- ModuleKit (`module_root`) resolution
- Component drag-to-place cursor mode

## Verification

```bash
godot --headless --path . --script tests/editor/test_indoor_kit_library.gd
godot --headless --path . --script tests/editor/test_indoor_builder_foundations.gd
```

## Acceptance

- [x] Kit loader + library tests pass
- [x] Add room from kit round-trips in document tests
- [x] Indoor Builder can add rooms when kits path is configured
- [x] `.indoor` opens from resource browser
- [x] Docs reflect Q23 shipped
