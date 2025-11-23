#!/bin/bash
set -euo pipefail

# Run ansible-lint on playbook files (warnings don't fail)
# Usage: validate-ansible-lint.sh <playbook_dir> [<playbook_dir> ...]

for dir in "$@"; do
  if [ -z "$dir" ]; then
    continue
  fi

  manifest_file="$dir/manifest.json"

  if [ ! -f "$manifest_file" ]; then
    continue
  fi

  # Get install and uninstall playbook files
  install_file=$(jq -r '.structure.playbooks.install.file' "$manifest_file" 2>/dev/null || echo "")
  uninstall_file=$(jq -r '.structure.playbooks.uninstall.file' "$manifest_file" 2>/dev/null || echo "")

  # Lint install playbook
  if [ -n "$install_file" ] && [ "$install_file" != "null" ] && [ -f "$dir/$install_file" ]; then
    playbook_file="$dir/$install_file"
    echo "::group::Running ansible-lint on $playbook_file"

    if ! ansible-lint "$playbook_file" 2>&1; then
      echo "::warning file=$playbook_file::ansible-lint warnings/errors in $playbook_file"
    else
      echo "✅ No ansible-lint issues in $playbook_file"
    fi

    echo "::endgroup::"
  fi

  # Lint uninstall playbook
  if [ -n "$uninstall_file" ] && [ "$uninstall_file" != "null" ] && [ -f "$dir/$uninstall_file" ]; then
    playbook_file="$dir/$uninstall_file"
    echo "::group::Running ansible-lint on $playbook_file"

    if ! ansible-lint "$playbook_file" 2>&1; then
      echo "::warning file=$playbook_file::ansible-lint warnings/errors in $playbook_file"
    else
      echo "✅ No ansible-lint issues in $playbook_file"
    fi

    echo "::endgroup::"
  fi
done

# Don't fail build on lint warnings
exit 0
