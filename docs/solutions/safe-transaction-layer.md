# Safe transaction layer

## Contract

- Workspace editors call `preview_*` before `apply_*` for install, export, and remove flows.
- `KotorPreflightDialog` summarizes action (`create`, `overwrite`, `noop`, `remove`), target file, rollback availability, and supports proceed/cancel.
- `KotorMutationService` records transactions with rollback metadata; destructive actions without rollback are blocked at preview time.
- `KotorTransactionHistoryPanel` lists recorded transactions and restores eligible entries via `KotorWorkspaceController.restore_transaction_from_history`.

## Limits (v1)

- Persisted transaction history stores metadata only; byte payloads remain in-memory for the active editor session.
- Legacy `ui/kotor_dock.gd` install/export paths route through `KotorMutationService` with the workspace controller's shared store (no interactive preflight in dock v1).
- Compare/read-only dock flows still use `KotorModdingPipeline` directly.

## Verification

Headless tests under `tests/editor/` cover mutation previews, restore conflicts, preflight cancel semantics, transaction history restore wiring, and legacy dock shared-store routing (`test_dock_mutation_contract.gd`).
