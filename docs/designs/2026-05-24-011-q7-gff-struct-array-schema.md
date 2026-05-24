---
title: Q7 GFF Struct/Array Schema and Validation Rules
phase: Q7
unit: U1
created: 2026-05-24
status: complete
---

# Q7 GFF Struct/Array Schema and Validation Rules (U1)

## Overview

This document defines the struct field schemas, array mutability, and validation strategy for GFF struct types that Q7 will support. It extends the Q6 DLG pattern to generic GFF resources (UTC, UTP, quest, etc.), establishing which arrays are editable, which fields are required vs. optional, sensible defaults for new structs, and reference update rules.

---

## Target GFF Struct Types

Q7 Phase 1 focuses on three representative GFF types:

1. **UTC (Creature Template)** — Editable CreatureActions array and itemList
2. **UTP (Placeable Template)** — Editable scripts and inventory arrays
3. **Quest-like structures** (generic)** — Editable entry/condition arrays (when embedded in quest data)

---

## Schema: UTC (Creature Template)

### Editable Arrays

#### CreatureActions List

**Purpose:** Actions the creature performs (combat, dialogue, movement).

**Mutability:**
- ✅ Add new action at any position
- ✅ Remove action
- ✅ Reorder actions (changes execution order)

**Struct Fields:**

| Field | Type | Required | Optional | Default | Notes |
|-------|------|----------|----------|---------|-------|
| ActionID | int | ✅ | | -1 | Links to action sequence; -1 = no action |
| Comment | string | | ✅ | "" | Modder notes; optional |
| Flags | int | | ✅ | 0 | Conditional flags |

**Validation Rules:**
- **Required:** ActionID must be >= -1 (bounds check after edit)
- **Optional:** Comment and Flags can be empty/0; warn if stale ActionID

**New Struct Defaults:**
```gdscript
{
    "ActionID": -1,       # -1 signals "not linked yet"
    "Comment": "",        # Optional modder note
    "Flags": 0            # Default flags
}
```

**Reference Update Rule:**
When reordering actions, ActionID field **is NOT auto-updated**. Modders manually verify links remain valid.

---

### Non-Editable Arrays (Q7 Out of Scope)

- **EquippedInventory**, **Inventory** — deferred to Q8 (requires item picker UI)
- **SkillList**, **FeatList** — deferred to Phase 1.5 (complex stat dependencies)

---

## Schema: UTP (Placeable Template)

### Editable Arrays

#### Scripts

**Purpose:** Custom script triggers and event handlers.

**Mutability:**
- ✅ Add script at any position
- ✅ Remove script
- ✅ Reorder scripts

**Struct Fields:**

| Field | Type | Required | Optional | Default | Notes |
|-------|------|----------|----------|---------|-------|
| Script | resref | ✅ | | "" | ResRef to compiled script (max 16 chars) |
| EventID | int | | ✅ | 0 | Event that triggers script |

**Validation Rules:**
- **Required:** Script resref must be <= 16 characters and not empty
- **Optional:** EventID can be 0 (default behavior)

**New Struct Defaults:**
```gdscript
{
    "Script": "",         # Empty signals "not set yet"; modder must assign
    "EventID": 0          # Default event = 0
}
```

**Reference Update Rule:**
Script references do **NOT** auto-update on reorder. Validation warns if Script field is empty.

---

### Non-Editable Arrays (Q7 Out of Scope)

- **Inventory** — deferred to Q8 (item picker)
- **TemplateResRef** list — deferred to Phase 1.5

---

## Schema: Generic Condition/Link Structures

### Conditional List (Generic Pattern)

When GFF resources embed condition blocks or entry links, they follow this pattern:

**Struct Fields:**

| Field | Type | Required | Optional | Default | Notes |
|-------|------|----------|----------|---------|-------|
| Operator | int | ✅ | | 0 | 0=AND, 1=OR, 2=NOT |
| Script | resref | ✅ | | "" | Condition script resref |
| Parameter | int | | ✅ | 0 | Script parameter |
| Comment | string | | ✅ | "" | Modder notes |

**Validation Rules:**
- **Required:** Operator must be 0-2; Script resref must be set and <= 16 chars
- **Optional:** Parameter and Comment can be empty/0

**New Struct Defaults:**
```gdscript
{
    "Operator": 0,        # Default to AND
    "Script": "",         # Empty; modder must assign
    "Parameter": 0,       # Default parameter
    "Comment": ""         # Optional note
}
```

---

## Struct Field Categorization (for typed_field_helpers.gd)

### Required Fields (Validation Blocks)

A required field edit that results in an invalid value **blocks save** with an error message.

**Examples:**
- Script resref fields (must be non-empty, max 16 chars)
- Action/Operator ID fields (must be within valid range)
- Index fields that point to other structures (must be in bounds)

**Validation logic:**
```gdscript
# In typed_field_helpers.gd
static func is_required_field(struct_type: String, field_name: String) -> bool:
    match struct_type:
        "CreatureActions":
            return field_name in ["ActionID"]  # ActionID -1 is valid "not set", but within bounds
        "UTCScripts":
            return field_name in ["Script"]
        "Condition":
            return field_name in ["Operator", "Script"]
        _:
            return false

static func validate_required_field(struct_type: String, field_name: String, value: Variant) -> bool:
    match struct_type:
        "CreatureActions":
            if field_name == "ActionID":
                return value >= -1  # -1 = no action, >= 0 = valid action
        "UTCScripts":
            if field_name == "Script":
                return not value.is_empty() and value.length() <= 16
        "Condition":
            if field_name == "Operator":
                return value in [0, 1, 2]
            if field_name == "Script":
                return not value.is_empty() and value.length() <= 16
    return true
```

### Optional Fields (Validation Warns)

An optional field edit that results in an empty/default value **warns in the UI** but **does NOT block save**.

**Examples:**
- Comment fields (documentation, always optional)
- EventID, Parameter fields (script parameters, often optional)
- Flags fields (conditional behavior, often optional)

**Validation logic:**
```gdscript
# In typed_field_helpers.gd
static func get_validation_warning(struct_type: String, field_name: String, value: Variant) -> String:
    match struct_type:
        "CreatureActions":
            if field_name == "Comment" and value.is_empty():
                return "Comment is empty; consider adding a note for clarity"
            if field_name == "ActionID" and value == -1:
                return "ActionID is -1 (no action linked); this may be intentional"
        "UTCScripts":
            if field_name == "EventID" and value == 0:
                return "EventID is 0 (default); confirm this is intended"
        "Condition":
            if field_name == "Comment" and value.is_empty():
                return "Condition has no comment; consider adding description"
    return ""
```

---

## Mark_Changed() and Tree Refresh

All struct mutations (array add/remove/reorder, field edit) call `mark_changed()`:

```gdscript
func mark_changed() -> void:
    _mark_changed_internal()
    changed.emit()
```

**Signal Flow:**
1. Editor handler (`_apply_*_edit()`) calls document method
2. Document method calls `mark_changed()`
3. `changed.emit()` triggers tree refresh
4. Tree UI updates to show new/removed/reordered structs

---

## Pattern Precedent: Q6 DLG Array Design

Q7 schema extends Q6 DLG pattern:

**Q6 DLG RepliesList entry** (from `2026-05-24-010-q6-array-mutation-design.md`):
```gdscript
{
    "Index": -1,           # -1 = "no link yet"
    "Comment": "",         # Optional modder notes
    "Active": "",          # Conditional script
    "IsChild": 0           # Boolean flag
}
```

**Q7 Extension:** Same pattern applied to UTC CreatureActions, UTP Scripts, generic Condition blocks.

**Key Decision:** Reordering does NOT auto-update sibling reference fields. Validation warns on stale references; modders manually fix.

---

## Reference Update Rules Summary

### Rule 1: Reordering Does NOT Update Links

**Invariant:** When reordering struct arrays (CreatureActions, Scripts, Conditions), **reference fields within those structs are NOT automatically updated**.

**Example:**
```
Initial:
  CreatureActions[0] = {ActionID: 5, ...}
  CreatureActions[1] = {ActionID: 3, ...}

After reorder CreatureActions[0] → position 2:
  CreatureActions[0] = {ActionID: 5, ...}  (unchanged, but now at position 1)
  CreatureActions[1] = {ActionID: 3, ...}  (unchanged)
  CreatureActions[2] = ...                 (moved here; ActionID unchanged)
```

**Rationale:**
- Prevents silent data loss from auto-updates
- Permits incremental authoring
- Validates explicitly; modder understands causality

### Rule 2: Validation Warns on Stale References

After reordering, validation checks reference fields and warns if they're now invalid.

**Example:**
```gdscript
# In handler after array reorder:
for (var struct in reordered_array):
    if struct.has("ActionID") and struct["ActionID"] >= 0:
        if struct["ActionID"] >= action_list_size:
            push_warning("Stale ActionID after reorder; update %s manually" % struct["ActionID"])
```

---

## Validation Styling and UX

### Error States (Required Field Invalid)

- **Tree item icon:** Error badge (red X)
- **Tree item color:** Red text
- **Editor bar:** Error banner with message (non-dismissible until fixed)
- **Log output:** `push_error()` with specific field and reason

**Example message:** "ActionID -1 is out of bounds; must be >= 0 and < action_list_size"

### Warning States (Optional Field Empty)

- **Tree item icon:** Warning badge (yellow triangle)
- **Tree item color:** Yellow/muted text
- **Editor bar:** Warning banner with message (dismissible)
- **Log output:** `push_warning()` with suggestion

**Example message:** "Script field is empty; consider assigning a valid ResRef (max 16 chars)"

---

## Scope: Phase 1 vs. Future Phases

### Phase 1 (Q7) — In Scope

- ✅ Array add/remove/reorder for CreatureActions, Scripts, generic Conditions
- ✅ Inline struct field editing for required/optional fields
- ✅ Hybrid validation (required blocks, optional warns)
- ✅ Single-language text fields (no multi-language locstring yet)
- ✅ ResRef field editing with length validation

### Phase 1.5+ — Deferred

- 🔄 Multi-language locstring editing (Q8: Typed field picker expansion)
- 🔄 ResRef file browser / auto-complete (Q8: Typed field picker)
- 🔄 Enum combo sourced from game files (Q8: Typed field picker)
- 🔄 Struct cloning / duplication (convenience feature)
- 🔄 Batch "fix stale refs" operation (convenience)

---

## Verification Checklist for U1

- [x] Schema covers at least 3 GFF struct types (UTC, UTP, generic Condition)
- [x] Required/optional field categorization documented per type
- [x] Defaults include rationale (especially -1 for "not set" signals)
- [x] Reference update rules explicitly stated (no auto-update, validation warns)
- [x] Pattern parallel to Q6 DLG established and justified
- [x] Validation helpers (is_required_field, validate_required_field, get_validation_warning) specified with logic sketches
- [x] Mark_changed() behavior confirmed
- [x] Scope boundaries explicit (Phase 1 in-scope vs. deferred)

**Status:** ✅ Complete. Ready for U2 implementation (tree populator uses this schema to mark editable arrays).

---

## Notes for Implementation (U2+)

1. **Schema in code:** Validate field schemas against actual GFF file types (UTC, UTP). If discrepancies found, note in learnings doc.
2. **Struct types:** When new GFF types are added later, extend this schema doc with new struct type entries.
3. **Validation extensibility:** typed_field_helpers.gd should be designed to allow adding new struct type schemas without modifying handler logic.
4. **Reference resolution:** For ActionID, Script resref, etc., consider future enhancement (Q8) to auto-suggest valid options from game files.
