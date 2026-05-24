# Godot Serialization Primitives for Custom Pipelines

## Binary IO Primitives

- `FileAccess` is the core byte-stream API for reading/writing files and cursor-driven binary operations.
- `PackedByteArray` is the canonical packed byte container for parsers and binary transforms.

Use these for Aurora binary formats where field-level layout control matters.

## Variant/Marshalling Primitives

- `Marshalls.variant_to_base64()` / `Marshalls.base64_to_variant()` for encoded transport/storage forms.
- `@GlobalScope` `var_to_bytes()` / `bytes_to_var()` and `var_to_str()` / `str_to_var()` for variant conversion pipelines.

Security note: object-capable variant decode/encode options can embed executable object data; keep object decoding disabled unless explicitly required by trusted data paths.

## Resource Serialization Boundaries

- Keep parser/writer concerns separate from editor UI concerns.
- Treat `Resource` wrappers as stable conversion boundaries between low-level bytes and editor-facing typed APIs.
- Keep extension recognition strict and explicit in savers/loaders.

## Repo Implications

- Existing Aurora parsers/writers in `formats/` should remain byte-oriented and deterministic.
- `resources/*` and `resources/documents/*` should carry mutation semantics; `savers/*` should only translate resource -> bytes/file.

## Next Actions

1. Add explicit endian/width handling notes next to each binary writer/parser where non-obvious.
2. Centralize shared byte/variant conversion helpers to reduce duplicate conversion logic.
3. Add malformed-input test vectors for each parser and writer.
