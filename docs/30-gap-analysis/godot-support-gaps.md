# Godot Support Gaps and Next Implementation Areas

## Purpose

This document answers two recurring planning questions:

1. What Godot-facing capabilities are already supported in `godot-kotor-tools`?
2. What implementation gaps should be prioritized next?

Project target: **Godot 4.6**.

## Current Support Snapshot

| Capability Area | Status | Notes |
| --- | --- | --- |
| Custom format parsing (GFF, ERF/RIM, 2DA, TLK, TPC, KEY/BIF, LYT) | **Supported** | Core parser stack exists in `formats/`. |
| Resource wrappers for editor/runtime access | **Supported** | `resources/` provides generic and typed wrappers for key formats. |
| Editor import integration | **Supported** | Importer plugins exist for major user-facing formats. |
| Save/write-back for editable formats | **Partial** | 2DA/TLK/GFF-family write-back supported; archive-style write-back paths are limited. |
| Install-aware browsing and precedence | **Supported** | `KotorGameFS` indexes install sources and applies override precedence. |
| Workspace editors (DLG, 2DA, TLK, NSS, area tools) | **Supported** | Core workspace surfaces are shipped and routable. |
| Browser-like visual verification for UI surfaces | **Missing** | Repo has no web surface; UI validation relies on Godot script tests and editor flows. |

## High-Priority Gaps

| Priority | Gap | Why it matters | Suggested implementation slice |
| --- | --- | --- | --- |
| P1 | Archive write-back parity (ERF/RIM/MOD workflows) | Limits full round-trip mod packaging workflows. | Add serializer + saver parity plan for archive families using existing saver patterns. |
| P1 | Cross-format dependency tooling expansion | Current helpers cover selected contexts; broader dependency-edit support improves reliability. | Expand dependency-list and rename utilities to additional typed document flows. |
| P1 | Stronger reload/consistency scenarios | Prevents subtle state drift after install/restore/edit loops. | Add targeted cache/reload behavior tests around mutation pipeline and workspace documents. |
| P2 | Authoring ergonomics for complex typed docs | Reduces manual error risk in larger content edits. | Add validation helpers and guided editing affordances in typed document wrappers. |
| P2 | Contributor-facing parity matrix maintenance process | Keeps roadmap clear as format support grows. | Maintain this document and plan links whenever a new format/editor capability lands. |

## What Else Godot Supports (Relevant Next Opportunities)

These are Godot capabilities that can be leveraged further in this plugin architecture:

1. Expanded import/saver ecosystems (`EditorImportPlugin`, `ResourceFormatSaver`) for additional format families.
2. Richer editor automation through `@tool` scripts and editor plugin lifecycle hooks.
3. More explicit custom resource loading strategies where runtime/editor behavior diverges.
4. Stronger end-to-end editor mutation validation via script-driven tests and deterministic fixtures.

## Refresh Triggers

Refresh this analysis when:

- Godot target version changes.
- New format parser/importer/saver capabilities ship.
- Workspace/editor surfaces gain or remove major behavior.

