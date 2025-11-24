#!/bin/bash
set -euo pipefail

# Validate YAML syntax of playbook files
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

  # Get install, uninstall, and update playbook files
  install_file=$(jq -r '.structure.playbooks.install.file' "$manifest_file" 2>/dev/null || echo "")
  uninstall_file=$(jq -r '.structure.playbooks.uninstall.file' "$manifest_file" 2>/dev/null || echo "")
  update_file=$(jq -r '.structure.playbooks.update.file // empty' "$manifest_file" 2>/dev/null || echo "")

  # Validate install playbook syntax
  if [ -n "$install_file" ] && [ "$install_file" != "null" ] && [ -f "$dir/$install_file" ]; then
    playbook_file="$dir/$install_file"
    echo "::group::Validating YAML syntax for $playbook_file"

    if ! ansible-playbook --syntax-check "$playbook_file" 2>&1; then
      echo "::error file=$playbook_file::YAML syntax error in $playbook_file"
      EXIT_CODE=1
    else
      echo "✅ Valid YAML syntax in $playbook_file"
    fi

    echo "::endgroup::"
  fi

  # Validate uninstall playbook syntax
  if [ -n "$uninstall_file" ] && [ "$uninstall_file" != "null" ] && [ -f "$dir/$uninstall_file" ]; then
    playbook_file="$dir/$uninstall_file"
    echo "::group::Validating YAML syntax for $playbook_file"

    if ! ansible-playbook --syntax-check "$playbook_file" 2>&1; then
      echo "::error file=$playbook_file::YAML syntax error in $playbook_file"
      EXIT_CODE=1
    else
      echo "✅ Valid YAML syntax in $playbook_file"
    fi

    echo "::endgroup::"
  fi

  # Validate update playbook syntax (optional)
  if [ -n "$update_file" ] && [ "$update_file" != "null" ] && [ -f "$dir/$update_file" ]; then
    playbook_file="$dir/$update_file"
    echo "::group::Validating YAML syntax for $playbook_file"

    if ! ansible-playbook --syntax-check "$playbook_file" 2>&1; then
      echo "::error file=$playbook_file::YAML syntax error in $playbook_file"
      EXIT_CODE=1
    else
      echo "✅ Valid YAML syntax in $playbook_file"
    fi

    echo "::endgroup::"
  fi
done

exit $EXIT_CODE
