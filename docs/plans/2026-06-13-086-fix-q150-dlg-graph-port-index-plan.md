---
title: "fix: Q150 DLG graph port index alignment"
type: fix
status: active
date: 2026-06-13
origin: lfg-next-after-q149-auto-selected
phase: Q150
track: OpenKotOR Parity
parent: docs/plans/2026-06-13-084-feat-q148-dlg-graph-fit-view-plan.md
related:
  - ui/workspace/panels/dlg_graph_view.gd
  - tests/editor/test_dlg_graph_layout.gd
---

# Q150: DLG Graph Port Index Alignment

## Summary

Fix DLG graph edge wiring to use slot **0** for both output and input ports. Q128c3 used port `1` for outputs, but `GraphNode.set_slot(0, …)` exposes only one right output port at index 0 — causing runtime port errors and broken visual connections after Q148 layout rebuilds.

## Problem Frame

Headless graph tests after Q148 logged `p_port_idx = 1 is out of bounds (right_port_cache.size() = 1)`. `connect_node` and `connection_request` handlers must align with Godot `GraphNode` slot indexing.

## Requirements Trace

| ID | Requirement | Plan coverage |
| --- | --- | --- |
| R1 | `build_from_layout` connects edges with from_port/to_port `0` | U1 |
| R2 | `_on_connection_request` accepts output port `0` | U1 |
| R3 | Headless test asserts connection count after layout build | U2 |
| R4 | Execution queue + gap audit note graph polish increment | U3 |

## Implementation Units

### U1. Port index fix

**Files:** `ui/workspace/panels/dlg_graph_view.gd`

### U2. Tests

**Files:** `tests/editor/test_dlg_graph_layout.gd`

### U3. Doc authority

**Files:** `docs/50-execution/godot-capability-execution-queue.md`, `docs/30-gap-analysis/godot-support-gaps.md`

## Verification

```bash
godot --headless --path . --script tests/editor/test_dlg_graph_layout.gd
```

## Out of Scope

- Minimap, zoom slider, animated edges
- Multi-slot graph nodes
