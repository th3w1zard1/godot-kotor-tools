# Godot Serialization Knowledgebase Intent

## Start Here (Authoritative Paths)

- **End-user setup and first run:** `README.md` and `docs/QUICKSTART.md`
- **Architecture + implementation orientation (this audience):** `docs/00-intent/godot-serialization-kb-intent.md`
- **Product strategy and active tracks:** `STRATEGY.md`
- **Support coverage + implementation gaps:** `docs/30-gap-analysis/godot-support-gaps.md`
- **Next implementation-wave requirements:** `docs/brainstorms/2026-05-24-godot-support-expansion-requirements.md`
- **Official external API source references:** `docs/90-meta/godot-doc-source-map.md`
- **Contributor implementation checklist:** `docs/50-execution/godot-kotor-implementation-playbook.md`
- **Loader/saver/importer parity matrix:** `docs/50-execution/godot-loader-saver-importer-parity-matrix.md`
- **Per-format serialization checklists:** `docs/50-execution/format-serialization-checklists/`

## Problem Frame

`godot-kotor-tools` already implements custom importers, savers, and editor workflows for Aurora formats, but we need a durable Godot API knowledgebase to guide future serializer/deserializer work without re-researching engine docs every time.

## Scope

This knowledgebase focuses on Godot 4.x editor/runtime APIs needed for custom format IO pipelines:

- `ResourceFormatLoader` / `ResourceFormatSaver`
- `ResourceLoader` / `ResourceSaver`
- `EditorImportPlugin` and editor plugin registration surface
- Binary and variant serialization helpers (`FileAccess`, `PackedByteArray`, `Marshalls`, `@GlobalScope` variant conversion)

## Repo Implications

- Keep importer/saver registration centralized in `plugin.gd`, `editor/core/kotor_importer_registry.gd`, `editor/core/kotor_saver_registry.gd`.
- Keep format-specific serialization logic in format/domain files (e.g. `formats/*`, `savers/*`, `resources/*`), not in UI shells.
- Align future docs and implementation with Godot 4.6 target stated in `README.md`.

## Next Actions

1. Use `docs/50-execution/godot-kotor-implementation-playbook.md` and per-format checklists before adding new format support.
2. Keep `docs/50-execution/godot-loader-saver-importer-parity-matrix.md` updated as each pipeline lands.
3. Re-run doc-source refresh when Godot minor versions change (last pass: 2026-06-04, Godot 4.6).
4. Add cache-mode-sensitive reload tests per playbook validation gates.
