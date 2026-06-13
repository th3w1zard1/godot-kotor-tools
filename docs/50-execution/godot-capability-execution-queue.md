# Godot Capability Execution Queue

## Purpose

This queue turns strategy and gap analysis into an execution-ready order for near-term implementation slices.

Use this document to answer:

1. What should ship next?
2. What must be true before starting?
3. What outcome marks the slice as shipped?

## Shipped Slices

Phase 2 Capability Expansion ([STRATEGY.md](../../STRATEGY.md)) has delivered the following completed capabilities:

| Order | Capability slice | Shipped outcome |
| --- | --- | --- |
| Q1 | Undo/redo command boundaries for document mutations | Users can undo/redo supported document edits (GFF/DLG/2DA/TLK) without losing changed/validation consistency. |
| Q2 | Targeted post-mutation refresh/reindex behavior | Install/restore actions produce deterministic install-aware state without manual re-open/reload workarounds. |
| Q3 | Inspector-guided typed GFF editing helpers | Common structured fields (locstrings, refs, enum-like fields) are editable with guided controls while validation constraints hold. |
| Q4 | Archive write-back parity (ERF/RIM/MOD) | ERF, RIM, and MOD archives support parser→edit→write-back parity through pipeline-owned flows. |
| Q5 | Context-action expansion for compare/install/export | Compare/install/export actions are available from resource browser, document tabs, and area tools surfaces. |
| Q6 | DLG struct/array mutation UI | Reply/entry container editing with add/remove/reorder, hybrid validation, and undo/redo support. |
| Q7 | GFF struct/array editing | GFF struct-array mutations and inline struct field editing with validation and undo/redo. |
| Q8 | Typed field picker UIs | Install-aware ResRef browsers, enum combos, and locstring/strref assist in workspace editors. |
| Q9 | Dynamic enum registry + inventory pickers | Install-aware 2DA enum labels, UTI item picker, GFF itemList integration. |
| Q10 | GFF inventory array editing | Inventory/EquippedInventory/itemList editable with shared item struct defaults. |
| Q11 | GFF skill/feat array editing | SkillList/FeatList editable with Rank/Feat defaults and hybrid validation. |
| Q12 | Install-aware feat/skill 2DA labels | Feat enum labels from feat.2da; SkillList rows show skills.2da names by index. |
| Q13 | GFF blueprint typed factory completion (`utt`, `utw`) | Holocron blueprint types `utt` and `utw` map to typed resources/documents in `GFFResourceFactory` with headless tests. |
| Q14 | Blueprint field-depth parity (scripts, traps, map notes, appearance) | Script hook NSS pickers, trap scalar/`TrapList` editing, typed document summaries, `TrapType` from traps.2da. |
| Q15 | Module designer foundations (`.git` workspace) | Dedicated Module Designer tab: typed GIT instances, 2D map + tree selection sync, module bundle context, save/install on mutation path; `.git` routed out of GFF entity editor. |
| Q16 | Module designer 3D viewport | SubViewport 3D view with GIT markers, LYT room overlay, orbit/zoom camera, tree ↔ map ↔ 3D selection sync; override-first module bundle for `lyt`/`vis`/`pth`. |
| Q17 | Module designer BWM walkmesh overlay | `BWMParser` for area `.wok`, walkable/unwalkable triangle overlay in 3D viewport, bundle `load_parsed_walkmesh`, camera fit includes walkmesh bounds. |
| Q18 | Module designer MDL room mesh placement | `MDLParser` for K1 trimesh read, `load_parsed_model_mesh`, flat-shaded LYT room meshes in 3D viewport, blue box fallback when MDL missing. |
| Q19 | GIT template → MDL instance meshes | `KotorTemplateModelResolver` maps creature/placeable/door templates via blueprint GFF + 2DA; `set_instance_meshes` renders MDL at GIT position/bearing with cube fallback. |
| Q20 | GIT instance drag-move + undo | `set_instance_position` on GIT document; 2D map drag with `_screen_to_world`; EditorUndoRedoManager undo; dirty refresh across map/tree/3D. |
| Q21 | GIT instance bearing rotate + undo | `set_instance_bearing` on GIT document; 2D map right-drag rotate with live preview; EditorUndoRedoManager undo; dirty refresh across map/tree/3D. |
| Q22 | Indoor Builder foundations | `KotorIndoorMapIO` + `KotorIndoorDocument`; Indoor Builder workspace tab; 2D room map drag/rotate with undo; `.indoor` filesystem save; session restore. |
| Q23 | Indoor kit library + placement | `KotorIndoorKitLoader`/`KotorIndoorKitLibrary`; kits path in editor settings; kit/component pickers; `add_room_from_kit` with undo; resource-browser `.indoor` routing. |
| Q24 | Indoor hook connections | `KotorIndoorHookConnections` + document connection cache; map hook markers; room hook summaries; auto-rebuild on mutations; manual rebuild button. |
| Q25 | Indoor `.mod` export | `KotorIndoorModExporter` PyKotor CLI bridge (`indoor-build`); Export .mod toolbar; `pykotor_cli_path` editor setting; preflight + dry-run tests. |
| Q26 | NSS/NCS script tools | `KotorScriptToolBridge` PyKotor CLI bridge (`assemble`/`decompile`/`disassemble`); Script tab Compile/Decompile/Disassemble; include-dir discovery; headless command tests. |
| Q27 | SSF/TPC/WAV media tooling | Native SSF parser/writer + workspace editor; TPC preview/metadata + PyKotor `texture-convert` export; WAV metadata + PyKotor `sound-convert`; `KotorMediaToolBridge`; workspace/dock routing for ssf/tpc/wav. |
| Q28 | LIP lip-sync tooling | Native LIP V1.0 parser/writer + `LIPResource`; LIP Sync workspace editor (duration, keyframe list, save/install); modding pipeline `lip` serialize; workspace/dock routing for `.lip`. |
| Q29 | LIP audio + waveform | Shared `formats/wav_metadata.gd`; `LipWaveformView` PCM peaks + keyframe markers; LIP editor Load WAV / Play / Stop / scrub / viseme preview; optional LIP duration sync from WAV; headless `test_wav_metadata.gd`. |
| Q30 | TPC native write-back | `TPCWriter` passthrough + RGBA encode; TPC editor Import TGA/PNG; pipeline `tpc` serialize validation; headless `test_tpc_writer.gd`. |
| Q31 | Batch LIP generator | `LipBatchGenerator` from 16-bit PCM WAV folder; neutral viseme keyframes at start/end; LIP editor **Batch Generate LIP...**; headless `test_lip_batch_generator.gd`. |
| Q32 | Semantic GFF compare reports | `GFFCompare` field-level diff for GFF-family install compare; DLG list count summaries; headless `test_gff_compare.gd`. |
| Q33 | DLG jump-to-target navigation | `get_link_target_metadata()` resolver; Jump to Target on link detail; outgoing link summaries and tree activation jump to target node; headless `test_dlg_workspace_editor.gd`. |
| Q35 | SSF semantic compare reports | `SSFCompare` slot-level StrRef diff for install compare; pipeline `ssf` arm; headless `test_ssf_compare.gd`. |
| Q36 | LIP semantic compare reports | `LIPCompare` duration/keyframe diff for install compare; pipeline `lip` arm; headless `test_lip_compare.gd`. |
| Q37 | TPC semantic compare reports | `TPCCompare` header/payload diff for install compare; pipeline `tpc` arm; headless `test_tpc_compare.gd`. |
| Q38 | WAV semantic compare reports | `WavCompare` format/duration/payload diff for install compare; pipeline `wav` arm; headless `test_wav_compare.gd`. |
| Q39 | Indoor layout validation | `KotorIndoorLayoutValidator` module/room/kit/hook checks; merged into mod export preflight; headless `test_indoor_layout_validator.gd`. |
| Q40 | Batch override compare | `compare_all_overrides` install scan with semantic diff aggregation; dock Compare All Overrides; headless `test_override_batch_compare.gd`. |
| Q41 | Compare report export | Save single/batch compare output to `.txt` via dock Export Compare Report; headless `test_compare_report_export.gd`. |
| Q42 | Native indoor build manifest | `KotorIndoorBuildManifest` core module + room asset preview; Indoor Builder Build Preview; headless `test_indoor_build_manifest.gd`. |
| Q43 | Native indoor LYT builder | `KotorIndoorLyTBuilder` roommodel `.lyt` generation; manifest + Export LYT Preview; headless `test_indoor_lyt_builder.gd`. |
| Q44 | Native indoor IFO builder | `KotorIndoorIfoBuilder` module `.ifo` GFF generation; manifest + Export IFO Preview; headless `test_indoor_ifo_builder.gd`. |
| Q45 | Native indoor VIS builder | `VISParser` + `KotorIndoorVisBuilder` hook-based `.vis` generation; manifest + Export VIS Preview; headless `test_indoor_vis_builder.gd`. |
| Q46 | Native indoor ARE builder | `KotorIndoorAreBuilder` module `.are` GFF generation; manifest + Export ARE Preview; headless `test_indoor_are_builder.gd`. |
| Q47 | Native indoor GIT builder | `KotorIndoorGitBuilder` hook-connection door `.git` generation; manifest + Export GIT Preview; headless `test_indoor_git_builder.gd`. |
| Q48 | Native indoor MOD builder | `KotorIndoorModBuilder` ERF `.mod` assembly from native writers + kit assets; manifest + Export Native MOD Preview; headless `test_indoor_mod_builder.gd`. |
| Q49 | KotorDiff CLI bridge | `KotorDiffToolBridge` standalone kotordiff / PyKotor `diff` invocation; GameFS **Run KotorDiff CLI…**; headless `test_kotor_diff_tool_bridge.gd`. |
| Q50 | Embedded component asset generation | `KotorIndoorEmbeddedAssetGenerator` base64 BWM/MDL/MDX → MOD room assets; manifest flags; headless `test_indoor_embedded_asset_generator.gd`. |
| Q51 | HoloPatcher CLI bridge | `HoloPatcherToolBridge` validate/install TSL patches; GameFS **Validate TSL Patch…** / **Install TSL Patch…**; headless `test_holo_patcher_tool_bridge.gd`. |
| Q52 | GIT 3D rotate gizmo | Module Designer viewport bearing ring + Shift+right-drag rotate; shared `KotorWorldCoordinates` bearing helpers; headless `test_git_viewport_bearing.gd`. |
| Q53 | LYT depth overlay + writer | `LYTWriter` round-trip; Module Designer tracks/obstacles/doorhooks 3D markers; layout/walkmesh summary; headless `test_lyt_writer.gd`. |
| Q54 | BWM writer + walkmesh export | `BWMWriter` round-trip; Module Designer **Export Walkmesh Preview…**; headless `test_bwm_writer.gd`. |
| Q55 | Native indoor MOD export default | `KotorIndoorNativeExporter`; **Export .mod** uses native builders; PyKotor CLI fallback toolbar action; headless `test_indoor_native_exporter.gd`. |
| Q56 | Module Designer walkmesh install | **Install Walkmesh to Override** via `BWMWriter` + mutation preflight; headless `test_module_designer_walkmesh_install.gd`. |
| Q57 | Indoor MOD install to modules | `KotorIndoorModuleInstaller`; **Install MOD to Modules** in Indoor Builder; headless `test_indoor_module_installer.gd`. |
| Q58 | Module Designer LYT install | **Install LYT to Override** via `LYTWriter` + mutation preflight; headless `test_module_designer_lyt_install.gd`. |
| Q59 | Module Designer VIS install | **Install VIS to Override** via `VISWriter` + mutation preflight; headless `test_vis_writer.gd`, `test_module_designer_vis_install.gd`. |
| Q60 | Module Designer PTH install | **Install PTH to Override** via typed `PTHResource` + mutation preflight; headless `test_module_designer_pth_install.gd`. |
| Q61 | Module Designer LYT preview export | **Export LYT Preview…** writes the loaded area layout to filesystem `.lyt`; headless `test_module_designer_lyt_export.gd`. |
| Q62 | Module Designer VIS preview export | **Export VIS Preview…** writes the loaded area visibility graph to filesystem `.vis`; headless `test_module_designer_vis_export.gd`. |
| Q63 | Module Designer PTH preview export | **Export PTH Preview…** writes the loaded area path graph to filesystem `.pth`; headless `test_module_designer_pth_export.gd`. |
| Q64 | Module Designer PTH point overlay | Loaded `.pth` points render in the 2D map and 3D viewport with overlay-aware bounds/camera; headless `test_module_designer_pth_overlay.gd`. |
| Q65 | Module Designer PTH connection overlay | Loaded `.pth` edges render in the 2D map and 3D viewport, with typed connection extraction and summary depth; headless `test_module_designer_pth_connection_overlay.gd`. |
| Q66 | Module Designer PTH point inspection | Loaded `.pth` points become tree/map/3D selectable with detail-panel connection context; headless `test_module_designer_pth_point_inspection.gd`. |
| Q67 | Module Designer PTH connection inspection | Loaded `.pth` edges become tree/map/3D selectable with source/target detail context and viewport edge highlighting; headless `test_module_designer_pth_connection_inspection.gd`. |
| Q68 | Module Designer PTH point drag-move | Loaded `.pth` points can be repositioned from the 2D map with undo-safe typed mutation and install-ready persistence; headless `test_module_designer_pth_point_drag.gd`. |
| Q69 | Module Designer PTH connection retarget | Loaded `.pth` connection destinations can be retargeted from the 2D map with undo-safe typed mutation and install-ready persistence; headless `test_module_designer_pth_connection_retarget.gd`. |
| Q70 | Module Designer PTH point add | Loaded `.pth` graphs can grow via toolbar-armed map placement with undo-safe typed mutation and install-ready persistence; headless `test_module_designer_pth_point_add.gd`. |
| Q71 | Module Designer PTH point remove | Loaded `.pth` graphs can shrink via topology-safe point removal with snapshot undo and install-ready persistence; headless `test_module_designer_pth_point_remove.gd`. |
| Q72 | Module Designer PTH connection add | Loaded `.pth` graphs can grow new edges via toolbar-armed source-to-target placement with snapshot undo and install-ready persistence; headless `test_module_designer_pth_connection_add.gd`. |
| Q73 | Module Designer PTH connection remove | Loaded `.pth` graphs can drop individual edges via toolbar action on selected connection with snapshot undo and install-ready persistence; headless `test_module_designer_pth_connection_remove.gd`. |
| Q74 | Module Designer bundle resources utility panel | Module Designer lists indexed GIT/ARE/IFO/LYT/VIS/PTH/WOK bundle files and opens selected siblings in workspace editors; headless `test_module_designer_bundle_utility_panel.gd`. |
| Q75 | Module Designer room models utility panel | Module Designer lists unique LYT room models with MDL/MDX/WOK presence, detail context, and MDL open routing; headless `test_module_designer_room_models_utility_panel.gd`. |
| Q76 | Install ResRef references finder | Workspace resource browser scans override GFF/NSS resources for selected resref usages with formatted hit reports; headless `test_resref_reference_scanner.gd`. |
| Q77 | Batch TGA/PNG to TPC converter | `TpcBatchConverter` scans flat image folders and writes RGBA `.tpc` files; TPC editor **Batch Convert TGA/PNG→TPC...**; headless `test_tpc_batch_converter.gd`. |
| Q78 | ModuleKit loader for Indoor Builder | `KotorModuleKitLoader` synthesizes kit components from module LYT rooms; Indoor Builder **Refresh Module Kits**; headless `test_module_kit_loader.gd`. |
| Q79 | Batch TPC to TGA export | `TpcBatchExporter` scans flat `.tpc` folders and exports via PyKotor `texture-convert`; TPC editor **Batch Export TGA...**; headless `test_tpc_batch_exporter.gd`. |
| Q81 | Install-scoped TPC batch export | `TpcGamefsBatchExporter` scans GameFS `.tpc` index and batch-exports TGA via PyKotor `texture-convert`; TPC editor **Batch Export Install TGA...** action; headless `test_tpc_gamefs_batch_exporter.gd`. |
| Q82 | Install-scoped GameFS batch TGA/PNG→TPC import | `TpcGamefsBatchImporter` scans override indexed `.tga` and flat `.png`, writes RGBA `.tpc` to override; TPC editor **Batch Import Install TGA/PNG→TPC...**; headless `test_tpc_gamefs_batch_importer.gd`. |
| Q83 | Install-scoped GameFS MDL batch export | `MdlGamefsBatchExporter` scans indexed `.mdl`, copies MDL/MDX to folder with `MdlModelMetadataHelper` summaries; resource browser **Batch Export Install MDL...**; headless `test_mdl_gamefs_batch_exporter.gd`. |
| Q84 | MDL workspace editor (read-only inspector) | `KotorMDLWorkspaceEditor` shows trimesh metadata, MDX sidecar context, export/install actions; workspace routing for `.mdl`; headless `test_mdl_workspace_editor.gd`. |
| Q85 | MDL workspace 3D preview | `MdlPreviewViewport` + `MdlMeshSurfaceBuilder` render K1 trimesh in Model Editor; orbit camera; headless `test_mdl_mesh_surface_builder.gd` + extended `test_mdl_workspace_editor.gd`. |
| Q86 | Native TPC DXT encode | `TpcDxtEncoder` + `TPCWriter.serialize_dxt1/dxt5` for compressed mip-0 TPC write-back; headless `test_tpc_dxt_encoder.gd`. |
| Q87 | TPC editor DXT re-encode | TPC workspace **Re-encode DXT1/DXT5...** toolbar actions; headless `test_tpc_dxt_reencode.gd`. |
| Q88 | Batch TGA/PNG→DXT TPC | `TpcBatchConverter` `encoding` option (`rgba`/`dxt1`/`dxt5`); TPC editor **Batch Convert DXT1/DXT5...**; headless `test_tpc_batch_converter.gd`. |
| Q89 | GameFS batch install DXT import | `TpcGamefsBatchImporter` `encoding` option; TPC editor **Batch Import Install DXT1/DXT5...**; headless `test_tpc_gamefs_batch_importer.gd`. |
| Q90 | TPC editor import image as DXT | **Import TGA/PNG as DXT1/DXT5...** toolbar actions; headless `test_tpc_dxt_reencode.gd`. |
| Q91 | MDL semantic compare | `MdlCompare` vertex/face/bounds summaries in GameFS diff; headless `test_mdl_compare.gd`. |
| Q92 | Flat-folder MDL batch export | `MdlBatchExporter` copies MDL/MDX from source folder to output; Model Editor **Batch Copy MDL Folder...**; headless `test_mdl_batch_exporter.gd`. |
| Q93 | Flat-folder MDL batch import to override | `MdlGamefsBatchImporter` copies MDL/MDX from source folder into install override; Model Editor **Batch Import MDL Folder to Override...**; headless `test_mdl_gamefs_batch_importer.gd`. |
| Q94 | BWM/WOK semantic compare | `BwmCompare` vertex/face/walkable summaries in GameFS diff; pipeline `wok` arm; headless `test_bwm_compare.gd`. |
| Q95 | MDL compare MDX sidecar pairing | `MdlCompare` optional MDX args; GameFS loads paired MDX per source; headless `test_mdl_compare.gd`. |
| Q96 | Install-scoped GameFS WOK batch export | `BwmGamefsBatchExporter` scans indexed `.wok`, copies to folder with `BwmMetadataHelper` summaries; resource browser **Batch Export Install WOK...**; headless `test_bwm_gamefs_batch_exporter.gd`. |
| Q97 | Flat-folder WOK batch export | `BwmBatchExporter` copies `.wok` from source folder to output; Module Designer **Batch Copy WOK Folder...**; headless `test_bwm_batch_exporter.gd`. |
| Q98 | Flat-folder WOK batch import to override | `BwmGamefsBatchImporter` copies `.wok` from source folder into install override; Module Designer **Batch Import WOK Folder to Override...**; headless `test_bwm_gamefs_batch_importer.gd`. |
| Q99 | TPC TXI sidecar pairing on image import | `TPCWriter.append_txi_bytes` + `TpcBatchConverter.attach_txi_sidecar` append sibling `.txi` on batch convert, GameFS import, and TPC editor single-file import; headless `test_tpc_writer.gd`, `test_tpc_batch_converter.gd`. |
| Q100 | Flat-folder TGA/PNG batch import to override | `TpcBatchConverter.batch_directory_to_output` + `TpcGamefsBatchImporter.batch_folder_to_override`; TPC editor **Batch Import Image Folder to Override...**; headless `test_tpc_batch_converter.gd`, `test_tpc_gamefs_batch_importer.gd`. |
| Q101 | TPC compare TXI sidecar diff | `TPCCompare` TXI presence/line-by-line summaries; mip-only payload diff; headless `test_tpc_compare.gd`. |
| Q102 | Batch WAV sound-convert | `WavBatchConverter` flat-folder PyKotor `sound-convert`; WAV editor **Batch Convert WAV...**; headless `test_wav_batch_converter.gd`. |
| Q103 | BWM `.bwm` extension alias | `BwmBatchExporter` accepts `.bwm` sources, normalizes to `{resref}.wok` on batch copy/import; headless `test_bwm_batch_exporter.gd`, `test_bwm_gamefs_batch_importer.gd`. |
| Q104 | Batch WAV import to override | `WavBatchConverter.batch_directory_to_output` + `WavGamefsBatchImporter.batch_folder_to_override`; WAV editor **Batch Import WAV Folder to Override...**; headless `test_wav_batch_converter.gd`, `test_wav_gamefs_batch_importer.gd`. |
| Q105 | TPC folder DXT import to override | TPC editor **Batch Import Folder DXT1/DXT5 to Override...** via `batch_folder_to_override` encoding passthrough; headless `test_tpc_gamefs_batch_importer.gd`. |
| Q106 | Install-scoped GameFS WAV batch convert | `WavGamefsBatchImporter.batch_install_to_override` scans override WAVs; WAV editor **Batch Convert Install WAV...**; headless `test_wav_gamefs_batch_importer.gd`. |
| Q107 | Install-scoped GameFS WAV batch export | `WavGamefsBatchExporter` scans indexed `.wav`, copies to folder with `WavMetadata` summaries; WAV editor **Batch Export Install WAV...**; headless `test_wav_gamefs_batch_exporter.gd`. |
| Q108 | Flat-folder WAV batch export | `WavBatchExporter` copies `.wav` from source folder to output; WAV editor **Batch Copy WAV Folder...**; headless `test_wav_batch_exporter.gd`. |
| Q109 | Flat-folder WAV batch copy to override | `WavGamefsBatchImporter.batch_folder_copy_to_override` raw byte copy via `WavBatchExporter`; WAV editor **Batch Copy WAV Folder to Override...**; headless `test_wav_gamefs_batch_importer.gd`. |
| Q110 | TPC editor TXI editing UI | TXI `TextEdit` + **Apply TXI** in TPC workspace editor via `TPCWriter.append_txi_bytes`; headless `test_tpc_txi_editor.gd`. |
| Q111 | Preserve TXI on TPC DXT re-encode | `_reencode_loaded_image` re-appends TXI tail after DXT1/DXT5 serialize; headless `test_tpc_dxt_reencode.gd`. |
| Q112 | Native TPC DXT3 encode | `TpcDxtEncoder.encode_dxt3_image` + `TPCWriter.serialize_dxt3`; TPC editor **Re-encode DXT3...**; headless `test_tpc_dxt_encoder.gd`, `test_tpc_dxt_reencode.gd`. |
| Q113 | TPC DXT3 batch/import toolbar parity | `TpcBatchConverter` `dxt3` encoding + TPC editor import/batch/install/folder DXT3 toolbar actions; headless batch/importer/re-encode tests. |
| Q114 | TPC editor TXI file import/export | **Import TXI...** / **Export TXI...** toolbar actions via `import_txi_from_file` / `export_txi_to_file`; headless `test_tpc_txi_editor.gd`. |
| Q115 | TPC recursive batch directory scan | `BatchDirectoryScanner` + `recursive` option on `TpcBatchConverter`; editor batch convert/folder import enable recursion; headless scanner/batch tests. |
| Q116 | WAV recursive batch directory scan | `recursive` on `WavBatchExporter` / `WavBatchConverter`; WAV editor folder batch actions enable recursion; headless WAV batch/importer tests. |
| Q117 | BWM/MDL recursive batch directory scan | `recursive` on `BwmBatchExporter` / `MdlBatchExporter`; Module Designer + Model Editor folder batch actions enable recursion; headless BWM/MDL batch/importer tests. |
| Q118 | LIP/TPC export recursive batch directory scan | `recursive` on `LipBatchGenerator` / `TpcBatchExporter`; LIP + TPC editor folder batch actions enable recursion; headless LIP/TPC export tests. |
| Q119 | Module/MDL install batch export toolbar parity | **Batch Export Install WOK...** in Module Designer + **Batch Export Install MDL...** in Model Editor via existing GameFS batch exporters; headless toolbar tests. |
| Q120 | WOK/MDL install batch copy to override | `batch_install_to_override` on WOK/MDL GameFS batch importers; Module Designer + Model Editor one-click install-copy toolbar actions; headless importer tests. |
| Q121 | Resource browser WOK/MDL install copy to override | Resource browser **Batch Copy Install WOK/MDL to Override...** wired to Q120 importers with GameFS refresh; headless browser button tests. |
| Q122 | Module/MDL compare with override toolbar parity | Module Designer **Compare Walkmesh with Override...** + Model Editor **Compare MDL with Override...** via `KotorModdingPipeline.compare_gamefs_resource`; headless toolbar tests. |
| Q123 | Module/MDL compare report export toolbar parity | **Export Compare Report...** in Module Designer + Model Editor after compare; uses `export_compare_result_to_path`; headless toolbar tests. |
| Q124 | Module Designer GIT instance CRUD *(PR #119)* | **Add Instance…** / **Remove Instance** toolbar actions with category+template dialog, map placement, undo-safe typed mutation, install-ready persistence; headless `test_module_designer_git_instance_crud.gd`. |
| Q125 | UTP typed parity expansion *(PR #119)* | Trap scalar and script hook typed helpers on UTP blueprints with aligned summary output; headless `test_gff_resource_factory.gd` UTP mapping coverage. |
| Q126 | Module Designer BWM walkmesh painter foundations *(PR #119)* | **Paint Walkmesh** toolbar arm, 3D face pick, walkable/unwalkable material toggle with undo, dirty baseline tracking, and install-ready persistence; headless `test_module_designer_bwm_paint.gd`. |
| Q127 | ERF archive workspace UX *(PR #119)* | **Archive Browser** workspace tab with member table, nested member open routing, and extract-to-override with preflight; headless `test_erf_workspace_editor.gd`. |
| Q128a | DLG node CRUD and orphan hygiene *(PR #119)* | **Add Entry/Reply/Start** and **Remove Node** toolbar actions, orphan dock with restore-link, document index repair + topology snapshot undo; headless `test_dlg_workspace_editor.gd` node CRUD tests. |
| Q128b | DLG read-only graph canvas *(PR #119)* | **Graph View** toolbar toggle with read-only `GraphEdit` layout (entries left, replies right), node click selects tree row; headless `test_dlg_graph_layout.gd`. |
| Q128c1 | DLG jump back-navigation *(PR #119)* | **Back** toolbar restores prior selection after jump-to-target; navigation stack cleared on document open; headless `test_dlg_workspace_editor.gd` back-nav tests. |
| Q128c2 | DLG delete-all-references *(PR #119)* | **Delete References** toolbar + detail panel + tree context menu call `remove_all_references_to_node` with topology undo; headless `test_dlg_workspace_editor.gd` delete-references tests. |
| Q128c3 | DLG graph port drag-connect *(PR #119)* | `connection_link_requested` on graph view calls `add_node_link` with topology undo; headless `test_dlg_workspace_editor.gd` + `test_dlg_graph_layout.gd` graph-link tests. |
| Q128c4 | DLG orphan restore UX *(PR #119)* | Double-click orphan restore, tree context **Link Selected Orphan Here**, detail-panel linkable orphans, `find_linkable_orphans_for_owner`; headless orphan-restore tests. |
| Q134 | ERF member add foundations | Archive Browser **Add Member...** + **Save Archive...** with `KotorErfDocument.add_member`, duplicate rejection, dirty tracking, and pipeline repack export; headless `test_erf_document_add_member.gd` + `test_erf_workspace_editor.gd`. |
| Q135 | ERF member remove/replace | **Remove Member** / **Replace Member...** with `remove_member_at`, `replace_member_at`, `restore_members` undo snapshots, and save integration; headless `test_erf_document_remove_replace.gd` + `test_erf_workspace_editor.gd`. |
| Q136 | ERF member compare with override | **Compare Member with Override...** + **Export Compare Report...** for selected archive members via `compare_gamefs_resource`; headless `test_erf_workspace_editor.gd`. |
| Q137 | Install archive to modules | **Install Archive to Modules** deploys open MOD/ERF/RIM via mutation preflight to game `modules/`; rejects `.sav`; headless `test_erf_workspace_editor.gd`. |
| Q138 | Extract all members to override | **Extract All to Override** batch-installs every archive member with per-member mutation apply and summary counts; headless `test_erf_workspace_editor.gd`. |
| Q139 | Extract all members to folder | **Extract All to Folder...** writes every archive member to a chosen directory (`{resref}.{ext}`); headless `test_erf_workspace_editor.gd`. |
| Q140 | Export selected member to file | **Export Selected...** saves the selected archive member to a chosen path via mutation export preflight; headless `test_erf_workspace_editor.gd`. |
| Q141 | Open game archive dialog | **Open Game Archive...** roots the picker at install `modules/`, `lips/`, or `rims/`; headless `test_erf_workspace_editor.gd`. |
| Q142 | Compare all members with override | **Compare All with Override...** batch-scans archive members against override via `compare_member_batch_with_override`; headless `test_erf_workspace_editor.gd`. |
| Q143 | Dirty path indicator | Archive Browser path label appends ` *` when document dirty; headless `test_erf_workspace_editor.gd`. |
| Q129 | Post-Q128 parity wave planning | **Shipped** — consolidation plan landed #124–#133 on `main` (2026-06-12). |
| Q130 | NSS compile-to-override UX | Dock + workspace script editors install compiled `.ncs` to override with mutation preflight; auto-offer after successful compile; headless `test_script_compile_install.gd`. |
| Q131 | LTR parser + workspace editor | `LTRParser`/`LTRWriter`, Letter Table workspace tab, `.ltr` routing, install/export; headless `test_ltr_parser.gd` + `test_ltr_workspace_editor.gd`. |
| Q132 | Savegame inspector foundations | Read-only `.sav` metadata workspace tab (`savenfo`/`partytable`/`globalvars`), member browse + GFF inspect routing; headless `test_savegame_inspector.gd` + `test_savegame_workspace_editor.gd`. |
| Q133 | MDL write-back phase 0 | `MDLWriter` passthrough + `MdlResource` + pipeline `mdl` serialize; MDL editor export/install via typed resource; headless `test_mdl_writer.gd`. Geometry rebuild deferred. |
| Q144 | LTR doubles/triples editing | Letter Table editor edits double contexts in tree and triple contexts via row/col selectors; round-trip save/install; headless `test_ltr_workspace_editor.gd`. |
| Q145 | Chitin BIF catalog browse foundations | `list_chitin_bif_catalog`, resource browser source filter + BIF catalog mode; headless `test_key_bif_parser.gd` + `test_gamefs_chitin_catalog.gd`. |
| Q146 | GitHub Actions headless editor test CI | `.github/workflows/headless-editor-tests.yml` + `scripts/run_headless_editor_tests.sh`; runs all `tests/editor/test_*.gd` on PR/push. |
| Q147 | Savegame member extract to override | Savegame Inspector **Extract to Override** for selected SAV member via mutation pipeline; headless `test_savegame_workspace_editor.gd`. |
| Q148 | DLG graph fit view + selection focus | **Fit Graph** toolbar + `focus_metadata` scroll sync for entry/reply nodes; headless `test_dlg_graph_layout.gd`. |
| Q149 | Savegame extract all members to override | Savegame Inspector **Extract All to Override** batch install; headless `test_savegame_workspace_editor.gd`. |
| Q150 | DLG graph port index alignment | `connect_node` / `connection_request` use output port `0` to match single `set_slot(0)`; headless `test_dlg_graph_layout.gd`. |

> **Branch note:** Q124–Q128c4 shipped via [PR #119](https://github.com/th3w1zard1/godot-kotor-tools/pull/119) (merged 2026-06-11). Q134–Q143 ERF archive wave shipped on `main` via PRs #124–#133 (2026-06-12). Q130–Q133 NSS/LTR/savegame/MDL wave shipped via PRs #120–#123 (2026-06-12). Q144 LTR depth via PR #135. Q145–Q149 merged to `main`; Q150 open as PR #141. Drop `*(PR #119)*` qualifiers in queue rows when editing legacy entries.

## Active Slice

| Order | Capability slice | Goal | Readiness criteria | Notes |
| --- | --- | --- | --- | --- |
| Q151+ | Holocron parity Wave B (archives) | Plan and ship Q151 BIF extract + Q152 KEY browse per Holocron backlog. | Q150 DLG graph port fix ready to merge. | See `docs/plans/2026-06-13-087-feat-holocron-parity-wave-b-archives-plan.md`. |

## Next Slices (Deferred)

| Order | Capability slice | Goal | Readiness criteria | Notes |
| --- | --- | --- | --- | --- |
| Q10 | GFF inventory array editing | Add/remove/reorder `Inventory`, `EquippedInventory`, and proper `itemList` defaults. | Q9 item picker shipped. | **Shipped** — inventory arrays editable with shared item struct defaults. |
| Q11 | GFF skill/feat array editing | Add/remove/reorder `SkillList` and `FeatList` with Rank/Feat defaults. | Q7 array machinery shipped. | **Shipped** — creature skill/feat lists editable in GFF tree. |
| Q12 | Install-aware feat/skill 2DA labels | Feat values and SkillList indices show install 2DA labels in GFF tree. | Q9 enum registry + Q11 arrays shipped. | **Shipped** — feat.2da and skills.2da labels in creature editing. |

## Queue Governance

- Re-evaluate queue order after each shipped slice.
- If a slice no longer aligns with `STRATEGY.md` tracks, move it out of the active queue before planning.
- Keep slices bounded: each item should map cleanly to one focused `ce-plan` and one implementation wave.

## Source Inputs

- Strategy grounding: `STRATEGY.md`
- Gap inventory: `docs/30-gap-analysis/godot-support-gaps.md`
- OpenKotOR parity matrix: `docs/30-gap-analysis/openkotor-parity-matrix.md`
- Next-wave requirements: `docs/brainstorms/2026-05-24-godot-support-expansion-requirements.md`
