# GFF-Family Serialization Checklist

Applies to: utc, utd, ute, uti, utp, uts, utt, utw, utm, jrl, dlg, git, are, ifo, gff

Current status: `[REPO]` importer + saver + pipeline + workspace editor shipped.

## Pre-implementation gates

### Parser / writer `[REPO]`

- [ ] `formats/gff_parser.gd` handles the extension's schema variant (if any)
- [ ] `formats/gff_writer.gd` requires `schema_data` on resource for serialize
- [ ] Typed resource + document exist in `resources/typed/` and `resources/documents/` when Holocron parity requires typed editing
- [ ] Factory mapping in `resources/gff_resource_factory.gd` for new blueprint types

### EditorImportPlugin `[OFFICIAL]`

- [ ] Extension added to `importers/gff_import_plugin.gd` `_get_recognized_extensions()` (or dedicated importer if schema diverges)
- [ ] `_get_importer_name()` remains `"kotor.gff"` unless incompatible import semantics require split
- [ ] `_import` parses bytes → builds typed resource via factory → saves `.tres`
- [ ] Bump `_get_format_version()` if imported `.tres` layout changes

### ResourceFormatSaver `[OFFICIAL]`

- [ ] `savers/gff_resource_format_saver.gd` `_recognize()` accepts new typed resource class
- [ ] `_get_recognized_extensions(resource)` returns correct Aurora extension
- [ ] `_save` delegates to `GFFWriter`; returns `Error`, not silent failure

### Pipeline / mutation `[REPO]`

- [ ] `kotor_modding_pipeline.gd` `_serialize_payload` includes extension in GFF match arm
- [ ] Workspace editor routes extension through `gff_workspace_editor.gd` or dedicated editor
- [ ] Document mutations use mutation service preflight for install/export

### Validation

- [ ] Parser/writer headless test with fixture bytes
- [ ] Factory test in `tests/editor/test_gff_resource_factory.gd` for new typed resources
- [ ] Editor mutation test if new editable fields ship
- [ ] Round-trip reload with `ResourceLoader.CACHE_MODE_REPLACE` when testing imported assets

## Reference implementations

- Importer: `importers/gff_import_plugin.gd`
- Saver: `savers/gff_resource_format_saver.gd`
- Writer: `formats/gff_writer.gd`
- Factory: `resources/gff_resource_factory.gd`
