#!/usr/bin/env bash
# PostToolUse hook: runs ruff check --fix on the edited Python file.
# Input: event JSON on stdin with .tool_input.file_path

INPUT="$(cat)"
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"

[[ -z "$FILE_PATH" ]] && exit 0
[[ "$FILE_PATH" != *.py ]] && exit 0
[[ ! -f "$FILE_PATH" ]] && exit 0

if command -v uv >/dev/null 2>&1; then
  uv run ruff check --fix --quiet "$FILE_PATH" 2>&1 || true
elif command -v ruff >/dev/null 2>&1; then
  ruff check --fix --quiet "$FILE_PATH" 2>&1 || true
fi
