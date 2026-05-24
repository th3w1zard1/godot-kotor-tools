---
title: "feat: Add Godot support gap analysis"
status: "active"
created: "2026-05-24"
owner: "copilot"
---

## Summary

Document current Godot-facing support in this repository, identify implementation/documentation gaps, and provide actionable next steps for what additional Godot capabilities can be added next.

---

## Problem Frame

The repository has strong format and editor tooling coverage, but there is no single authoritative artifact that answers: "what does this plugin already support in Godot, what is partial, and what remains to implement?"

---

## Scope Boundaries

### In scope

- Produce a contributor-facing support/gap analysis document.
- Link that document from top-level docs so it is discoverable.
- Align findings to current repository architecture and known Godot 4.6 target.

### Deferred for later

- Implementing the newly identified feature gaps.
- Adding benchmark/performance measurements for each gap.

### Out of scope

- Runtime/editor feature code changes unrelated to documentation.
- External service integrations.

---

## Requirements

- **R1:** Capture current supported Godot/plugin capabilities in one doc.
- **R2:** Identify concrete implementation gaps and classify them by priority.
- **R3:** Include examples of additional Godot support areas relevant to this plugin architecture.
- **R4:** Keep navigation authoritative by linking this analysis from README/knowledgebase surfaces.

---

## Key Technical Decisions

- Keep the analysis in `docs/` as a durable knowledgebase artifact rather than transient PR notes.
- Use "supported / partial / missing / next step" structure so the document is actionable.
- Keep recommendations grounded in existing architecture boundaries (parsers/resources/importers/savers/workspace pipeline).

---

## Implementation Units

### U1. Create Godot support and gap analysis document

**Goal:** Add an authoritative document that summarizes current support, gaps, and proposed next implementation areas.

**Requirements:** R1, R2, R3

**Dependencies:** None

**Files:**
- `docs/30-gap-analysis/godot-support-gaps.md`

**Approach:**
- Summarize currently shipped support by capability area.
- Add prioritized gap table with concrete "next implementation slice" guidance.
- Include examples of what else Godot supports that this plugin can adopt next.

**Patterns to follow:**
- Layered docs structure used across `docs/00-intent`, `docs/50-execution`, and `docs/90-meta`.

**Test scenarios:**
- Happy path: contributor can answer "what is supported now?" from this doc without reading source.
- Edge case: partial support areas are marked clearly so readers do not assume full parity.
- Integration: recommendations are mapped to existing repo architecture (formats/resources/importers/savers/workspace).

**Verification:**
- Document includes supported/partial/missing breakdown and prioritized next steps.

### U2. Wire discoverability from README and knowledgebase entry points

**Goal:** Ensure the new gap analysis is easy to discover from canonical docs.

**Requirements:** R4

**Dependencies:** U1

**Files:**
- `README.md`
- `docs/00-intent/godot-serialization-kb-intent.md`

**Approach:**
- Add links in existing "documentation map" sections.
- Keep wording concise and consistent with authority cues.

**Patterns to follow:**
- Existing documentation map and start-here patterns already used in these files.

**Test scenarios:**
- Happy path: users can navigate from README to gap analysis in one click.
- Integration: knowledgebase intent doc includes the same link target and role.

**Verification:**
- Both README and KB intent contain valid links to the new analysis doc.

---

## System-Wide Impact

- Improves planning quality by making support boundaries explicit.
- Reduces repetitive "what should we build next?" rediscovery work.

---

## Risks and Mitigations

- **Risk:** Gap analysis becomes stale.
  - **Mitigation:** Include "refresh when" guidance in the analysis doc.
- **Risk:** Recommendations become too speculative.
  - **Mitigation:** Tie each recommendation to current architecture and concrete implementation slices.

---

## Deferred Implementation Notes

- After adoption, convert high-priority gaps into dedicated feature plans with scoped implementation units.

