---
title: Q6 Array Mutation Design
phase: Q6
unit: U1
created: 2026-05-24
status: complete
---

# Q6 Array Mutation Design (U1)

## Array Mutation Method Contracts

### Method 1: `insert_struct_at_array`

```gdscript
func insert_struct_at_array(array_field_name: String, index: int, struct_value: Dictionary) -> bool:
    """
    Inserts struct_value at the specified index within root[array_field_name].
    
    Args:
        array_field_name: Name of root-level array field (e.g., "EntryList", "RepliesList")
        index: Position to insert at (0 = beginning, size = end)
        struct_value: The struct (Dictionary) to insert
    
    Returns:
        true if insert succeeded, false if index out of bounds or array field not found
    
    Side Effects:
        - Inserts struct at position, shifting existing elements right
        - Calls mark_changed() to emit changed signal
        - Does NOT update any reference fields (e.g., Index pointers)
    """
```

**Example Usage:**
```gdscript
var new_reply = {Index: -1, Comment: "", Active: "", IsChild: 0}
var success = dlg_document.insert_struct_at_array("RepliesList", 2, new_reply)
# Inserts new_reply at position 2; existing items at 2+ shift right
```

---

### Method 2: `remove_struct_from_array`

```gdscript
func remove_struct_from_array(array_field_name: String, index: int) -> bool:
    """
    Removes the struct at the specified index from root[array_field_name].
    
    Args:
        array_field_name: Name of root-level array field
        index: Position to remove from
    
    Returns:
        true if removal succeeded, false if index out of bounds
    
    Side Effects:
        - Removes struct at position, shifting existing elements left
        - Calls mark_changed() to emit changed signal
        - Does NOT update any reference fields
    """
```

**Example Usage:**
```gdscript
var success = dlg_document.remove_struct_from_array("RepliesList", 1)
# Removes RepliesList[1]; items at 2+ shift left
```

---

### Method 3: `reorder_array_item`

```gdscript
func reorder_array_item(array_field_name: String, from_index: int, to_index: int) -> bool:
    """
    Moves the struct from from_index to to_index within root[array_field_name].
    
    Args:
        array_field_name: Name of root-level array field
        from_index: Current position of item
        to_index: Desired position of item
    
    Returns:
        true if reorder succeeded, false if either index out of bounds
    
    Side Effects:
        - Moves element from from_index to to_index
        - Shifts intervening elements appropriately
        - Calls mark_changed() to emit changed signal
        - Does NOT update any reference fields
    
    Examples:
        reorder_array_item("RepliesList", 0, 2)  # Move first item to position 2
        reorder_array_item("RepliesList", 3, 1)  # Move position 3 to position 1
    """
```

**Example Usage:**
```gdscript
var success = dlg_document.reorder_array_item("RepliesList", 1, 3)
# Moves RepliesList[1] → RepliesList[3], shifts intervening items
```

---

## Reference Validation Rules

### Rule: Reordering Does NOT Update Sibling References

**Invariant:** When reordering a RepliesList or EntriesList, the Index fields within those items **are NOT automatically updated**. The modder must manually correct stale references.

**Example Scenario:**
```
Initial state:
  RepliesList[0] = {Index: 0, ...}  ← Link to EntryList[0]
  RepliesList[1] = {Index: 0, ...}  ← Link to EntryList[0]
  
Reorder RepliesList[0] → position 2:
  RepliesList[0] = {Index: 0, ...}  ← Link to EntryList[0] (unchanged)
  RepliesList[1] = {Index: 0, ...}  ← Link to EntryList[0] (unchanged)
  RepliesList[2] = {Index: 0, ...}  ← Moved here, Index still points to EntryList[0]
```

**Validation Strategy:**
1. On insert: If Index field is out of bounds, **WARN** (don't block)
2. On reorder: Check each link's Index after reorder, **WARN** if stale
3. On remove: Check remaining links, **WARN** if stale

**Rationale:**
- Prevents silent data loss from automatic updates
- Permits incremental dialogue authoring (add structure, fix links later)
- Test coverage ensures warnings are visible and actionable

---

## Struct Initialization Defaults

### Default for New RepliesList Entry

When adding a reply to an entry's RepliesList:

```gdscript
{
    "Index": -1,          # -1 = "no link yet"; modder must set valid EntryList index
    "Comment": "",        # Optional descriptive text for modder
    "Active": "",         # Conditional script (optional, text editing only in Q6)
    "IsChild": 0          # Boolean flag: 0 = false, 1 = true
}
```

**Rationale:**
- Index: -1 is invalid and will trigger validation warning, signaling modder to fix
- Comment: Empty string is valid but warns (optional field)
- Active: Empty is valid (conditional scripts are optional in KotOR DLG)
- IsChild: Default to 0 (non-child reply)

---

### Default for New EntriesList Entry

When adding an entry link within a reply's EntriesList:

```gdscript
{
    "Index": -1,          # -1 = "no link yet"; modder must set valid EntryList index
    "Comment": "",        # Optional descriptive text for modder
    "Active": "",         # Conditional script (optional, text editing only in Q6)
    "IsChild": 0          # Boolean flag
}
```

**Same as RepliesList entry** — both represent structural links within a dialogue tree.

---

## Mark_Changed() Behavior

All three methods **MUST** call `mark_changed()` after mutation to:
1. Update internal dirty tracking
2. Emit the `changed` signal
3. Trigger tree refresh in the DLG editor UI

**Implementation Pattern (from kotor_gff_document.gd:297-298):**
```gdscript
func mark_changed() -> void:
    _mark_changed_internal()
    changed.emit()
```

---

## Pattern Precedent: `set_struct_field()`

The array mutation methods follow the same guard-check and mutation pattern as `set_struct_field()` in kotor_dlg_document.gd:133-140:

```gdscript
func set_struct_field(struct_value: Dictionary, field_name: String, value: Variant) -> bool:
    if not struct_value.has(field_name):
        return false
    if struct_value[field_name] == value:
        return false  # No change, no-op
    struct_value[field_name] = value
    mark_changed()
    return true
```

**For array methods:**
- Guard check root field exists and is an array
- Bounds check index
- Perform mutation in-place
- Call mark_changed()
- Return success bool

---

## Notes for Implementation (U2)

1. **Location:** Add all three methods to `KotorGFFDocument` base class (resources/documents/kotor_gff_document.gd)
2. **Override in KotorDLGDocument:** Can add DLG-specific validation if needed (e.g., enforce Index bounds for RepliesList/EntriesList)
3. **Signal Pattern:** Use existing `mark_changed()` infrastructure — no new signal machinery needed
4. **Bounds Checking:** Return false on invalid index; don't throw exceptions
5. **No Reference Updates:** Array methods are "dumb mutations" — they don't update Index fields or validate references. That's the validator's job (U4).

---

## Verification Checklist for U1

- [x] Method contracts documented with args, returns, side effects
- [x] Reference validation rule (reordering doesn't update siblings) documented
- [x] Struct initialization defaults specified with rationale
- [x] Pattern precedent (set_struct_field) identified and referenced
- [x] mark_changed() behavior confirmed
- [x] Notes for U2 implementation provided

**Status:** ✅ Complete. Ready for U2 implementation.
