---
title: "feat: Q63 Module Designer PTH preview export"
type: feat
status: completed
date: 2026-06-05
origin: lfg-next-after-q62-auto-selected
phase: Q63
track: Module/Area Designer
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-06-05-035-feat-q62-vis-preview-export-plan.md
  - docs/plans/2026-06-05-033-feat-q60-pth-install-override-plan.md
---

# Q63: Module Designer PTH Preview Export

## Summary

Add **Export PTH Preview…** in Module Designer so modders can save the loaded area path graph to a filesystem `.pth` file for inspection or external tooling.

---

## Problem Frame

Q60 shipped PTH install-to-override, and Q61–Q62 shipped LYT/VIS preview export. Module Designer still lacks the non-destructive export path for the currently loaded PTH graph, leaving install as the only PTH write-back workflow on this surface.

---

## Scope Boundaries

### In scope

- Module Designer **Export PTH Preview…** toolbar action and write helper
- Headless `tests/editor/test_module_designer_pth_export.gd`
- Execution queue + parity matrix Q63 entry

### Deferred

- PTH editing UI
- Path-node/edge visualization changes
- Broader generic GFF workspace export UX changes

### Out of scope

- Indoor Builder changes
- PTH serializer changes beyond existing GFF-family write path
- Install-to-override behavior changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Export fails when no PTH is loaded | Unit test |
| R2 | Export writes the loaded path graph to a `.pth` file, adding the extension when omitted | Unit test |
| R3 | Exported bytes round-trip through `GFFParser`/`PTHResource` with matching point data | Unit test |
| R4 | Toolbar **Export PTH Preview…** is wired in Module Designer | Wiring |
| R5 | Docs mark Q63 shipped | Doc diff |

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_module_designer_pth_export.gd
godot --headless --path . --script tests/editor/test_gff_resource_factory.gd
```
