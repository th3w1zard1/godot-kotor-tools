---
title: "feat: Holocron parity Wave I — platform integration"
type: feat
status: active
date: 2026-06-13
origin: holocron-parity-backlog-roadmap
phase: Q168-Q169
track: OpenKotOR Parity
parent: docs/50-execution/holocron-parity-backlog-roadmap.md
related:
  - ui/kotor_dock.gd
  - ui/workspace/kotor_workspace_shell.gd
  - plugin.gd
---

# Wave I: Platform & Godot Integration (Q168–Q169)

## Summary

Retire duplicate legacy dock flows and wire Godot-native editor plugins for GFF field patterns.

## Requirements

| ID | Requirement | Slice |
| --- | --- | --- |
| R1 | Migrate unique legacy dock flows into workspace shell | Q168 |
| R2 | Remove duplicate DLG/2DA/TLK/Script editors in dock | Q168 |
| R3 | Single navigation model in `kotor_workspace_shell.gd` | Q168 |
| R4 | `EditorInspectorPlugin` for locstring, ResRef, enum GFF fields | Q169 |
| R5 | `EditorContextMenuPlugin` — compare/install/export from filesystem | Q169 |
| R6 | `EditorFileSystem` targeted rescan after install | Q169 |
| R7 | Unify `EditorSettings` profiles (install, modules, kits) | Q169 |

## Q168 — Legacy dock migration

**Files:**
- `ui/kotor_dock.gd` — deprecate or thin to redirect-only
- `kotor_workspace_shell.gd` — absorb Area Tools / batch compare entry points
- `tests/editor/test_kotor_workspace_shell.gd`

**Acceptance:** No unique edit loop exists only in legacy dock.

## Q169 — Inspector & context menu plugins

**Files:**
- `addons/kotor_tools/editor/kotor_inspector_plugin.gd` (new)
- `addons/kotor_tools/editor/kotor_context_menu_plugin.gd` (new)
- `plugin.gd` — register plugins

## Verification

```bash
godot --headless --path . --script tests/editor/test_kotor_workspace_shell.gd
bash scripts/run_headless_editor_tests.sh
```

## Out of scope

- Godot Asset Library packaging (separate release track)
- Pixel-perfect Holocron window layout
