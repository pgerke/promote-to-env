#!/bin/bash

set -euo pipefail

TARGET_BRANCH="${1:?Missing target branch (e.g. int)}"
SOURCE_BRANCH="${2:?Missing source branch (e.g. dev)}"
BODY_FILE="${3:-}"                # optional: path to Markdown file
REMOTE="${4:-origin}"             # optional: remote name
REPO="${5:-}"                     # optional: owner/repo or path

NEW_BRANCH="merge-to-${TARGET_BRANCH}"

# Optional: override working directory for repo
if [[ -n "${REPO}" ]]; then
  echo "📁 Changing to repo: ${REPO}"
  cd "${REPO}"
fi

echo "🚀 Using remote: ${REMOTE}"
echo "🌿 Creating branch ${NEW_BRANCH} from ${REMOTE}/${TARGET_BRANCH}"

# Checkout base branch and create new one
git fetch "${REMOTE}" "${TARGET_BRANCH}"
git checkout -B "${NEW_BRANCH}" "${REMOTE}/${TARGET_BRANCH}"

# Merge source branch with fast-forward only
git fetch "${REMOTE}" "${SOURCE_BRANCH}"
git merge --ff-only "${REMOTE}/${SOURCE_BRANCH}"

# Push new branch
git push -u "${REMOTE}" "${NEW_BRANCH}"

# Prepare PR body
PR_BODY_ARGS=()
if [[ -n "${BODY_FILE}" ]]; then
  TEMP_BODY=$(mktemp)
  sed -e "s/SOURCE_BRANCH/${SOURCE_BRANCH}/g" \
      -e "s/TARGET_BRANCH/${TARGET_BRANCH}/g" \
      "${BODY_FILE}" > "${TEMP_BODY}"
  PR_BODY_ARGS+=(--body-file "${TEMP_BODY}")
else
  PR_BODY_ARGS+=(--body "**This PR promotes \`${SOURCE_BRANCH}\` into \`${TARGET_BRANCH}\`.**")
fi

# Create PR
PR_URL=$(gh pr create \
  --title "Merge to ${TARGET_BRANCH}" \
  --base "${TARGET_BRANCH}" \
  --head "${NEW_BRANCH}" \
  --assignee "@me" \
  --repo "$(gh repo view --json nameWithOwner -q .nameWithOwner)" \
  "${PR_BODY_ARGS[@]}")

# Clean up if needed
[[ -n "${TEMP_BODY:-}" ]] && rm -f "${TEMP_BODY}"

# Output
echo "✅ PR created: ${PR_URL}"
