---
title: "feat: Q148 DLG graph fit view and selection focus"
type: feat
status: completed
date: 2026-06-13
origin: lfg-next-after-q147-auto-selected
phase: Q148
track: OpenKotOR Parity
parent: docs/plans/2026-06-10-058-feat-q128-dlg-graph-editor-depth-plan.md
related:
  - ui/workspace/panels/dlg_graph_view.gd
  - ui/workspace/editors/dlg_workspace_editor.gd
  - tests/editor/test_dlg_graph_layout.gd
---

# Q148: DLG Graph Fit View and Selection Focus

## Summary

Add bounded DLG graph navigation polish: **Fit Graph** toolbar action and automatic scroll focus when tree selection maps to an entry/reply graph node. Closes a slice of the P1 DLG graph depth gap without minimap or animated edges.

## Problem Frame

Q128b–c shipped read-only/interactive graph layout, port linking, and tree sync on graph click. Large DLGs still require manual panning to find the selected node after tree navigation or jump-to-target. Holocron graph view includes viewport framing behaviors; Godot has no fit/minimap yet.

## Requirements Trace

| ID | Requirement | Plan coverage |
| --- | --- | --- |
| R1 | `KotorDLGGraphView.fit_all_nodes()` frames all graph nodes in the viewport | U1 |
| R2 | `KotorDLGGraphView.focus_metadata()` scrolls to entry/reply node for tree selection | U1 |
| R3 | Toolbar **Fit Graph** visible when graph view toggled on | U2 |
| R4 | Tree selection sync calls graph focus when graph view active | U2 |
| R5 | Headless tests for layout bounds + scroll offset helpers | U3 |
| R6 | Execution queue + gap audit note partial DLG graph polish | U4 |

## Implementation Units

### U1. Graph view framing helpers

**Files:** `ui/workspace/panels/dlg_graph_view.gd`

- `static compute_layout_bounds(layout, default_node_size)`
- `static compute_center_scroll_offset(bounds, viewport_size)`
- `fit_all_nodes()` using live `GraphNode` rects when present, else layout positions
- `focus_metadata(metadata)` for `entry`/`reply` kinds only

### U2. DLG editor wiring

**Files:** `ui/workspace/editors/dlg_workspace_editor.gd`

- **Fit Graph** toolbar button after Graph View toggle
- `_on_fit_graph_pressed()` calls `fit_all_nodes()`
- `_sync_graph_focus_to_selection()` from `_select_dlg_metadata` and graph toggle on

### U3. Tests

**Files:** `tests/editor/test_dlg_graph_layout.gd`

- Bounds union over fixture layout nodes
- Center scroll offset math
- `focus_metadata` no-op for link/start kinds

### U4. Doc authority

**Files:** `docs/50-execution/godot-capability-execution-queue.md`, `docs/30-gap-analysis/godot-support-gaps.md`

## Verification

```bash
godot --headless --path . --script tests/editor/test_dlg_graph_layout.gd
godot --headless --path . --script tests/editor/test_dlg_workspace_editor.gd
```

## Out of Scope

- Minimap, animated edges, zoom slider
- TSL-only DLG fields
- Graph node drag reposition
