#!/bin/bash
set -euo pipefail

# Validate JSON syntax for playbook manifests
# Usage: validate-json-syntax.sh <playbook_dir> [<playbook_dir> ...]

EXIT_CODE=0

for dir in "$@"; do
  if [ -z "$dir" ]; then
    continue
  fi

  manifest_file="$dir/manifest.json"

  echo "::group::Validating JSON syntax for $manifest_file"

  if [ ! -f "$manifest_file" ]; then
    echo "::error file=$manifest_file::Manifest file not found: $manifest_file"
    EXIT_CODE=1
  elif ! jq empty "$manifest_file" 2>&1; then
    echo "::error file=$manifest_file::Invalid JSON in $manifest_file"
    EXIT_CODE=1
  else
    echo "✅ Valid JSON in $manifest_file"
  fi

  echo "::endgroup::"
done

exit $EXIT_CODE
