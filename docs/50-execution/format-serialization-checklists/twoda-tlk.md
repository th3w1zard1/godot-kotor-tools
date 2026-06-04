# 2DA and TLK Serialization Checklist

## 2DA

Current status: `[REPO]` full import + saver + pipeline + workspace editor shipped.

### Pre-implementation gates

- [ ] Parser: `formats/twoda_parser.gd` — row/column semantics preserved
- [ ] Writer: `formats/twoda_writer.gd` — ASCII output, deterministic column order
- [ ] Importer: `importers/twoda_import_plugin.gd` — `_get_importer_name()` `"kotor.twoda"`
- [ ] Saver: `savers/twoda_resource_format_saver.gd`
- [ ] Resource: `resources/twoda_resource.gd` + document wrapper
- [ ] Pipeline: `"2da"` arm in `kotor_modding_pipeline.gd`
- [ ] Workspace: `ui/workspace/editors/twoda_workspace_editor.gd`
- [ ] Tests: parser round-trip + editor mutation tests

## TLK

Current status: `[REPO]` full import + saver + pipeline + workspace editor shipped.

### Pre-implementation gates

- [ ] Parser: `formats/tlk_parser.gd` — V3.0 layout
- [ ] Writer: `formats/tlk_writer.gd` — binary V3.0 serialize
- [ ] Importer: `importers/tlk_import_plugin.gd` — dynamic load path in registry
- [ ] Saver: `savers/tlk_resource_format_saver.gd`
- [ ] Resource: `resources/tlk_resource.gd` + document wrapper
- [ ] Pipeline: `"tlk"` arm in `kotor_modding_pipeline.gd`
- [ ] Workspace: `ui/workspace/editors/tlk_workspace_editor.gd`
- [ ] Tests: parser round-trip + editor mutation tests

## Shared notes `[SYNTH]`

- Both use `"Resource"` as `_get_resource_type()` and `"tres"` save extension.
- TLK importer load failure aborts entire plugin registration — follow same fail-fast pattern or degrade gracefully when adding importers.
- Enum label integration (feat.2da, skills.2da) is editor-layer concern; serializers remain byte-faithful.
