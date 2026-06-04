# Godot Documentation Source Map (Research Snapshot)

## Scope and Authority

- This file is the **external source map** for official Godot docs used by this repository.
- It supports (but does not replace) repo-local guidance in:
  - `README.md` for user-facing setup and plugin usage
  - `docs/QUICKSTART.md` for first-run instructions
  - `docs/00-intent/godot-serialization-kb-intent.md` for knowledgebase orientation
  - `docs/50-execution/godot-kotor-implementation-playbook.md` for contributor execution workflow
  - `docs/50-execution/godot-loader-saver-importer-parity-matrix.md` for format coverage inventory

## Version + Source Notes

- Project target: Godot **4.6** (`README.md`).
- `[OFFICIAL]` URLs below use the **4.6** doc channel (`/en/4.6/`). The stable channel currently tracks 4.6 for these classes; prefer 4.6 URLs when refreshing.
- Last research pass: 2026-06-04 (kb-docs-researcher / LFG).

## Primary API References

### Resource loading and saving

- ResourceFormatLoader
  - https://docs.godotengine.org/en/4.6/classes/class_resourceformatloader.html
- ResourceFormatSaver
  - https://docs.godotengine.org/en/4.6/classes/class_resourceformatsaver.html
- ResourceLoader
  - https://docs.godotengine.org/en/4.6/classes/class_resourceloader.html
- ResourceSaver
  - https://docs.godotengine.org/en/4.6/classes/class_resourcesaver.html

### Editor import and plugin registration

- EditorImportPlugin
  - https://docs.godotengine.org/en/4.6/classes/class_editorimportplugin.html
- Editor plugin registration surface
  - https://docs.godotengine.org/en/4.6/classes/class_editorplugin.html
- Import plugins tutorial
  - https://docs.godotengine.org/en/4.6/tutorials/plugins/editor/import_plugins.html

### Binary and variant serialization

- FileAccess
  - https://docs.godotengine.org/en/4.6/classes/class_fileaccess.html
- PackedByteArray
  - https://docs.godotengine.org/en/4.6/classes/class_packedbytearray.html
- Marshalls
  - https://docs.godotengine.org/en/4.6/classes/class_marshalls.html
- GlobalScope variant conversion helpers
  - https://docs.godotengine.org/en/4.6/classes/class_%40globalscope.html

## Contract Quick Reference

### ResourceLoader / ResourceFormatLoader CacheMode `[OFFICIAL]`

| Constant | Value | Behavior |
| --- | --- | --- |
| `CACHE_MODE_IGNORE` | 0 | No cache read/write for main resource; dependencies use REUSE |
| `CACHE_MODE_REUSE` | 1 | Default — use cache when present, store after load |
| `CACHE_MODE_REPLACE` | 2 | Refresh existing cached instances in-place when types match |
| `CACHE_MODE_IGNORE_DEEP` | 3 | IGNORE, recursive on dependency tree |
| `CACHE_MODE_REPLACE_DEEP` | 4 | REPLACE, recursive on dependency tree |

Source: [ResourceLoader CacheMode](https://docs.godotengine.org/en/4.6/classes/class_resourceloader.html)

`[SYNTH]` After write-back or external file change, round-trip validation should use `CACHE_MODE_REPLACE` (or reload via parser), not default REUSE.

### ResourceSaver.SaverFlags `[OFFICIAL]`

| Flag | Value | Meaning |
| --- | --- | --- |
| `FLAG_NONE` | 0 | Default |
| `FLAG_RELATIVE_PATHS` | 1 | Save paths relative to using scene |
| `FLAG_BUNDLE_RESOURCES` | 2 | Bundle external resources |
| `FLAG_CHANGE_PATH` | 4 | Update `resource.resource_path` |
| `FLAG_OMIT_EDITOR_PROPERTIES` | 8 | Skip `__editor*` metadata |
| `FLAG_SAVE_BIG_ENDIAN` | 16 | Big-endian write |
| `FLAG_COMPRESS` | 32 | ZSTD compression (binary resource types) |
| `FLAG_REPLACE_SUBRESOURCE_PATHS` | 64 | `Resource.take_over_path()` for subresources |

Source: [ResourceSaver SaverFlags](https://docs.godotengine.org/en/4.6/classes/class_resourcesaver.html)

`[SYNTH]` KotOR `ResourceFormatSaver` implementations write raw Aurora bytes and should ignore Godot saver flags unless writing Godot-native formats.

### EditorImportPlugin required virtuals `[OFFICIAL]`

- `_get_importer_name()` — unique stable ID stored in `.import`
- `_get_recognized_extensions()` — case-insensitive extensions
- `_get_save_extension()` — extension under `.godot/imported`
- `_get_resource_type()` — Godot type string (script resources → `"Resource"`)
- `_get_import_options(path, preset_index)` — option array (may be empty)
- `_import(source_file, save_path, options, platform_variants, gen_files)` — write `save_path + "." + save_extension`

Registration: `EditorPlugin.add_import_plugin(importer, first_priority=false)` in `_enter_tree()`, symmetric `remove_import_plugin` in `_exit_tree()`.

Source: [EditorImportPlugin](https://docs.godotengine.org/en/4.6/classes/class_editorimportplugin.html)

### FileAccess endianness `[OFFICIAL]`

- `big_endian` defaults to `false` (little-endian) on all supported platforms.
- Must be set **after** `open()`, not before — reset on each open.

Source: [FileAccess](https://docs.godotengine.org/en/4.6/classes/class_fileaccess.html)

`[SYNTH]` Aurora parsers in this repo assume little-endian; aligns with FileAccess default.

## Deprecation/Sunset Check

- No third-party external service API is in scope for this research slice.
- Researched APIs showed **no signature changes** between Godot 4.5 and 4.6 class pages (spot-check, 2026-06-04).

## Maintenance Trigger

Refresh this source map when:

- Godot target version changes,
- import/saver/loader API signatures or enums change,
- or major pipeline behavior changes in this repository.
