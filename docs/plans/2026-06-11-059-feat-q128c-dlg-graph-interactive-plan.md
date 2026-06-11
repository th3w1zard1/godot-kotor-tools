---
title: "feat: Q128c DLG interactive graph depth"
type: feat
status: completed
date: 2026-06-11
origin: docs/plans/2026-06-10-058-feat-q128-dlg-graph-editor-depth-plan.md
phase: Q128c
track: OpenKotOR Parity
parent: docs/plans/2026-06-10-058-feat-q128-dlg-graph-editor-depth-plan.md
related:
  - docs/plans/2026-06-04-006-feat-q33-dlg-jump-to-target-plan.md
---

# Q128c: DLG Interactive Graph Depth

## Summary

Complete the deferred Holocron graph interactions in phased vertical slices after Q128b read-only graph: back-navigation for jump-to-target, bulk reference removal, interactive port linking, and orphan drag-restore.

---

## Problem Frame

Q33 jump-to-target and Q128b graph selection help modders orient in large DLGs, but there is no way to return to the prior node after a jump. Holocron also supports reference cleanup before deletion, graph link dragging, and orphan restore — all still missing in Godot.

---

## Phased Units

### Q128c1 — Back-navigation stack (implement first)

**Goal:** After jump-to-target, **Back** restores the prior tree/graph selection.

**Files:**
- `ui/workspace/editors/dlg_workspace_editor.gd`
- `tests/editor/test_dlg_workspace_editor.gd`

**Approach:** Push `_dlg_selection` snapshot before successful `_jump_to_link_target`; toolbar **Back** pops stack and calls `_select_dlg_metadata`. Clear stack on `open_resource`.

**Test scenarios:**
- Jump pushes prior link selection; Back restores it
- Failed jump does not push
- Back on empty stack is no-op

---

### Q128c2 — Delete all references menu

**Goal:** Context action on entry/reply nodes calling `remove_all_references_to_node` (orphan without delete).

**Files:** `dlg_workspace_editor.gd`, tests

---

### Q128c3 — Graph port drag-connect

**Goal:** Allow `connection_request` on `KotorDLGGraphView` to append typed link structs with undo.

**Files:** `dlg_graph_view.gd`, `kotor_dlg_document.gd`, `dlg_workspace_editor.gd`, tests

---

### Q128c4 — Orphan drag-restore

**Goal:** Holocron-style restore orphan by linking from selected tree node (enhance orphan dock UX).

**Files:** `dlg_workspace_editor.gd` (mostly shipped in Q128a — verify parity gaps)

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_dlg_workspace_editor.gd
godot --headless --path . --script tests/editor/test_dlg_graph_layout.gd
```
