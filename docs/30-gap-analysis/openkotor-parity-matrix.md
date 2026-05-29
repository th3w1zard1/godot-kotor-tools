# OpenKotOR Parity Matrix (PyKotor + HolocronToolset -> godot-kotor-tools)

Date: 2026-05-29
Source method: gh CLI repository metadata, README content, and recursive tree path sampling for OpenKotOR/PyKotor and OpenKotOR/HolocronToolset.

## Purpose

Track feature parity between upstream OpenKotOR toolchains and godot-kotor-tools in a way that is actionable for Godot editor implementation slices.

## Upstream Surfaces Considered

- PyKotor library
  - extract subsystem (`pykotor/extract/*`)
  - resource formats (`pykotor/resource/formats/*`)
  - tools utilities (`pykotor/tools/*`)
- HolocronToolset GUI
  - editors (`src/toolset/gui/editors/*`)
  - dialogs/widgets/windows (`src/toolset/gui/dialogs|widgets|windows/*`)

## Legend

- `Shipped`: broadly available in Godot editor flow now.
- `Partial`: core support exists but editor UX depth or workflow breadth is below upstream.
- `Planned`: tracked for a dedicated parity slice.
- `Not started`: no dedicated parity slice yet.

## Capability Families

| Family | Upstream examples | godot-kotor-tools status | Notes |
| --- | --- | --- | --- |
| Core GFF parsing/editing | Holocron editors: utc/utp/uti/utd/ute/utm/uts/utt/utw, gff; PyKotor `formats/gff/*` | Partial | Q13: typed factory for all Holocron blueprint families; Q14 (shipped 2026-05-29): script hooks, trap fields, map notes, appearance IDs in summaries and GFF tree pickers. |
| Extended GFF-family routes | jrl, pth, fac editor surfaces in Holocron | Partial | Routing parity expanded in current slice (`jrl`, `pth`, `fac` route into GFF workspace editor). |
| DLG editing | Holocron DLG editor stack (`editors/dlg/*`) | Partial | Q6 shipped struct/array mutation UI; continue with advanced dialogue tooling parity. |
| 2DA editing | Holocron `twoda` editor; PyKotor `formats/twoda/*` | Shipped | Parser/importer/editor/write-back available. |
| TLK editing | Holocron `tlk` editor; PyKotor `formats/tlk/*` | Shipped | Parser/importer/editor/write-back available. |
| NSS/script editing | Holocron `nss` editor; PyKotor NCS/NSS tooling | Partial | Text editor + validation + counterpart lookup shipped; deeper script tool parity remains. |
| Archive formats | ERF/RIM/MOD, BIF/KEY | Partial | ERF/RIM/MOD write-back shipped; broader archive utilities and workflows remain. |
| Texture/media editing | tpc/tga/dds/wav/lip/mdl surfaces | Partial | TPC read/import available; full media editor parity not complete. |
| Install-aware extraction/indexing | PyKotor `extract/installation`, talktable, key/chitin flows | Shipped | GameFS index and install-aware browsing/mutation workflow available. |
| Module/area designer workflows | Holocron module designer, indoor builder, walkmesh/lyt tools | Partial | Q15 (shipped 2026-05-29): Module Designer tab with typed GIT instances, 2D map, instance tree, bundle context, save/install. Q16 (shipped 2026-05-29): SubViewport 3D markers, LYT room overlay, three-way selection sync, override-first layout bundle resolution. Q17 (shipped 2026-05-29): BWM/WOK walkmesh read + semi-transparent 3D overlay (walkable vs blocked materials), area `.wok` in module bundle. Q18 (shipped 2026-05-29): K1 MDL trimesh read + flat-shaded LYT room meshes in 3D viewport via GameFS `mdl`/`mdx` resolution; blue box fallback when missing. Q19+: indoor builder, GIT template models. |
| Patching/diff tooling parity | HoloPatcher, KotorDiff | Not started | Out of current in-editor scope; can be linked as companion tooling initially. |
| Advanced utility tools | PyKotor tools (modulekit, references, texture batch, model helpers) | Not started | Candidate backlog for targeted Godot utility panels or CLI integration. |

## Current Godot Editor Functionality (Operational)

- Install-aware resource browser (indexed game install, variants, open/export/install/compare actions)
- Workspace editors:
  - GFF-family entity editor (`utc`, `utp`, `uti`, `utd`, `ute`, `utm`, `uts`, `utt`, `utw`, `are`, `ifo`, `jrl`, `pth`, `fac`)
  - Module Designer (`.git` area layout: instance map, 3D viewport, tree, bundle context)
  - DLG editor
  - 2DA editor
  - TLK editor
  - NSS script editor
- Mutation safety and recoverability:
  - Preflight + preview for install/export flows
  - Transaction history + rollback support
  - Undo/redo boundaries for major document mutation paths
- Serializer/write-back coverage:
  - GFF-family
  - TLK
  - 2DA
  - Archive parity for ERF/RIM/MOD

## Next Parity Slices

1. **Q13 (shipped 2026-05-29):** Typed `UTT`/`UTW` resources + documents in GFF factory; see `docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md`.
2. **Q14 (shipped 2026-05-29):** Blueprint field-depth parity — script hook NSS pickers, trap summaries/`TrapList` editing, appearance enum labels; see `docs/plans/2026-05-29-019-feat-q14-blueprint-field-depth-plan.md`.
3. Script tooling parity expansion (NCS compile/decompile workflows and diagnostics).
4. Media/tooling parity wave (LIP/SSF/TPC advanced editing and previews).
5. Module/area designer parity wave (LYT/walkmesh/module designer tooling).

## Evidence Notes

- Upstream capability references were derived via `gh` CLI on 2026-05-28.
- This matrix should be updated per shipped slice and linked from strategy + execution queue.
