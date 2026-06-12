# Concepts

Shared domain vocabulary for this project — entities, named processes, and status concepts with project-specific meaning. Seeded with core domain vocabulary, then accretes as ce-compound and ce-compound-refresh process learnings; direct edits are fine. Glossary only, not a spec or catch-all.

## Workspace architecture

### Workspace shell
The Godot editor surface that hosts workspace editors, target context, and embedded legacy dock routes. Distinct from the main-screen host plugin entry.

### Workspace controller
Coordinates open documents, mutation service access, session persist/restore, and transaction-history restore — but not install targeting directly.

### Workspace editor
A format-specific editor plugin under `ui/workspace/editors/` implementing open, dirty state, validation, and (when writing) safe mutation flows.

### Target context
Install-aware targeting state (game path, override/modules focus) wired through the workspace shell so editors resolve where reads and writes apply.

## Mutation and I/O

### Safe transaction layer
The preview → preflight → apply pattern for install, export, and remove writes, with rollback metadata and user confirmation before destructive changes.

### Preflight
The user-facing confirmation step summarizing the pending mutation action, target path, and rollback availability before apply proceeds.

### Mutation service
The service that previews mutations, records transactions, blocks unsafe overwrites, and restores eligible history entries within the active session.

### Modding pipeline
Stateless install/export/compare/write helpers for game payloads; compare/read-only flows use this directly instead of the mutation service.

### GameFS
Install-aware virtual filesystem indexing for locating core and override resources without performing workspace mutations itself.
