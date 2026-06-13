# Holocron Parity Backlog Roadmap (K1-first)

Date: 2026-06-13  
Authority: Post-Q150 merge; supersedes ad-hoc Q150+ TBD planning.  
Scope: Functional parity with HolocronToolset inside the Godot 4.6 editor plugin (`addons/kotor_tools`).

## Parity target

Modders complete **edit → validate → install/export** loops in Godot equivalent to Holocron — not a Qt UI clone. **K1-first**; K2/TSL deferred to Q200+ track.

## Shipped baseline (Q1–Q150 on `main`)

Core GFF/2DA/TLK, ERF archive wave, module designer, indoor builder, media batch/compare tooling, savegame extract, DLG graph depth (Q128 + Q148–Q150), BIF catalog browse (Q145), CI (Q146).

## Remaining waves

| Wave | Q range | Plan | Holocron gap closed |
| --- | --- | --- | --- |
| **B — Archives** | Q151–Q152 | [087-wave-b-archives](../plans/2026-06-13-087-feat-holocron-parity-wave-b-archives-plan.md) | BIF extract, KEY browse |
| **C — Saves** | Q153–Q154 | [088-wave-c-savegame](../plans/2026-06-13-088-feat-holocron-parity-wave-c-savegame-plan.md) | `savegame.py` write-back |
| **D — DLG K1** | Q155–Q157 | [089-wave-d-dlg-k1](../plans/2026-06-13-089-feat-holocron-parity-wave-d-dlg-k1-plan.md) | Animations, minimap, VO fields |
| **E/F — Spatial/Model** | Q158–Q161 | [090-wave-e-f-spatial-model](../plans/2026-06-13-090-feat-holocron-parity-wave-e-f-spatial-model-plan.md) | BWM depth, MDL geometry |
| **G — Dedicated editors** | Q162–Q164 | [091-wave-g-dedicated-editors](../plans/2026-06-13-091-feat-holocron-parity-wave-g-dedicated-editors-plan.md) | JRL, PTH, FAC panels |
| **H — Tooling** | Q165–Q167 | [092-wave-h-tooling](../plans/2026-06-13-092-feat-holocron-parity-wave-h-tooling-plan.md) | NSS decompile, diff viewer, LTR preview |
| **I — Platform** | Q168–Q169 | [093-wave-i-platform](../plans/2026-06-13-093-feat-holocron-parity-wave-i-platform-plan.md) | Legacy dock, inspector plugins |
| **J — K2/TSL** | Q200+ | [094-k2-track](../plans/2026-06-13-094-feat-holocron-parity-k2-track-plan.md) | TSL fields, K2 install profiles |

## Governance

- One slice = one `ce-plan` + vertical implementation + headless test + matrix update.
- Active slice in [godot-capability-execution-queue.md](godot-capability-execution-queue.md) points at the current wave plan.
- Family status in [openkotor-parity-matrix.md](../30-gap-analysis/openkotor-parity-matrix.md) is backlog truth.

## Verification ladder

```bash
godot --headless --path . --script tests/editor/test_<surface>.gd
bash scripts/run_headless_editor_tests.sh
```
