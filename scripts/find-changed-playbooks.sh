#!/bin/bash
set -euo pipefail

# Find changed playbooks between two git refs
# Usage: find-changed-playbooks.sh <base_ref> <head_ref>

BASE_REF="${1:-}"
HEAD_REF="${2:-}"

if [ -z "$BASE_REF" ] || [ -z "$HEAD_REF" ]; then
  echo "Usage: $0 <base_ref> <head_ref>" >&2
  exit 1
fi

echo "Comparing $BASE_REF...$HEAD_REF" >&2

# Get changed files in playbook directories (catalog/a-z)
changed_files=$(git diff --name-only "$BASE_REF"..."$HEAD_REF" | grep -E '^catalog/[a-z]/[^/]+/' || true)

if [ -z "$changed_files" ]; then
  echo "No playbook changes detected" >&2
  exit 0
fi

echo "Changed files:" >&2
echo "$changed_files" >&2

# Extract unique playbook directories (catalog/letter/playbook)
changed_dirs=$(echo "$changed_files" | cut -d'/' -f1,2,3 | sort -u)

echo "Changed playbook directories:" >&2
echo "$changed_dirs" >&2

# Output to stdout (for GitHub Actions)
echo "$changed_dirs"
