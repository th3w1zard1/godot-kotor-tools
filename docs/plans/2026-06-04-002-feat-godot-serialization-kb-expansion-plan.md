---
title: "feat: Expand Godot serialization knowledgebase with 4.6 API evidence and parity matrix"
status: "active"
created: "2026-06-04"
owner: "lfg"
origin: user-request-kb-docs-researcher-lfg
---

## Summary

Refresh and extend the Godot serialization knowledgebase with Godot 4.6 official API evidence, a loader/saver/importer parity matrix grounded in repo inventory, per-format serialization checklists, and cache-mode validation guidance for contributors.

---

## Problem Frame

`docs/00-intent/godot-serialization-kb-intent.md` and adjacent layers exist but lack a maintained parity matrix tying each Aurora format to its importer/saver/pipeline coverage. The source map still points at `/en/stable/` URLs and omits CacheMode/SaverFlags contracts. Playbook next actions call for per-format checklists that are not yet written.

---

## Scope Boundaries

### In scope

- Refresh `docs/90-meta/godot-doc-source-map.md` with 4.6 URLs and CacheMode/SaverFlags references.
- Add `docs/50-execution/godot-loader-saver-importer-parity-matrix.md`.
- Add per-format checklists under `docs/50-execution/format-serialization-checklists/`.
- Update intent, architecture, and playbook docs with cross-links and cache-mode guidance.

### Deferred for later

- Implementing `ResourceFormatLoader` for direct on-disk Aurora loading.
- Automated doc-source refresh tooling or Context7 integration.

### Out of scope

- Plugin runtime or format parser code changes.
- OpenKotOR/Holocron feature parity (tracked separately).

---

## Requirements

- **R1:** Source map lists Godot 4.6 canonical URLs for all APIs named in the intent doc, plus CacheMode and SaverFlags.
- **R2:** Parity matrix enumerates each supported format family with importer, saver, pipeline serialize, and round-trip test status.
- **R3:** Per-format checklists exist for GFF-family, 2DA, TLK, ERF/RIM/MOD, SSF, and LIP with pre-implementation gates from official API contracts.
- **R4:** Architecture and playbook docs link to the matrix and document cache-mode expectations for post-write-back reload validation.
- **R5:** Intent doc next-actions reflect shipped artifacts and remaining gaps.

---

## Key Technical Decisions

- **Matrix location:** `docs/50-execution/` alongside playbook and execution queue — same audience, same maintenance trigger.
- **Checklist granularity:** One checklist per format family (not per GFF extension) because GFF shares one importer/saver/writer stack.
- **Loader column:** Document as "Not registered" with rationale (import→`.tres` path) rather than implying missing implementation is a bug.
- **Evidence labels:** Use `[OFFICIAL]` / `[REPO]` / `[SYNTH]` in new docs per build-knowledgebase contract.

---

## Implementation Units

### U1. Refresh godot-doc-source-map (4.6 evidence)

**Requirements:** R1

**Files:**
- `docs/90-meta/godot-doc-source-map.md`

**Approach:** Replace stable URLs with 4.6 URLs where available; add CacheMode enum, SaverFlags, `add_import_plugin` lifecycle links.

### U2. Add loader/saver/importer parity matrix

**Requirements:** R2

**Files:**
- `docs/50-execution/godot-loader-saver-importer-parity-matrix.md`

**Approach:** Inventory from `kotor_importer_registry.gd`, `kotor_saver_registry.gd`, `kotor_modding_pipeline.gd`, and `formats/*_writer.gd`.

### U3. Add per-format serialization checklists

**Requirements:** R3

**Files:**
- `docs/50-execution/format-serialization-checklists/README.md`
- `docs/50-execution/format-serialization-checklists/gff-family.md`
- `docs/50-execution/format-serialization-checklists/twoda-tlk.md`
- `docs/50-execution/format-serialization-checklists/erf-rim-mod.md`
- `docs/50-execution/format-serialization-checklists/ssf-lip.md`

### U4. Cross-link and cache-mode guidance

**Requirements:** R4, R5

**Files:**
- `docs/00-intent/godot-serialization-kb-intent.md`
- `docs/10-architecture-runtime/godot-editor-resource-pipeline.md`
- `docs/50-execution/godot-kotor-implementation-playbook.md`

**Verification:**
- All new doc links resolve from intent doc.
- `git diff --check` passes on touched markdown.

---

## Test Scenarios

- Happy path: contributor opens intent doc and reaches parity matrix and format checklist within two clicks.
- Edge case: matrix clearly distinguishes pipeline-only serialize (SSF/LIP) from ResourceFormatSaver registration.
- Integration: checklist pre-implementation gates align with official EditorImportPlugin and ResourceFormatSaver contracts.
