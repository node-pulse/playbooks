#!/bin/bash
set -euo pipefail

# Validate required fields and basic rules in manifest.json
# Usage: validate-manifest-fields.sh <playbook_dir> [<playbook_dir> ...]

EXIT_CODE=0
REQUIRED_FIELDS=("id" "name" "version" "description" "category" "entry_point" "ansible_version" "os_support" "license")

for dir in "$@"; do
  if [ -z "$dir" ]; then
    continue
  fi

  manifest_file="$dir/manifest.json"

  echo "::group::Validating required fields in $manifest_file"

  if [ ! -f "$manifest_file" ]; then
    echo "::error file=$manifest_file::Manifest file not found"
    EXIT_CODE=1
    echo "::endgroup::"
    continue
  fi

  # Check required fields exist
  for field in "${REQUIRED_FIELDS[@]}"; do
    if ! jq -e ".$field" "$manifest_file" > /dev/null 2>&1; then
      echo "::error file=$manifest_file::Missing required field '$field' in $manifest_file"
      EXIT_CODE=1
    fi
  done

  # Validate ID format (must be pb_[A-Za-z0-9]{10})
  manifest_id=$(jq -r '.id' "$manifest_file" 2>/dev/null || echo "")

  if [ -n "$manifest_id" ]; then
    if [[ ! "$manifest_id" =~ ^pb_[A-Za-z0-9]{10}$ ]]; then
      echo "::error file=$manifest_file::Manifest ID '$manifest_id' must match format 'pb_[A-Za-z0-9]{10}'"
      EXIT_CODE=1
    else
      echo "✅ Manifest ID format is valid: $manifest_id"
    fi
  fi

  if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ All required fields present in $manifest_file"
  fi

  echo "::endgroup::"
done

exit $EXIT_CODE
