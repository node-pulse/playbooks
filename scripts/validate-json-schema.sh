#!/bin/bash
set -euo pipefail

# Validate manifest.json files against JSON Schema
# Usage: validate-json-schema.sh <playbook_dir> [<playbook_dir> ...]

SCHEMA_FILE="schemas/node-pulse-admiral-playbook-manifest-v1.schema.json"
EXIT_CODE=0

if [ ! -f "$SCHEMA_FILE" ]; then
  echo "::error::Schema file not found: $SCHEMA_FILE"
  exit 1
fi

for dir in "$@"; do
  if [ -z "$dir" ]; then
    continue
  fi

  manifest_file="$dir/manifest.json"

  echo "::group::Validating $manifest_file against schema"

  if [ ! -f "$manifest_file" ]; then
    echo "::error file=$manifest_file::Manifest file not found: $manifest_file"
    EXIT_CODE=1
  elif ! check-jsonschema --schemafile "$SCHEMA_FILE" "$manifest_file"; then
    echo "::error file=$manifest_file::Schema validation failed for $manifest_file"
    EXIT_CODE=1
  else
    echo "✅ Schema validation passed for $manifest_file"
  fi

  echo "::endgroup::"
done

exit $EXIT_CODE
