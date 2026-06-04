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
| DLG editing | Holocron DLG editor stack (`editors/dlg/*`) | Partial | Q6 shipped struct/array mutation UI; Q33 (shipped 2026-06-04): jump-to-target link navigation in DLG tree. |
| 2DA editing | Holocron `twoda` editor; PyKotor `formats/twoda/*` | Shipped | Parser/importer/editor/write-back available. |
| TLK editing | Holocron `tlk` editor; PyKotor `formats/tlk/*` | Shipped | Parser/importer/editor/write-back available. |
| NSS/script editing | Holocron `nss` editor; PyKotor NCS/NSS tooling | Partial | Q26 (shipped 2026-05-29): PyKotor CLI bridge for `assemble`/`decompile`/`disassemble` in Script tab (Compile/Decompile/Disassemble toolbar); reuses `pykotor_cli_path` + install inference. Prior: text editor, validation, counterpart lookup. |
| Archive formats | ERF/RIM/MOD, BIF/KEY | Partial | ERF/RIM/MOD write-back shipped; broader archive utilities and workflows remain. |
| Texture/media editing | tpc/tga/dds/wav/lip/mdl surfaces | Partial | Q27–Q29 shipped SSF/TPC preview/WAV/LIP tooling. Q30 (shipped 2026-06-04): native `TPCWriter` passthrough + RGBA encode, Import TGA/PNG in TPC editor, pipeline `tpc` validation. Q31 (shipped 2026-06-04): `LipBatchGenerator` batch placeholder LIP from PCM WAV folder; LIP editor **Batch Generate LIP...**. DXT encode remains backlog. |
| Install-aware extraction/indexing | PyKotor `extract/installation`, talktable, key/chitin flows | Shipped | GameFS index and install-aware browsing/mutation workflow available. |
| Module/area designer workflows | Holocron module designer, indoor builder, walkmesh/lyt tools | Partial | Q15 (shipped 2026-05-29): Module Designer tab with typed GIT instances, 2D map, instance tree, bundle context, save/install. Q16 (shipped 2026-05-29): SubViewport 3D markers, LYT room overlay, three-way selection sync, override-first layout bundle resolution. Q17 (shipped 2026-05-29): BWM/WOK walkmesh read + semi-transparent 3D overlay (walkable vs blocked materials), area `.wok` in module bundle. Q18 (shipped 2026-05-29): K1 MDL trimesh read + flat-shaded LYT room meshes in 3D viewport via GameFS `mdl`/`mdx` resolution; blue box fallback when missing. Q19 (shipped 2026-05-29): GIT creature/placeable/door template → blueprint GFF + 2DA → MDL mesh in 3D viewport; cube marker fallback. Q20 (shipped 2026-05-29): GIT instance drag-move on 2D map with EditorUndoRedoManager undo and dirty refresh across map/tree/3D. Q21 (shipped 2026-05-29): GIT instance right-drag bearing rotate on 2D map with live preview, undo/redo, and `set_instance_bearing` document API. Q22 (shipped 2026-05-29): Indoor Builder tab with Holocron/PyKotor `.indoor` JSON I/O, room tree + 2D map, drag-move and right-drag rotation with undo, filesystem save, session restore (`editor_kind == "indoor"`). Q23 (shipped 2026-05-29): Holocron/PyKotor on-disk indoor kit library (`KotorIndoorKitLoader`/`KotorIndoorKitLibrary`), kit/component pickers, add room from kit with undo, resource-browser `.indoor` routing, persisted kits path in editor settings. Q24 (shipped 2026-05-29): PyKotor-compatible hook world positions + `rebuild_connections` (`KotorIndoorHookConnections`), runtime connection cache on `KotorIndoorDocument`, map hook markers, room hook summaries, auto-rebuild on room mutations. Q25 (shipped 2026-05-29): PyKotor CLI `indoor-build` bridge (`KotorIndoorModExporter`), Export `.mod` toolbar action, optional `pykotor_cli_path` setting, preflight validation. Q48 (shipped 2026-06-04): native MOD assembly from indoor writers + kit assets. Q50 (shipped 2026-06-04): embedded component base64 BWM/MDL/MDX decoded into native MOD room assets. Q52 (shipped 2026-06-04): GIT 3D bearing ring gizmo + Shift+right-drag rotate in Module Designer viewport. Q53 (shipped 2026-06-04): LYT depth overlay — tracks/obstacles/doorhooks markers, `LYTWriter`, layout/walkmesh summary. Q26+: native `IndoorMap.build()` port. Script tooling: Q26 (shipped 2026-05-29) — see NSS row. |
| Patching/diff tooling parity | HoloPatcher, KotorDiff | Partial | Q32–Q38 semantic compare for GFF/SSF/LIP/TPC/WAV plus 2DA/TLK; install diff reports label structural/media changes. Q40 (shipped 2026-06-04): batch override compare scan in dock with aggregated semantic diff reports. Q41 (shipped 2026-06-04): compare report export to `.txt` from dock. Q49 (shipped 2026-06-04): KotorDiff CLI bridge — `KotorDiffToolBridge` invokes standalone kotordiff or PyKotor `diff` from GameFS **Run KotorDiff CLI…**. Q51 (shipped 2026-06-04): HoloPatcher CLI bridge — `HoloPatcherToolBridge` validate/install TSL patches from GameFS dock. |
| Advanced utility tools | PyKotor tools (modulekit, references, texture batch, model helpers) | Not started | Candidate backlog for targeted Godot utility panels or CLI integration. |

## Current Godot Editor Functionality (Operational)

- Install-aware resource browser (indexed game install, variants, open/export/install/compare actions)
- Workspace editors:
  - GFF-family entity editor (`utc`, `utp`, `uti`, `utd`, `ute`, `utm`, `uts`, `utt`, `utw`, `are`, `ifo`, `jrl`, `pth`, `fac`)
  - Module Designer (`.git` area layout: instance map, 3D viewport, tree, bundle context)
  - Indoor Builder (`.indoor` JSON layout: room map, tree, Holocron kit library, hook connection visualization, filesystem save)
  - DLG editor
  - 2DA editor
  - TLK editor
  - NSS script editor
  - SSF, TPC, WAV, and LIP Sync media workspace editors
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
3. **Q26 (shipped 2026-05-29):** Script tooling parity — PyKotor CLI `assemble`/`decompile`/`disassemble` via `KotorScriptToolBridge`; see `docs/plans/2026-05-29-031-feat-q26-nss-ncs-script-tools-plan.md`.
4. **Q28 (shipped 2026-05-29):** LIP lip-sync — native V1.0 parser/writer, LIP Sync workspace editor, pipeline serialize; see `docs/plans/2026-05-29-033-feat-q28-lip-tooling-plan.md`.
5. **Q29 (shipped 2026-05-29):** LIP audio + waveform — shared `WavMetadata`, paired WAV playback/scrub, viseme preview, duration sync prompt; see `docs/plans/2026-05-29-034-feat-q29-lip-audio-waveform-plan.md`.
6. **Q30 (shipped 2026-06-04):** TPC native write-back — `TPCWriter`, Import TGA/PNG, pipeline validate; see `docs/plans/2026-06-04-003-feat-q30-tpc-write-back-plan.md`.
7. **Q31 (shipped 2026-06-04):** Batch LIP generator — `LipBatchGenerator`, LIP editor folder action; see `docs/plans/2026-06-04-004-feat-q31-batch-lip-generator-plan.md`.
8. **Q32 (shipped 2026-06-04):** Semantic GFF compare — field-level install diff for GFF/DLG/UTC/etc.; see `docs/plans/2026-06-04-005-feat-q32-semantic-gff-compare-plan.md`.
9. **Q33 (shipped 2026-06-04):** DLG jump-to-target — link navigation in DLG tree; see `docs/plans/2026-06-04-006-feat-q33-dlg-jump-to-target-plan.md`.
10. **Q35 (shipped 2026-06-04):** SSF semantic compare — slot-level install diff; see `docs/plans/2026-06-04-008-feat-q35-ssf-semantic-compare-plan.md`.
11. **Q36 (shipped 2026-06-04):** LIP semantic compare — duration/keyframe install diff; see `docs/plans/2026-06-04-009-feat-q36-lip-semantic-compare-plan.md`.
12. **Q37 (shipped 2026-06-04):** TPC semantic compare — header/payload install diff; see `docs/plans/2026-06-04-010-feat-q37-tpc-semantic-compare-plan.md`.
13. **Q38 (shipped 2026-06-04):** WAV semantic compare — format/duration install diff; see `docs/plans/2026-06-04-011-feat-q38-wav-semantic-compare-plan.md`.
14. **Q39 (shipped 2026-06-04):** Indoor layout validation — module/kit/hook preflight before `.mod` export; see `docs/plans/2026-06-04-012-feat-q39-indoor-layout-validation-plan.md`.
15. **Q40 (shipped 2026-06-04):** Batch override compare — install-wide override scan in dock; see `docs/plans/2026-06-04-013-feat-q40-override-batch-compare-plan.md`.
16. **Q41 (shipped 2026-06-04):** Compare report export — save compare output to `.txt`; see `docs/plans/2026-06-04-014-feat-q41-compare-report-export-plan.md`.
17. **Q42 (shipped 2026-06-04):** Native indoor build manifest — module/room asset preview before native build; see `docs/plans/2026-06-04-015-feat-q42-indoor-build-manifest-plan.md`.
18. **Q43 (shipped 2026-06-04):** Native indoor LYT builder — `.lyt` roommodel generation from layouts; see `docs/plans/2026-06-04-016-feat-q43-indoor-lyt-builder-plan.md`.
19. **Q44 (shipped 2026-06-04):** Native indoor IFO builder — module `.ifo` GFF generation from layouts; see `docs/plans/2026-06-04-017-feat-q44-indoor-ifo-builder-plan.md`.
20. **Q45 (shipped 2026-06-04):** Native indoor VIS builder — hook-based `.vis` visibility generation; see `docs/plans/2026-06-04-018-feat-q45-indoor-vis-builder-plan.md`.
21. **Q46 (shipped 2026-06-04):** Native indoor ARE builder — module `.are` GFF from layout lighting/skybox; see `docs/plans/2026-06-04-019-feat-q46-indoor-are-builder-plan.md`.
22. **Q47 (shipped 2026-06-04):** Native indoor GIT builder — door instances at hook connections; see `docs/plans/2026-06-04-020-feat-q47-indoor-git-builder-plan.md`.
23. **Q48 (shipped 2026-06-04):** Native indoor MOD builder — ERF `.mod` assembly from native writers + kit assets; see `docs/plans/2026-06-04-021-feat-q48-indoor-mod-builder-plan.md`.
24. **Q49 (shipped 2026-06-04):** KotorDiff CLI bridge — standalone kotordiff / PyKotor `diff` from GameFS dock; see `docs/plans/2026-06-04-022-feat-q49-kotordiff-cli-bridge-plan.md`.
25. **Q50 (shipped 2026-06-04):** Embedded component asset generation — base64 BWM/MDL/MDX into native MOD room assets; see `docs/plans/2026-06-04-023-feat-q50-embedded-component-asset-generation-plan.md`.
26. **Q51 (shipped 2026-06-04):** HoloPatcher CLI bridge — validate/install TSL patches from GameFS dock; see `docs/plans/2026-06-04-024-feat-q51-holopatcher-cli-bridge-plan.md`.
27. **Q52 (shipped 2026-06-04):** GIT 3D rotate gizmo — bearing ring + Shift+right-drag in Module Designer viewport; see `docs/plans/2026-06-04-025-feat-q52-git-3d-rotate-gizmo-plan.md`.
28. **Q53 (shipped 2026-06-04):** LYT depth overlay + writer — tracks/obstacles/doorhooks in 3D viewport and `LYTWriter` round-trip; see `docs/plans/2026-06-04-026-feat-q53-lyt-depth-overlay-plan.md`.
29. Module/area designer parity wave (walkmesh write-back, indoor native build parity).

## Evidence Notes

- Upstream capability references were derived via `gh` CLI on 2026-05-28.
- This matrix should be updated per shipped slice and linked from strategy + execution queue.
