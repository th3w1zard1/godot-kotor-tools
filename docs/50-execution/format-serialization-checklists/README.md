# Format Serialization Checklists

Per-format pre-implementation gates for contributors adding or extending Aurora format IO in godot-kotor-tools.

## How to use

1. Read the shared playbook: `docs/50-execution/godot-kotor-implementation-playbook.md`
2. Check coverage in `docs/50-execution/godot-loader-saver-importer-parity-matrix.md`
3. Open the checklist for your format family below
4. Confirm official API contracts in `docs/90-meta/godot-doc-source-map.md`

## Checklists

| Format family | Checklist |
| --- | --- |
| GFF-family (utc…gff) | [gff-family.md](gff-family.md) |
| 2DA and TLK | [twoda-tlk.md](twoda-tlk.md) |
| ERF / RIM / MOD | [erf-rim-mod.md](erf-rim-mod.md) |
| SSF and LIP | [ssf-lip.md](ssf-lip.md) |

## Shared gates (all formats) `[OFFICIAL]` + `[SYNTH]`

Before shipping a new format slice:

- [ ] Parser handles malformed input with explicit errors (no silent fallbacks)
- [ ] Writer output is deterministic for a given semantic input
- [ ] Round-trip test: parse → mutate → serialize → re-parse
- [ ] Post-write reload uses explicit cache mode (`CACHE_MODE_REPLACE`) when testing via `ResourceLoader`
- [ ] UI mutations flow through document + mutation service, not ad-hoc binary writes
- [ ] Parity matrix updated in `godot-loader-saver-importer-parity-matrix.md`
