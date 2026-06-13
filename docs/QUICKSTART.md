# KotOR Tools Quickstart

This guide gets you from install to first successful editor workflow quickly.

## What this plugin is for

KotOR Tools is a Godot 4.6 editor plugin for browsing and editing KotOR/Jade Empire game resources with install-aware workflows (open, compare, install, and restore via transaction history).

## Prerequisites

1. Godot 4.6 project where you want to use the plugin.
2. A legal install of KotOR 1, KotOR 2, or Jade Empire on disk.
3. Write access to your Godot project `addons/` directory.

## Install

### Option A (recommended): Godot Asset Library

1. Open **AssetLib** in Godot.
2. Search for **KotOR Tools**.
3. Install into your project.

### Option B: Manual clone

```bash
cd your_project/addons
git clone https://github.com/OpenKotOR/godot-kotor-tools.git kotor_tools
```

## Enable the plugin

1. Open **Project -> Project Settings -> Plugins**.
2. Find **KotOR Tools**.
3. Switch it to **Enable**.

If the plugin does not appear, verify the folder path is `addons/kotor_tools/` and restart the editor once.

## First-run flow

1. Open the KotOR Tools workspace.
2. Set your game install path when prompted.
3. Wait for indexing to complete.
4. Use the resource browser to open a resource (DLG, 2DA, TLK, NSS, or area-linked assets).
5. Make a small edit, then use compare/install actions through the workspace pipeline.

## Using the editor effectively

1. Select a resource in the browser and open it in the workspace editor.
2. Use typed controls and inline tree editing to modify values.
3. Review validation and preflight output before install/export.
4. Use compare output to verify expected changes.
5. Apply install/export actions.
6. Use transaction history to restore if needed.

## Current functionality coverage

- Workspace editors:
  - GFF-family editing (`utc`, `utp`, `uti`, `utd`, `ute`, `utm`, `uts`, `utt`, `utw`, `are`, `git`, `ifo`, `jrl`, `pth`, `fac`)
  - DLG editing
  - 2DA editing
  - TLK editing
  - NSS script editing
- Install-aware capabilities:
  - indexed resource browsing
  - compare/install/export actions
  - transaction history + rollback
- Format/serialization support:
  - GFF write-back
  - TLK write-back
  - 2DA write-back
  - ERF/RIM/MOD archive write-back

OpenKotOR parity status is tracked in [30-gap-analysis/openkotor-parity-matrix.md](30-gap-analysis/openkotor-parity-matrix.md).

## Troubleshooting

- **Plugin not listed in Plugins panel**
  - Confirm the addon folder name is exactly `kotor_tools`.
  - Confirm `plugin.cfg` is present under `addons/kotor_tools/`.
- **No resources shown after setting game path**
  - Re-check the selected install root.
  - Ensure game data files exist and are readable.
- **Install/restore actions unavailable**
  - Open resources from an indexed install context rather than loose standalone files.

## Validation (maintainers/contributors)

Validate one script:

```bash
godot --headless --quiet --check-only --script path/to/file.gd
```

Run all headless editor tests:

```bash
bash scripts/run_headless_editor_tests.sh
```

CI runs the same script via `.github/workflows/headless-editor-tests.yml` on pull requests and pushes to `main`.

## Next reading

- Repository overview and feature matrix: [../README.md](../README.md)
- Knowledgebase intent and architecture orientation: [00-intent/godot-serialization-kb-intent.md](00-intent/godot-serialization-kb-intent.md)
- Godot API source references used in this project: [90-meta/godot-doc-source-map.md](90-meta/godot-doc-source-map.md)
