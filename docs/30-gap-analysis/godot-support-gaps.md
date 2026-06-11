# Godot Support Gaps and Next Implementation Areas

## Purpose

This document answers two recurring planning questions:

1. What Godot-facing capabilities are already supported in `godot-kotor-tools`?
2. What implementation gaps should be prioritized next?

Project target: **Godot 4.6**.

## Current Support Snapshot

| Capability Area | Status | Execution Status | Notes |
| --- | --- | --- | --- |
| Custom format parsing (GFF, ERF/RIM, 2DA, TLK, TPC, KEY/BIF, LYT) | **Supported** | Shipped (Q1–Q5) | Core parser stack exists in `formats/`. |
| Resource wrappers for editor/runtime access | **Supported** | Shipped (Q1–Q5) | `resources/` provides generic and typed wrappers for key formats. |
| Editor import integration | **Supported** | Shipped (Q1–Q5) | Importer plugins exist for major user-facing formats. |
| Save/write-back for editable formats | **Partial** | Shipped (Q4) | 2DA/TLK/GFF-family write-back supported; archive write-back complete via Q4. |
| Install-aware browsing and precedence | **Supported** | Shipped (Q1–Q5) | `KotorGameFS` indexes install sources and applies override precedence. |
| Workspace editors (DLG, 2DA, TLK, NSS, area tools) | **Supported** | Shipped (Q1–Q5) | Core workspace surfaces are shipped and routable. |
| Module Designer (GIT/PTH/LYT/VIS/WOK, instance CRUD, walkmesh paint) | **Partial** | Shipped on `main` (Q15–Q73); Q124–Q126 on PR #119 | Full Holocron module designer depth still deferred (DLG graph, advanced BWM tools). |
| Media editors (TPC/WAV/LIP/SSF) + batch/compare tooling | **Partial** | Shipped (Q27–Q31, Q77–Q118) | Workspace + install-scoped batch flows; not full Holocron media suite parity. |
| Model Editor + MDL/BWM batch/compare | **Partial** | Shipped (Q84–Q85, Q91–Q123, Q133 phase 0) | Preview, batch, compare, install-copy; Q133 passthrough write-back plumbing (`MDLWriter`/`MdlResource`); geometry mutation deferred. |
| Browser-like visual verification for UI surfaces | **Missing** | Deferred | Repo has no web surface; UI validation relies on Godot script tests and editor flows. |

## High-Priority Gaps

| Priority | Gap | Execution Status | Why it matters | Suggested implementation slice |
| --- | --- | --- | --- | --- |
| P1 | Archive write-back parity (ERF/RIM/MOD workflows) | Shipped (Q4) | Unlocks full round-trip mod packaging workflows. | Serializer + saver parity plan for archive families using existing `ResourceFormatSaver` and pipeline write/export flows. |
| P1 | Cross-format dependency tooling expansion | Shipped (Q1–Q5) | Current helpers cover selected contexts; broader dependency-edit support improves reliability. | Expand dependency-list and rename utilities to additional typed document flows with shared document mutation primitives. |
| P1 | Stronger reload/consistency scenarios | Shipped (Q2) | Prevents subtle state drift after install/restore/edit loops. | Add targeted cache/reload behavior tests around mutation pipeline, session restore, and install-aware reindex boundaries. |
| P2 | Authoring ergonomics for complex typed docs | Shipped (Q6–Q12) | Reduces manual error risk in larger content edits. | Struct/array editing, typed pickers, enum registry, inventory/skill/feat arrays, feat/skill 2DA labels. |
| P2 | Contributor-facing parity matrix maintenance process | Shipped (Q1–Q5) | Keeps roadmap clear as format support grows. | Maintain this document and plan links whenever a new format/editor capability lands. |

For detailed readiness criteria and dependencies, see [docs/50-execution/godot-capability-execution-queue.md](docs/50-execution/godot-capability-execution-queue.md).

## What Else Godot Supports (Relevant Next Opportunities)

These are Godot capabilities that can be leveraged further in this plugin architecture:

1. Expanded import/saver ecosystems (`EditorImportPlugin`, `ResourceFormatSaver`) for additional format families.
2. Richer editor automation through `@tool` scripts and editor plugin lifecycle hooks.
3. More explicit custom resource loading strategies where runtime/editor behavior diverges.
4. Stronger end-to-end editor mutation validation via script-driven tests and deterministic fixtures.

## Implementation-Ready Godot Capability Opportunities

| Godot capability | Repository fit | Candidate implementation area |
| --- | --- | --- |
| `EditorUndoRedoManager` integration | Workspace editors already centralize mutation paths through documents. | Add explicit undo/redo command framing for GFF/DLG/2DA/TLK document edits and ensure transaction history interop stays coherent. |
| `EditorInspectorPlugin` + custom property editors | Typed resources/documents already expose structured fields and validation hooks. | Build inspector-assisted editing widgets for common GFF patterns (locstrings, ResRef references, enum-like integer fields). |
| `EditorFileSystem` and rescan hooks | Install/export actions already modify files and refresh GameFS state. | Trigger targeted reindex/rescan pathways after install/restore actions to reduce stale-surface windows. |
| `EditorContextMenuPlugin` / dock action integration | Resource browser and workspace actions are already command-oriented. | Add context actions for compare/install/export from more surfaces without duplicating pipeline logic. |
| `SubViewport` + scene preview workflows | Area tools already surface module relationships and model checks. | Add lightweight area/entity preview panes for supported model resources, gated behind explicit "preview" actions. |
| `EditorSettings` profile-backed preferences | Plugin already has install-path and workspace settings concerns. | Add per-project and global preference boundaries for game-install profiles, recent modules, and editor ergonomics. |

## Next Planning Seeds

For Phase 2 and beyond, use these reference documents in order:

1. **Execution queue:** [docs/50-execution/godot-capability-execution-queue.md](docs/50-execution/godot-capability-execution-queue.md) — Shipped slices (Q1–Q123 on `main`; Q124–Q126 on PR #119) and active/deferred next slices with readiness criteria and dependencies.
2. **Requirement source:** [docs/brainstorms/2026-05-24-godot-support-expansion-requirements.md](docs/brainstorms/2026-05-24-godot-support-expansion-requirements.md) — Detailed requirement grounding for the next implementation wave (when Q6+ readiness criteria are met).
3. **This document:** Gap inventory and Godot capability opportunities for strategic context.

## Refresh Triggers

Refresh this analysis when:

- Godot target version changes.
- New format parser/importer/saver capabilities ship.
- Workspace/editor surfaces gain or remove major behavior.
