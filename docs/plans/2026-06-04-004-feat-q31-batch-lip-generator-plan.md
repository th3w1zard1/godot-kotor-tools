---
title: "feat: Q31 batch LIP generator from WAV folder"
type: feat
status: completed
date: 2026-06-04
origin: lfg-main-next-parity-slice
phase: Q31
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
related:
  - docs/plans/2026-05-29-033-feat-q28-lip-tooling-plan.md
  - docs/plans/2026-05-29-034-feat-q29-lip-audio-waveform-plan.md
---

# Q31: Batch LIP Generator from WAV Folder

## Summary

Ship native batch LIP generation: scan a folder of WAV files, derive duration from `WavMetadata`, emit minimal V1.0 LIP keyframes (neutral viseme at start/end), and expose a **Batch Generate LIP...** action in the LIP Sync editor.

---

## Problem Frame

Q28–Q29 shipped single-file LIP editing with WAV pairing. Holocron `batch_processor.py` batch LIP generation remains backlog. Modders voicing many lines need placeholder LIP files aligned to WAV duration without hand-authoring each file.

---

## Scope Boundaries

### In scope

- `formats/lip_batch_generator.gd` — single WAV → LIP bytes + directory batch scan
- LIP editor toolbar **Batch Generate LIP...** with folder picker and summary status
- Headless tests with synthetic PCM WAV fixtures
- Execution queue + parity matrix Q31 entry

### Deferred

- Rhubarb / phoneme-driven viseme automation
- PyKotor CLI lip generation (no upstream CLI subcommand)
- Recursive subfolder scan (flat folder only for v1)
- Undo stack for batch writes

### Out of scope

- Auto-install batch output to Override
- IMA ADPCM WAV → LIP (skip with report; user converts in WAV editor first)

---

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `LipBatchGenerator.generate_from_wav_bytes` returns LIP bytes with length matching WAV duration | `test_lip_batch_generator.gd` |
| R2 | `LipBatchGenerator.batch_directory` writes `.lip` beside each `.wav`, skips existing when configured | `test_lip_batch_generator.gd` |
| R3 | Non-PCM / invalid WAV reported as failed, not silent | Unit test |
| R4 | LIP editor exposes batch folder action with result summary | Manual + editor wiring |
| R5 | Docs mark Q31 shipped | Doc diff |

---

## Key Technical Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Keyframe strategy | NEUTRAL (shape 0) at t=0 and t=duration | Valid minimal LIP; modders refine in editor |
| PCM requirement | Require `WavMetadata.playable_pcm` or valid duration | ADPCM duration unreliable without decode |
| Output location | Same directory, matching basename `.lip` | Matches Holocron batch output convention |
| skip_existing | Default true | Safe re-run on partial folders |

---

## Implementation Units

### U1. LipBatchGenerator

**Files:** `formats/lip_batch_generator.gd`

### U2. Tests

**Files:** `tests/editor/test_lip_batch_generator.gd`

### U3. LIP editor UI

**Files:** `ui/workspace/editors/lip_workspace_editor.gd`

### U4. Docs

**Files:** execution queue, parity matrix, ssf-lip checklist note

---

## Verification

```bash
godot --headless --path . --script tests/editor/test_lip_batch_generator.gd
```
