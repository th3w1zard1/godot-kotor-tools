# SSF and LIP Serialization Checklist

## SSF (Sound Set File)

Current status: `[REPO]` parser + writer + workspace editor + pipeline serialize; **no** EditorImportPlugin or ResourceFormatSaver.

### Pre-implementation gates

- [ ] Parser: `formats/ssf_parser.gd` — V1.1 layout, 28 strref slots
- [ ] Writer: `formats/ssf_writer.gd`
- [ ] Resource: `resources/ssf_resource.gd` + document wrapper
- [ ] Pipeline: `"ssf"` arm in `kotor_modding_pipeline.gd`
- [ ] Workspace: SSF workspace editor + dock routing (Q27)
- [ ] Tests: `tests/editor/test_ssf_parser.gd`

### Optional future layers

- [ ] EditorImportPlugin if project-asset `.ssf` import is needed
- [ ] ResourceFormatSaver if `ResourceSaver.save()` on SSFResource is required

## LIP (Lip Sync)

Current status: `[REPO]` parser + writer + workspace editor + pipeline serialize + WAV pairing (Q28–Q29); **no** EditorImportPlugin or ResourceFormatSaver.

### Pre-implementation gates

- [ ] Parser: `formats/lip_parser.gd` — V1.0 keyframes
- [ ] Writer: `formats/lip_writer.gd`
- [ ] Resource: `resources/lip_resource.gd` + document wrapper
- [ ] Pipeline: `"lip"` arm in `kotor_modding_pipeline.gd`
- [ ] Workspace: LIP Sync editor with waveform (Q29)
- [ ] Tests: `tests/editor/test_lip_parser.gd`, `tests/editor/test_wav_metadata.gd`

### Optional future layers

- [ ] EditorImportPlugin for project-asset lip files
- [ ] ResourceFormatSaver for direct save dialog support
- [ ] Batch LIP tooling (OpenKotOR parity backlog)

## Shared notes `[SYNTH]`

Media formats (SSF, LIP, TPC, WAV) often ship workspace-first: GameFS open → document edit → pipeline install. Import registration is optional until contributors need `.tres` project assets.

When adding EditorImportPlugin for these formats:

- Use unique `_get_importer_name()` (e.g. `"kotor.ssf"`, `"kotor.lip"`)
- Save extension `"tres"`, resource type `"Resource"`
- Register in `kotor_importer_registry.gd`
- Update parity matrix
