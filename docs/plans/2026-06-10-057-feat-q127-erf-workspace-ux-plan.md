---
title: feat: Q127 ERF archive workspace UX
type: feat
status: shipped
date: 2026-06-10
parent: docs/plans/2026-06-10-056-feat-pr-stack-merge-holocron-parity-roadmap-plan.md
---

## Summary

Dedicated workspace tab for ERF/RIM/MOD/SAV archives with member listing, nested resource open routing, and extract-to-override with preflight.

## Verification

- `tests/editor/test_erf_workspace_editor.gd` — member listing, extract install, invalid resref blocked
- Workspace shell routes archive extensions and `member_open_requested` to typed editors
