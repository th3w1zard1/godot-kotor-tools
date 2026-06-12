---
title: "feat: Q129 post-Q128 parity wave planning"
type: feat
status: completed
date: 2026-06-11
origin: docs/plans/2026-06-10-056-feat-pr-stack-merge-holocron-parity-roadmap-plan.md
phase: Q129
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-11-059-feat-q128c-dlg-graph-interactive-plan.md
  - docs/50-execution/godot-capability-execution-queue.md
---

# Q129: Post-Q128 Parity Wave Planning

## Summary

Land PR #119 (Q124–Q128c4) on `main`, run post-merge verification, refresh documentation authority, and sequence the next Holocron/PyKotor parity wave (Q130+).

---

## Problem Frame

Q128 child plan is complete on `feat/parity-roadmap-q124-wave` but `main` still reflects Q123. Planning docs, STRATEGY, and support-gaps carry `*(PR #119)*` qualifiers that block trustworthy backlog selection for wave 2.

---

## Requirements

- **R1.** Merge [PR #119](https://github.com/th3w1zard1/godot-kotor-tools/pull/119) to `main` without force-push.
- **R2.** Post-merge headless tests pass for Q124–Q128 representative suite.
- **R3.** Documentation authority sync: STRATEGY, README, `godot-support-gaps.md`, execution queue, parity matrix — Q124–Q128 unconditional on `main`.
- **R4.** Define bounded Q130+ slices for remaining Partial/Not started families.

---

## Implementation Units

### U1. Merge PR #119

**Files:** git only  
**Verification:** `gh pr view 119` shows `MERGED`; `main` contains Q128c4 commit.

### U2. Post-merge verification

**Commands:**

```bash
godot --headless --path . --script tests/editor/test_dlg_workspace_editor.gd
godot --headless --path . --script tests/editor/test_module_designer_git_instance_crud.gd
godot --headless --path . --script tests/editor/test_erf_workspace_editor.gd
```

**Verification:** All exit 0.

### U3. Documentation authority sync

**Files:**

- `STRATEGY.md`
- `README.md`
- `docs/30-gap-analysis/godot-support-gaps.md`
- `docs/50-execution/godot-capability-execution-queue.md`
- `docs/plans/2026-06-10-056-feat-pr-stack-merge-holocron-parity-roadmap-plan.md` (status note)

**Verification:** No `*(PR #119)*` qualifiers; active slice names Q130.

---

## Q130+ Wave (sequenced backlog)

| Order | Slice | Goal | Holocron/PyKotor ref |
| --- | --- | --- | --- |
| Q130 | NSS compile-to-override UX | After successful assemble, offer one-click install compiled `.ncs` to override with preflight | `nss.py` compile loop |
| Q131 | LTR parser + workspace editor foundations | Read/write letter tables; route `.ltr` in workspace | `ltr.py`, `formats/ltr` |
| Q132 | Savegame inspector foundations | Read-only save metadata surface | `savegame.py` |
| Q133 | MDL write-back phase 0 | Trimesh metadata mutation boundaries + writer scaffold | `mdl.py` |
| Q134 | Archive member create/add | ERF workspace add-member (beyond extract/browse) | `erf.py` |
| Q135 | BWM painter depth | Edge/region paint tools beyond Q126 toggle | `bwm.py` |

**Active after Q129:** Q130 (NSS compile-to-override UX).

---

## Verification

Post-merge representative suite green; docs synced; execution queue active row = Q130.
