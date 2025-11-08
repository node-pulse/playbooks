#!/bin/bash
set -euo pipefail

# Validate os_support format in manifest.json
# Usage: validate-os-support.sh <playbook_dir> [<playbook_dir> ...]

EXIT_CODE=0
VALID_DISTROS=("ubuntu" "debian" "centos" "rhel" "rocky" "alma")
VALID_ARCH=("amd64" "arm64" "both")

for dir in "$@"; do
  if [ -z "$dir" ]; then
    continue
  fi

  manifest_file="$dir/manifest.json"

  echo "::group::Validating os_support format for $manifest_file"

  if [ ! -f "$manifest_file" ]; then
    echo "::error file=$manifest_file::Manifest file not found"
    EXIT_CODE=1
    echo "::endgroup::"
    continue
  fi

  # Check if os_support is an array
  if ! jq -e '.os_support | type == "array"' "$manifest_file" > /dev/null 2>&1; then
    echo "::error file=$manifest_file::os_support must be an array"
    EXIT_CODE=1
    echo "::endgroup::"
    continue
  fi

  # Check if os_support has at least one entry
  os_count=$(jq '.os_support | length' "$manifest_file")
  if [ "$os_count" -eq 0 ]; then
    echo "::error file=$manifest_file::os_support must have at least one entry"
    EXIT_CODE=1
    echo "::endgroup::"
    continue
  fi

  # Validate each os_support entry
  for i in $(seq 0 $((os_count - 1))); do
    distro=$(jq -r ".os_support[$i].distro" "$manifest_file" 2>/dev/null || echo "")
    version=$(jq -r ".os_support[$i].version" "$manifest_file" 2>/dev/null || echo "")
    arch=$(jq -r ".os_support[$i].arch" "$manifest_file" 2>/dev/null || echo "")

    # Check distro
    if [[ ! " ${VALID_DISTROS[@]} " =~ " ${distro} " ]]; then
      echo "::error file=$manifest_file::Invalid distro '$distro' in os_support[$i]"
      EXIT_CODE=1
    fi

    # Check version exists
    if [ "$version" = "null" ] || [ -z "$version" ]; then
      echo "::error file=$manifest_file::Missing version in os_support[$i]"
      EXIT_CODE=1
    fi

    # Check arch
    if [[ ! " ${VALID_ARCH[@]} " =~ " ${arch} " ]]; then
      echo "::error file=$manifest_file::Invalid arch '$arch' in os_support[$i] (must be: amd64, arm64, or both)"
      EXIT_CODE=1
    fi
  done

  if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Valid os_support format with $os_count entries"
  fi

  echo "::endgroup::"
done

exit $EXIT_CODE
