# Copilot Instructions

## Commands

- **Single-file GDScript validation:** `godot --headless --quiet --check-only --script path/to/file.gd`
- **Repo-wide GDScript validation:** `find . -name '*.gd' -print0 | xargs -0 -I{} godot --headless --quiet --check-only --script '{}'`
- This repository does not define a separate build, lint, or automated test suite. Treat Godot `--check-only` validation as the baseline verification workflow.

## High-level architecture

- `plugin.gd` is the editor-plugin entry point. It wires three subsystems together: importer registration (`editor/core/kotor_importer_registry.gd`), saver registration (`editor/core/kotor_saver_registry.gd`), and the bottom-panel shell (`editor/shell/kotor_editor_shell.gd`).
- `formats/` contains the core Aurora/KotOR format logic. These scripts are byte/file parsers and serializers (`gff`, `erf/rim`, `2da`, `tlk`, `tpc`, `key/bif`, `lyt`) and are the canonical place for binary-format behavior.
- `importers/` convert game files into Godot editor resources, usually saved as `.tres`. `resources/` then layers editor-facing wrappers on top of parsed data: generic resources (`gff_resource.gd`, `twoda_resource.gd`, `tlk_resource.gd`), typed GFF resources in `resources/typed/`, and document helpers in `resources/documents/` for summaries, editing helpers, and validation.
- `gamefs/kotor_gamefs.gd` is the install-aware index over a real game directory. It discovers resources from `chitin.key`, `dialog.tlk`, module archives, and `override/`, keeps both the winning entry and all variants, and is the canonical source for browsing or resolving install content.
- `ui/kotor_dock.gd` is the main workspace UI. It routes indexed resources by extension into the GameFS, ERF, GFF, DLG, Area Tools, 2DA, TLK, and Script surfaces. `editor/modding/kotor_modding_pipeline.gd` owns export/install/compare/write-back behavior so the dock stays as a UI orchestrator instead of duplicating file-writing logic.

## Key conventions

- This is a **Godot 4.6 editor plugin written in pure GDScript**. Prefer extending the existing GDScript parser/resource/editor pipeline instead of introducing native modules or parallel tooling.
- New format support should usually follow the existing vertical slice: parser/reader in `formats/`, importer in `importers/`, resource wrapper in `resources/`, optional typed/document helpers in `resources/typed/` and `resources/documents/`, then UI routing in `ui/kotor_dock.gd` if the format becomes editor-visible.
- GFF-backed editing goes through document wrappers, not raw dictionary manipulation alone. `GFFResource.create_document()` and typed document subclasses (`resources/documents/*.gd`) centralize display names, locstring handling, validation, and `changed` propagation.
- Keep install browsing logic in `KotorGameFS`. It already normalizes resource types, tracks source variants, and applies source precedence by indexing core sources first and `override/` last so override entries win while variants remain inspectable.
- Keep write/export/install logic in `KotorModdingPipeline`, not in UI event handlers. The pipeline is where serialization decisions, absolute-path checks, compare behavior, and override backup creation live.
- Custom `ResourceFormatSaver`s are how edited resources get written back to original game formats (`.2da`, `.tlk`, GFF-family extensions). Importers still save Godot-side editor resources as `.tres`.
- Most editor-facing scripts are `@tool` scripts and are expected to run inside the editor. Preserve that behavior for new plugin, importer, saver, and editor UI scripts that must execute in-editor.
