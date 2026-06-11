---
title: "feat: Q34 stack Q31 batch LIP generator on parity branch"
type: feat
status: completed
date: 2026-06-04
origin: lfg-q33-next-parity-slice
phase: Q34
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-04-004-feat-q31-batch-lip-generator-plan.md
---

# Q34: Stack Q31 Batch LIP Generator on Parity Branch

## Summary

Integrate the shipped Q31 batch LIP generator (`LipBatchGenerator`, LIP editor **Batch Generate LIP...**, headless tests) onto the active parity stack (`feat/q33-dlg-jump-to-target` base) so media tooling ships with Q30–Q33 rather than only on `main` via PR #15.

---

## Problem Frame

Q31 landed on `feat/q31-batch-lip-generator` (PR #15 → `main`) while Q30–Q33 stacked on separate branches. Parity matrix marks Q31 shipped but the generator is absent from the Q33 stack. Modders on the parity branch cannot batch-generate LIP files from WAV folders.

---

## Scope Boundaries

### In scope

- Cherry-pick Q31 commit (`9b5ca99`) onto parity stack
- Resolve doc conflicts in execution queue + parity matrix (retain Q30–Q33 entries + add Q31)
- Run `test_lip_batch_generator.gd`
- Open stacked PR on `feat/q33-dlg-jump-to-target`

### Deferred

- Rebasing PR #15 or closing it (out of scope for this slice)
- Rhubarb / phoneme automation (Q31 deferred items)

### Out of scope

- Re-implementing LipBatchGenerator from scratch
- New LIP editor features beyond Q31

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `formats/lip_batch_generator.gd` present on parity stack | File exists |
| R2 | LIP editor **Batch Generate LIP...** wired | `lip_workspace_editor.gd` diff |
| R3 | Headless batch generator tests pass | `test_lip_batch_generator.gd` |
| R4 | Execution queue lists Q31 on shipped slices | Doc diff |
| R5 | Parity matrix notes batch LIP no longer backlog | Doc diff |

---

## Key Technical Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Integration | Cherry-pick Q31 commit | Code already reviewed on PR #15 |
| Doc conflicts | Merge shipped tables (Q30–Q33 + Q31) | Single source of truth |
| Base branch | `feat/q33-dlg-jump-to-target` | Continue parity stack |

---

## Implementation Units

### U1. Cherry-pick Q31

**Files:** `formats/lip_batch_generator.gd`, `tests/editor/test_lip_batch_generator.gd`, `ui/workspace/editors/lip_workspace_editor.gd`, `docs/plans/2026-06-04-004-feat-q31-batch-lip-generator-plan.md`, checklist updates

### U2. Resolve doc conflicts

**Files:** `docs/50-execution/godot-capability-execution-queue.md`, `docs/30-gap-analysis/openkotor-parity-matrix.md`

### U3. Verification

```bash
godot --headless --path . --script tests/editor/test_lip_batch_generator.gd
```

---

## Acceptance

- [ ] Q31 code on parity stack branch
- [ ] Tests pass
- [ ] Docs reflect Q31 on stack
- [ ] Stacked PR opened
