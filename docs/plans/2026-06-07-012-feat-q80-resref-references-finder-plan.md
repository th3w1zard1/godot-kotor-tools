---
title: "feat: Q80 install ResRef references finder"
type: feat
status: completed
date: 2026-06-07
origin: lfg-next-after-q79-auto-selected
phase: Q80
track: Advanced Utility Tools
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-07-011-feat-q79-batch-tpc-export-plan.md
---

# Q80: Install ResRef References Finder

## Summary

Add override-scoped **Find References** to the workspace resource browser — scan indexed GFF and NSS override files for a selected resref and show formatted field-path hit reports.

---

## Problem Frame

Holocron/PyKotor reference tools help modders trace blueprint dependencies. The Godot plugin can browse and compare resources but cannot answer "where is this resref used?" without leaving the workspace.

---

## Scope Boundaries

### In scope

- `KotorResRefReferenceScanner.scan_install_references()`
- GFF recursive field walk + NSS text scan in override index
- Resource browser **Find References** action and formatted detail report
- Headless `tests/editor/test_resref_reference_scanner.gd`
- Execution queue + parity matrix Q80 entry

### Deferred

- Full-install (modules/chitin) scan
- 2DA/TLK StrRef reference tracing
- Open-hit navigation from report lines

### Out of scope

- PyKotor CLI reference tool bridge
- Modulekit / texture batch utilities

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Scanner finds GFF resref field matches case-insensitively | Unit test |
| R2 | Scanner finds NSS substring matches for `.nss` override files | Unit test |
| R3 | Resource browser exposes Find References on selection | Wiring test |
| R4 | Report lists file + field paths for hits | Unit test |
| R5 | Docs mark Q80 shipped | Doc diff |

---

## Implementation Units

### U1 — Reference scanner

- **Files:** `editor/tools/kotor_resref_reference_scanner.gd`

### U2 — Resource browser action

- **Files:** `ui/workspace/panels/resource_browser_panel.gd`, `editor/workspace/kotor_target_context.gd`

### U3 — Tests + docs

- **Files:** `tests/editor/test_resref_reference_scanner.gd`, execution queue, parity matrix

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_resref_reference_scanner.gd
```
