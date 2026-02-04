---
name: github-pr-workflow
description: Working with GitHub Pull Requests using the gh CLI. Use for fetching PR details, review comments, CI status, and understanding the difference between PR-level comments vs inline code review comments.
---

# GitHub PR Workflow

## Key Concepts

### Comment Types

GitHub PRs have **two different types of comments**:

1. **PR-level comments** - General discussion on the PR (shown via `gh pr view --comments`)
2. **Inline code review comments** - Comments attached to specific lines of code (requires API)

**Important**: `gh pr view --comments` does NOT show inline code review comments!

## Scripts

| Script | Purpose |
|--------|---------|
| `gh-pr-info <PR> [REPO]` | **Comprehensive PR info**: summary, CI checks and unresolved review and inline comments |

The script auto-detects the repo from git remote, or accepts `[REPO]` as second argument (format: `owner/repo`).

**Key features**:
- Uses GitHub's GraphQL API to reliably filter out already resolved/addressed comments
- Excludes collapsed/hidden review threads
- Excludes minimized comments (marked as spam/off-topic/resolved)
- Excludes dismissed reviews
- Shows only what still needs attention

## Common Commands

```bash
# Get complete PR info with UNRESOLVED comments only
gh-pr-info <PR> [REPO]             # ✅ Everything you need: summary, checks, reviews, unresolved comments

# Basic PR info (native gh commands)
gh pr view <PR>                    # Overview
gh pr view <PR> --comments         # PR-level comments only (NOT inline!)
gh pr diff <PR>                    # View the diff

# Reviews (approve/request changes)
gh pr review <PR> --approve
gh pr review <PR> --request-changes --body "Please fix X"
gh pr review <PR> --comment --body "Looks good overall"

# Checks
gh pr checks <PR>                  # CI status
gh run view <RUN_ID> --log-failed  # Failed job logs
```

## API Endpoints Reference

When `gh` commands don't expose what you need, use the API:

```bash
# Inline review comments
gh api repos/OWNER/REPO/pulls/PR/comments

# PR-level comments (issue comments)
gh api repos/OWNER/REPO/issues/PR/comments

# Review submissions
gh api repos/OWNER/REPO/pulls/PR/reviews

# Commits in PR
gh api repos/OWNER/REPO/pulls/PR/commits

# Files changed
gh api repos/OWNER/REPO/pulls/PR/files
```

## Workflow: Addressing Review Comments

1. **Get unresolved comments**: `gh-pr-info <PR>`
2. **Make fixes** in your local branch
