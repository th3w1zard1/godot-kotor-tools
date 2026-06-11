# PR #51 — feat(module): inspect area PTH connections

> Q67: Module Designer PTH connection inspection

## Summary

Q67 makes loaded area path **connections** first-class inspectable items in Module Designer. After Q65 (connection overlay) and Q66 (point inspection), modders could see path topology but could not select or inspect individual edges. This PR closes that gap with tree, map, and 3D selection sync plus structured detail for each connection.

## Problem

PTH edges were visible as overlays only. There was no way to:

- Browse connections in the instance tree
- Click an edge on the 2D map or 3D viewport to inspect it
- See source/target point IDs and coordinates without reading raw GFF bytes

## What changed

### Module Designer workspace (`module_designer_workspace_editor.gd`)

- Adds a **Path Connections** tree group when `.pth` data is loaded
- Each connection is labeled with source → target point IDs (e.g. `Connection 1: 2 -> 3`)
- Detail panel shows connection index, source/target point IDs, and 3D coordinates
- Selection clears and syncs correctly alongside GIT instances and path points

### 2D map (`module_designer_map_view.gd`)

- Path connections are pickable via click
- Selected edge is highlighted distinctly from points and GIT instances
- Emits `path_connection_selected` for workspace sync

### 3D viewport (`module_designer_viewport_3d.gd`)

- Path connections are pickable in the 3D overlay
- Selected edge renders a `SelectedPathEdge` highlight mesh
- Emits `path_connection_selected` for workspace sync

### Docs & tests

- Plan: `docs/plans/2026-06-05-040-feat-q67-pth-connection-inspection-plan.md`
- Parity matrix + execution queue updated to mark Q67 shipped
- Headless regression: `tests/editor/test_module_designer_pth_connection_inspection.gd`

## Out of scope

- Path point or edge **editing** (deferred to Q68)
- Install/export behavior changes
- Walkmesh/layout editing changes

## Verification

```bash
godot --headless --path . --script tests/editor/test_module_designer_pth_connection_inspection.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_point_inspection.gd
godot --headless --path . --script tests/editor/test_module_designer_pth_connection_overlay.gd
```

## Parity context

Part of the Module Designer PTH workflow sequence:

| Phase | Capability |
| --- | --- |
| Q64 | PTH point overlay |
| Q65 | PTH connection overlay |
| Q66 | PTH point inspection |
| **Q67** | **PTH connection inspection** (this PR) |
