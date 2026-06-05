---
title: "feat: Q30 native TPC write-back (TPCWriter + import TGA path)"
type: feat
status: completed
date: 2026-06-04
origin: lfg-main-next-parity-slice
phase: Q30
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-05-29-032-feat-q27-media-tooling-plan.md
  - docs/50-execution/godot-loader-saver-importer-parity-matrix.md
---

# Q30: Native TPC Write-Back

## Summary

Add native `TPCWriter` for KotOR TPC textures with passthrough round-trip and RGBA mip-0 encoding, wire TPC workspace import-from-TGA, pipeline serialize for `.tpc`, and headless tests. Closes the "full TPC write-back" gap left after Q27 preview/export-only tooling.

---

## Problem Frame

Q27 shipped TPC preview, metadata display, passthrough save of unchanged bytes, and PyKotor `texture-convert` TGA **export**. Modders cannot round-trip edited textures back into TPC without leaving Godot. The parity matrix lists "full TPC write-back" as backlog; pipeline has no `tpc` serialize arm.

---

## Scope Boundaries

### In scope

- `formats/tpc_writer.gd` — passthrough + RGBA encode (mip 0, num_mips=1)
- `tests/editor/test_tpc_writer.gd` — synthetic round-trip tests
- TPC workspace editor "Import TGA..." → rebuild as RGBA TPC
- `kotor_modding_pipeline.gd` `tpc` serialize via `TPCWriter`
- Parity matrix + execution queue Q30 entry

### Deferred

- Native DXT1/DXT3/DXT5 **encoding** (keep decode-only; modders can use PyKotor CLI when DXT output required)
- Mipmap generation beyond mip 0
- TXI sidecar editing UI
- TPC ResourceFormatSaver / EditorImportPlugin changes

### Out of scope

- Texture paint / in-editor pixel editing
- Batch texture conversion

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `TPCWriter.serialize_passthrough(bytes)` preserves valid TPC bytes byte-identical | `test_tpc_writer.gd` |
| R2 | `TPCWriter.serialize_rgba(image, alpha_test)` writes valid RGBA TPC readable by `TPCReader` | `test_tpc_writer.gd` |
| R3 | Imported TGA rebuilds `_bytes` as RGBA TPC and marks document dirty | TPC editor import path |
| R4 | Pipeline `_serialize_payload` handles `tpc` + `PackedByteArray` or writer path | Pipeline test or writer unit test |
| R5 | Parity matrix + execution queue document Q30 shipped | Doc diff |

---

## Key Technical Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Encoding scope | Passthrough + RGBA only | Matches reader support; DXT encode is large scope |
| Import path | Godot `Image.load()` from TGA/PNG | No PyKotor dependency for common modder loop |
| Alpha test | Preserve from source metadata on passthrough; 0.0 default on RGBA import | Matches TPC header field |
| TXI tail | Preserve on passthrough; omit on fresh RGBA encode | TXI rarely edited; avoid corrupting passthrough |

---

## Implementation Units

### U1. TPCWriter

**Requirements:** R1, R2

**Files:**
- `formats/tpc_writer.gd`

**Approach:**
- Mirror header layout from `formats/tpc_reader.gd` constants
- `serialize_passthrough(data)` validates via `TPCReader.read_metadata` then returns copy
- `serialize_rgba(image, alpha_test := 0.0)` converts to `Image.FORMAT_RGBA8`, writes header + pixels
- Return empty `PackedByteArray` on validation failure

**Test scenarios:**
- Passthrough 4x4 RGBA synthetic TPC → byte-identical
- RGBA encode 8x8 checker image → metadata ok, `read_image` dimensions match
- Invalid input → empty bytes

### U2. Headless tests

**Requirements:** R1, R2

**Files:**
- `tests/editor/test_tpc_writer.gd`

**Approach:** Build minimal TPC bytes inline (128-byte header + pixels); no external fixtures.

### U3. TPC workspace import TGA

**Requirements:** R3

**Files:**
- `ui/workspace/editors/tpc_workspace_editor.gd`

**Approach:**
- Toolbar "Import TGA/PNG..." opens file dialog
- Load image, call `TPCWriter.serialize_rgba`, replace `_bytes`, refresh preview, set `_dirty = true`
- Preserve `_file_name` basename; clear absolute `_source_path` when bytes replaced in-memory

### U4. Pipeline serialize

**Requirements:** R4

**Files:**
- `editor/modding/kotor_modding_pipeline.gd`

**Approach:** Add `"tpc"` match arm accepting `PackedByteArray` payload (same as raw bytes path) — editor already passes bytes.

### U5. Docs

**Requirements:** R5

**Files:**
- `docs/50-execution/godot-capability-execution-queue.md`
- `docs/30-gap-analysis/openkotor-parity-matrix.md`
- `docs/50-execution/godot-loader-saver-importer-parity-matrix.md`
- `docs/50-execution/format-serialization-checklists/` (TPC note if needed)

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_tpc_writer.gd
godot --headless --path . --check-only
```

---

## Acceptance

- [ ] TPC writer tests pass
- [ ] TPC editor imports TGA/PNG and preview updates
- [ ] Docs reflect Q30 partial→shipped write-back path
