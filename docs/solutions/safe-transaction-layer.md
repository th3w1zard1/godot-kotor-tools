# Safe transaction layer

## Contract

- Workspace editors call `preview_*` before `apply_*` for install, export, and remove flows.
- `KotorPreflightDialog` summarizes action (`create`, `overwrite`, `noop`, `remove`), target file, rollback availability, and supports proceed/cancel.
- `KotorMutationService` records transactions with rollback metadata; destructive overwrites block when backup capture is impossible (e.g. backup path occupied by a directory).
- `KotorTransactionHistoryPanel` lists recorded transactions and restores eligible entries via `KotorWorkspaceController.restore_transaction_from_history`.

## Limits (v1)

- Persisted transaction history stores metadata only; byte payloads remain in-memory for the active editor session.
- Legacy `ui/kotor_dock.gd` install/export paths use the same preview → preflight → apply flow as workspace editors (set `_skip_preflight_for_testing` in headless tests).
- Compare/read-only dock flows still use `KotorModdingPipeline` directly.

## Verification

Headless tests under `tests/editor/` cover mutation previews, restore conflicts, preflight cancel semantics, transaction history restore wiring, legacy dock shared-store routing (`test_dock_mutation_contract.gd`), dock preflight coordinator (`test_dock_preflight_routing.gd`), and brainstorm acceptance examples AE1–AE5 (`test_safe_transaction_acceptance.gd`).
