# KotOR Tools Product Strategy

## Target Problem

KotOR and Jade Empire modding workflows still rely on fragmented external tools and manual file operations for core edit/install loops. This project's job is to make those workflows reliable inside a single Godot-native workspace.

## Target Users

- Modders editing game resources with minimal manual file-system risk
- Technical contributors extending parser/importer/saver/editor support
- Tool maintainers responsible for long-term format and workflow parity

## Product Approach

1. Keep the plugin install-aware so every action is grounded in real game-install context.
2. Deliver vertical slices per capability family (format support, editor UX, safe write/install flow) instead of disconnected utilities.
3. Favor document-driven editing abstractions and pipeline-owned mutation logic over ad hoc UI writes.
4. Preserve recoverability and explicit mutation reporting as default behavior.

## Product Identity

KotOR Tools is a **Godot 4.6 editor plugin** focused on practical modding parity for Aurora-family resources, not a generic binary reverse-engineering toolkit.

## Success Metrics

- More supported format families reach parser/importer/resource/write-back parity.
- More high-frequency edits complete in workspace editors without external tools.
- Install/restore operations remain deterministic and inspectable.
- Contributor planning/docs map directly to implementable slices with less re-discovery effort.

## Current Work Tracks

1. **Parity expansion:** close write-back and editor parity gaps identified in `docs/30-gap-analysis/godot-support-gaps.md`.
2. **Editing safety and consistency:** strengthen post-mutation consistency, reload behavior, and state coherence.
3. **Godot capability leverage:** adopt additional Godot editor systems (undo/redo, inspector-guided editing, targeted refresh hooks) where they reduce user risk or effort.
4. **Execution readiness:** keep strategy, requirements, plans, and gap-analysis docs aligned so implementation starts from authoritative inputs.

## Near-Term Priorities

- Convert the highest-priority gap items into focused implementation plans.
- Land one strategy-aligned capability slice end-to-end, then refresh strategy/gap docs based on outcomes.
- Keep this strategy updated as capabilities shift so contributors inherit current direction by default.
