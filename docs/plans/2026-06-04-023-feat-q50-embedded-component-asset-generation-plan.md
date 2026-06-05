---
title: "feat: Q50 embedded component asset generation"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q49-next-embedded-asset-slice
phase: Q50
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-021-feat-q48-indoor-mod-builder-plan.md
  - docs/plans/2026-05-29-027-feat-q22-indoor-builder-foundations-plan.md
---

# Q50: Embedded Component Asset Generation

## Summary

Add `KotorIndoorEmbeddedAssetGenerator` to decode base64 `bwm`/`mdl`/`mdx` payloads from `.indoor` embedded components into MOD room assets, wire into `KotorIndoorModBuilder`, and update the build manifest asset flags.

---

## Problem Frame

Q48 native MOD assembly copies kit on-disk assets but skips embedded rooms with a warning. Holocron/PyKotor `.indoor` maps store embedded component geometry as base64 fields (`bwm` → `.wok`, optional `mdl`/`mdx`). Native MOD export must include those bytes for embedded-only layouts to load.

---

## Scope Boundaries

### In scope

- `resources/indoor/kotor_indoor_embedded_asset_generator.gd`
- `KotorIndoorModBuilder` embedded room asset path (replace omit warning)
- `KotorIndoorBuildManifest` embedded `has_wok`/`has_mdl`/`has_mdx` flags from decoded fields
- `KotorIndoorDocument.get_embedded_component()` helper
- Headless `tests/editor/test_indoor_embedded_asset_generator.gd`
- Extend `tests/editor/test_indoor_mod_builder.gd` for embedded WOK inclusion
- Execution queue + parity matrix Q50 entry

### Deferred

- Procedural MDL generation from BWM (only passthrough embedded base64)
- HoloPatcher CLI bridge
- 3D rotate gizmo

### Out of scope

- PyKotor CLI indoor-build replacement
- Module Designer changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Generator decodes base64 `bwm`/`mdl`/`mdx` to bytes | Unit test |
| R2 | Invalid or empty embedded fields yield no entry + optional warning | Unit test |
| R3 | MOD builder includes embedded `.wok`/`.mdl`/`.mdx` entries | Unit test |
| R4 | Manifest room_assets reflect embedded asset presence | Unit test |
| R5 | Docs mark Q50 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_indoor_embedded_asset_generator.gd
godot --headless --path . --script tests/editor/test_indoor_mod_builder.gd
```
