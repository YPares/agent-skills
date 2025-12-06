# Working with Git Remotes

JJ coexists with Git. The `.git` directory is the source of truth for remotes.

**Note (v0.34+):** Git repositories are colocated by default (both `.jj` and `.git`).
To disable: `git.colocate = false` in config.

## Basic Workflow

```bash
# 1. Fetch latest from remotes
jj git fetch

# 2. Rebase your work onto updated main
jj rebase -o 'main@origin'    # Note: -o/--onto replaces -d in v0.36+

# 3. Make changes...

# 4. Point a bookmark at your work
jj bookmark set my-feature -r @

# 5. Track before pushing (required for new bookmarks, v0.35+)
jj bookmark track my-feature@origin

# 6. Push to remote
jj git push --bookmark my-feature
```

**Note (v0.36+):** `jj git push --allow-new` is deprecated. Use `jj bookmark track` instead.

## Bookmarks vs Git Branches

JJ "bookmarks" = Git "branches". They're just named pointers to revisions.

```bash
jj bookmark list                        # List all bookmarks
jj bookmark create <name> -r <rev>      # Create new bookmark
jj bookmark set <name> -r <rev>         # Move existing bookmark
jj bookmark delete <name>               # Delete bookmark
```

**Key insight:** Unlike Git, you don't need to "be on a branch" to work. Just edit any revision directly.

## Remote Bookmarks

Remote bookmarks have the form `name@remote`:

```bash
main@origin                             # Remote main on origin
feature@upstream                        # Remote feature on upstream
```

### Tracking

```bash
jj bookmark track main@origin           # Start tracking remote bookmark
jj bookmark untrack main@origin         # Stop tracking
```

Tracked bookmarks automatically update on `jj git fetch`.

### Local vs Remote

After fetch, `main` (local) and `main@origin` (remote) may differ:

```bash
# See the difference
jj log -r '::main ~ ::main@origin'      # Local commits not in remote
jj log -r '::main@origin ~ ::main'      # Remote commits not in local

# Update local to match remote
jj bookmark set main -r 'main@origin'
```

## Pushing

```bash
jj git push --bookmark <name>           # Push specific bookmark
jj git push --all                       # Push all bookmarks
jj git push --change <rev>              # Create and push bookmark for revision
```

### Push Errors

**"bookmark moved unexpectedly"**: Someone else pushed. Fetch and rebase:

```bash
jj git fetch
jj rebase -d 'main@origin'
jj git push --bookmark my-feature
```

**"would delete remote bookmark"**: Remote has bookmark you don't:

```bash
jj git fetch
jj bookmark track <name>@origin                # Keep tracking it
```

## Fetching

```bash
jj git fetch                            # Fetch all remotes
jj git fetch --remote origin            # Fetch specific remote
```

After fetch, rebase onto updated remote:

```bash
jj rebase -d 'main@origin'
```

## Cloning

```bash
jj git clone <url> [path]               # Clone Git repo into JJ
```

### Colocated Repos

Colocated repos have both `.git` and `.jj` at the root (default since v0.34).
Git and JJ see the same history.

```bash
# Convert existing Git repo to colocated JJ
cd existing-git-repo
jj git init --colocate

# Convert between modes (v0.35+)
jj git colocation enable      # Make colocated
jj git colocation disable     # Make non-colocated
jj git colocation status      # Check current mode

# Clone without colocation
jj git clone --no-colocate <url>
```

**Config option:** `git.colocate = false` to disable default colocation.

## Local Tags (v0.35+)

JJ now supports local tag management (stored as lightweight Git tags):

```bash
jj tag set release-v1.0 -r @            # Create/update tag
jj tag delete release-v1.0              # Delete tag
jj tag list                             # List all tags
```

Tags are not automatically pushed; use `jj git push --tag <name>` to push.

## Import/Export

JJ auto-imports from Git on most operations. Manual control:

```bash
jj git import                           # Import Git refs → JJ
jj git export                           # Export JJ bookmarks → Git refs
```

## Common Patterns

### Start feature from latest main

```bash
jj git fetch
jj new 'main@origin' -m "Start feature X"
```

### Rebase feature onto updated main

```bash
jj git fetch
jj rebase -s <feature-root> -o 'main@origin'    # -o replaces -d in v0.36+
```

### Push new feature for review (v0.35+ workflow)

```bash
jj bookmark create my-feature -r @
jj bookmark track my-feature@origin     # Required before first push
jj git push --bookmark my-feature
```

### Update PR after review

```bash
# Make changes...
jj bookmark set my-feature -r @
jj git push --bookmark my-feature
```

### Delete remote branch after merge

```bash
jj bookmark delete my-feature
jj git push --bookmark my-feature --deleted    # --allow-delete also works
```

## Configuration Options

```toml
# In ~/.config/jj/config.toml or .jj/repo/config.toml

[git]
colocate = true                          # Default: colocate with Git (v0.34+)
track-default-bookmark-on-clone = true   # Auto-track default branch (v0.30+)
sign-on-push = true                      # Auto-sign commits when pushing (v0.26+)

[remotes.origin]
auto-track-bookmarks = true              # Auto-track bookmarks from this remote (v0.36+)
```
