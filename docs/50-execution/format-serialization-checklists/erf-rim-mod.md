# ERF / RIM / MOD Serialization Checklist

Applies to: erf, rim, mod archive containers

Current status: `[REPO]` import + pipeline write-back shipped (Q4); no `ResourceFormatSaver`.

## Pre-implementation gates

### Parser / writer `[REPO]`

- [ ] `formats/erf_parser.gd` reads header, key list, resource table
- [ ] `formats/erf_writer.gd` produces valid container bytes for install/export
- [ ] Embedded entry serialize delegates to format-specific writers (GFF, 2DA, etc.)

### EditorImportPlugin `[OFFICIAL]`

- [ ] `importers/erf_import_plugin.gd` — `_get_importer_name()` `"kotor.erf"`
- [ ] Recognized extensions: erf, rim, mod
- [ ] `_import` stores container **metadata** (offsets/sizes/resrefs) in imported `.tres`
- [ ] Do not assume full embedded-byte round-trip from imported `.tres` alone `[SYNTH]`

### Pipeline / mutation `[REPO]`

- [ ] `kotor_modding_pipeline.gd` archive entry extraction and repack paths
- [ ] Preflight validates entry types before install
- [ ] Export/MOD packaging flows use `ErfWriter`

### ResourceFormatSaver

- [ ] **Not registered** — pipeline-owned write path is intentional
- [ ] Add saver only if `ResourceSaver.save()` on `ErfResource` becomes a user-facing requirement

### Validation

- [ ] Parser tests with fixture archives
- [ ] Write-back test: extract entry → mutate → repack → re-parse header
- [ ] Install preflight tests in mutation service suite

## Reference implementations

- Importer: `importers/erf_import_plugin.gd`
- Writer: `formats/erf_writer.gd`
- Pipeline: `editor/modding/kotor_modding_pipeline.gd`
