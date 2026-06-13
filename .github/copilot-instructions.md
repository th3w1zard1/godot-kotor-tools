# Copilot Instructions

## Commands

- **Single-file GDScript validation:** `godot --headless --quiet --check-only --script path/to/file.gd`
- **Repo-wide GDScript validation:** `find . -name '*.gd' -print0 | xargs -0 -I{} godot --headless --quiet --check-only --script '{}'`
- **Single headless editor test:** `godot --headless --path . --script tests/editor/test_dock_workspace_routing.gd`
- **All headless editor tests:** `bash scripts/run_headless_editor_tests.sh`
- **Legacy all-tests invocation:** `find tests/editor -name 'test_*.gd' -print0 | xargs -0 -I{} godot --headless --path . --script '{}'`
- **CI:** GitHub Actions workflow `.github/workflows/headless-editor-tests.yml` runs the runner script on `push` to `main` and on pull requests.
- There is no separate build or lint toolchain in this repository; use the Godot commands above as the validation baseline.

## High-level architecture

- `plugin.gd` is the editor-plugin entry point. It wires importer registration (`editor/core/kotor_importer_registry.gd`), saver registration (`editor/core/kotor_saver_registry.gd`), and the workspace stack (`editor/workspace/kotor_workspace_controller.gd` + `editor/workspace/kotor_main_screen.gd`).
- `ui/workspace/kotor_workspace_shell.gd` is the main in-editor workspace surface. It composes the resource browser, transaction history, legacy dock shell, and dedicated editors (DLG, 2DA, TLK, script, and typed GFF entity editors) and restores session documents through `KotorWorkspaceController`.
- `formats/` contains the core Aurora/KotOR format logic. These scripts are byte/file parsers and serializers (`gff`, `erf/rim`, `2da`, `tlk`, `tpc`, `key/bif`, `lyt`) and are the canonical place for binary-format behavior.
- `importers/` convert game files into Godot editor resources, usually saved as `.tres`. `resources/` then layers editor-facing wrappers on top of parsed data: generic resources (`gff_resource.gd`, `twoda_resource.gd`, `tlk_resource.gd`), typed GFF resources in `resources/typed/`, and document helpers in `resources/documents/` for summaries, editing helpers, and validation.
- `gamefs/kotor_gamefs.gd` is the install-aware index over a real game directory. It discovers resources from `chitin.key`, `dialog.tlk`, module archives, and `override/`, keeps both the winning entry and all variants, and is the canonical source for browsing or resolving install content.
- `editor/transactions/kotor_mutation_service.gd` + `editor/transactions/kotor_transaction_store.gd` provide preflight/apply/rollback transaction semantics for install/export/remove flows; `editor/modding/kotor_modding_pipeline.gd` performs serialization, compare, write, and backup behavior used by both legacy and workspace editors.

## Key conventions

- This is a **Godot 4.6 editor plugin written in pure GDScript**. Prefer extending the existing GDScript parser/resource/editor pipeline instead of introducing native modules or parallel tooling.
- New format support should usually follow the existing vertical slice: parser/reader in `formats/`, importer in `importers/`, resource wrapper in `resources/`, optional typed/document helpers in `resources/typed/` and `resources/documents/`, then UI routing in `ui/kotor_dock.gd` if the format becomes editor-visible.
- GFF-backed editing goes through document wrappers, not raw dictionary manipulation alone. `GFFResource.create_document()` and typed document subclasses (`resources/documents/*.gd`) centralize display names, locstring handling, validation, and `changed` propagation.
- Keep install browsing logic in `KotorGameFS`. It already normalizes resource types, tracks source variants, and applies source precedence by indexing core sources first and `override/` last so override entries win while variants remain inspectable.
- Keep write/export/install/remove logic in `KotorMutationService` + `KotorModdingPipeline`, not in UI event handlers. Mutating actions are expected to run through preview/preflight/apply flows so rollback metadata is captured consistently.
- Custom `ResourceFormatSaver`s are how edited resources get written back to original game formats (`.2da`, `.tlk`, GFF-family extensions). Importers still save Godot-side editor resources as `.tres`.
- Most editor-facing scripts are `@tool` scripts and are expected to run inside the editor. Preserve that behavior for new plugin, importer, saver, and editor UI scripts that must execute in-editor.
- Headless tests in `tests/editor/test_*.gd` are executable `SceneTree` scripts (not a separate test framework); add new editor regressions in that pattern so they run with `godot --headless --path . --script ...`.
