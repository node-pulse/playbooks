#!/bin/bash
set -euo pipefail

# Run ansible-lint on playbook entry points (warnings don't fail)
# Usage: validate-ansible-lint.sh <playbook_dir> [<playbook_dir> ...]

for dir in "$@"; do
  if [ -z "$dir" ]; then
    continue
  fi

  manifest_file="$dir/manifest.json"

  if [ ! -f "$manifest_file" ]; then
    continue
  fi

  entry_point=$(jq -r '.entry_point' "$manifest_file" 2>/dev/null || echo "")
  playbook_file="$dir/$entry_point"

  if [ ! -f "$playbook_file" ]; then
    continue
  fi

  echo "::group::Running ansible-lint on $playbook_file"

  # Run ansible-lint but don't fail on warnings
  if ! ansible-lint "$playbook_file" 2>&1; then
    echo "::warning file=$playbook_file::ansible-lint warnings/errors in $playbook_file"
    # Don't set EXIT_CODE=1 for lint warnings
  else
    echo "✅ No ansible-lint issues in $playbook_file"
  fi

  echo "::endgroup::"
done

# Don't fail build on lint warnings
exit 0
