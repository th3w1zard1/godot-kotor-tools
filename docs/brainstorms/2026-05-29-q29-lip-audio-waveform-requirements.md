# Q29 LIP Audio + Waveform Requirements

**Created:** 2026-05-29  
**Origin:** Holocron `lip_editor.py` (load WAV, duration sync, QMediaPlayer preview, viseme label during playback)  
**Parent:** Q28 shipped native LIP V1.0 editor without audio UX.

## What we're building

Extend the LIP Sync workspace editor so modders can **pair a voice WAV**, see a **simple waveform**, **play/stop** audio, **scrub** by clicking the waveform or selecting keyframes, and see the **active viseme** during playback — matching Holocron's core lip-sync authoring loop without batch generation or undo stacks.

## In scope

- Load paired `.wav` (file dialog + optional same-basename hint next to open LIP path)
- Parse WAV metadata (reuse PCM-oriented logic; surface IMA ADPCM as non-playable with clear message)
- Build downsampled peak envelope for PCM WAV and draw waveform + keyframe markers + playhead
- `AudioStreamPlayer` playback for PCM WAV; play/stop toolbar; sync playhead on `_process`
- Click waveform → seek; select keyframe row → seek to keyframe time
- When loading PCM WAV, offer to set LIP duration from WAV length (Holocron behavior)
- Live viseme label during playback (interpolate last keyframe at or before playhead)
- Tests for WAV metadata + peak builder (headless); existing LIP tests unchanged

## Out of scope (Q30+)

- Holocron `batch_processor.py` batch LIP generation
- Full undo/redo command stack for LIP edits
- Auto PyKotor convert-on-load for IMA ADPCM (user can convert in WAV editor first)
- LIP XML/JSON CLI import-export

## Success criteria

- Modder can open LIP + WAV, play audio, see waveform and current viseme
- PCM WAV round-trip metadata tests pass
- Parity matrix marks Q29 waveform/audio partial for LIP
