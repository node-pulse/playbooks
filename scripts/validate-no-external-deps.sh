#!/bin/bash
set -euo pipefail

# Validate playbooks have no external dependencies
# Usage: validate-no-external-deps.sh <playbook_dir> [<playbook_dir> ...]

EXIT_CODE=0

for dir in "$@"; do
  if [ -z "$dir" ]; then
    continue
  fi

  echo "::group::Checking $dir for external dependencies"

  # Check for requirements.yml
  if [ -f "$dir/requirements.yml" ]; then
    echo "::error file=$dir/requirements.yml::Found requirements.yml in $dir"
    echo "Playbooks must not use external dependency fetching."
    echo "If you need Galaxy role code, copy it into your playbook directory."
    EXIT_CODE=1
  fi

  # Check for meta/main.yml with external dependencies
  if [ -f "$dir/meta/main.yml" ]; then
    if grep -q "dependencies:" "$dir/meta/main.yml" 2>/dev/null; then
      if grep -qE "dependencies:.*[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+" "$dir/meta/main.yml" 2>/dev/null; then
        echo "::error file=$dir/meta/main.yml::External role dependencies found in meta/main.yml"
        echo "Copy external role code into your playbook directory instead."
        EXIT_CODE=1
      fi
    fi
  fi

  if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Playbook $dir has zero external dependencies"
  fi

  echo "::endgroup::"
done

exit $EXIT_CODE
