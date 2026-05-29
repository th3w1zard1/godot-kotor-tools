# godot-kotor-tools

A **Godot 4.6** editor plugin for importing and browsing Star Wars: Knights of the Old Republic (K1/K2) and Jade Empire game archive formats.

Fully implemented static parsers for all major Aurora Engine binary formats. Plug-in and use — no C++ modules required.

---

## What this plugin does

KotOR Tools gives you an install-aware modding workspace directly in the Godot editor. You can browse indexed game resources, open structured editors for supported file types, compare/export/install changes to override, and restore through transaction history.

Use this plugin when you want a Godot-native workflow for reading and editing KotOR/Jade Empire content without writing custom extraction scripts.

---

## Quick start (first run)

For a full guided setup, use **[docs/QUICKSTART.md](docs/QUICKSTART.md)**.

Fast path:

1. Install the plugin (Asset Library or manual clone under `addons/kotor_tools`).
2. Enable **Project Settings -> Plugins -> KotOR Tools**.
3. Open KotOR Tools and set your game install path.
4. Let indexing complete, then open a resource (for example a DLG, 2DA, or TLK entry).
5. Make a safe change and use compare/install actions through the workspace.

---

## Features

| Format | Parser | Importer | Resource wrapper | Write-back |
| --- | --- | --- | --- | --- |
| GFF (`.utc` `.dlg` `.gff` `.utp` .utt …) | `GffParser` | ✅ | `GFFResource` + typed GFF docs/resources | ✅ typed GFF serializer + DLG editing |
| ERF / RIM / MOD archives | `ErfParser` | ✅ | `ErfResource` | — |
| 2DA spreadsheets | `TwoDaParser` | ✅ | `TwoDaResource` | ✅ `.2da` serializer + dock editing |
| TLK string tables | `TlkParser` | ✅ | `TLKResource` | ✅ `.tlk` serializer + dock text editing |
| TPC textures | `TpcReader` | ✅ | — (native `ImageTexture`) | — |
| KEY / BIF archives | `KeyBifParser` | — | — | — |

**KotOR Tools** workspace (main editor screen + optional bottom dock during migration):

- Game path picker + install status for the active K1/K2/JE workspace
- Install-aware resource browser with search, grouped resource tree, and open/export/install/compare actions
- Document-style editors for DLG, 2DA, TLK, and NSS with shared dirty/session/stale handling
- Preflight before install/export/remove mutations, transaction history, and in-product restore
- Dialogue editor with tree/form editing, link validation, and override install/save support
- Script editor with NSS text editing/validation, NCS inspection, and counterpart lookup
- Area Tools with indexed module ARE discovery, linked GIT/IFO/LYT inspection, and room-model checks (MDL/MDX/WOK)
- Activity log for modding writes, compare output, and editor actions

### Current functionality catalog

The plugin currently includes the following in-editor functionality:

- Install indexing for KotOR 1, KotOR 2, and Jade Empire resource trees
- Open/edit/save/install/compare flows for GFF-family resources via workspace editor (`utc`, `utp`, `uti`, `utd`, `ute`, `utm`, `uts`, `utt`, `utw`, `are`, `git`, `ifo`, `jrl`, `pth`, `fac`)
- Open/edit/save/install/compare flows for DLG resources with struct/array mutation support
- Open/edit/save/install/compare flows for 2DA resources with write-back
- Open/edit/save/install/compare flows for TLK resources with write-back
- Open/edit/save/install/compare flows for NSS script resources
- Archive and format support for ERF/RIM/MOD parse and write-back parity
- Archive and format support for KEY/BIF index and extraction
- Archive and format support for TPC import/read pipeline
- Transaction safety via preflight previews, install/export mutation history, and rollback/restore operations

### OpenKotOR parity program

This repository now tracks parity against both upstream toolsets:

- [PyKotor](https://github.com/OpenKotOR/PyKotor)
- [HolocronToolset](https://github.com/OpenKotOR/HolocronToolset)

Parity status and remaining capability backlog are maintained in:

- [docs/30-gap-analysis/openkotor-parity-matrix.md](docs/30-gap-analysis/openkotor-parity-matrix.md)

The parity matrix is updated slice-by-slice as functionality lands in Godot editor workflows.

---

## Installation

### Asset Library (recommended)

Search **KotOR Tools** in the Godot Asset Library and click Install.

### Manual

```bash
cd your_project/addons
git clone https://github.com/OpenKotOR/godot-kotor-tools.git kotor_tools
```

Then **Project → Project Settings → Plugins → KotOR Tools → Enable**.

## Using the plugin in Godot editor

1. Enable the plugin.
2. Open the KotOR Tools workspace from the editor UI.
3. Configure the game install path and wait for index completion.
4. Browse resources and open files in the corresponding workspace editor.
5. Edit fields, run compare, and use install/export actions.
6. Use transaction history to inspect and restore previous mutation operations.

For full first-run instructions and troubleshooting, see [docs/QUICKSTART.md](docs/QUICKSTART.md).

---

## Validation and development checks

This repository uses Godot script validation as the baseline verification workflow.

### Validate one script

```bash
godot --headless --quiet --check-only --script path/to/file.gd
```

### Validate all GDScript files in the repository

```bash
find . -name '*.gd' -print0 | xargs -0 -I{} godot --headless --quiet --check-only --script '{}'
```

---

## Documentation map

- **Setup and first run:** [docs/QUICKSTART.md](docs/QUICKSTART.md)
- **Architecture and implementation orientation:** [docs/00-intent/godot-serialization-kb-intent.md](docs/00-intent/godot-serialization-kb-intent.md)
- **Product direction and active tracks:** [STRATEGY.md](STRATEGY.md)
- **Support coverage + implementation gaps:** [docs/30-gap-analysis/godot-support-gaps.md](docs/30-gap-analysis/godot-support-gaps.md)
- **Prioritized capability execution queue (Phase 2 shipped + deferred slices):** [docs/50-execution/godot-capability-execution-queue.md](docs/50-execution/godot-capability-execution-queue.md)
- **Next implementation-wave requirements (brainstorm):** [docs/brainstorms/2026-05-24-godot-support-expansion-requirements.md](docs/brainstorms/2026-05-24-godot-support-expansion-requirements.md)
- **Godot API source references used by this repo:** [docs/90-meta/godot-doc-source-map.md](docs/90-meta/godot-doc-source-map.md)
- **Implementation playbook for contributors:** [docs/50-execution/godot-kotor-implementation-playbook.md](docs/50-execution/godot-kotor-implementation-playbook.md)

---

## Contributing and Planning Next Work

**For contributors selecting next-wave work:**

The execution queue ([docs/50-execution/godot-capability-execution-queue.md](docs/50-execution/godot-capability-execution-queue.md)) tracks both **shipped slices (Q1–Q5)** and **deferred next slices (Q6–Q8)** with readiness criteria and dependencies. Start there to understand:

- What's already shipped and working
- What deferred work is ready to plan when criteria are met
- How the next slice depends on priors

Then reference [STRATEGY.md](STRATEGY.md) for the broader capability families and multi-year direction, and [docs/30-gap-analysis/godot-support-gaps.md](docs/30-gap-analysis/godot-support-gaps.md) for gap coverage mapping.

---

## API Reference

### `GffParser` — `addons/kotor_tools/formats/gff_parser.gd`

Static parser for Aurora GFF (Generic File Format) binary files.

```gdscript
# Parse from raw bytes
var gff: Dictionary = GffParser.parse(raw_bytes: PackedByteArray) -> Dictionary

# Keys returned:
#   "type"    : String  — four-char GFF type tag ("UTC ", "DLG ", etc.)
#   "version" : String  — format version ("V3.2")
#   "fields"  : Dictionary — field_label → value (recursively parsed structs/lists)
```

### `ErfParser` — `addons/kotor_tools/formats/erf_parser.gd`

Static parser for ERF / RIM / MOD compound archive files.

```gdscript
# Parse archive header and resource list (does NOT load resource data)
var erf: Dictionary = ErfParser.parse_header(raw_bytes: PackedByteArray) -> Dictionary

# Extract a single resource by ResRef + type
var bytes: PackedByteArray = ErfParser.extract_resource(
    raw_bytes: PackedByteArray,
    res_ref: String,
    res_type: int          # Aurora resource type constant (e.g. 0x03ED = UTC)
) -> PackedByteArray
```

### `TwoDaParser` — `addons/kotor_tools/formats/twoda_parser.gd`

Static parser for `.2da` tab-separated spreadsheet files (ASCII format used by K1/K2).

```gdscript
# Parse full sheet
var sheet: Dictionary = TwoDaParser.parse(raw_bytes: PackedByteArray) -> Dictionary
# Keys: "columns" (Array[String]), "rows" (Array[Dictionary])

# Access convenience wrapper (use TwoDaResource instead at runtime)
```

### `TlkParser` — `addons/kotor_tools/formats/tlk_parser.gd`

Static parser for `.tlk` string table files (binary V3.0 format, K1/K2 PC).

```gdscript
# Parse all strings (indexed by StrRef ID)
var strings: Dictionary = TlkParser.parse(raw_bytes: PackedByteArray) -> Dictionary
# Keys: int StrRef → String text
```

### `KeyBifParser` — `addons/kotor_tools/formats/key_bif_parser.gd`

Static parser for `chitin.key` and associated `.bif` data files.

```gdscript
# Parse KEY index
var key: Dictionary = KeyBifParser.parse_key(raw_bytes: PackedByteArray) -> Dictionary

# Extract resource raw bytes from a BIF using the offset from KEY
var bytes: PackedByteArray = KeyBifParser.extract_from_bif(
    bif_bytes: PackedByteArray,
    variable_resource_index: int
) -> PackedByteArray
```

### `TpcReader` — `addons/kotor_tools/formats/tpc_reader.gd`

Converts Aurora `.tpc` texture files to Godot `Image` objects. Handles DXT1/DXT5/RGBA8/greyscale and cubemaps.

```gdscript
var image: Image = TpcReader.read(raw_bytes: PackedByteArray) -> Image
```

---

## Resource Wrappers

Importers produce these `Resource` subclasses, loadable via `load()` at runtime.

### `GFFResource`

```gdscript
var res: GFFResource = load("res://path/to/file.utc")
var value = res.get_field("Tag")        # → Variant
var struct = res.get_struct("Stats")    # → Dictionary
```

### `ErfResource`

```gdscript
var erf: ErfResource = load("res://path/to/file.erf")
var names: Array = erf.resource_names()              # → Array[String]
var bytes: PackedByteArray = erf.get_resource("k_ptar_inc", 0x03ED)
```

### `TLKResource`

```gdscript
var tlk: TLKResource = load("res://path/to/dialog.tlk")
var text: String = tlk.get_string(1234)   # StrRef → text

# Save modified entries back to a TLK file
tlk.set_entry_text(1234, "Updated text")
ResourceSaver.save(tlk, "/absolute/path/to/dialog.tlk")
```

### `TwoDaResource`

```gdscript
var sheet: TwoDaResource = load("res://path/to/feat.2da")
var val: String = sheet.get_cell(row_index: int, column_name: String) -> String
var row: Dictionary = sheet.rows[row_index]

# Update a cell and save back to a 2DA file
sheet.set_cell(0, "label", "new_row")
ResourceSaver.save(sheet, "/absolute/path/to/feat.2da")
```

---

## Compatibility

| Godot | Status |
|---|---|
| 4.6 | ✅ Tested |
| 4.5 | Likely works |
| 4.x < 4.5 | Untested |
| 3.x | ❌ Not supported |

Targets K1 (GOG), K2 (GOG), and Jade Empire (GOG). Console/mobile formats are not supported.

---

## License

MIT — see [LICENSE](LICENSE).

No original game assets are included. You must own a legal copy of KotOR or Jade Empire to use this plugin with game data.
