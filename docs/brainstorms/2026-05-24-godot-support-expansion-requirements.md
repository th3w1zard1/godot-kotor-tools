---
date: 2026-05-24
topic: godot-support-expansion
---

# Godot Support Expansion Requirements

## Summary

Define the next implementation wave that expands Godot-native editor capabilities for `godot-kotor-tools`, with a focus on safer editing ergonomics, better state consistency after mutations, and clearer contributor execution targets.

---

## Problem Frame

The plugin already ships strong parser/importer/editor coverage, but several high-value Godot capabilities are still underused. Contributors can see the gap list, yet need a requirements artifact that translates those opportunities into execution-ready product intent.

---

## Actors

- A1. Modder: edits game resources in the Godot workspace and expects safe, predictable behavior.
- A2. Contributor: implements and maintains editor/importer/saver behavior in this repository.
- A3. Workspace shell: routes actions, mutation flows, and install-aware refresh behavior.

---

## Key Flows

- F1. Edit structured data with undo/redo confidence
  - **Trigger:** A1 edits fields in a supported workspace editor.
  - **Actors:** A1, A3
  - **Steps:** A3 applies mutation through document abstractions; A3 records undo/redo operations; A1 can reverse and reapply edits without losing state coherence.
  - **Outcome:** Editing is safer and faster for iterative modding workflows.
  - **Covered by:** R1, R2, R6

- F2. Install or restore changes with consistent workspace state
  - **Trigger:** A1 installs a change or restores a transaction.
  - **Actors:** A1, A3
  - **Steps:** A3 performs pipeline mutation; A3 triggers targeted refresh/reindex flow; A1 sees updated install-aware state without stale winners/variants.
  - **Outcome:** Workspace state remains trustworthy after write actions.
  - **Covered by:** R3, R4, R7

- F3. Contributor plans and lands support expansion slices
  - **Trigger:** A2 chooses a next backlog slice.
  - **Actors:** A2
  - **Steps:** A2 uses this requirements doc and linked gap analysis to select scope, define acceptance, and generate a technical plan.
  - **Outcome:** Expansion work is execution-ready instead of ad hoc.
  - **Covered by:** R5, R8

---

## Requirements

- P1 R1. Workspace editors should support clear undo/redo boundaries for document mutations that already flow through shared document abstractions.
- P1 R2. Undo/redo behavior must preserve validation and changed-signal propagation semantics used by current document wrappers.
- P1 R3. Install/restore actions must trigger deterministic post-mutation refresh behavior so install-aware winners and variants remain accurate.
- P1 R4. Refresh behavior should avoid full reindex when targeted refresh can provide equivalent correctness.
- P2 R5. Gap-analysis-to-implementation handoff must remain explicit and discoverable from top-level contributor docs.
- P2 R6. New editing ergonomics should prioritize high-frequency field patterns first (for example locstrings, resource references, enum-like selectors).
- P1 R7. Mutation consistency checks should include failure-path handling and user-visible error context, not only happy-path completion.
- P2 R8. Each expansion slice must be small enough to plan and land independently without architectural rewrites.

---

## Acceptance Examples

- AE1. **Covers R1, R2.** Given a structured GFF field edit, when the user invokes undo and redo, the field value, change indicators, and validation state all return to expected prior/next values.
- AE2. **Covers R3, R4, R7.** Given an install or restore action, when the pipeline completes, workspace listings refresh correctly and failure paths surface explicit user-visible diagnostics.
- AE3. **Covers R5, R8.** Given a contributor selecting a backlog item, when they start `ce-plan`, the linked docs provide enough scope/acceptance detail to produce a bounded implementation plan without re-scoping product intent.
- AE4. **Covers R6.** Given high-frequency editing of locstring or reference-style fields, when using new editor ergonomics, the user completes edits with fewer manual low-level operations while preserving existing data constraints.
- AE5. **Covers R1, R2, R7.** Given an undo or redo operation that cannot be applied cleanly due to stale document state, when the user invokes the action, the editor preserves current data, surfaces a clear failure message, and does not desynchronize changed/validation indicators.

---

## Success Criteria

- Contributors can pick and execute the next Godot support slice with clear requirements and acceptance targets.
- Modders experience safer editing and stronger post-mutation consistency as expansion slices ship.

---

## Scope Boundaries

- No requirement to deliver all listed capability opportunities in one iteration.
- No replacement of existing parser/resource architecture.
- No introduction of non-Godot tooling for core editor workflows.

---

## Key Decisions

- Prioritize reliability and editing safety before visual polish.
- Keep expansion slices additive and architecture-aligned to current pipeline boundaries.
- Use this requirements doc as the canonical bridge between gap analysis and follow-up technical plans.
