# Godot-native workspace parity foundation

## Contract

- Primary host is `editor/workspace/kotor_main_screen.gd` (main editor screen), with `ui/workspace/kotor_workspace_shell.gd` as the workspace surface.
- `editor/workspace/kotor_workspace_controller.gd` coordinates documents, target context, mutation service, and session restore.
- Workspace editors (`ui/workspace/editors/*`) implement the shared open/dirty/validation/mutation flow; DLG, 2DA, TLK, script, and entity GFF (UTC/UTP pilot) families are on this contract.
- Install-aware indexing stays in `gamefs/kotor_gamefs.gd`; writes stay in `editor/modding/kotor_modding_pipeline.gd`.
- Safe mutations: see `docs/solutions/safe-transaction-layer.md`.

## Limits (v1 foundation)

- Legacy `ui/kotor_dock.gd` remains for area tools and migration-era routes; when embedded in `KotorWorkspaceShell`, dock GameFS opens for DLG/2DA/TLK/script/workspace-GFF extensions delegate to the workspace editors instead of legacy dock tabs.
- New cross-editor orchestration belongs in workspace modules.
- Entity and module GFF files (UTC/UTP/… blueprint extensions plus ARE/GIT/IFO) open in `ui/workspace/editors/gff_workspace_editor.gd` with document registration, Tag editing, display-name locstring editing (`LocName`/`Name`), scalar leaf editing in the field tree (struct fields and array scalar elements), and preflight mutations; locstring/struct tree editing and array add/remove remain deferred.
- Profile management and packaging/share workflows are deferred.

## Verification

Headless tests under `tests/editor/` cover host lifecycle (`test_plugin_workspace_host.gd`), documents/session (`test_workspace_documents.gd`), target context (`test_target_context.gd`), DLG pilot (`test_dlg_workspace_editor.gd`), text/table editors (`test_text_table_editors.gd`), entity GFF pilot (`test_gff_workspace_editor.gd`), and mutation safety (`test_mutation_service.gd`, `test_safe_transaction_acceptance.gd`).
