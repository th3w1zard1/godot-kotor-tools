---
title: Q24 Indoor Hook Connections
type: feat
status: shipped
date: 2026-05-29
origin: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
phase: Q24
track: OpenKotOR Parity
parent: docs/plans/2026-05-29-018-feat-holocron-full-parity-master-plan.md
---

# Q24: Indoor Hook Connections

## Summary

Mirror PyKotor `IndoorMapRoom.rebuild_connections` and `door_insertions` **connection detection**: compute door-hook world positions, snap hooks between rooms within tolerance, expose connection state in the Indoor Builder UI, and auto-refresh after room transforms.

## Problem frame

Q23 placed kit rooms but does not evaluate hook adjacency. Holocron/PyKotor infers door connections at build time from hook positions; mod authors need visual feedback that adjacent hooks align before export (Q25+).

## Key technical decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Persistence | Runtime-only connection cache | Matches PyKotor — connections not stored in `.indoor` JSON |
| Algorithm | `distance < 0.001` hook world positions | Same threshold as `pykotor.common.indoormap.IndoorMapRoom.rebuild_connections` |
| Hook source | Kit library + embedded component `hooks` | Unified resolver on document |
| UX | Auto-rebuild on move/rotate/add; manual button | Keeps map state current without export |

## Requirements

| ID | Requirement | Verification |
| --- | --- | --- |
| R1 | `KotorIndoorHookConnections` computes hook world positions with flip/rotate | Unit test |
| R2 | `KotorIndoorDocument.rebuild_room_connections` fills per-room hook targets | Unit test with two aligned rooms |
| R3 | Summary + room detail show hook connection counts | Editor wiring |
| R4 | Map view draws hook markers (connected vs open) | Visual in map view code path |
| R5 | Auto-rebuild after drag/rotate/add room | Editor hooks |
| R6 | Docs mark Q24 shipped | Parity matrix + queue |

## Explicit non-goals (Q24)

- `.mod` export / `IndoorMap.build()`
- Door insertion GIT/UTD generation
- Hook snap drag placement mode
- Tile kit v2 (`format_version == 2`)

## Verification

```bash
godot --headless --path . --script tests/editor/test_indoor_hook_connections.gd
godot --headless --path . --script tests/editor/test_indoor_builder_foundations.gd
godot --headless --path . --script tests/editor/test_indoor_kit_library.gd
```

## Acceptance

- [x] Hook connection tests pass
- [x] Indoor Builder shows hook markers and connection summary
- [x] Move/rotate triggers connection rebuild
- [x] Docs reflect Q24 shipped
