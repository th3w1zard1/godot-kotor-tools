#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v godot >/dev/null 2>&1; then
	echo "error: godot is not on PATH" >&2
	exit 127
fi

mapfile -d '' TEST_SCRIPTS < <(find tests/editor -name 'test_*.gd' -print0 | sort -z)

if [[ ${#TEST_SCRIPTS[@]} -eq 0 ]]; then
	echo "error: no headless editor tests found under tests/editor" >&2
	exit 1
fi

failed=0
passed=0

for test_script in "${TEST_SCRIPTS[@]}"; do
	echo "==> ${test_script}"
	if godot --headless --path . --script "${test_script}"; then
		passed=$((passed + 1))
	else
		echo "FAILED: ${test_script}" >&2
		failed=$((failed + 1))
	fi
done

echo "Headless editor tests: ${passed} passed, ${failed} failed (${#TEST_SCRIPTS[@]} total)"

if [[ "${failed}" -gt 0 ]]; then
	exit 1
fi
