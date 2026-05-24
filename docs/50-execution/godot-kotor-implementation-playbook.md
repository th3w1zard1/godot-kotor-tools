# Godot-KotOR Custom Serialization Implementation Playbook

## Pre-Implementation Checklist

1. Confirm target format behavior (read-only vs read-write).
2. Define importer contract:
   - recognized source extensions
   - resulting resource type
   - save extension for imported artifact
3. Define saver contract:
   - recognized resource subtype
   - recognized output extensions
   - writer error semantics
4. Define loader contract if runtime/editor loading path is custom.
5. Define round-trip test cases (parse -> mutate -> save -> reload).

## Recommended Build Sequence

1. Add/extend format parser/writer in `formats/`.
2. Add/extend typed resources/documents in `resources/`.
3. Implement importer plugin (if source-file import needed).
4. Implement resource format saver.
5. Register importer/saver in registries + plugin lifecycle.
6. Wire editor workflows through workspace controller/service (not direct UI duplication).
7. Add script tests for parser/writer and editor mutation paths.

## Validation Gates

- GDScript check-only passes for all touched scripts.
- Importing sample fixture succeeds and produces expected resource object.
- Save/write-back emits expected bytes and extension.
- Reload of saved output returns equivalent semantic structure.
- Error paths return explicit `Error` values (not silent fallbacks).

## Current Example References in Repo

- Import plugin: `importers/gff_import_plugin.gd`
- Saver: `savers/gff_resource_format_saver.gd`
- Registration lifecycle: `plugin.gd`, `editor/core/kotor_*_registry.gd`
- Mutation/write orchestration: `editor/transactions/kotor_mutation_service.gd`

## Next Actions

1. Create per-format checklist docs for ERF/TLK/2DA/GFF parity.
2. Add dependency-rename/dependency-list coverage where format supports references.
3. Add cache-mode-sensitive tests for reload behavior.
