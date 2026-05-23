---
date: 2026-05-23
topic: safe-transaction-layer
---

# Safe Transaction Layer for Install and Export Actions

## Summary

Add a pipeline-first safety layer around install/export actions so users can see what will change, proceed intentionally, and roll back touched files from inside the workspace. The feature should extend the existing `gamefs/kotor_gamefs.gd` and `editor/modding/kotor_modding_pipeline.gd` flow rather than introducing a separate installer or a full workspace redesign.

---

## Problem Frame

The plugin already gives users real power over live game installs: it can index an install, open winning resource variants, compare core vs override state, and write supported resources back out through the modding pipeline. That means the tool has crossed from “viewer” into “editor against a real target,” but its safety model is still narrow. Today the write path can create a `.bak` when overwriting an existing file, yet that backup is an implementation detail rather than a visible user-facing workflow.

For a modder working against a live KotOR or Jade Empire install, the hard part is not only editing data — it is trusting the moment when a draft becomes a mutation of the target install. The user needs to know what files will be touched, whether anything is being overwritten, whether recovery exists, and what exactly happened after the action completes. Without that safety layer, the product asks users to rely on caution and filesystem literacy at the exact point where the tool should be carrying the trust burden.

---

## Actors

- A1. Modder: Uses the workspace to inspect, edit, export, and install resources into a real game directory.
- A2. KotOR Tools workspace: Presents preflight information, executes actions, records outcomes, and exposes rollback affordances.
- A3. Target game install: The install root and its `override/` content that the tool reads from and writes to.

---

## Key Flows

- F1. Preview and apply an install action
  - **Trigger:** A1 chooses an install action for a supported resource from the workspace.
  - **Actors:** A1, A2, A3
  - **Steps:** A2 resolves the target through the existing install-aware flow; A2 shows what files will be created or overwritten and whether rollback is available; A1 proceeds or cancels; if A1 proceeds, A2 writes the change and records the action outcome; A2 refreshes install-aware state.
  - **Outcome:** A1 knows the blast radius before committing and can inspect the outcome after the action completes.
  - **Covered by:** R1, R2, R3, R4, R5, R6, R8, R9

- F2. Restore a previous action
  - **Trigger:** A1 chooses a previously recorded transaction to roll back.
  - **Actors:** A1, A2, A3
  - **Steps:** A2 presents the recorded action and touched files; A1 chooses restore; A2 restores the saved prior contents for the touched files; A2 refreshes install-aware state and reports per-file results.
  - **Outcome:** A3 returns to the prior state for the files that were captured by that transaction.
  - **Covered by:** R4, R6, R7, R10

- F3. Review transaction history after working
  - **Trigger:** A1 wants to understand what the workspace changed during the session.
  - **Actors:** A1, A2
  - **Steps:** A2 shows recorded actions with targets, outcomes, and rollback availability; A1 opens a specific transaction to inspect what happened or decide whether to restore it.
  - **Outcome:** A1 can answer “what changed?” without leaving the workspace or guessing from `.bak` files.
  - **Covered by:** R4, R5, R10, R12

---

## Requirements

**Preflight and action lifecycle**
- R1. Before any supported install-to-override action mutates the target install, the workspace must show a preflight summary of the files the action will touch and where those files will land.
- R2. The preflight summary must make it clear whether each touched file is a new create, an overwrite of existing install content, or a no-op because the target is already up to date.
- R3. The user must be able to cancel from the preflight step without changing the target install.
- R4. When a user proceeds, the workspace must record a transaction result describing the action, the touched files, the target paths, and whether rollback data exists.
- R5. After a successful action, the workspace must refresh install-aware state and surface the recorded outcome in an inspectable workspace-facing result, not only as a silent filesystem side effect.

**Rollback and recovery**
- R6. For any touched file that would be overwritten or replaced, the tool must capture the prior contents before the mutation happens so the action can be rolled back later.
- R7. The workspace must let the user restore a recorded transaction from inside the product without requiring manual filesystem work.
- R8. If the tool cannot create the required rollback data for a destructive action, it must block that action and explain why rather than proceeding without recovery.

**Scope and product shape**
- R9. The safe transaction layer must extend the existing install-aware path rather than bypassing it: target resolution remains grounded in `gamefs/kotor_gamefs.gd`, and write/export/install execution remains grounded in `editor/modding/kotor_modding_pipeline.gd`.
- R10. The recorded transaction history must be visible through the existing workspace surfaces so the user can inspect prior actions and rollback availability during a normal editing session.
- R11. v1 applies to the resource types and actions the current pipeline already supports; it does not require redesigning the entire editor around a new staging workspace.
- R12. Transaction records must be descriptive enough to support future packaging/share concepts, but v1 does not need to ship a sharable package format or collaborative workflow.

---

## Acceptance Examples

- AE1. **Covers R1, R2, R3.** Given a supported resource with no existing override copy, when the user chooses install, the workspace shows a preflight summary that marks the target as a new create, and canceling leaves the install unchanged.
- AE2. **Covers R1, R2, R4, R6.** Given a supported resource whose target file already exists in `override/`, when the user chooses install and proceeds, the workspace shows that the action is an overwrite, captures the prior file contents, and records a transaction entry for that action.
- AE3. **Covers R7, R10.** Given a previously recorded transaction with rollback data, when the user chooses restore from the workspace, the prior file contents are written back and the workspace reports the restore result in the transaction history.
- AE4. **Covers R8.** Given a destructive action where rollback capture fails, when the user attempts to proceed, the action is blocked and the workspace explains that recovery could not be created.
- AE5. **Covers R5, R9, R11.** Given a successful install of a currently supported resource type, when the action completes, the install-aware resource view refreshes and the result appears through the existing workspace reporting surfaces rather than through a separate tool.

---

## Success Criteria

- Users can perform install/export actions against a live game directory with a clear understanding of what will change and how to undo it.
- The requirements are specific enough that `ce-plan` does not need to invent whether preview, recording, rollback, and workspace visibility are in or out of scope.

---

## Scope Boundaries

- No full compare-first workspace redesign in this doc; compare can inform the preflight, but the proposal is not a broader editing-model overhaul.
- No install-profile system in this doc; the transaction layer should work with today’s single active install workflow.
- No full packaging/share format in v1; the feature records transactions for local safety first.
- No virtual filesystem or overlay stack model; actions still resolve and write through the current install-aware pipeline.
- No batch queue of unrelated pending actions in v1; this feature is about making each existing install/export action safer and reversible.

---

## Key Decisions

- **Pipeline-first over workspace-first:** The feature extends the current install/export path rather than introducing a second workspace model. This matches the repository’s existing subsystem boundaries.
- **Visible rollback over implicit backup:** Existing `.bak` behavior is not enough on its own; rollback must become a user-facing part of the workflow.
- **Safety before shareability:** The initial win is trust while editing against a live install. Shareable packaging can build on the same transaction record later, but it is not the v1 target.

---

## Dependencies / Assumptions

- The current pipeline remains the only sanctioned path for supported install/export mutations.
- The supported v1 surface is limited to actions and resource types the current pipeline can already serialize and write.
- The existing dock/report/activity surfaces can host preflight and transaction-history affordances without requiring a total shell rewrite.

---

## Outstanding Questions

### Deferred to Planning

- [Affects R4, R6, R7][Technical] Where should transaction metadata and rollback payloads persist so they survive long enough to be useful without becoming a hidden data-management problem?
- [Affects R1, R2, R10][Needs research] What is the minimum preflight detail that builds trust without turning the feature into a full diff workstation?
- [Affects R7][Technical] How should restore behave when the same target file has been changed again after the original transaction was recorded?
- [Affects R12][Needs research] Should export actions use the exact same transaction record shape as install actions, or a lighter variant that still preserves user trust?
