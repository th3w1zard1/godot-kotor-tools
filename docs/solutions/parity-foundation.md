# Godot-native workspace parity foundation

## Contract

- Primary host is `editor/workspace/kotor_main_screen.gd` (main editor screen), with `ui/workspace/kotor_workspace_shell.gd` as the workspace surface.
- `editor/workspace/kotor_workspace_controller.gd` coordinates documents, mutation service, and session restore; `KotorTargetContext` is wired through the workspace shell for install-aware targeting.
- Workspace editors (`ui/workspace/editors/*`) implement the shared open/dirty/validation/mutation flow. Current shell-hosted families include DLG, 2DA, TLK, script, SSF, TPC, WAV, MDL, LIP, GFF entity/module resources, module designer (GIT), indoor builder, and ERF archives.
- Install-aware indexing stays in `gamefs/kotor_gamefs.gd`; writes stay in `editor/modding/kotor_modding_pipeline.gd`.
- Safe mutations: see `docs/solutions/safe-transaction-layer.md`.

## Limits (v1 foundation)

- Legacy `ui/kotor_dock.gd` remains for area tools and migration-era routes. When embedded in `KotorWorkspaceShell`, dock GameFS opens for extensions delegated by `_should_delegate_to_workspace_editor`: DLG, 2DA, TLK, SSF, TPC, WAV, LIP, ERF/archive types, script extensions, module designer (GIT), and workspace-GFF extensions — instead of legacy dock tabs.
- New cross-editor orchestration belongs in workspace modules.
- **GFF routing:** blueprint and module resource extensions in `WORKSPACE_GFF_EXTENSIONS` (UTC/UTP/UTI/…, ARE, IFO, JRL, PTH, FAC) open in `ui/workspace/editors/gff_workspace_editor.gd` with document registration, Tag editing, display-name locstring editing (`LocName`/`Name`), scalar leaf editing in the field tree, and struct-array add/remove/reorder. **GIT** opens in `ui/workspace/editors/module_designer_workspace_editor.gd`, not the GFF editor.
- **Remaining GFF deferrals:** locstring editing inside the field tree (toolbar LocName/Name is shipped); struct-container nodes vs scalar-in-struct editing boundaries still evolve.
- Profile management and packaging/share workflows are deferred.
- Parity tracking lives separately in `docs/50-execution/godot-capability-execution-queue.md` and `docs/50-execution/godot-loader-saver-importer-parity-matrix.md`.

## Verification

Headless tests under `tests/editor/` cover host lifecycle (`test_plugin_workspace_host.gd`), documents/session (`test_workspace_documents.gd`), target context (`test_target_context.gd`), DLG pilot (`test_dlg_workspace_editor.gd`), text/table editors (`test_text_table_editors.gd`), entity GFF pilot (`test_gff_workspace_editor.gd`), dock workspace routing (`test_dock_workspace_routing.gd`), ERF archive slice (`test_erf_workspace_editor.gd`), and mutation safety (`test_mutation_service.gd`, `test_safe_transaction_acceptance.gd`).
