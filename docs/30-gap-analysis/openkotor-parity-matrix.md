# OpenKotOR Parity Matrix (PyKotor + HolocronToolset -> godot-kotor-tools)

Date: 2026-06-05
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
| Texture/media editing | tpc/tga/dds/wav/lip/mdl surfaces | Partial | Q27–Q29 shipped SSF/TPC preview/WAV/LIP tooling. Q30 (shipped 2026-06-04): native `TPCWriter` passthrough + RGBA encode, Import TGA/PNG in TPC editor, pipeline `tpc` validation. Q31 (shipped 2026-06-04): `LipBatchGenerator` batch placeholder LIP from PCM WAV folder; LIP editor **Batch Generate LIP...**. Q77 (shipped 2026-06-07): `TpcBatchConverter` batch TGA/PNG→TPC from flat folders; TPC editor **Batch Convert TGA/PNG→TPC...**. Q79 (shipped 2026-06-07): `TpcBatchExporter` batch TPC→TGA via PyKotor CLI; TPC editor **Batch Export TGA...**. Q81 (shipped 2026-06-07): `TpcGamefsBatchExporter` install-indexed TPC→TGA batch export; TPC editor **Batch Export Install TGA...**. Q82 (shipped 2026-06-10): `TpcGamefsBatchImporter` install override TGA/PNG→TPC batch import; TPC editor **Batch Import Install TGA/PNG→TPC...**. Q83 (shipped 2026-06-10): `MdlGamefsBatchExporter` install-indexed MDL/MDX batch export with `MdlModelMetadataHelper`; resource browser **Batch Export Install MDL...**. Q84 (shipped 2026-06-10): `KotorMDLWorkspaceEditor` read-only MDL inspector with metadata, export/install, and workspace `.mdl` routing. Q85 (shipped 2026-06-10): `MdlPreviewViewport` 3D trimesh preview in Model Editor via `MdlMeshSurfaceBuilder`. Q86 (shipped 2026-06-10): `TpcDxtEncoder` + `TPCWriter.serialize_dxt1/dxt5` native DXT write-back. Q87 (shipped 2026-06-10): TPC editor **Re-encode DXT1/DXT5...** toolbar actions. Q88 (shipped 2026-06-10): `TpcBatchConverter` DXT1/DXT5 batch folder encode; TPC editor **Batch Convert DXT1/DXT5...**. Q89 (shipped 2026-06-10): `TpcGamefsBatchImporter` DXT1/DXT5 install batch import; TPC editor **Batch Import Install DXT1/DXT5...**. Q90 (shipped 2026-06-10): TPC editor **Import TGA/PNG as DXT1/DXT5...** single-file import. |
| Install-aware extraction/indexing | PyKotor `extract/installation`, talktable, key/chitin flows | Shipped | GameFS index and install-aware browsing/mutation workflow available. |
| Module/area designer workflows | Holocron module designer, indoor builder, walkmesh/lyt tools | Partial | Q15 (shipped 2026-05-29): Module Designer tab with typed GIT instances, 2D map, instance tree, bundle context, save/install. Q16 (shipped 2026-05-29): SubViewport 3D markers, LYT room overlay, three-way selection sync, override-first layout bundle resolution. Q17 (shipped 2026-05-29): BWM/WOK walkmesh read + semi-transparent 3D overlay (walkable vs blocked materials), area `.wok` in module bundle. Q18 (shipped 2026-05-29): K1 MDL trimesh read + flat-shaded LYT room meshes in 3D viewport via GameFS `mdl`/`mdx` resolution; blue box fallback when missing. Q19 (shipped 2026-05-29): GIT creature/placeable/door template → blueprint GFF + 2DA → MDL mesh in 3D viewport; cube marker fallback. Q20 (shipped 2026-05-29): GIT instance drag-move on 2D map with EditorUndoRedoManager undo and dirty refresh across map/tree/3D. Q21 (shipped 2026-05-29): GIT instance right-drag bearing rotate on 2D map with live preview, undo/redo, and `set_instance_bearing` document API. Q22 (shipped 2026-05-29): Indoor Builder tab with Holocron/PyKotor `.indoor` JSON I/O, room tree + 2D map, drag-move and right-drag rotation with undo, filesystem save, session restore (`editor_kind == "indoor"`). Q23 (shipped 2026-05-29): Holocron/PyKotor on-disk indoor kit library (`KotorIndoorKitLoader`/`KotorIndoorKitLibrary`), kit/component pickers, add room from kit with undo, resource-browser `.indoor` routing, persisted kits path in editor settings. Q24 (shipped 2026-05-29): PyKotor-compatible hook world positions + `rebuild_connections` (`KotorIndoorHookConnections`), runtime connection cache on `KotorIndoorDocument`, map hook markers, room hook summaries, auto-rebuild on room mutations. Q25 (shipped 2026-05-29): PyKotor CLI `indoor-build` bridge (`KotorIndoorModExporter`), Export `.mod` toolbar action, optional `pykotor_cli_path` setting, preflight validation. Q48 (shipped 2026-06-04): native MOD assembly from indoor writers + kit assets. Q50 (shipped 2026-06-04): embedded component base64 BWM/MDL/MDX decoded into native MOD room assets. Q52 (shipped 2026-06-04): GIT 3D bearing ring gizmo + Shift+right-drag rotate in Module Designer viewport. Q53 (shipped 2026-06-04): LYT depth overlay — tracks/obstacles/doorhooks markers, `LYTWriter`, layout/walkmesh summary. Q54 (shipped 2026-06-04): BWM writer + walkmesh export preview via `BWMWriter`. Q55 (shipped 2026-06-04): native indoor MOD export default via `KotorIndoorNativeExporter` (PyKotor CLI fallback retained). Q56 (shipped 2026-06-04): Module Designer walkmesh install to override via `BWMWriter`. Q57 (shipped 2026-06-04): Indoor Builder **Install MOD to Modules** via `KotorIndoorModuleInstaller`. Q58 (shipped 2026-06-04): Module Designer LYT install to override via `LYTWriter`. Q59 (shipped 2026-06-05): Module Designer VIS install to override via `VISWriter`. Q60 (shipped 2026-06-05): Module Designer PTH install to override via typed `PTHResource`. Q61 (shipped 2026-06-05): Module Designer LYT preview export writes loaded area layouts to filesystem `.lyt`. Q62 (shipped 2026-06-05): Module Designer VIS preview export writes loaded visibility graphs to filesystem `.vis`. Q63 (shipped 2026-06-05): Module Designer PTH preview export writes loaded path graphs to filesystem `.pth`. Q64 (shipped 2026-06-05): Module Designer PTH point overlay renders loaded path points in the 2D map and 3D viewport. Q65 (shipped 2026-06-05): Module Designer PTH connection overlay renders loaded path edges in the 2D map and 3D viewport. Q66 (shipped 2026-06-05): Module Designer PTH point inspection makes loaded path points tree/map/3D selectable with detail-panel connection context. Q67 (shipped 2026-06-05): Module Designer PTH connection inspection makes loaded path edges tree/map/3D selectable with source/target detail context and viewport edge highlighting. Q68 (shipped 2026-06-05): Module Designer PTH point drag-move lets loaded path points move on the 2D map with typed mutation, dirty-state tracking, and install-ready persistence. Q69 (shipped 2026-06-07): Module Designer PTH connection retarget lets loaded path connection destinations change from the 2D map with typed mutation, dirty-state tracking, and install-ready persistence. Q70 (shipped 2026-06-07): Module Designer PTH point add lets loaded path graphs grow via toolbar-armed map placement with typed mutation, dirty-state tracking, and install-ready persistence. Q71 (shipped 2026-06-07): Module Designer PTH point remove lets loaded path graphs shrink via topology-safe point removal with typed mutation, dirty-state tracking, and install-ready persistence. Q72 (shipped 2026-06-07): Module Designer PTH connection add lets loaded path graphs grow new edges via toolbar-armed source-to-target placement with typed mutation, dirty-state tracking, and install-ready persistence. Q78 (shipped 2026-06-07): `KotorModuleKitLoader` exposes module LYT rooms as Indoor Builder kits with **Refresh Module Kits**. Q26+: native `IndoorMap.build()` port. Script tooling: Q26 (shipped 2026-05-29) — see NSS row. |
| Patching/diff tooling parity | HoloPatcher, KotorDiff | Partial | Q32–Q38 semantic compare for GFF/SSF/LIP/TPC/WAV plus 2DA/TLK; install diff reports label structural/media changes. Q40 (shipped 2026-06-04): batch override compare scan in dock with aggregated semantic diff reports. Q41 (shipped 2026-06-04): compare report export to `.txt` from dock. Q49 (shipped 2026-06-04): KotorDiff CLI bridge — `KotorDiffToolBridge` invokes standalone kotordiff or PyKotor `diff` from GameFS **Run KotorDiff CLI…**. Q51 (shipped 2026-06-04): HoloPatcher CLI bridge — `HoloPatcherToolBridge` validate/install TSL patches from GameFS dock. Q91 (shipped 2026-06-10): `MdlCompare` semantic MDL override diff (vertices/faces/bounds). |
| Advanced utility tools | PyKotor tools (modulekit, references, texture batch, model helpers) | Partial | Q76 (shipped 2026-06-07): override-scoped ResRef references finder in workspace resource browser; see `docs/plans/2026-06-07-008-feat-q76-resref-references-finder-plan.md`. Q77 (shipped 2026-06-07): native batch TGA/PNG→TPC converter in TPC editor; see `docs/plans/2026-06-07-009-feat-q77-texture-batch-converter-plan.md`. Q78 (shipped 2026-06-07): `KotorModuleKitLoader` exposes module LYT rooms as Indoor Builder kits with **Refresh Module Kits**; see `docs/plans/2026-06-07-010-feat-q78-modulekit-loader-plan.md`. Q79 (shipped 2026-06-07): batch TPC→TGA export in TPC editor; see `docs/plans/2026-06-07-011-feat-q79-batch-tpc-export-plan.md`. Q81 (shipped 2026-06-07): install-scoped GameFS TPC batch export; see `docs/plans/2026-06-07-013-feat-q81-gamefs-tpc-batch-export-plan.md`. Q82 (shipped 2026-06-10): install-scoped GameFS TGA/PNG→TPC batch import; see `docs/plans/2026-06-10-014-feat-q82-gamefs-tpc-batch-import-plan.md`. Q83 (shipped 2026-06-10): install-scoped GameFS MDL batch export + model metadata helper; see `docs/plans/2026-06-10-015-feat-q83-gamefs-mdl-batch-export-plan.md`. Q84 (shipped 2026-06-10): read-only MDL workspace editor; see `docs/plans/2026-06-10-016-feat-q84-mdl-workspace-editor-plan.md`. Q85 (shipped 2026-06-10): MDL workspace 3D preview; see `docs/plans/2026-06-10-017-feat-q85-mdl-workspace-3d-preview-plan.md`. Q91 (shipped 2026-06-10): `MdlCompare` semantic MDL override diff; see `docs/plans/2026-06-10-023-feat-q91-mdl-semantic-compare-plan.md`. Q92 (shipped 2026-06-10): `MdlBatchExporter` flat-folder MDL/MDX copy; see `docs/plans/2026-06-10-024-feat-q92-mdl-batch-folder-export-plan.md`. Q93 (shipped 2026-06-10): `MdlGamefsBatchImporter` flat-folder MDL/MDX import to override; see `docs/plans/2026-06-10-025-feat-q93-mdl-batch-folder-import-override-plan.md`. |

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
29. **Q54 (shipped 2026-06-04):** BWM writer + walkmesh export — `BWMWriter` round-trip and Module Designer walkmesh preview export; see `docs/plans/2026-06-04-027-feat-q54-bwm-writer-walkmesh-export-plan.md`.
30. **Q55 (shipped 2026-06-04):** Native indoor MOD export default — `KotorIndoorNativeExporter` primary **Export .mod** with PyKotor CLI fallback; see `docs/plans/2026-06-04-028-feat-q55-native-indoor-mod-export-default-plan.md`.
31. **Q56 (shipped 2026-06-04):** Module Designer walkmesh install — **Install Walkmesh to Override** via mutation preflight; see `docs/plans/2026-06-04-029-feat-q56-walkmesh-install-override-plan.md`.
32. **Q57 (shipped 2026-06-04):** Indoor MOD install to modules — `KotorIndoorModuleInstaller` + Indoor Builder **Install MOD to Modules**; see `docs/plans/2026-06-04-030-feat-q57-indoor-mod-install-modules-plan.md`.
33. **Q58 (shipped 2026-06-04):** Module Designer LYT install — **Install LYT to Override** via `LYTWriter`; see `docs/plans/2026-06-04-031-feat-q58-lyt-install-override-plan.md`.
34. **Q59 (shipped 2026-06-05):** Module Designer VIS install — **Install VIS to Override** via `VISWriter`; see `docs/plans/2026-06-04-032-feat-q59-vis-install-override-plan.md`.
35. **Q60 (shipped 2026-06-05):** Module Designer PTH install — **Install PTH to Override** via typed `PTHResource`; see `docs/plans/2026-06-05-033-feat-q60-pth-install-override-plan.md`.
36. **Q61 (shipped 2026-06-05):** Module Designer LYT preview export — **Export LYT Preview…** writes loaded layout files to filesystem; see `docs/plans/2026-06-05-034-feat-q61-lyt-preview-export-plan.md`.
37. **Q62 (shipped 2026-06-05):** Module Designer VIS preview export — **Export VIS Preview…** writes loaded visibility files to filesystem; see `docs/plans/2026-06-05-035-feat-q62-vis-preview-export-plan.md`.
38. **Q63 (shipped 2026-06-05):** Module Designer PTH preview export — **Export PTH Preview…** writes loaded path graph files to filesystem; see `docs/plans/2026-06-05-036-feat-q63-pth-preview-export-plan.md`.
39. **Q64 (shipped 2026-06-05):** Module Designer PTH point overlay — loaded path points render in the 2D map and 3D viewport; see `docs/plans/2026-06-05-037-feat-q64-pth-point-overlay-plan.md`.
40. **Q65 (shipped 2026-06-05):** Module Designer PTH connection overlay — loaded path edges render in the 2D map and 3D viewport; see `docs/plans/2026-06-05-038-feat-q65-pth-connection-overlay-plan.md`.
41. **Q66 (shipped 2026-06-05):** Module Designer PTH point inspection — loaded path points become tree/map/3D selectable with detail-panel connection context; see `docs/plans/2026-06-05-039-feat-q66-pth-point-inspection-plan.md`.
42. **Q67 (shipped 2026-06-05):** Module Designer PTH connection inspection — loaded path edges become tree/map/3D selectable with source/target detail context and viewport edge highlighting; see `docs/plans/2026-06-05-040-feat-q67-pth-connection-inspection-plan.md`.
43. **Q68 (shipped 2026-06-05):** Module Designer PTH point drag-move — loaded path points can be repositioned from the 2D map with typed mutation, dirty-state tracking, and install-ready persistence; see `docs/plans/2026-06-05-041-feat-q68-pth-point-drag-undo-plan.md`.
44. **Q69 (shipped 2026-06-07):** Module Designer PTH connection retarget — loaded path connection destinations can be retargeted from the 2D map with typed mutation, dirty-state tracking, and install-ready persistence; see `docs/plans/2026-06-07-001-feat-q69-pth-connection-retarget-plan.md`.
45. **Q70 (shipped 2026-06-07):** Module Designer PTH point add — loaded path graphs can grow via toolbar-armed map placement with typed mutation, dirty-state tracking, and install-ready persistence; see `docs/plans/2026-06-07-002-feat-q70-pth-point-add-plan.md`.
46. **Q71 (shipped 2026-06-07):** Module Designer PTH point remove — loaded path graphs can shrink via topology-safe point removal with typed mutation, dirty-state tracking, and install-ready persistence; see `docs/plans/2026-06-07-003-feat-q71-pth-point-remove-plan.md`.
47. **Q72 (shipped 2026-06-07):** Module Designer PTH connection add — loaded path graphs can grow new edges via toolbar-armed source-to-target placement with typed mutation, dirty-state tracking, and install-ready persistence; see `docs/plans/2026-06-07-004-feat-q72-pth-connection-add-plan.md`.
48. **Q73 (shipped 2026-06-07):** Module Designer PTH connection remove — loaded path graphs can drop individual edges via toolbar action on selected connection with typed mutation, dirty-state tracking, and install-ready persistence; see `docs/plans/2026-06-07-005-feat-q73-pth-connection-remove-plan.md`.
49. **Q74 (shipped 2026-06-07):** Module Designer bundle resources utility panel — indexed module bundle files (GIT/ARE/IFO/LYT/VIS/PTH/WOK) surface in a left-panel tree with open-in-workspace routing; see `docs/plans/2026-06-07-006-feat-q74-module-bundle-utility-panel-plan.md`.
50. **Q75 (shipped 2026-06-07):** Module Designer room models utility panel — unique LYT room models list MDL/MDX/WOK presence with detail context and MDL open routing; see `docs/plans/2026-06-07-007-feat-q75-room-models-utility-panel-plan.md`.
51. **Q76 (shipped 2026-06-07):** Install ResRef references finder — workspace resource browser scans override GFF/NSS files for selected resref usages with field-path reports; see `docs/plans/2026-06-07-008-feat-q76-resref-references-finder-plan.md`.
52. **Q77 (shipped 2026-06-07):** Batch TGA/PNG→TPC converter — `TpcBatchConverter` writes RGBA `.tpc` files from flat image folders; TPC editor batch toolbar action; see `docs/plans/2026-06-07-009-feat-q77-texture-batch-converter-plan.md`.
53. **Q78 (shipped 2026-06-07):** ModuleKit loader — module LYT rooms surface as Indoor Builder kits; see `docs/plans/2026-06-07-010-feat-q78-modulekit-loader-plan.md`.
54. **Q79 (shipped 2026-06-07):** Batch TPC→TGA export — folder-level `texture-convert` batching in TPC editor; see `docs/plans/2026-06-07-011-feat-q79-batch-tpc-export-plan.md`.
55. **Q81 (shipped 2026-06-07):** Install-scoped TPC batch export — GameFS override-index scan with `TpcGamefsBatchExporter`; see `docs/plans/2026-06-07-013-feat-q81-gamefs-tpc-batch-export-plan.md`.
56. **Q82 (shipped 2026-06-10):** Install-scoped GameFS batch TGA/PNG→TPC import — override indexed `.tga` + flat `.png` scan with `TpcGamefsBatchImporter`; see `docs/plans/2026-06-10-014-feat-q82-gamefs-tpc-batch-import-plan.md`.
57. **Q83 (shipped 2026-06-10):** Install-scoped GameFS MDL batch export — indexed `.mdl` dump with MDX sidecar + `MdlModelMetadataHelper`; see `docs/plans/2026-06-10-015-feat-q83-gamefs-mdl-batch-export-plan.md`.
58. **Q84 (shipped 2026-06-10):** MDL workspace editor — read-only trimesh inspector with export/install and resource-browser routing; see `docs/plans/2026-06-10-016-feat-q84-mdl-workspace-editor-plan.md`.
59. **Q85 (shipped 2026-06-10):** MDL workspace 3D preview — `MdlPreviewViewport` flat-shaded trimesh with orbit camera in Model Editor; see `docs/plans/2026-06-10-017-feat-q85-mdl-workspace-3d-preview-plan.md`.
60. **Q86 (shipped 2026-06-10):** Native TPC DXT encode — `TpcDxtEncoder` with `TPCWriter.serialize_dxt1/dxt5`; see `docs/plans/2026-06-10-018-feat-q86-tpc-dxt-encode-plan.md`.
61. **Q87 (shipped 2026-06-10):** TPC editor DXT re-encode — workspace toolbar compresses loaded textures to DXT1/DXT5; see `docs/plans/2026-06-10-019-feat-q87-tpc-editor-dxt-reencode-plan.md`.
62. **Q88 (shipped 2026-06-10):** Batch TGA/PNG→DXT TPC — `TpcBatchConverter` `encoding` option plus TPC editor **Batch Convert DXT1/DXT5...**; see `docs/plans/2026-06-10-020-feat-q88-tpc-batch-dxt-convert-plan.md`.
63. **Q89 (shipped 2026-06-10):** GameFS batch install DXT import — `TpcGamefsBatchImporter` `encoding` option plus TPC editor **Batch Import Install DXT1/DXT5...**; see `docs/plans/2026-06-10-021-feat-q89-gamefs-batch-dxt-import-plan.md`.
64. **Q90 (shipped 2026-06-10):** TPC editor import image as DXT — **Import TGA/PNG as DXT1/DXT5...** toolbar actions; see `docs/plans/2026-06-10-022-feat-q90-tpc-import-dxt-plan.md`.
65. **Q91 (shipped 2026-06-10):** MDL semantic compare — `MdlCompare` geometry summaries in GameFS override diff; see `docs/plans/2026-06-10-023-feat-q91-mdl-semantic-compare-plan.md`.
66. **Q92 (shipped 2026-06-10):** Flat-folder MDL batch export — `MdlBatchExporter` copies MDL/MDX folders; Model Editor **Batch Copy MDL Folder...**; see `docs/plans/2026-06-10-024-feat-q92-mdl-batch-folder-export-plan.md`.
67. **Q93 (shipped 2026-06-10):** Flat-folder MDL batch import to override — `MdlGamefsBatchImporter` copies MDL/MDX into install override; Model Editor **Batch Import MDL Folder to Override...**; see `docs/plans/2026-06-10-025-feat-q93-mdl-batch-folder-import-override-plan.md`.
68. Module/area designer parity wave (further model tooling).

## Evidence Notes

- Upstream capability references were derived via `gh` CLI on 2026-05-28.
- This matrix should be updated per shipped slice and linked from strategy + execution queue.
