---
title: "feat: Q128 DLG graph editor depth"
type: feat
status: active
shipped_units:
  - Q128a
date: 2026-06-10
origin: docs/plans/2026-06-10-056-feat-pr-stack-merge-holocron-parity-roadmap-plan.md
phase: Q128
track: OpenKotOR Parity
parent: docs/plans/2026-06-10-056-feat-pr-stack-merge-holocron-parity-roadmap-plan.md
related:
  - docs/plans/2026-05-24-010-feat-q6-dlg-struct-array-editing-plan.md
  - docs/plans/2026-06-04-006-feat-q33-dlg-jump-to-target-plan.md
  - docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
---

# Q128: DLG Graph Editor Depth

## Summary

Close the largest remaining DLG parity gap versus Holocron by delivering **node-level CRUD** (add/remove Entry and Reply nodes), **orphan/reference hygiene**, and a **read-only graph canvas** in phased vertical slices. Q6 covers in-node link array editing; Q33 covers jump-to-target navigation. Q128 adds the structural authoring loop Holocron users expect when branching dialogue — without porting Qt's full node-editor UX in one pass.

---

## Problem Frame

**[REPO]** `KotorDLGWorkspaceEditor` is tree-only: modders can edit scalars, reorder `RepliesList`/`EntriesList` link arrays (Q6), and jump to link targets (Q33), but cannot add or remove top-level Entry/Reply nodes, manage `StartingList` entries, or visualize the dialogue as a graph.

**[REPO]** `KotorDLGDocument` exposes read helpers (`get_node_list`, `get_link_target_metadata`, `validate`) and generic GFF struct-array insert/remove via `KotorGFFDocument.insert_struct_at_array`, but has no DLG-specific defaults, index-rewiring, or orphan detection.

**[UI/Holocron]** Holocron `editors/dlg/` ships dual surfaces (`DLGViewSwitcher`: tree ↔ graph), a `DialogueNodeEditor` graph canvas with ports/connections, context-menu **Add Entry**, orphan-node dock (`orphaned_nodes_list`), **restore orphan** / **delete orphaned node permanently**, and bulk **delete all references** before removal. Evidence: `OpenKotOR/HolocronToolset` paths `editor.py`, `node_editor.py`, `view_switcher.py` (audited 2026-06-10).

**[SYNTH]** Minimum viable Godot parity is **tree-first node CRUD + validation** (Q128a), then **read-only graph layout** synced from the document (Q128b). Interactive graph link dragging and full orphan drag-restore match Holocron's Qt graph editor and belong in Q128c+ unless Q128b proves cheap with `GraphEdit`.

---

## Holocron Audit (2026-06-10)

| Holocron capability | Godot today | Q128 target |
| --- | --- | --- |
| Tree view editing | Shipped (Q1–Q6) | Maintain |
| Jump-to-target on links | Shipped (Q33) | Maintain |
| Add Entry / Add Reply (top-level nodes) | Missing | **Q128a** |
| Remove node + reference cleanup | Missing | **Q128a** |
| Orphan list + restore / permanent delete | Missing | **Q128a** (list + restore); permanent delete **Q128c** |
| StartingList add/remove | Partial (array context menu on nested fields only) | **Q128a** toolbar |
| Tree ↔ graph view switch | Missing | **Q128b** |
| Graph node drag, port connect, animated edges | Missing | **Deferred Q128c** |
| Search / reference finder | Missing | Deferred (Holocron `search_manager.py`) |
| Copy/paste node subgraph | Missing | Deferred (Holocron `NodeCopyData`) |

---

## Scope Boundaries

### In scope (Q128 program)

- Document APIs: `add_entry`, `add_reply`, `remove_entry`, `remove_reply`, `add_start`, `remove_start`, default struct templates, link-index repair helpers, `find_orphaned_nodes()`, `remove_all_references_to_node()`
- Tree toolbar + context menu: Add Entry, Add Reply, Remove Node, Add Start
- Orphan panel listing nodes with zero incoming links (excluding valid starts)
- Read-only graph tab: auto-layout Entry/Reply nodes, draw edges from link `Index` fields, click node selects tree row
- Headless tests for document CRUD, reference cleanup, orphan detection, graph metadata builder
- Execution queue + parity matrix updates per shipped sub-slice

### Deferred (Q128c or later)

- Interactive graph link creation/deletion (drag port to port)
- Orphan drag-restore from dock onto tree selection (Holocron `restore_orphaned_node`)
- Back-navigation stack for jump-to-target
- Broken-link auto-repair wizard
- DLG search / cross-file reference finder
- Node duplicate / copy-paste subgraph
- Minimap, animated edges, resize handles

### Out of scope

- Rewriting Q6 array mutation paths
- NCS script editor integration inside DLG nodes
- PyKotor/Holocron file format changes

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `add_entry` / `add_reply` append typed default structs to `EntryList` / `ReplyList` | Headless document test |
| R2 | `remove_entry` / `remove_reply` remove node and scrub stale link `Index` values pointing at removed index | Headless test + `validate()` clean |
| R3 | `remove_all_references_to_node` removes incoming links without deleting the target node (orphan) | Headless test |
| R4 | `find_orphaned_nodes` returns entries/replies with no incoming links (per Holocron rules) | Headless test |
| R5 | Editor toolbar exposes Add Entry / Add Reply / Remove Node with undo | Editor test or headless controller hook |
| R6 | Orphan list panel selects orphan; Restore wires link from selected tree parent | Manual + test hook |
| R7 | Graph tab renders nodes and edges read-only; node click selects tree item | Headless graph builder test |
| R8 | Q128a–b documented in execution queue; parity matrix DLG row updated | Doc diff |

---

## Key Technical Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| KTD1 | Phased delivery: Q128a (CRUD) before Q128b (graph) | Unblocks structural editing without GraphEdit complexity |
| KTD2 | Document owns index repair and orphan logic | Keeps editor thin; headless-testable; mirrors `KotorGITDocument` CRUD pattern |
| KTD3 | Default Entry/Reply structs from GFF factory or inline schema | Match Q6 reply/link defaults; avoid empty invalid nodes on add |
| KTD4 | Graph layout: layered DAG on Entry/Reply indices | Good enough for read-only; no force-directed sim in Q128b |
| KTD5 | Godot `GraphEdit` + `GraphNode` for Q128b | Native editor control; defer custom port wiring to Q128c |
| KTD6 | Undo via existing `EditorUndoRedoManager` do/undo on document methods | Consistent with Q6 array undo and Q124 GIT CRUD |

---

## Phased Implementation Units

### Q128a — Node CRUD and orphan hygiene (implement first)

**Goal:** Holocron-aligned add/remove Entry/Reply/Start with reference-safe mutations.

**Files:**

- `resources/documents/kotor_dlg_document.gd` — CRUD + orphan/reference helpers
- `ui/workspace/editors/dlg_workspace_editor.gd` — toolbar, orphan dock, wiring
- `tests/editor/test_dlg_workspace_editor.gd` — CRUD, cleanup, orphan tests

**Approach:**

1. Add `create_default_entry_struct()` / `create_default_reply_struct()` / `create_default_start_struct()` static or document methods (empty locstring, empty link arrays, valid script field placeholders per Q6 schema).
2. `add_entry()` / `add_reply()` call `insert_struct_at_array("EntryList"|"ReplyList", size, default)` and return new index.
3. `remove_entry(index)` / `remove_reply(index)`:
   - Option A (Holocron default): call `remove_all_references_to_node` first → node becomes orphan → user deletes from orphan list OR
   - Option B (simple): scrub all links with `Index == index` and decrement indices `> index` across all link lists and `StartingList`.
   - **Pick Option B for Q128a** with toolbar confirm dialog; orphan dock shows nodes after reference-only removal.
4. Orphan dock: `ItemList` bound to `find_orphaned_nodes()`; selecting item highlights tree; **Restore** adds link from currently selected tree node (mirror Holocron `restore_orphaned_node` simplified).
5. Toolbar: Add Entry, Add Reply, Add Start, Remove Selected Node.

**Test scenarios:**

- Add entry → count increases; new entry validates
- Add reply linked from entry 0 → link `Index` resolves
- Remove entry 0 with two incoming links → links scrubbed or indices repaired; `validate()` passes
- `find_orphaned_nodes` after `remove_all_references_to_node` includes expected node
- Undo/redo round-trip on add + remove

---

### Q128b — Read-only graph canvas

**Goal:** Tree ↔ graph toggle; visualize dialogue structure for orientation.

**Files:**

- `ui/workspace/panels/dlg_graph_view.gd` (new)
- `ui/workspace/editors/dlg_workspace_editor.gd` — tab or split toggle
- `resources/documents/kotor_dlg_document.gd` — `build_graph_layout_metadata()` returning nodes/edges
- `tests/editor/test_dlg_graph_layout.gd` (new)

**Approach:**

1. Document method returns `{nodes: [{id, kind, index, label, pos}], edges: [{from_id, to_id, link_index}]}` using simple column layout (entries left, replies right).
2. `DlgGraphView` extends `GraphEdit`, sets `mouse_filter` read-only, populates `GraphNode` children, draws `GraphEdit.connect_node` for each edge.
3. `node_selected` → call editor `_select_dlg_metadata(kind, index)`.
4. Toggle button **Graph View** alongside existing tree (no Holocron dock parity required).

**Test scenarios:**

- Layout builder produces node count == entry + reply count
- Edge count matches total link count with valid targets
- Invalid link targets omitted from edges (validation warning still in tree)

---

### Q128c — Interactive graph (deferred child plan)

- Port drag-connect, orphan drag-restore, delete-all-references menu, back-nav stack
- Spawn `docs/plans/2026-06-XX-XXX-feat-q129-dlg-graph-interactive-plan.md` when Q128b ships

---

## Dependencies

- Q6 struct/array editing (shipped)
- Q33 jump-to-target (shipped)
- Q127 ERF workspace (shipped on PR #119) — sequencing gate only

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_dlg_workspace_editor.gd
godot --headless --path . --script tests/editor/test_dlg_graph_layout.gd
```

After Q128a ships, grep headless output for `Assertion failed` / `SCRIPT ERROR` before claiming green.

---

## Documentation Updates (per sub-slice)

- `docs/50-execution/godot-capability-execution-queue.md` — Q128a/b rows
- `docs/30-gap-analysis/openkotor-parity-matrix.md` — DLG editing row
- `docs/plans/2026-06-10-056-feat-pr-stack-merge-holocron-parity-roadmap-plan.md` — U7 status note

---

## Risks

| Risk | Mitigation |
| --- | --- |
| Index repair bugs corrupt dialogue | Characterization tests from real DLG fixtures; `validate()` gate before save |
| GraphEdit performance on large DLGs | Read-only + lazy build; defer layout until tab opened |
| Orphan semantics differ from Holocron | Document rules in plan; test against small hand-built graphs |
