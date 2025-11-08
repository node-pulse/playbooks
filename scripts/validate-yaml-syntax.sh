#!/bin/bash
set -euo pipefail

# Validate YAML syntax of playbook entry points
# Usage: validate-yaml-syntax.sh <playbook_dir> [<playbook_dir> ...]

EXIT_CODE=0

for dir in "$@"; do
  if [ -z "$dir" ]; then
    continue
  fi

  manifest_file="$dir/manifest.json"

  if [ ! -f "$manifest_file" ]; then
    continue
  fi

  entry_point=$(jq -r '.entry_point' "$manifest_file" 2>/dev/null || echo "")
  playbook_file="$dir/$entry_point"

  if [ ! -f "$playbook_file" ]; then
    continue
  fi

  echo "::group::Validating YAML syntax for $playbook_file"

  if ! ansible-playbook --syntax-check "$playbook_file" 2>&1; then
    echo "::error file=$playbook_file::YAML syntax error in $playbook_file"
    EXIT_CODE=1
  else
    echo "✅ Valid YAML syntax in $playbook_file"
  fi

  echo "::endgroup::"
done

exit $EXIT_CODE
