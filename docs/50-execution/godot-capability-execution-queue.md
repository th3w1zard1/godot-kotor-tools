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

## Active Slice

| Order | Capability slice | Goal | Readiness criteria | Notes |
| --- | --- | --- | --- | --- |
| P1 | OpenKotOR parity program (PyKotor/Holocron) | Drive upstream parity in bounded Godot editor slices with matrix-driven backlog. | Q40 shipped batch override compare; KotorDiff-style install scan in dock. | Next: native indoor build or KotorDiff report export per master plan Phase C–E. |

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
