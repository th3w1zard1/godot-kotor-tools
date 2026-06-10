# Residual Review Findings — Q50

**Branch:** `feat/q50-embedded-asset-generation`  
**Plan:** `docs/plans/2026-06-04-023-feat-q50-embedded-component-asset-generation-plan.md`  
**Review run:** LFG step 3 correctness review (2026-06-10)

## Residual Review Findings

- **medium** — `resources/documents/kotor_indoor_document.gd:294-307` — **Embedded component lookup fails when stored `id` has leading/trailing whitespace** — `_rebuild_embedded_index()` keys `_embedded_by_id` with raw JSON `id`, but `get_embedded_component()` strips the lookup key; components declared as `" room_a "` miss lookups from rooms referencing `"room_a"`. Suggested fix: normalize on index build with `component_id.strip_edges()`.

## Testing gaps (non-blocking)

- R4: No dedicated manifest test for embedded `has_wok`/`has_mdl`/`has_mdx` flags.
- R3: MOD builder embedded test asserts `.wok` only, not optional `mdl`/`mdx` entries.
