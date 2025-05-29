#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# --- Defaults ---
REMOTE="origin"
BODY_FILE=""
BODY=""
DRY_RUN=false
REPO_PATH=""
MERGE_STRATEGY="merge"
AUTO_MERGE=false

# --- Argument parsing ---
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target|-t)
      TARGET_BRANCH="$2"
      shift 2
      ;;
    --source|-s)
      SOURCE_BRANCH="$2"
      shift 2
      ;;
    --body-file)
      BODY_FILE="$2"
      shift 2
      ;;
    --body)
      BODY="$2"
      shift 2
      ;;
    --remote)
      REMOTE="$2"
      shift 2
      ;;
    --merge-strategy)
      MERGE_STRATEGY="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --auto-merge)
      AUTO_MERGE=true
      shift
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

# If a final positional parameter is left, assume it's the repo path
if [[ ${#POSITIONAL[@]} -ge 1 ]]; then
  REPO_PATH="${POSITIONAL[${#POSITIONAL[@]}-1]}"
fi

# --- Required checks ---
if [[ -z "${TARGET_BRANCH:-}" || -z "${SOURCE_BRANCH:-}" ]]; then
  echo "❌ --target/-t and --source/-s are required."
  exit 1
fi

if [[ ! "$MERGE_STRATEGY" =~ ^(ff|rebase|merge)$ ]]; then
  echo "❌ Invalid merge strategy: $MERGE_STRATEGY (allowed: ff, rebase, merge)"
  exit 1
fi

# --- Preload body file if present ---
if [[ -n "$BODY_FILE" ]]; then
  if [[ -n "$BODY" ]]; then
    echo "⚠️  Warning: --body is ignored because --body-file is set."
  fi
  if [[ ! -f "$BODY_FILE" || ! -r "$BODY_FILE" ]]; then
    echo "❌ Cannot read body file: $BODY_FILE"
    exit 1
  fi
  TEMP_BODY=$(mktemp)
  sed -e "s/SOURCE_BRANCH/$SOURCE_BRANCH/g" \
      -e "s/TARGET_BRANCH/$TARGET_BRANCH/g" \
      "$BODY_FILE" > "$TEMP_BODY"
fi

# --- Move to repo path if set ---
if [[ -n "$REPO_PATH" ]]; then
  cd "$REPO_PATH"
fi

NEW_BRANCH="merge-to-${TARGET_BRANCH}"

# --- Dry run output ---
if $DRY_RUN; then
  echo "🔍 Dry run mode enabled."
  echo "Would checkout $TARGET_BRANCH from $REMOTE"
  echo "Would create branch $NEW_BRANCH"
  echo "Would apply merge strategy: $MERGE_STRATEGY"
  echo "Would push $NEW_BRANCH and create PR"
  echo "Would auto-merge: $AUTO_MERGE"
  exit 0
fi

# --- Git operations ---
echo "🚀 Using remote: $REMOTE"
git fetch "$REMOTE" "$TARGET_BRANCH"
git checkout -B "$NEW_BRANCH" "$REMOTE/$TARGET_BRANCH"
git fetch "$REMOTE" "$SOURCE_BRANCH"

# --- Apply merge strategy ---
echo "🔀 Applying merge strategy: $MERGE_STRATEGY"
if [[ "$MERGE_STRATEGY" == "ff" ]]; then
  if ! git merge --ff-only "$REMOTE/$SOURCE_BRANCH"; then
    echo "❌ Fast-forward merge not possible. Use --merge-strategy rebase or merge."
    exit 1
  fi
elif [[ "$MERGE_STRATEGY" == "rebase" ]]; then
  git rebase "$REMOTE/$SOURCE_BRANCH"
elif [[ "$MERGE_STRATEGY" == "merge" ]]; then
  git merge --no-ff "$REMOTE/$SOURCE_BRANCH" -m "Merge $SOURCE_BRANCH into $NEW_BRANCH"
fi

# --- Push branch ---
echo "📤 Pushing branch $NEW_BRANCH..."
git push -u "$REMOTE" "$NEW_BRANCH"

# --- Check for existing PR ---
if gh pr list --head "$NEW_BRANCH" --json url --jq '.[].url' | grep -q .; then
  echo "⚠️ PR already exists for branch $NEW_BRANCH"
  exit 0
fi

# --- Build PR body ---
PR_BODY_ARGS=()
if [[ -n "${TEMP_BODY:-}" ]]; then
  PR_BODY_ARGS+=(--body-file "$TEMP_BODY")
elif [[ -n "$BODY" ]]; then
  PR_BODY_ARGS+=(--body "$BODY")
else
  PR_BODY_ARGS+=(--body "**This PR merges \`$SOURCE_BRANCH\` into \`$TARGET_BRANCH\`.**")
fi

# --- Create PR ---
REPO_ARG="--repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)"
PR_URL=$(gh pr create \
  --title "Merge to $TARGET_BRANCH" \
  --base "$TARGET_BRANCH" \
  --head "$NEW_BRANCH" \
  --assignee "@me" \
  "$REPO_ARG" \
  "${PR_BODY_ARGS[@]}")

[[ -n "${TEMP_BODY:-}" ]] && rm -f "$TEMP_BODY"

echo "✅ PR created: $PR_URL"

# --- Auto merge ---
if $AUTO_MERGE; then
  echo "🔁 Enabling auto-merge for PR..."
  gh pr merge "$PR_URL" --merge --auto
fi
