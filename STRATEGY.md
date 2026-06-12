---
name: KotOR Tools
last_updated: 2026-06-12
---

# KotOR Tools Strategy

## Target problem

KotOR and Jade Empire modders still bounce between fragmented tools and manual file operations for core edit/install loops. The hard part is keeping install-aware edits safe and coherent without losing trust in what changed.

## Our approach

We commit to a Godot-native, install-aware workspace where parser/importer/editor/write-back capabilities land as coherent vertical slices. We favor document-driven mutation paths with explicit recoverability and reporting so edits stay reliable against real game installs.

## Who it's for

**Primary:** KotOR/Jade Empire modders and contributor-maintainers - They're hiring KotOR Tools to edit real game resources safely inside Godot without stitching together multiple external tools.

## Key metrics

- **Format parity coverage** - Number of target format families that reach parser/importer/resource/write-back parity; measured from repository capability docs.
- **In-workspace completion rate** - Share of high-frequency modding edits completed in workspace editors without external tooling; measured from tracked workflow checks and release notes.
- **Mutation consistency pass rate** - Percentage of install/restore/edit consistency scenarios that pass without stale state drift; measured from editor test suite outcomes.
- **Planning-to-execution throughput** - Ratio of documented strategy/gap items converted into completed plans and shipped slices; measured from `docs/` artifacts and merged PR history.

## Tracks

### Phase 2 Capability Expansion

**Status:** Active (Q1–Q123 shipped on `main`; Q124–Q128c4 shipped via PR #119; Q134–Q143 ERF wave via PRs #124–#133; Q130 NSS via PR #120; active slice Q131 LTR)

Deliver vertical capability slices that combine editor ergonomics, mutation safety, and native Godot integration. Each slice lands parser/importer/editor/write-back parity for a format family or major editing surface.

_Why it serves the approach:_ Vertical slices reduce fragmentation and preserve coherent mutation semantics across the workspace.

Execution queue: [docs/50-execution/godot-capability-execution-queue.md](docs/50-execution/godot-capability-execution-queue.md)

### Parity expansion

Close remaining format and write-back/editor parity gaps so modders can run full round-trip workflows in one workspace.

_Why it serves the approach:_ Vertical parity slices are the fastest path to a trustworthy Godot-native workflow.

### OpenKotOR parity program

Run a sustained parity program that maps PyKotor and HolocronToolset capabilities to Godot editor slices, with explicit shipped/partial/backlog status.

_Why it serves the approach:_ Upstream parity tracking prevents feature drift and keeps implementation priorities tied to real modder workflows.

Parity matrix reference: [docs/30-gap-analysis/openkotor-parity-matrix.md](docs/30-gap-analysis/openkotor-parity-matrix.md)

### Editing safety and consistency

Strengthen post-mutation refresh behavior, state coherence, and failure-path handling across install-aware workflows.

_Why it serves the approach:_ Recoverable and deterministic editing is required for users to trust live-install mutations.

### Godot capability leverage

Adopt high-value Godot editor systems (undo/redo boundaries, inspector-guided editing, targeted refresh hooks) where they reduce manual error risk.

_Why it serves the approach:_ Native editor primitives improve reliability without introducing parallel architecture.

### Execution readiness

Keep strategy, requirements, plans, and gap-analysis docs aligned so contributors can start implementation from authoritative context.

_Why it serves the approach:_ Coherent planning input reduces drift and preserves the strategy's guiding choices during execution.

Execution queue reference: [docs/50-execution/godot-capability-execution-queue.md](docs/50-execution/godot-capability-execution-queue.md)

## Completed Tracks

**Q1–Q5 Phase 2 Capability Expansion:**

- Q1: Undo/redo command boundaries wired for GFF/DLG/2DA/TLK document mutations with shared entry points.
- Q2: Targeted reindex and refresh behavior for install/restore workflows eliminating stale-state windows.
- Q3: Inspector-guided typed GFF editors for locstrings, references, and enum-like fields with validation preservation.
- Q4: Full archive write-back parity for ERF/RIM/MOD families via serializers and ResourceFormatSaver integration.
- Q5: Context-action expansion making compare/install/export accessible from browser, tabs, and area surfaces.

## Next Waves

Future capability work is organized by family. Slices map to Q6+, with dependencies and readiness criteria tracked in the execution queue.

**Editor Ergonomics:**

- Q7: GFF struct/array editing (add/remove/reorder + locstring hierarchies)
- Q8: Typed field picker UIs (resref browsers, enum combos from gamefs)
- Q9: Dynamic enum registry + inventory pickers (2DA-backed enum labels, UTI item browse)
- Q10: GFF inventory array editing (`Inventory`, `EquippedInventory`, itemList defaults)
- Q11: GFF skill/feat array editing (`SkillList`, `FeatList` with Rank/Feat defaults)
- Q12: Install-aware feat/skill 2DA labels (`feat.2da`, `skills.2da` in GFF tree)

**Data Mutation Safety:**

- Advanced rollback strategies (preview before commit, multi-slice transactions)
- Installation verification and pre-flight checks

**Workspace Integration:**

- Q6: DLG struct/array mutation UI (dialogue container editing)
- Script authoring and validation improvements
- Area model visualization and linking

- Replacing the plugin with a generic reverse-engineering platform.
- Large schedule-heavy roadmap management inside this strategy doc.

## Marketing

**One-liner:** Godot-native KotOR modding, with install-aware safety and parity-first editing workflows.
