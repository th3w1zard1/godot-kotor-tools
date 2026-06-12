# Safe transaction layer

## Contract

- Workspace editors call `preview_*` before `apply_*` for install, export, and remove flows.
- `KotorPreflightDialog` (`ui/workspace/dialogs/kotor_preflight_dialog.gd`) summarizes action (`create`, `overwrite`, `noop`, `remove`), target file, rollback availability, and supports proceed/cancel.
- `KotorMutationService` (`editor/transactions/kotor_mutation_service.gd`) records transactions with rollback metadata via `KotorTransactionStore` (`editor/transactions/kotor_transaction_store.gd`); destructive overwrites block when backup capture is impossible (e.g. backup path occupied by a directory).
- `KotorTransactionHistoryPanel` (`ui/workspace/panels/transaction_history_panel.gd`) lists recorded transactions; `KotorWorkspaceController.restore_transaction_from_history` (`editor/workspace/kotor_workspace_controller.gd`) restores eligible entries.

## Limits (v1)

- Persisted transaction history stores metadata only (`EditorSettings` key `kotor_tools/workspace/transaction_history`); byte payloads (`before_bytes` / `after_bytes`) remain in-memory for the active editor session — restore after restart requires the same session's in-memory store.
- Legacy `ui/kotor_dock.gd` install/export paths use the same preview → preflight → apply flow as workspace editors (set `_skip_preflight_for_testing` in headless tests).
- Compare/read-only dock flows still use `KotorModdingPipeline` (`editor/modding/kotor_modding_pipeline.gd`) directly.
- `preview_remove_override` / `apply_remove_override` are implemented in `KotorMutationService` and covered by service tests, but no workspace editor or legacy dock UI wires remove yet.
- **ERF batch exceptions:** `extract_all_members_to_override` (`ui/workspace/editors/erf_workspace_editor.gd`) applies per-member installs with `proceed=true` and skips per-file preflight (still uses mutation preview → apply). `extract_all_members_to_folder` writes with `FileAccess` and bypasses the mutation layer entirely.

## Verification

Headless tests under `tests/editor/` cover mutation previews (`test_mutation_service.gd`, `test_preflight_mutation.gd`), restore conflicts (`test_transaction_restore.gd`), transaction history restore wiring (`test_transaction_history_panel.gd`), legacy dock shared-store routing (`test_dock_mutation_contract.gd`), dock preflight coordinator (`test_dock_preflight_routing.gd`), and brainstorm acceptance examples AE1–AE5 (`test_safe_transaction_acceptance.gd`). ERF workspace flows use `_skip_preflight_for_testing` in `test_erf_workspace_editor.gd`.
