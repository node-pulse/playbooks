#!/bin/bash
set -euo pipefail

# Validate that all playbook IDs are unique across the catalog
# Usage: validate-unique-ids.sh

EXIT_CODE=0

echo "::group::Validating unique playbook IDs"

# Find all manifest.json files and extract their IDs
manifest_files=$(find catalog -type f -name "manifest.json" 2>/dev/null || true)

if [ -z "$manifest_files" ]; then
  echo "No manifest.json files found in catalog/"
  echo "::endgroup::"
  exit 0
fi

# Extract all IDs into a temporary file
temp_ids=$(mktemp)

for manifest in $manifest_files; do
  id=$(jq -r '.id' "$manifest" 2>/dev/null || echo "")

  if [ -z "$id" ] || [ "$id" = "null" ]; then
    echo "::error file=$manifest::Missing or invalid 'id' field"
    EXIT_CODE=1
  else
    echo "$id:$manifest" >> "$temp_ids"
  fi
done

# Check for duplicate IDs
duplicates=$(cut -d: -f1 "$temp_ids" | sort | uniq -d)

if [ -n "$duplicates" ]; then
  echo "::error::Duplicate playbook IDs found!"

  for dup_id in $duplicates; do
    echo ""
    echo "Duplicate ID: $dup_id"
    grep "^$dup_id:" "$temp_ids" | while read -r line; do
      file=$(echo "$line" | cut -d: -f2-)
      echo "  - $file"
      echo "::error file=$file::Duplicate playbook ID '$dup_id'"
    done
  done

  EXIT_CODE=1
else
  total_count=$(wc -l < "$temp_ids")
  echo "✅ All $total_count playbook IDs are unique"
fi

# Cleanup
rm -f "$temp_ids"

echo "::endgroup::"
exit $EXIT_CODE
