# 🚀 promote-to-env.sh

A shell script to automate fast-forward merges between branches and create pull requests using the GitHub CLI (`gh`).

## 🔧 Features

- Creates a new branch `merge-to-<TARGET_BRANCH>` based on a target environment branch (e.g., `INT`)
- Performs a **fast-forward merge** from a source branch (e.g., `dev`) into the new branch
- Pushes the new branch and opens a **pull request**
- Supports Markdown files as PR body content
- Automatically assigns the PR to the current authenticated user (`@me`)
- Outputs the URL of the created PR
- Supports optional override of remote name and local repo path – great for CI and automation

## 📦 Requirements

- Git
- [GitHub CLI](https://cli.github.com/) (`gh`) authenticated via `gh auth login`
- Write access to the target repository

## 🖥️ Usage

```bash
./promote-to-env.sh <TARGET_BRANCH> <SOURCE_BRANCH> [BODY_FILE.md] [REMOTE] [REPO_PATH]
```

### 🔤 Arguments

| Argument          | Description                                                   | Example             |
| ----------------- | ------------------------------------------------------------- | ------------------- |
| `<TARGET_BRANCH>` | The target branch for the merge and PR (e.g., `INT`, `STAGE`) | `INT`               |
| `<SOURCE_BRANCH>` | The source branch to merge (e.g., `dev`)                      | `dev`               |
| `[BODY_FILE]`     | Optional: path to a Markdown file for the PR body             | `pr-description.md` |
| `[REMOTE]`        | Optional: Git remote name (default: `origin`)                 | `upstream`          |
| `[REPO_PATH]`     | Optional: path to the local git repository                    | `/repos/my-project` |

## 📝 PR Body Template

You can use a Markdown file as the pull request body. The script replaces the placeholders `SOURCE_BRANCH` and `TARGET_BRANCH` automatically:

```md
## 🔀 Merge to TARGET_BRANCH

This pull request fast-forward merges the latest changes from `SOURCE_BRANCH` into `TARGET_BRANCH`.

### ✅ Context

This is part of our regular promotion pipeline.

### 🚰 Details

- Source branch: `SOURCE_BRANCH`
- Target branch: `TARGET_BRANCH`
- Merge type: fast-forward only

### 🙋‍♂️ Assignee

Assigned to: @me
```

## 🔁 Example

```bash
./promote-to-env.sh int dev .github/pr-description.md origin
```

This will:

- Create a branch `merge-to-int` off `origin/int`
- Fast-forward merge `origin/dev` into it
- Push the new branch
- Open a PR with the provided markdown as body
- Assign it to the current user
- Output the PR URL

## 🛉 Cleanup

Temporary files used for template substitution are cleaned up automatically.

## 💠 Extensions

This script can be easily extended to:

- Add reviewers
- Auto-approve or auto-merge
- Label or categorize PRs

---

Made with ❤️ by [Michaela Andermann](https://github.com/michix99) and [Philip Gerke](https://github.com/pgerke)
