---
title: "feat: Holocron parity Wave H — NSS, diff, LTR tooling"
type: feat
status: active
date: 2026-06-13
origin: holocron-parity-backlog-roadmap
phase: Q165-Q167
track: OpenKotOR Parity
parent: docs/50-execution/holocron-parity-backlog-roadmap.md
related:
  - ui/workspace/editors/nss_workspace_editor.gd
  - ui/workspace/panels/compare_panel.gd
  - ui/workspace/editors/ltr_workspace_editor.gd
---

# Wave H: Tooling Polish (Q165–Q167)

## Summary

Holocron workflow depth for NSS decompile/diagnostics, in-editor diff viewing, and LTR procedural preview.

## Requirements

| ID | Requirement | Slice |
| --- | --- | --- |
| R1 | In-editor decompile output pane with line mapping | Q165 |
| R2 | Compile error → source line navigation | Q165 |
| R3 | Optional NCS bytecode disassembly panel | Q165 |
| R4 | In-editor diff report viewer (not export-only) | Q166 |
| R5 | LTR procedural name generation preview | Q167 |
| R6 | LTR probability grid UX + sum validation | Q167 |

## Q165 — NSS decompile pane

**Files:**
- `nss_workspace_editor.gd` — decompile tab, error list → source jump
- CLI bridge output surfaced in docked `RichTextLabel` / `CodeEdit`
- `tests/editor/test_nss_workspace_editor.gd`

## Q166 — In-editor diff viewer

**Files:**
- `compare_panel.gd` or new `diff_report_viewer.gd`
- Parse KotorDiff / semantic compare output into navigable tree
- `tests/editor/test_compare_panel.gd`

## Q167 — LTR preview

**Files:**
- `ltr_workspace_editor.gd` — **Generate Sample Names** from table
- Grid view for doubles/triples matrices
- `tests/editor/test_ltr_workspace_editor.gd`

## Verification

```bash
godot --headless --path . --script tests/editor/test_nss_workspace_editor.gd
godot --headless --path . --script tests/editor/test_ltr_workspace_editor.gd
```

## Out of scope

- TSLPatcher authoring UI (defer to platform wave or Q170+)
- DDS import path (media long-tail)
