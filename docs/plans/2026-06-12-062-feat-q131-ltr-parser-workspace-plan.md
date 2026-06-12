---
title: "feat: Q131 LTR parser + workspace editor foundations"
type: feat
status: completed
date: 2026-06-12
origin: docs/plans/2026-06-11-060-feat-q129-post-q128-parity-wave-plan.md
phase: Q131
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-05-29-031-feat-q26-nss-ncs-script-tools-plan.md
  - docs/50-execution/godot-capability-execution-queue.md
---

# Q131: LTR Parser + Workspace Editor Foundations

## Summary

Add KotOR LTR (letter / name-generation probability table) read/write support and route `.ltr` resources through the workspace shell with save and install-to-override flows.

## Problem Frame

Holocron and PyKotor expose `ltr.py` editors for procedural name tables. Godot Holocron parity lists `ltr` as **Not started**. Modders cannot inspect or edit `.ltr` resources from the workspace.

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `LTRParser.parse_bytes` reads LTR V1.0 header + singles/doubles/triples blocks | `test_ltr_parser.gd` |
| R2 | `LTRWriter` round-trips parsed data byte-identical for KotOR 28-letter alphabet | `test_ltr_parser.gd` |
| R3 | `LTRResource` holds blocks with mutation + `changed` signal | Resource serialize test |
| R4 | `KotorLTRWorkspaceEditor` opens `.ltr`, edits singles probabilities, save/install | `test_ltr_workspace_editor.gd` |
| R5 | Workspace shell + dock delegate `.ltr` to LTR editor tab | Routing grep / headless open test |
| R6 | `KotorModdingPipeline` serializes `LTRResource` for install/export | Pipeline serialize path |
| R7 | Execution queue marks Q131 shipped; active slice → Q132 | Doc sync |

## Key Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Alphabet | 28 chars (`a–z`, `'`, `-`) | KotOR LTR V1.0 standard per PyKotor wiki |
| Editor depth | Singles fully editable; doubles/triples view + selected-context edit | Foundations slice — full 784-block grid deferred |
| Pattern | Mirror LIP/SSF parser → resource → workspace editor | Established parity stack |

## Implementation Units

### U1. Parser + writer + resource

**Files:**

- `formats/ltr_parser.gd`
- `formats/ltr_writer.gd`
- `resources/ltr_resource.gd`

### U2. Workspace editor + routing

**Files:**

- `ui/workspace/editors/ltr_workspace_editor.gd`
- `ui/workspace/kotor_workspace_shell.gd`
- `ui/kotor_dock.gd`
- `editor/modding/kotor_modding_pipeline.gd`

### U3. Tests + docs

**Files:**

- `tests/editor/test_ltr_parser.gd`
- `tests/editor/test_ltr_workspace_editor.gd`
- `docs/50-execution/godot-capability-execution-queue.md`
- `docs/30-gap-analysis/openkotor-parity-matrix.md`
- `STRATEGY.md`

## Verification

```bash
godot --headless --path . --script tests/editor/test_ltr_parser.gd
godot --headless --path . --script tests/editor/test_ltr_workspace_editor.gd
```

## Non-Goals

- Procedural name generator preview UI
- LTR semantic compare reports
- Batch LTR folder tooling
