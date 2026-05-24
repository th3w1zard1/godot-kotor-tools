# Safe transaction layer

## Contract

- Workspace editors call `preview_*` before `apply_*` for install, export, and remove flows.
- `KotorPreflightDialog` summarizes action (`create`, `overwrite`, `noop`, `remove`), target file, rollback availability, and supports proceed/cancel.
- `KotorMutationService` records transactions with rollback metadata; destructive actions without rollback are blocked at preview time.
- `KotorTransactionHistoryPanel` lists recorded transactions and restores eligible entries via `KotorWorkspaceController.restore_transaction_from_history`.

## Limits (v1)

- Persisted transaction history stores metadata only; byte payloads remain in-memory for the active editor session.
- Legacy `ui/kotor_dock.gd` may still call the modding pipeline directly for some flows until dock convergence lands.

## Verification

Headless tests under `tests/editor/` cover mutation previews, restore conflicts, preflight cancel semantics, and transaction history restore wiring.
