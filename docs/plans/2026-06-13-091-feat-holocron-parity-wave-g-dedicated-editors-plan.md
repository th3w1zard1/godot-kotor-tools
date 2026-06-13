---
title: "feat: Holocron parity Wave G — dedicated JRL/PTH/FAC editors"
type: feat
status: active
date: 2026-06-13
origin: holocron-parity-backlog-roadmap
phase: Q162-Q164
track: OpenKotOR Parity
parent: docs/50-execution/holocron-parity-backlog-roadmap.md
related:
  - ui/workspace/kotor_workspace_shell.gd
  - ui/workspace/editors/gff_workspace_editor.gd
  - resources/documents/kotor_gff_document.gd
---

# Wave G: Dedicated JRL / PTH / FAC Editors (Q162–Q164)

## Summary

Exit generic GFF-only routing for journal, path, and faction files. Holocron ships `jrl.py`, `pth.py`, `fac.py` with domain-specific panels.

## Godot today

- Typed GFF documents exist; opens route through `gff_workspace_editor.gd`
- Module Designer covers area PTH but not standalone `.pth` file UX

## Requirements

| ID | Requirement | Slice |
| --- | --- | --- |
| R1 | `jrl_workspace_editor.gd` — quest list CRUD, entry states | Q162 |
| R2 | `pth_workspace_editor.gd` — waypoint list, 2D path preview | Q163 |
| R3 | `fac_workspace_editor.gd` — faction reputation matrix UX | Q164 |
| R4 | Shell routing: `.jrl`/`.pth`/`.fac` → dedicated editors | All |
| R5 | Headless tests per editor | All |

## Q162 — JRL editor

**Holocron parity:** Journal quest tree, priority, XP hooks summary panel.

**Files:**
- `ui/workspace/editors/jrl_workspace_editor.gd` (new)
- `kotor_workspace_shell.gd` — register editor
- `tests/editor/test_jrl_workspace_editor.gd`

## Q163 — PTH editor

**Holocron parity:** Standalone path file waypoint editor with map overlay.

**Files:**
- `ui/workspace/editors/pth_workspace_editor.gd` (new)
- Reuse module designer path rendering where possible

## Q164 — FAC editor

**Holocron parity:** Faction rows, reputation defaults, hostile/friendly matrix.

**Files:**
- `ui/workspace/editors/fac_workspace_editor.gd` (new)

## Verification

```bash
godot --headless --path . --script tests/editor/test_jrl_workspace_editor.gd
godot --headless --path . --script tests/editor/test_pth_workspace_editor.gd
godot --headless --path . --script tests/editor/test_fac_workspace_editor.gd
```
