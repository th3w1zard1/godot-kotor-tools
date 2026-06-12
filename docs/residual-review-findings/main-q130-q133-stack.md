# Residual Review Findings — Q130–Q133 stack merge

**Source:** `ce-code-review` against `docs/plans/2026-06-10-078-chore-q130-q133-stack-merge-plan.md` (2026-06-12)

## Residual Review Findings

- **P1** `editor/modding/kotor_modding_pipeline.gd:523-537` — MdlResource install serializes MDL with MDX-aware validation but writes only `.mdl`; defer paired `.mdx` sidecar install (mirror `mdl_gamefs_batch_importer.gd` pairing).
- **P1** `ui/workspace/editors/mdl_workspace_editor.gd:570-576` — Install MDL to Override never installs paired MDX sidecar when `has_mdx()`; extend install flow after successful MDL write.

**Deferred:** Not applied in LFG step 4 — behavior change requiring design sign-off (confidence 85).
