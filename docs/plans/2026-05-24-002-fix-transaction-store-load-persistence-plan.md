---
title: fix: Restore transaction history read consistency
type: fix
status: active
date: 2026-05-24
---

# fix: Restore transaction history read consistency

## Summary

Fix transaction history behavior so persisted history is available to read APIs immediately after startup and so clear operations persist to storage.

---

## Problem Frame

`KotorTransactionStore` currently loads persisted state only in `record_transaction()`, so read APIs can appear empty until a write occurs. `clear_transactions()` also clears memory without persisting, which allows stale history to reappear after reload.

---

## Requirements

- R1. Read APIs in `KotorTransactionStore` must load persisted transaction state before returning values.
- R2. `clear_transactions()` must persist the cleared state so history does not reappear after restart.
- R3. Existing transaction behavior (ID progression, listing order, session filtering) must remain intact.

---

## Scope Boundaries

### In scope

- `editor/transactions/kotor_transaction_store.gd`
- Tests validating load-on-read and clear persistence behavior

### Out of scope

- Mutation service or UI workflow redesign
- New transaction storage format

---

## Implementation Units

### U1. Add centralized load guard for store methods

**Goal:** Ensure all public store methods operate on loaded persisted data.

**Requirements:** R1, R3

**Dependencies:** None

**Files:** `editor/transactions/kotor_transaction_store.gd`, `tests/editor/test_transaction_restore.gd`

**Approach:** Introduce a private `_ensure_loaded()` helper and call it from read/write methods that consume `_transactions` or `_next_id`.

**Patterns to follow:** Existing lazy-load behavior in `record_transaction()` and dictionary-array usage conventions in transaction editor tests.

**Test scenarios:**
- Happy path: persisted store with existing transactions returns expected entries via `get_transaction()` before any new writes.
- Happy path: `list_transactions()` returns persisted items on first call after store initialization.
- Edge case: empty persisted state keeps read methods stable and returns empty results.

**Verification:** Read methods return persisted history immediately after initialization without requiring `record_transaction()`.

### U2. Persist clear operations

**Goal:** Make clear operations durable across reloads.

**Requirements:** R2, R3

**Dependencies:** U1

**Files:** `editor/transactions/kotor_transaction_store.gd`, `tests/editor/test_transaction_restore.gd`

**Approach:** Update `clear_transactions()` to persist cleared state and maintain `_loaded`/ID consistency.

**Patterns to follow:** Existing `_persist_transactions()` error-tolerant behavior and current in-memory reset semantics.

**Test scenarios:**
- Happy path: after clear, reloading store returns zero transactions.
- Edge case: clear called on already-empty store remains no-op safe and persisted.
- Integration: record transaction, clear, then instantiate fresh store and confirm no stale records reappear.

**Verification:** Clear behavior remains immediate in memory and survives store recreation.

---

## Deferred Implementation Notes

- If broader transaction lifecycle issues surface in UI flows, defer to a separate plan focused on cross-layer transaction UX.

