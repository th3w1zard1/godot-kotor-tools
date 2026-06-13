---
title: "feat: Holocron parity Wave B — BIF/KEY archives"
type: feat
status: active
date: 2026-06-13
origin: holocron-parity-backlog-roadmap
phase: Q151-Q152
track: OpenKotOR Parity
parent: docs/50-execution/holocron-parity-backlog-roadmap.md
related:
  - formats/key_bif_parser.gd
  - gamefs/kotor_gamefs.gd
  - ui/workspace/editors/erf_workspace_editor.gd
  - ui/workspace/panels/resource_browser_panel.gd
---

# Wave B: BIF/KEY Archive Parity (Q151–Q152)

## Summary

Close the P1 archive gap beyond ERF/RIM/MOD by shipping BIF member extract and KEY/chitin browse utilities matching Holocron `bif`/`key` workflows.

## Holocron reference

- PyKotor `extract/chitin` + KEY/BIF index flows
- Holocron archive browsing from base game data

## Requirements

| ID | Requirement | Slice |
| --- | --- | --- |
| R1 | Extract single BIF catalog member to override via mutation pipeline | Q151 |
| R2 | Batch extract BIF members to override or folder (mirror ERF Q138/Q139) | Q151 |
| R3 | Open BIF catalog resource in correct workspace editor from browser | Q151 |
| R4 | Read-only KEY inspector: list BIF entries, resref lookup | Q152 |
| R5 | Resource browser KEY/chitin mode with install-rooted paths | Q152 |
| R6 | Headless tests + parity matrix archive row update | Both |

## Q151 — BIF member extract

**Files:**
- `gamefs/kotor_gamefs.gd` — `extract_bif_member_to_override`, batch helpers
- `ui/workspace/panels/resource_browser_panel.gd` — extract actions on catalog rows
- `tests/editor/test_gamefs_chitin_catalog.gd` — extract paths

**Pattern:** Mirror [erf_workspace_editor.gd](ui/workspace/editors/erf_workspace_editor.gd) extract + preflight; reuse `KotorMutationService`.

## Q152 — KEY browse / inspect

**Files:**
- `ui/workspace/panels/resource_browser_panel.gd` — KEY file open mode
- New `ui/workspace/panels/key_inspector_panel.gd` or lightweight dialog
- `tests/editor/test_key_bif_parser.gd` — KEY round-trip browse

## Verification

```bash
godot --headless --path . --script tests/editor/test_gamefs_chitin_catalog.gd
godot --headless --path . --script tests/editor/test_key_bif_parser.gd
```

## Out of scope

- BIF write-back / repacking (K1 extract-only unless product requests)
- K2 KEY variants (Q200+ track)
