# 🚀 promote-to-env.sh

A shell script to automate merges between branches and create pull requests using the GitHub CLI (`gh`).

## 🔧 Features

- Creates a new branch `merge-to-<TARGET_BRANCH>` based on a target environment branch (e.g., `INT`)
- Supports different merge strategies: `merge` (default), `rebase`, `ff` (fast-forward only)
- Pushes the new branch and opens a **pull request**
- Supports Markdown files or inline strings as PR body content
- Automatically assigns the PR to the current authenticated user (`@me`)
- Outputs the URL of the created PR
- Supports optional override of remote name and local repo path – great for CI and automation
- Supports `--dry-run` mode to simulate operations
- Skips creating duplicate PRs if one already exists
- Supports optional `--auto-merge` flag to auto-merge the PR after passing checks

## 📦 Requirements

- Git
- [GitHub CLI](https://cli.github.com/) (`gh`) authenticated via `gh auth login`
- Write access to the target repository

## 🖥️ Usage

```bash
./promote-to-env.sh --target <TARGET_BRANCH> --source <SOURCE_BRANCH> \
  [--body-file FILE.md | --body "Markdown text"] \
  [--remote origin] [--merge-strategy merge] [--auto-merge] [--dry-run] [REPO_PATH]
```

### 🔤 Flags

| Flag               | Description                                                     | Example                   |
| ------------------ | --------------------------------------------------------------- | ------------------------- |
| `--target`, `-t`   | Target branch for the PR (required)                             | `--target int`            |
| `--source`, `-s`   | Source branch to merge (required)                               | `--source dev`            |
| `--body-file`      | Optional: path to a Markdown file for the PR body               | `--body-file pr.md`       |
| `--body`           | Optional: PR body string (ignored if `--body-file` is set)      | `--body "text"`           |
| `--remote`         | Optional: Git remote (default: `origin`)                        | `--remote upstream`       |
| `--merge-strategy` | Optional: `merge` (default), `rebase`, or `ff`                  | `--merge-strategy rebase` |
| `--auto-merge`     | Optional: Auto-merge the PR once checks pass                    | `--auto-merge`            |
| `--dry-run`        | Optional: Show what would happen without performing any changes | `--dry-run`               |
| `REPO_PATH`        | Optional: Path to local Git repo (as last positional argument)  | `./my-repo`               |

## 📝 PR Body Template

You can use a Markdown file as the pull request body. The script replaces the placeholders `SOURCE_BRANCH` and `TARGET_BRANCH` automatically:

```md
## 🔀 Merge to TARGET_BRANCH

This pull request merges the latest changes from `SOURCE_BRANCH` into `TARGET_BRANCH`.

### ✅ Context

This is part of our regular promotion pipeline.

### 🚰 Details

- Source branch: `SOURCE_BRANCH`
- Target branch: `TARGET_BRANCH`
- Merge strategy: default (merge)

### 🙋‍♂️ Assignee

Assigned to: @me
```

## 🔁 Example

```bash
./merge-to-env.sh -t int -s main --merge-strategy rebase --body-file .github/pr.md --auto-merge ./repo
```

This will:

- Create a branch `merge-to-int` off `origin/int`
- Rebase `main` onto it
- Push the new branch
- Open a PR with the provided markdown as body
- Assign it to the current user
- Enable auto-merge if checks pass
- Output the PR URL

## 🛉 Cleanup

Temporary files used for template substitution are cleaned up automatically.

## 💠 Extensions

This script can be easily extended to:

- Add reviewers
- Label or categorize PRs
- GitHub Actions integration
- Bash completion

---

Made with ❤️ by [Michaela Andermann](https://github.com/michix99) and [Philip Gerke](https://github.com/pgerke)
