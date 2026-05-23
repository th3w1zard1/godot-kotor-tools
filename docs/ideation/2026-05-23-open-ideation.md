---
date: 2026-05-23
topic: open
focus: surprise-me
mode: repo-grounded
---

# Ideation: Repository-grounded improvement ideas

## Grounding Context

- **Codebase Context:** `godot-kotor-tools` is a Godot 4.6 editor plugin written in pure GDScript. Its main seams are `formats/` for parsers/serializers, `importers/`, typed resource/document helpers in `resources/`, install-aware indexing in `gamefs/kotor_gamefs.gd`, write/export/install/compare in `editor/modding/kotor_modding_pipeline.gd`, and the main workspace shell in `ui/kotor_dock.gd`.
- **Past Learnings:** Strong ideas should extend the existing vertical slice, keep install indexing in `gamefs/kotor_gamefs.gd`, keep write/install behavior in `editor/modding/kotor_modding_pipeline.gd`, and use typed/document wrappers instead of raw dictionary mutation in the UI.
- **External Context:** The strongest adjacent signals cluster around install safety, rollback, compare visibility, profiles, previewable writes, and mature Godot editor-plugin UX. Relevant prior art includes Holocron Toolset, HoloPatcher, PyKotor, Dialogic, r2modman, and Mod Organizer 2.
- **Additional Context:** `README.md` has already drifted from the current implementation in at least some parser/API descriptions, so documentation-hardening ideas have direct repository evidence behind them.

## Topic Axes

Decomposition skipped — surprise-me mode

## Ranked Ideas

### 1. Safe Transaction Layer
**Description:** Make every export/install action in `editor/modding/kotor_modding_pipeline.gd` behave like a visible transaction: preflight impact preview, automatic snapshot of touched files, manifest of what changed, and one-click rollback. This extends existing pipeline responsibilities instead of inventing a second installer.
**Basis:** `direct:` install-aware indexing already exists in `gamefs/kotor_gamefs.gd`, write/export/install already lives in `editor/modding/kotor_modding_pipeline.gd`, and external grounding repeatedly emphasized install safety, rollback, and previewable writes as high-value user expectations.
**Rationale:** This is the clearest product-strengthening move because it directly addresses the highest-cost modding fear: touching a live install without confidence. It also gives the repo a durable differentiator versus “just another parser/editor.”
**Downsides:** Requires careful UI design to stay understandable, and the manifest/rollback model raises data-model and storage questions.
**Confidence:** 91%
**Complexity:** High
**Status:** Explored

### 2. Compare-First Workspace
**Description:** Promote compare from an afterthought to the editor’s default context: installed baseline, winning current variant, and draft/export state visible as the normal mode for supported resource types. Use `gamefs/kotor_gamefs.gd` for source resolution, typed resource/document wrappers for normalized comparison inputs, and the dock as the orchestration surface.
**Basis:** `direct:` `gamefs/kotor_gamefs.gd` already tracks both the winning entry and all variants, and compare behavior already belongs in `editor/modding/kotor_modding_pipeline.gd`. `external:` surrounding tooling patterns strongly reward compare/merge visibility.
**Rationale:** This leans into a core strength the repo already has—install-aware resolution—while making editing safer and more legible in the exact workflows where users are most likely to make destructive mistakes.
**Downsides:** Type-aware diffs are non-trivial across multiple formats, and the UX could become visually dense if not scoped carefully.
**Confidence:** 88%
**Complexity:** High
**Status:** Unexplored

### 3. Document Contract System
**Description:** Turn typed/document wrappers into the canonical source of “is this safe to apply/save/export/install?” by adding structured readiness and validation contracts at apply/export/install boundaries. This builds on the existing `resources/documents/` pattern instead of relying on repo-wide script validation alone.
**Basis:** `direct:` the repo already centralizes editing behavior, validation, and change propagation in document wrappers, and currently lacks a stronger verification harness than Godot `--check-only`.
**Rationale:** It is one of the highest-leverage internal quality moves because it strengthens correctness at the exact seam where users act, and it compounds across every future editor surface the repo adds.
**Downsides:** Requires format-specific validation work and careful agreement on what is advisory versus blocking.
**Confidence:** 90%
**Complexity:** Medium
**Status:** Unexplored

### 4. Profile-Centered Workspace
**Description:** Make named install profiles the primary unit of workspace context so switching between clean/test/modded installs becomes explicit, safe, and fast. Let `gamefs/kotor_gamefs.gd` remain the authority on install resolution while the dock and pipeline key their behavior off the selected profile.
**Basis:** `direct:` the repo is already organized around install-aware indexing and write/export/install seams. `external:` profile-based context switching is a strong, repeated expectation in adjacent mod-manager ecosystems.
**Rationale:** The repo already looks like it wants to be a real modding workspace; this idea gives that workspace a stable, user-facing center of gravity.
**Downsides:** Adds persistence/state management complexity and can become confusing if profile scope is not kept tight.
**Confidence:** 84%
**Complexity:** Medium
**Status:** Unexplored

### 5. Self-Healing Knowledge Surface
**Description:** Generate repo and in-editor documentation from live capability metadata in wrappers, resources, and pipeline surfaces so the tool can explain its current behavior without depending on hand-maintained docs. This addresses the specific drift already visible between `README.md` and the current code.
**Basis:** `direct:` the learnings pass found that README/API docs have already drifted from implementation. `reasoned:` the repo’s clear subsystem seams make code-owned capability descriptions feasible.
**Rationale:** This is a lower-complexity, high-pragmatism move that reduces onboarding drag and prevents future refactors from silently making docs less trustworthy.
**Downsides:** Generated docs can still be shallow if the metadata model is weak, and it needs discipline to avoid becoming a parallel documentation DSL.
**Confidence:** 86%
**Complexity:** Medium
**Status:** Unexplored

### 6. Change Intelligence Graph
**Description:** Build a shared awareness layer for “what changed, what else it affects, and what conflicts with it” across open documents, install variants, and pending pipeline actions. In practice this would combine relationship discovery, conflict visibility, and multi-tab change tracking into one coherent workspace surface.
**Basis:** `reasoned:` the repo already cleanly separates documents, install resolution, and pipeline actions, which creates the structural preconditions for a cross-cutting awareness layer. `external:` mod-manager and editor analogies repeatedly point to conflict visibility as a differentiator.
**Rationale:** This is the strongest medium-term leverage play because it could power conflict boards, dependent-resource warnings, better diffs, and clearer multi-tab editing without repeating logic in many places.
**Downsides:** It is conceptually broad and could become overbuilt if not anchored to a few immediately useful user-visible features first.
**Confidence:** 76%
**Complexity:** High
**Status:** Unexplored

## Rejection Summary

| # | Idea | Reason Rejected |
|---|------|-----------------|
| 1 | Artifact-First Packaging Flow | Promising, but overlaps with the stronger Safe Transaction Layer and would add more product surface than the current repo evidence justifies. |
| 2 | Workflow Surfaces Instead of Format Tabs | Interesting reframing, but too expensive relative to likely value until safety/compare foundations are stronger. |
| 3 | Derived Asset Graph | Folded into the broader Change Intelligence Graph idea. |
| 4 | Reactive Install Drift Watcher / Index Drift Detector | Valuable, but narrower than the surviving profile/safety directions and better treated as a component inside them. |
| 5 | Auto-Resolve Workspace From Install | Useful, but a smaller variant of the stronger Profile-Centered Workspace direction. |
| 6 | Undoable Bulk Fixes From Install Scan | Under-grounded for the current repo; it assumes repetitive fix classes the grounding did not clearly support. |
| 7 | Flight Recorder Workspace | Folded into the broader Change Intelligence Graph idea. |
| 8 | Air-Traffic Conflict Board | Folded into the broader Change Intelligence Graph idea. |
| 9 | Workspace Change Ledger Across Tabs | Folded into the broader Change Intelligence Graph idea. |
| 10 | Visual Diff + Merge Preview / Museum Conservator Diff View | Folded into the broader Compare-First Workspace idea. |
| 11 | Export Recipe Templates / One-Click Mod Recipe Capture | Useful, but less foundational than the top survivors and overlaps with packaging/transaction ideas. |
| 12 | Live Docs / Self-Healing Documentation Panels | Folded into the broader Self-Healing Knowledge Surface idea. |
| 13 | Install Profiles / Safe Target Switching | Folded into the broader Profile-Centered Workspace idea. |
| 14 | Impact Preview / Rollback Pack / Rollback Ledger / Checklist | Folded into the broader Safe Transaction Layer idea. |
| 15 | Apply-Changes Guardrails / Discipline Mode / Validation Gates | Folded into the broader Document Contract System idea. |
