---
title: OpenKotOR PyKotor and HolocronToolset Parity Program
type: feat
status: active
date: 2026-05-28
origin: user-request-lfg-openkotor-parity
phase: Parity Program
track: Capability Expansion
---

## OpenKotOR Parity Program (Godot Editor)

## Summary

Run a staged parity program that maps PyKotor and HolocronToolset capabilities into godot-kotor-tools, lands editor/runtime parity slices in Godot, and keeps install/use documentation current for contributors and modders.

## Problem Frame

PyKotor and HolocronToolset provide broader format and workflow coverage than current godot-kotor-tools. Contributors need a durable, evidence-based parity map plus continuous implementation slices so Godot editor workflows can approach functional parity without architecture drift.

## Source Research

- Upstream repo metadata and README content gathered via `gh`:
  - `OpenKotOR/PyKotor` (library + tools)
  - `OpenKotOR/HolocronToolset` (GUI editor surface)
- Upstream path inventory sampled via `gh api ... git/trees/master?recursive=1` for:
  - `Libraries/PyKotor/src/pykotor/resource/formats/*`
  - `Libraries/PyKotor/src/pykotor/extract/*`
  - `Libraries/PyKotor/src/pykotor/tools/*`
  - `src/toolset/gui/editors/*`, dialogs/widgets/windows in HolocronToolset

## Requirements

- R1: Maintain an evidence-backed parity matrix between PyKotor/HolocronToolset and godot-kotor-tools.
- R2: Land incremental editor/runtime parity slices in Godot each pass (code + tests + docs).
- R3: Keep user-facing install and usage documentation current, including feature coverage status.
- R4: Preserve existing Godot workspace architecture patterns (document wrappers, mutation service, transaction safety).
- R5: Keep all slices validated with headless Godot tests.

## Scope Boundaries

### In scope for this execution slice

- Add parity-plan artifact and parity-matrix documentation.
- Extend GFF-family extension routing parity where safe.
- Add installation and usage instructions with explicit current functionality coverage.
- Update tests for any routing/capability changes.

### Deferred to subsequent slices

- Full implementation of every Holocron/PyKotor feature in one pass.
- New large editor families (e.g., walkmesh visual editors, full module designer parity, full NCS decompile parity) without dedicated design slices.
- Non-Godot tooling parity (HoloPatcher/KotorDiff CLIs) beyond documented roadmap linkage.

## Key Technical Decisions

1. Keep parity work as vertical slices with explicit matrix status; avoid one-shot mega-refactors.
2. Prefer enabling safe GFF-family extension routes before creating new dedicated editors.
3. Use docs parity matrix as authoritative backlog for remaining upstream capabilities.
4. Keep plugin install/use guidance in README and QUICKSTART synchronized.

## Implementation Units

### U1. Create upstream parity matrix and install/use guidance

Files:

- `docs/30-gap-analysis/openkotor-parity-matrix.md` (new)
- `README.md`
- `docs/QUICKSTART.md`

Verification:

- Matrix includes upstream capability families, current status, next slice link.
- README and QUICKSTART include plugin installation + usage + capability coverage notes.

### U2. Expand safe GFF-family extension routing parity

Files:

- `ui/workspace/editors/gff_workspace_editor.gd`
- `tests/editor/test_gff_workspace_editor.gd`
- `tests/editor/test_dock_workspace_routing.gd`

Verification:

- New extensions route to GFF workspace editor where parser/file-type checks remain authoritative.
- Existing routing behavior remains intact for non-GFF types.

### U3. Execution docs linkage for parity program

Files:

- `docs/50-execution/godot-capability-execution-queue.md`
- `STRATEGY.md`

Verification:

- Program reflected as active parity track with clear next slices.

## Risks

- Upstream feature names do not map 1:1 to Godot architecture boundaries.
- Over-broad extension routing could expose unsupported file-type UX gaps.
- Matrix can drift without regular updates per slice.

## Test Scenarios

- GFF extension allow-list accepts newly added GFF-family resource extensions.
- Non-GFF extensions still route away from GFF editor.
- Headless tests remain green for GFF workspace routing.

## Done Criteria for this slice

- New parity plan and matrix docs committed.
- At least one concrete code-path parity improvement landed and tested.
- Install/use instructions updated for modders and contributors.
