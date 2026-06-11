# Godot Loader / Saver / Importer Parity Matrix

Date: 2026-06-04
Evidence: `[REPO]` inventory from `editor/core/kotor_importer_registry.gd`, `editor/core/kotor_saver_registry.gd`, `editor/modding/kotor_modding_pipeline.gd`, and `formats/*`.

## Purpose

Answer: for each Aurora format family, which Godot IO layers are registered and which write paths exist?

## Legend

| Symbol | Meaning |
| --- | --- |
| **Yes** | Registered or implemented |
| **Pipeline** | Serialize via `KotorModdingPipeline` / mutation install path only |
| **Parser** | Read/parse exists; no editor import registration |
| **No** | Not implemented at this layer |
| **N/A** | Layer not applicable for this format family |

## Architectural note `[SYNTH]`

This plugin uses **EditorImportPlugin → `.tres` in `.godot/imported`** for project assets. **No `ResourceFormatLoader` is registered** — direct `ResourceLoader.load("res://foo.utc")` without import is not supported. Raw game-install files are read via `FileAccess` + parsers through GameFS, not through `ResourceLoader`.

Add a `ResourceFormatLoader` only when direct on-disk loading without import indirection is required (e.g. runtime mod loading).

## Format coverage matrix

| Format family | Extensions | EditorImportPlugin | ResourceFormatSaver | Pipeline serialize | Parser | Round-trip tests |
| --- | --- | --- | --- | --- | --- | --- |
| GFF-family | utc, utd, ute, uti, utp, uts, utt, utw, utm, jrl, dlg, git, are, ifo, gff | Yes (`kotor.gff`) | Yes (`GffResourceFormatSaver`) | Yes (`GFFWriter`) | Yes | Yes (editor + parser tests) |
| 2DA | 2da | Yes (`kotor.twoda`) | Yes (`TwodaResourceFormatSaver`) | Yes (`TwoDaWriter`) | Yes | Yes |
| TLK | tlk | Yes (`kotor.tlk`) | Yes (`TlkResourceFormatSaver`) | Yes (`TLKWriter`) | Yes | Yes |
| ERF/RIM/MOD | erf, rim, mod | Yes (`kotor.erf`) | No | Yes (`ErfWriter` via pipeline) | Yes | Partial (write-back shipped Q4) |
| TPC | tpc, tga | Yes (`kotor.tpc`) | No | Yes (`TPCWriter` passthrough/RGBA/DXT1/DXT5 + pipeline validate) | Yes | Partial (Q30/Q86 write-back; DXT3 encode deferred) |
| SSF | ssf | No | No | Yes (`SSFWriter`) | Yes | Yes (`test_ssf_parser.gd`) |
| LIP | lip | No | No | Yes (`LIPWriter`) | Yes | Yes (`test_lip_parser.gd`) |
| NSS | nss | No | No | No (text) | N/A | Partial (script editor; PyKotor CLI bridge Q26) |
| WAV | wav | No | No | No | Yes (metadata) | Partial (`test_wav_metadata.gd`) |
| KEY/BIF | key, bif | No | No | No | Yes (index/extract) | Partial |
| LYT/VIS/PTH | lyt, vis, pth | No | No | No | Yes (module designer) | Partial |
| BWM/WOK | wok | No | No | No | Yes | Partial (module designer Q17) |
| MDL/MDX | mdl, mdx | No | No | No | Yes (K1 trimesh read) | Partial (module designer Q18) |
| Indoor map | indoor | No | No | Yes (`KotorIndoorMapIO`) | Yes | Yes (indoor builder tests) |

## Registry inventory `[REPO]`

### Importers (`kotor_importer_registry.gd`)

| Importer name | Script | Extensions |
| --- | --- | --- |
| `kotor.gff` | `importers/gff_import_plugin.gd` | utc, utd, ute, uti, utp, uts, utt, utw, utm, jrl, dlg, git, are, ifo, gff |
| `kotor.erf` | `importers/erf_import_plugin.gd` | erf, rim, mod |
| `kotor.twoda` | `importers/twoda_import_plugin.gd` | 2da |
| `kotor.tlk` | `importers/tlk_import_plugin.gd` | tlk |
| `kotor.tpc` | `importers/tpc_import_plugin.gd` | tpc, tga |

### Savers (`kotor_saver_registry.gd`)

| Saver | Script | Resource types |
| --- | --- | --- |
| GFF | `savers/gff_resource_format_saver.gd` | `GFFResource` and typed GFF resources |
| 2DA | `savers/twoda_resource_format_saver.gd` | `TwoDaResource` |
| TLK | `savers/tlk_resource_format_saver.gd` | `TLKResource` |

All savers register with `ResourceSaver.add_resource_format_saver(saver, true)` (front priority).

### Pipeline-only serialize (`kotor_modding_pipeline.gd`)

Extensions handled by `_serialize_payload` but **without** `ResourceFormatSaver`: ssf, lip, erf/rim/mod (archive entries), gff-family (also has saver), 2da, tlk.

## Gap summary `[SYNTH]`

| Gap | Priority | Notes |
| --- | --- | --- |
| No `ResourceFormatLoader` | Low | Import path is intentional; document before adding |
| SSF/LIP lack EditorImportPlugin | Medium | Workspace editors + pipeline serialize work; import registration would enable `.tres` project assets |
| TPC write-back | Medium | Tracked in OpenKotOR parity matrix |
| ERF lacks ResourceFormatSaver | Low | Pipeline write-back sufficient for install flows |
| Cache-mode reload tests | Medium | Playbook calls for explicit CACHE_MODE_REPLACE validation |

## Related docs

- Implementation playbook: `docs/50-execution/godot-kotor-implementation-playbook.md`
- Per-format checklists: `docs/50-execution/format-serialization-checklists/`
- Architecture pipeline: `docs/10-architecture-runtime/godot-editor-resource-pipeline.md`
- Official API source map: `docs/90-meta/godot-doc-source-map.md`

## Refresh triggers

Update this matrix when:

- A new importer or saver is registered,
- Pipeline serialize support lands for a format,
- ResourceFormatLoader is added for any format family.
