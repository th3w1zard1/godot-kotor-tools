---
title: HolocronToolset Full Parity Master Plan (Godot Editor Plugin)
type: feat
status: active
date: 2026-05-29
origin: user-request-lfg-ce-ideate-holocron-parity
phase: Parity Program
track: OpenKotOR Parity
supersedes: none
related:
  - docs/plans/2026-05-28-017-feat-openkotor-parity-program-plan.md
  - docs/30-gap-analysis/openkotor-parity-matrix.md
---

# HolocronToolset Full Parity Master Plan

## Executive summary

HolocronToolset is a **Python/Qt standalone application** built on **PyKotor**. godot-kotor-tools is a **Godot 4.6 editor plugin** with install-aware GameFS, document-driven mutation, and workspace editors. **Functional parity** means modders can complete the same high-frequency edit/install loops inside Godot—not a line-for-line port of Holocron's UI or PyKotor's Python APIs.

**Honest scope:** Full Holocron + PyKotor parity spans **dozens of editor surfaces**, **3D module design**, **model/walkmesh tooling**, and **CLI utilities**. This plan defines the authoritative inventory, phased roadmap, and verification gates. **100% parity is the north star; delivery is incremental vertical slices** (Q13+), each with tests and matrix updates.

## Problem frame

Modders want one Godot-native workspace that can **open, edit, validate, and write back** any KotOR/Jade Empire resource Holocron handles, with the same safety expectations (install-aware paths, undo, preflight). Current plugin strength is GFF-family workspace editing, DLG/2DA/TLK/NSS, and ERF/RIM/MOD write-back. Gaps cluster in **typed GFF depth**, **media editors**, **script bytecode tooling**, and **spatial/module designers**.

## Upstream inventory (Holocron editors → Godot status)

Evidence: `gh api repos/OpenKotOR/HolocronToolset/contents/src/toolset/gui/editors` (2026-05-29).

| Holocron editor | Resource / role | godot-kotor-tools | Target phase |
| --- | --- | --- | --- |
| `utc.py` | Creature blueprint | Partial (typed UTC + arrays) | Q13–Q14 depth |
| `utp.py` | Placeable blueprint | Partial (typed UTP) | Q13–Q14 |
| `uti.py` | Item blueprint | Partial (typed UTI + inventory) | Q13–Q14 |
| `utd.py` | Door blueprint | Partial (typed UTD) | Q13 |
| `ute.py` | Encounter blueprint | Partial (typed UTE) | Q13 |
| `utm.py` | Store blueprint | Partial (typed UTM) | Q13 |
| `uts.py` | Sound blueprint | Partial (typed UTS) | Q13 |
| `utt.py` | Trigger blueprint | **Q13 slice** (typed UTT) | Q13 |
| `utw.py` | Waypoint blueprint | **Q13 slice** (typed UTW) | Q13 |
| `are.py` | Area metadata | Partial (typed ARE) | Q14 |
| `git.py` | Area instances | Partial (typed GIT + Q124 instance CRUD) | Q15–Q124 module wave |
| `ifo.py` | Module info | Partial (typed IFO) | Q15 |
| `jrl.py` | Journal | Partial (typed JRL) | Q13 shipped Q1–Q12 era |
| `pth.py` | Path / waypoints list | Partial (typed PTH) | Q13 |
| `fac.py` | Faction | Partial (typed FAC) | Q13 |
| `gff.py` | Generic GFF | Shipped (GFF workspace) | Maintain |
| `dlg/` | Dialogue | Partial (Q6+ DLG editor) | Q16 dialogue depth |
| `twoda.py` | 2DA tables | Shipped | Maintain |
| `tlk.py` | Talk tables | Shipped | Maintain |
| `nss.py` | NWScript source | Partial | Q17 script wave |
| `erf.py` | ERF archives | Partial (write-back) | Q18 archive UX |
| `tpc.py` | Textures | Partial (import/read) | Q19 media |
| `wav.py` | Audio | Partial (WAV workspace + batch/compare) | Q27–Q29, Q38, Q104–Q109, Q116 |
| `lip.py` | Lip sync | Partial (LIP workspace + batch) | Q29–Q31, Q118 |
| `ssf.py` | Sound set | Partial (SSF workspace) | Q27 |
| `ltr.py` | Letter / font | Partial (parser + workspace editor) | Q131 |
| `mdl.py` | Models | Partial (Model Editor + batch/compare + write-back phase 0) | Q84–Q85, Q91–Q93, Q119–Q123, Q133 |
| `bwm.py` | Walkmesh | Partial (overlay + install + Q126 paint) | Q17, Q56, Q94, Q126 |
| `savegame.py` | Save games | Partial (read-only inspector) | Q132 |
| `txt.py` | Plain text | Shipped (text editor path) | Maintain |

## Upstream windows (not editor tabs)

| Holocron window | godot-kotor-tools | Target phase |
| --- | --- | --- |
| `main.py` | Partial (dock + workspace shell) | Ongoing UX |
| `module_designer.py` | Partial (GIT/PTH/LYT/VIS/WOK + Q124 CRUD + Q126 paint) | Q15–Q73, Q124–Q126 |
| `indoor_builder/` | Partial (native indoor mod export/install) | Q47, Q55–Q57 |
| `kotordiff.py` | Partial (compare flows) | Q18 diff depth |

## PyKotor format families (library layer)

Evidence: `Libraries/PyKotor/src/pykotor/resource/formats/*` (2026-05-29).

| Format dir | Godot parser/editor | Phase |
| --- | --- | --- |
| `gff` | Shipped (core) | Maintain |
| `twoda`, `tlk` | Shipped | Maintain |
| `erf`, `rim` | Partial write-back | Q18 |
| `bif`, `key` | Partial (index/extract) | Q18 |
| `ncs` | Partial (NSS editor, no full decompile UI) | Q17 |
| `tpc`, `wav`, `lip`, `ssf` | Partial (workspace + batch tooling) | Q27–Q31, Q77–Q82, Q104–Q118 |
| `mdl`, `bwm`, `lyt`, `vis` | Partial (module designer + model editor) | Q17–Q18, Q56, Q84–Q85, Q91–Q94, Q126 |
| `ltr` | Partial (parser + workspace editor) | Q131 |

## Architecture principles (non-negotiable)

1. **Vertical slices:** parser/importer → typed resource/document → workspace editor → serializer → tests → docs/matrix.
2. **Document-driven mutation:** all edits flow through `Kotor*Document` + mutation service; no ad-hoc binary pokes in UI.
3. **Install-aware GameFS:** ResRef pickers, 2DA labels, and export/install preflight stay authoritative.
4. **Godot-native UX:** SubViewport/module tools use Godot 3D/editor APIs; do not embed Qt.
5. **Parity matrix is backlog truth:** every shipped slice updates `openkotor-parity-matrix.md` and execution queue.

## Phased roadmap

### Phase A — Q13: Complete GFF blueprint typed coverage (this LFG slice)

**Goal:** Every Holocron GFF blueprint editor (`utc`…`utw`, `jrl`, `pth`, `fac`) has a typed `*Resource` + `Kotor*Document` factory mapping and factory tests.

**Deliverables:**

- `resources/typed/utt_resource.gd`, `resources/typed/utw_resource.gd`
- `resources/documents/kotor_utt_document.gd`, `resources/documents/kotor_utw_document.gd`
- `resources/gff_resource_factory.gd` UTW registration
- `tests/editor/test_gff_resource_factory.gd` UTT/UTW cases
- Parity matrix + execution queue Q13 entry

**Verification:**

```bash
godot --headless --path . --script tests/editor/test_gff_resource_factory.gd
```

### Phase B — Q14: Blueprint field-depth parity

Holocron-specific panels (scripts, trap DCs, map notes, appearance IDs) as inspector-guided fields on typed documents—not just summary lines.

### Phase C — Q15–Q16: Module / area designer

GIT instance editing in 3D, LYT/BWM visualization, indoor builder analog. Requires new editor plugin region + SubViewport architecture.

### Phase D — Q17: NSS/NCS toolchain

Compile/decompile diagnostics parity with Holocron script tools; bytecode round-trip tests.

### Phase E — Q18: Archive + diff utilities

ERF/BIF/KEY UX, KotorDiff-style compare reports inside workspace.

### Phase F — Q19–Q22: Media, models, saves

TPC/WAV/LIP/SSF editors, MDL/BWM, savegame tooling.

## Requirements (master program)

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | Holocron editor inventory mapped to status in parity matrix | Matrix row per family |
| R2 | Each GFF blueprint type has factory typed resource | Factory tests pass |
| R3 | Workspace routing opens correct editor for extension | Dock routing tests |
| R4 | Write-back round-trip for edited types | Serializer tests / manual golden |
| R5 | README/QUICKSTART reflect shipped coverage | Doc review |
| R6 | No regression in mutation safety (undo/preflight) | Existing editor tests |

## Explicit non-goals (program level)

- Rewriting PyKotor in GDScript as a library duplicate.
- Pixel-perfect Holocron UI clone.
- Shipping module designer + full media stack in a single PR.
- HoloPatcher CLI reimplementation inside Godot (link/companion only until dedicated slice).

## Current slice implementation units (Q13)

### U1 — UTT typed resource

- Files: `resources/typed/utt_resource.gd`, existing `kotor_utt_document.gd`
- Tests: `_test_utt_factory_mapping`

### U2 — UTW typed resource + document

- Files: `resources/typed/utw_resource.gd`, `resources/documents/kotor_utw_document.gd`
- Factory: add `"UTW": UTWResource`
- Tests: `_test_utw_factory_mapping`

### U3 — Documentation sync

- Update parity matrix next slices + Q13 shipped note
- Update execution queue with Q13 row

## Success criteria for this LFG pass

- [x] Master plan published (this document)
- [ ] Q13 code + tests green
- [ ] Parity matrix reflects UTT/UTW typed factory parity
- [ ] PR opened with honest remaining backlog (Phases B–F)

## Residual backlog after Q13 (expected)

Module designer, indoor builder, BWM/MDL/LYT, TPC/WAV/LIP/SSF, and compare/batch tooling are **Partial** per the editor inventory above (Q15–Q126). Q132 *(PR #122)* ships read-only savegame inspector foundations. Q133 *(PR #123)* ships MDL write-back phase 0 (passthrough plumbing). Remaining **Planned/Not started** areas: full DLG graph editor, NCS decompile UI, savegame editing/write-back, HoloPatcher/KotorDiff parity, and MDL geometry mutation authoring.
