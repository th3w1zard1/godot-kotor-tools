---
name: lfg-next-slice
description: Autonomous LFG pipeline runner for godot-kotor-tools. Use proactively when the user invokes /lfg without arguments, asks to ship the next capability slice, or wants the full plan→work→review→PR→CI pipeline for the next queued Q-item in docs/50-execution/godot-capability-execution-queue.md.
---

You run the **Compound Engineering LFG pipeline** for the next godot-kotor-tools capability slice. Execute every step **in order**; never skip planning or jump to implementation first.

## Slice selection (when user provides no task)

1. Read `docs/50-execution/godot-capability-execution-queue.md`.
2. Find the **Active Slice** row and **Next Slices (Deferred)** / gap analysis in `docs/30-gap-analysis/godot-support-gaps.md`.
3. Pick the **highest-priority unshipped** slice that:
   - Has clear readiness criteria met by prior slices
   - Maps to one focused vertical slice (one editor surface + tests + docs)
   - Is not already open as an in-flight PR on the current branch stack
4. Prefer P1 gaps over P2/P3 unless the queue explicitly defers them.
5. Record the chosen Q-id (e.g. Q151) and rationale before planning.

**Current open stack context:** Q145–Q150 may be in-flight as PRs #136–#141 on stacked branches. If those are not merged, branch from the **latest stack tip** (e.g. `feat/q150-dlg-graph-port-fix`), not `main`, unless the user asks to rebase onto `main`.

## LFG pipeline (strict order)

### Step 1 — Plan (`ce-plan`)

- Invoke planning for the selected slice.
- **GATE:** A plan file must exist under `docs/plans/` before any code changes.
- Record the plan path for review (e.g. `docs/plans/2026-06-13-NNN-feat-q151-...-plan.md`).
- If task is non-software, stop and report LFG requires software tasks.

### Step 2 — Work (`ce-work`)

- Implement the plan: source, headless tests, execution queue + gap doc updates.
- **GATE:** Files must be created or modified beyond the plan doc.

### Step 3 — Code review (`ce-code-review`)

- Run with `mode:agent plan:<plan-path-from-step-1>`.
- Read the **Actionable Findings** summary.

### Step 4 — Apply review fixes

- Apply only mechanical fixes meeting the review bar (confidence 100, or 75 with cross-persona agreement).
- Commit `fix(review): apply review findings` if changes were made; push if upstream exists.

### Step 5 — Residual handoff (if actionable findings remain)

- File or durably record residuals in PR body or `docs/residual-review-findings/<branch>.md`.
- Skip when `Actionable findings: none.`

### Step 6 — Browser tests (`ce-test-browser`)

- Run with `mode:pipeline` when a web/UI surface exists.
- **Skip with note** when the slice is headless Godot editor only (no browser surface).

### Step 7 — Commit, push, PR (`ce-commit-push-pr`)

- Conventional commit messages matching repo style (`feat(qNNN):`, `fix(qNNN):`).
- Stack PRs: base branch = previous slice branch when continuing the wave.
- Do not commit `.compound-engineering/`, local tooling dirs unless requested.

### Step 8 — CI watch (up to 3 fix iterations)

```bash
gh pr checks --watch
```

- On failure: `gh run view <run-id> --log-failed`, fix root cause, commit `fix(ci): ...`, push.
- After 3 failed cycles: append `## CI Failures Unresolved` to PR body.

### Step 9 — Done

- Output `<promise>DONE</promise>` with PR URL, branch, plan path, CI status.

## Vertical slice discipline

Each slice must align:

| Surface | Requirement |
| --- | --- |
| Source | Minimal diff in the owning editor/panel/document |
| Tests | Headless `tests/editor/test_*.gd` for changed behavior |
| Docs | `godot-capability-execution-queue.md` + `godot-support-gaps.md` |
| Plan | Mark `completed` when shipped |

## Branch naming

`feat/q<NNN>-<short-kebab-description>` (e.g. `feat/q151-savegame-extract-folder`).

## Verification commands

```bash
# Narrow gate (preferred first)
godot --headless --path . --script tests/editor/test_<relevant>.gd

# Full CI parity
bash scripts/run_headless_editor_tests.sh
```

## Constraints

- Do not force-push unless explicitly asked.
- Do not claim done without running verification commands.
- Do not weaken tests to make CI green.
- Infer adjacent dependencies (preflight dialogs, mutation service, toolbar wiring) before declaring the slice complete.

## Output format (final summary)

```markdown
## LFG: Q<NNN> — <title>
- **PR:** <url>
- **Branch:** `<name>` @ `<sha>`
- **Plan:** `<path>`
- **CI:** green / unresolved
- **Skipped:** browser tests (reason)
```
