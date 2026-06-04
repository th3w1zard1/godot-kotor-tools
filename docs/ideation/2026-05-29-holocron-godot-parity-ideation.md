# Ideation: Holocron-Grade Godot KotOR Editor Plugin

Date: 2026-05-29  
Focus: Exhaustive HolocronToolset functional parity inside Godot editor  
Status: Survivors routed to master plan + Q13 slice

## Grounding context

- Holocron = PyKotor + Qt; godot-kotor-tools = GDScript + Godot workspace (STRATEGY.md, parity matrix).
- Q1–Q12 shipped typed GFF depth; factory gap remained for `utt`/`utw`.
- Module designer, BWM/MDL, media editors are multi-month surfaces.

## Topic axes

1. **Format coverage** — which resource types must round-trip in-editor
2. **Editor UX depth** — generic GFF tree vs Holocron-specific panels
3. **Spatial tooling** — GIT/module/walkmesh/visual placement
4. **Script toolchain** — NSS/NCS compile/decompile/diagnostics
5. **Program governance** — matrix-driven slices vs one-shot mega-port

## Survivors (ranked)

### 1. Parity matrix as single backlog authority

**Summary:** Maintain Holocron editor ↔ Godot status table updated every slice; all plans link to it.  
**Basis:** `direct:` existing `openkotor-parity-matrix.md` + user Holocron URL constraint.  
**Why it matters:** Prevents scope drift and makes "100% parity" measurable.

### 2. Complete typed GFF factory for all blueprint families

**Summary:** Every Holocron GFF blueprint editor type gets `*Resource` + `Kotor*Document` + factory test before field-depth work.  
**Basis:** `direct:` broken UTT preload in factory; Holocron editor list includes utt/utw.  
**Why it matters:** Unblocks summary lines, typed accessors, and future inspector panels uniformly.

### 3. Godot SubViewport module designer (Phase C)

**Summary:** New editor region for GIT instance manipulation with 3D preview—not Qt canvas port.  
**Basis:** `external:` Holocron `module_designer.py`; `direct:` matrix marks module designer Not started.  
**Why it matters:** Largest modder workflow gap after text/table editors.

### 4. PyKotor capability mapping, not PyKotor reimplementation

**Summary:** Use PyKotor/Holocron as behavioral spec; implement parsers/editors in existing GDScript architecture.  
**Basis:** `reasoned:` duplicating Python stack inside Godot adds dual maintenance without user benefit.  
**Why it matters:** Keeps install-aware mutation model coherent.

### 5. Companion CLI boundary for HoloPatcher/KotorDiff

**Summary:** Document and optionally invoke external OpenKotOR CLIs until in-editor diff/patch slices land.  
**Basis:** `direct:` matrix lists HoloPatcher/KotorDiff as Not started.  
**Why it matters:** Honest parity story without blocking editor work.

## Rejected (sample)

- **Full Holocron UI clone in one release** — scope exceeds team capacity; violates vertical slice strategy.
- **Embed Python/PyKotor runtime in Godot** — architecture drift, packaging pain.

## Next step

Selected direction → `docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md` (ce-plan). Q13 implements survivor #2.
