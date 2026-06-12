---
title: "feat: Q144 LTR doubles/triples context editing"
type: feat
status: completed
date: 2026-06-12
origin: docs/30-gap-analysis/godot-support-gaps.md
phase: Q144
track: OpenKotOR Parity
parent: docs/plans/2026-06-12-062-feat-q131-ltr-parser-workspace-plan.md
related:
  - formats/ltr_parser.gd
  - resources/ltr_resource.gd
  - ui/workspace/editors/ltr_workspace_editor.gd
  - tests/editor/test_ltr_workspace_editor.gd
---

# Q144: LTR Doubles/Triples Context Editing

## Summary

Extend the Letter Table workspace editor so modders can edit double- and triple-letter probability blocks — not only singles — with round-trip save/install preserved.

## Problem Frame

Q131 shipped LTR foundations with singles editing; doubles/triples were preserved on save but not editable. Gap audit marks this P2. Zero open PRs; Q144 is the first post-stack capability slice.

## Requirements Trace

| ID | Requirement | Plan coverage |
| --- | --- | --- |
| R1 | `LTRResource` get/set APIs for double and triple block cells | U1 |
| R2 | LTR editor tree edits all double contexts (collapsed sections) | U2 |
| R3 | LTR editor edits selected triple context via row/col selectors | U2 |
| R4 | Writer round-trip preserves edited double/triple values | U3 |
| R5 | Execution queue + parity matrix mark Q144 shipped | U4 |

## Implementation Units

### U1. Resource mutation APIs

**Files:** `resources/ltr_resource.gd`

### U2. Workspace editor UX

**Files:** `ui/workspace/editors/ltr_workspace_editor.gd`

**Design:** Doubles — tree sections per context letter. Triples — toolbar row/col `OptionButton` pair editing one block at a time (avoids 784-node tree).

### U3. Tests

**Files:** `tests/editor/test_ltr_workspace_editor.gd`

**Verification:**
```bash
godot --headless --path . --script tests/editor/test_ltr_parser.gd
godot --headless --path . --script tests/editor/test_ltr_workspace_editor.gd
```

### U4. Doc authority

**Files:** `docs/50-execution/godot-capability-execution-queue.md`, `docs/30-gap-analysis/openkotor-parity-matrix.md`, `docs/30-gap-analysis/godot-support-gaps.md`, `STRATEGY.md`

## Out of Scope

- Procedural name preview
- Full 784-block triple grid visible at once
- LTR semantic compare
