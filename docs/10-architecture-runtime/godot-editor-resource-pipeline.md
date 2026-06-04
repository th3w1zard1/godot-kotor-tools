# Godot Editor Resource Pipeline Architecture (4.x)

## Canonical Engine Flow

1. **Editor import phase**
   - `EditorImportPlugin` maps source files/extensions to imported resource outputs and writes into the imported cache path (`.godot/imported` behavior described in docs).
2. **Resource load phase**
   - `ResourceLoader` queries registered `ResourceFormatLoader` implementations.
   - Loader `_load(path, original_path, use_sub_threads, cache_mode)` returns a `Resource` or `Error`.
3. **Resource save phase**
   - `ResourceSaver` queries registered `ResourceFormatSaver` implementations.
   - Saver `_save(resource, path, flags)` writes the canonical output format.

## Key Godot API Contracts

- `ResourceLoader.load(path, type_hint, cache_mode)` supports cache modes (`IGNORE`, `REUSE`, `REPLACE`, deep variants) and threaded loading APIs.
- `ResourceSaver.save(resource, path, flags)` supports saver flags such as `FLAG_RELATIVE_PATHS`, `FLAG_COMPRESS`, and endian/path behaviors.
- `ResourceFormatLoader._load(...)` receives cache mode and may return `Resource` or `Error`.
- `ResourceFormatSaver._recognize(resource)` + `_get_recognized_extensions(resource)` gate save routing.

## Current Repo Mapping

- Plugin boot + registration lifecycle:
  - `plugin.gd`
  - `editor/core/kotor_importer_registry.gd`
  - `editor/core/kotor_saver_registry.gd`
- Example importer (GFF):
  - `importers/gff_import_plugin.gd`
- Example saver (GFF):
  - `savers/gff_resource_format_saver.gd`

## Architectural Guidance for New Formats

- **Importer responsibility:** source-file parsing + initial `Resource` creation (editor import path).
- **Loader responsibility:** runtime/editor load compatibility for stored format.
- **Saver responsibility:** deterministic write-back with clear extension and error semantics.
- **Domain model responsibility:** stable typed access/update APIs in `resources/` and `resources/documents/`.

## Risks and Constraints

- Resource cache behavior can hide stale-data bugs if cache mode assumptions are wrong.
- Import-time output extension/type mismatches break downstream loader/saver routing.
- UI actions should invoke service/pipeline layers, not duplicate serialization logic.
- `[OFFICIAL]` Default `ResourceLoader.load()` uses `CACHE_MODE_REUSE`; after write-back or external file change, cached in-memory resources may be stale until reloaded with `CACHE_MODE_REPLACE`.

## Cache mode expectations `[SYNTH]`

| Operation | Recommended cache mode | Rationale |
| --- | --- | --- |
| Normal editor open (imported `.tres`) | `CACHE_MODE_REUSE` (default) | Standard editor behavior |
| Post-write-back validation | `CACHE_MODE_REPLACE` | Refresh in-place cached instance after saver wrote bytes |
| Round-trip test harness | `CACHE_MODE_IGNORE` or `REPLACE` | Avoid false passes from stale cache |
| GameFS raw file read | N/A — use `FileAccess` + parser | Importable assets require import before `ResourceLoader.load()` |

See `docs/90-meta/godot-doc-source-map.md` for CacheMode enum reference.

## ResourceFormatLoader gap `[REPO]`

No `ResourceFormatLoader` is registered. Aurora source files enter via `EditorImportPlugin` → `.godot/imported/*.tres`. Direct `ResourceLoader.load("res://foo.utc")` without prior import is unsupported. See parity matrix for format-level coverage.

## Next Actions

1. ~~Add explicit loader docs/examples for all currently saver-backed formats.~~ Covered by parity matrix and per-format checklists (2026-06-04).
2. ~~Standardize cache mode expectations per pipeline operation.~~ Documented above; add automated tests.
3. Add regression tests around import/save/load round trips for every writable format with explicit cache modes.
