#!/bin/bash
set -euo pipefail

# Validate entry point file exists
# Usage: validate-entry-point.sh <playbook_dir> [<playbook_dir> ...]

EXIT_CODE=0

for dir in "$@"; do
  if [ -z "$dir" ]; then
    continue
  fi

  manifest_file="$dir/manifest.json"

  echo "::group::Validating entry point for $dir"

  if [ ! -f "$manifest_file" ]; then
    echo "::error file=$manifest_file::Manifest file not found"
    EXIT_CODE=1
    echo "::endgroup::"
    continue
  fi

  entry_point=$(jq -r '.entry_point' "$manifest_file" 2>/dev/null || echo "")

  if [ -z "$entry_point" ] || [ "$entry_point" = "null" ]; then
    echo "::error file=$manifest_file::Missing entry_point in manifest"
    EXIT_CODE=1
  elif [ ! -f "$dir/$entry_point" ]; then
    echo "::error file=$dir/$entry_point::Entry point '$entry_point' not found in $dir"
    EXIT_CODE=1
  else
    echo "✅ Entry point '$entry_point' exists in $dir"
  fi

  echo "::endgroup::"
done

exit $EXIT_CODE
