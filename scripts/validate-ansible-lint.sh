#!/bin/bash
set -euo pipefail

# Run ansible-lint on playbook files (ENFORCED - will fail build on errors)
# Usage: validate-ansible-lint.sh <playbook_dir> [<playbook_dir> ...]

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

  # Lint install playbook
  if [ -n "$install_file" ] && [ "$install_file" != "null" ] && [ -f "$dir/$install_file" ]; then
    playbook_file="$dir/$install_file"
    echo "::group::Running ansible-lint on $playbook_file"

    # Run ansible-lint and capture exit code
    set +e
    ansible-lint "$playbook_file"
    lint_exit_code=$?
    set -e

    if [ $lint_exit_code -ne 0 ]; then
      echo "::error file=$playbook_file::ansible-lint found violations in $playbook_file"
      EXIT_CODE=1
    else
      echo "✅ No ansible-lint issues in $playbook_file"
    fi

    echo "::endgroup::"
  fi

  # Lint uninstall playbook
  if [ -n "$uninstall_file" ] && [ "$uninstall_file" != "null" ] && [ -f "$dir/$uninstall_file" ]; then
    playbook_file="$dir/$uninstall_file"
    echo "::group::Running ansible-lint on $playbook_file"

    # Run ansible-lint and capture exit code
    set +e
    ansible-lint "$playbook_file"
    lint_exit_code=$?
    set -e

    if [ $lint_exit_code -ne 0 ]; then
      echo "::error file=$playbook_file::ansible-lint found violations in $playbook_file"
      EXIT_CODE=1
    else
      echo "✅ No ansible-lint issues in $playbook_file"
    fi

    echo "::endgroup::"
  fi

  # Lint update playbook (optional)
  if [ -n "$update_file" ] && [ "$update_file" != "null" ] && [ -f "$dir/$update_file" ]; then
    playbook_file="$dir/$update_file"
    echo "::group::Running ansible-lint on $playbook_file"

    # Run ansible-lint and capture exit code
    set +e
    ansible-lint "$playbook_file"
    lint_exit_code=$?
    set -e

    if [ $lint_exit_code -ne 0 ]; then
      echo "::error file=$playbook_file::ansible-lint found violations in $playbook_file"
      EXIT_CODE=1
    else
      echo "✅ No ansible-lint issues in $playbook_file"
    fi

    echo "::endgroup::"
  fi
done

# Exit with failure if any playbook had lint errors
exit $EXIT_CODE
