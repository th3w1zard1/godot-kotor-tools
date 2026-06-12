---
title: "feat: Q133 MDL write-back phase 0"
type: feat
status: completed
date: 2026-06-12
origin: docs/50-execution/godot-capability-execution-queue.md
phase: Q133
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-10-016-feat-q84-mdl-workspace-editor-plan.md
  - docs/plans/2026-06-04-003-feat-q30-tpc-write-back-plan.md
---

# Q133: MDL Write-Back Phase 0

## Summary

Introduce `MDLWriter` passthrough serialization, a typed `MdlResource` document model, and pipeline serialize wiring so MDL export/install flows use a validated write-back path — foundations for future geometry mutation without changing modder-visible behavior today.

## Problem Frame

Q84 shipped read-only MDL inspection with raw-byte passthrough export/install. The parity matrix still lists **MDL write-back authoring** as deferred. There is no `MDLWriter`, no typed `MdlResource`, and `KotorModdingPipeline` has no `mdl` serialize arm — blocking coherent mutation/write-back slices.

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `MDLWriter.serialize_passthrough` validates parseable MDL and returns byte-identical MDL | `test_mdl_writer.gd` |
| R2 | `MDLWriter.serialize_mdx_passthrough` returns byte-identical MDX (empty allowed) | `test_mdl_writer.gd` |
| R3 | `MdlResource` holds MDL/MDX bytes + parsed summary metadata | Resource setup test |
| R4 | `KotorModdingPipeline` serializes `MdlResource` and validated `PackedByteArray` MDL | Pipeline/writer test |
| R5 | MDL workspace editor loads `MdlResource` and exports via writer path | `test_mdl_workspace_editor.gd` or writer test |
| R6 | Execution queue marks Q133 shipped; active slice → Q134 | Doc sync |

## Key Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Encode scope | Passthrough only | Full trimesh rebuild is multi-slice; mirror Q30 TPC phase |
| Validation gate | Require `MDLParser.parse_bytes` success | Reject corrupt exports early |
| MDX handling | Separate passthrough helper | MDL/MDX pair semantics preserved |
| Editor UX | No new toolbar; same export/install | Phase 0 is plumbing, not authoring UI |

## Implementation Units

### U1. Writer + resource

- `formats/mdl_writer.gd`
- `resources/mdl_resource.gd`

### U2. Pipeline + editor wiring

- `editor/modding/kotor_modding_pipeline.gd`
- `ui/workspace/editors/mdl_workspace_editor.gd`

### U3. Tests + docs

- `tests/editor/test_mdl_writer.gd`
- `docs/50-execution/godot-capability-execution-queue.md`
- `STRATEGY.md`

## Verification

```bash
godot --headless --path . --script tests/editor/test_mdl_writer.gd
godot --headless --path . --script tests/editor/test_mdl_workspace_editor.gd
```

## Out of Scope (Q134+)

- Geometry mutation / trimesh rebuild from edited meshes
- MDX vertex table regeneration
- Blender bridge integration
