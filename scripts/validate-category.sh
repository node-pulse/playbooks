#!/bin/bash
set -euo pipefail

# Validate category field in manifest.json
# Usage: validate-category.sh <playbook_dir> [<playbook_dir> ...]

EXIT_CODE=0
VALID_CATEGORIES=("monitoring" "database" "search" "security" "proxy" "storage" "dev-tools" "automation" "finance")

for dir in "$@"; do
  if [ -z "$dir" ]; then
    continue
  fi

  manifest_file="$dir/manifest.json"

  echo "::group::Validating category for $manifest_file"

  if [ ! -f "$manifest_file" ]; then
    echo "::error file=$manifest_file::Manifest file not found"
    EXIT_CODE=1
    echo "::endgroup::"
    continue
  fi

  category=$(jq -r '.category' "$manifest_file" 2>/dev/null || echo "")

  if [ -z "$category" ] || [ "$category" = "null" ]; then
    echo "::error file=$manifest_file::Missing category in manifest"
    EXIT_CODE=1
  elif [[ ! " ${VALID_CATEGORIES[@]} " =~ " ${category} " ]]; then
    echo "::error file=$manifest_file::Invalid category '$category' in $manifest_file"
    echo "Valid categories: ${VALID_CATEGORIES[*]}"
    EXIT_CODE=1
  else
    echo "✅ Valid category '$category' in $manifest_file"
  fi

  echo "::endgroup::"
done

exit $EXIT_CODE
