---
title: "feat: Strengthen knowledgebase, quickstart, and README authority"
status: "active"
created: "2026-05-24"
owner: "copilot"
---

## Summary

Improve onboarding and documentation trust by aligning the repository README with the current plugin architecture and verification workflow, adding a user-facing quickstart guide, and tightening knowledgebase navigation so future contributors can find canonical guidance quickly.

---

## Problem Frame

Current docs are useful but fragmented: onboarding instructions are broad, quickstart guidance is not centralized, and knowledgebase entry points do not clearly indicate which files are authoritative for setup vs architecture vs implementation conventions.

---

## Scope Boundaries

### In scope

- Refresh `README.md` for accurate setup, usage framing, and validation workflow.
- Add a concise `docs/QUICKSTART.md` with practical first-run steps for end users.
- Update knowledgebase index/navigation docs so readers can find canonical sources quickly.

### Deferred for later

- Any UI/tutorial screenshots or video walkthroughs.
- Localization of user-facing docs.

### Out of scope

- Feature/code changes to plugin runtime behavior.
- New format support or editor functionality.

---

## Requirements

- **R1:** README provides authoritative, accurate setup and purpose statements for the plugin.
- **R2:** A quickstart document gives a short, user-facing path from install to first successful workflow.
- **R3:** Knowledgebase docs clearly identify authoritative doc paths and intended audience.
- **R4:** Doc updates remain consistent with existing repository architecture and validation conventions.

---

## Key Technical Decisions

- Keep README as the top-level canonical entrypoint for repository visitors; keep deep implementation guidance in `docs/`.
- Introduce a dedicated quickstart guide in `docs/` and link it from README to reduce onboarding friction.
- Preserve command and architecture claims already validated in this repository (Godot 4.6 target, `--check-only` validation baseline).

---

## Implementation Units

### U1. Refresh README as canonical entrypoint

**Goal:** Ensure README accurately communicates what the plugin does, who it is for, and how to install and verify setup.

**Requirements:** R1, R4

**Dependencies:** None

**Files:**
- `README.md`

**Approach:**
- Rework README headings for a clear user journey: purpose -> install -> first run -> validation -> architecture pointers.
- Ensure setup steps are explicit and editor-oriented (enable plugin, configure game path, open workspace).
- Keep advanced API details concise and link readers to docs where deeper detail belongs.

**Patterns to follow:**
- Existing repository architecture and command conventions in `.github/copilot-instructions.md`.
- Current feature coverage language already present in `README.md`.

**Test scenarios:**
- Happy path: new user can follow README steps and identify how to enable the plugin in Godot.
- Edge case: user cloning manually still sees complete install instructions without Asset Library.
- Error path: user without game install path can still complete plugin enablement and understand limitation.
- Integration: README links to quickstart and knowledgebase docs resolve and describe correct purpose.

**Verification:**
- README presents a coherent setup flow with no contradictory commands or architecture claims.

### U2. Add a focused quickstart guide

**Goal:** Provide a short, user-facing quickstart that gets users from install to first successful use.

**Requirements:** R2, R4

**Dependencies:** U1

**Files:**
- `docs/QUICKSTART.md`
- `README.md`

**Approach:**
- Create a compact guide with prerequisites, install, plugin enablement, first workspace open, and common pitfalls.
- Include minimal validation guidance so users can confirm plugin scripts parse in their environment.
- Link back to README and architecture docs for deeper context.

**Patterns to follow:**
- Concise instructional style used in existing repository docs under `docs/`.

**Test scenarios:**
- Happy path: quickstart can be followed linearly to reach visible plugin UI in Godot editor.
- Edge case: user on non-default project path can still perform manual install with clear directory example.
- Error path: plugin not visible scenario includes clear troubleshooting checks.
- Integration: quickstart references README and knowledgebase docs consistently with no duplicate/conflicting claims.

**Verification:**
- Quickstart is scannable and complete enough for first-use success without requiring deep architecture reading.

### U3. Tighten knowledgebase navigation and authority cues

**Goal:** Make it obvious which docs are canonical for setup, architecture, and implementation guidance.

**Requirements:** R3, R4

**Dependencies:** U1, U2

**Files:**
- `docs/00-intent/godot-serialization-kb-intent.md`
- `docs/90-meta/godot-doc-source-map.md`

**Approach:**
- Add explicit authority cues and "start here" links that differentiate user onboarding docs vs maintainer docs.
- Ensure references to external docs are presented as supporting sources, not replacing repo-specific guidance.

**Patterns to follow:**
- Existing layered documentation taxonomy in `docs/` and current intent/source-map structure.

**Test scenarios:**
- Happy path: contributor can identify which doc to read first for setup vs implementation.
- Edge case: contributor seeking API references can find official doc links from source map quickly.
- Integration: all cross-links between README, quickstart, and knowledgebase docs are bidirectional where useful.

**Verification:**
- Documentation hierarchy is explicit and reduces ambiguity about authoritative sources.

---

## System-Wide Impact

- Improves first-run success and decreases onboarding friction for new users and contributors.
- Reduces documentation drift risk by clarifying canonical doc ownership and linkage.

---

## Risks and Mitigations

- **Risk:** README and quickstart drift over time.
  - **Mitigation:** Add clear authority statements and keep validation command references aligned with repository conventions.
- **Risk:** Overly long README reduces usability.
  - **Mitigation:** Keep deep details in `docs/` and use concise links from README.

---

## Deferred Implementation Notes

- If future releases add major UI flows, add screenshots in a follow-up documentation slice.
- Consider adding a docs check script in a separate effort if link drift becomes frequent.

