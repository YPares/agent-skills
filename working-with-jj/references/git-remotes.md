# Working with Git Remotes

JJ coexists with Git. The `.git` directory is the source of truth for remotes.

## Basic Workflow

```bash
# 1. Fetch latest from remotes
jj git fetch

# 2. Rebase your work onto updated main
jj rebase -d 'main@origin'

# 3. Make changes...

# 4. Point a bookmark at your work
jj bookmark set my-feature -r @

# 5. Push to remote
jj git push --bookmark my-feature
```

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

Colocated repos have both `.git` and `.jj` at the root (this is the default).
Git and JJ see the same history.

```bash
# Convert existing Git repo to colocated JJ
cd existing-git-repo
jj git init --colocate
```

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
jj rebase -s <feature-root> -d 'main@origin'
```

### Push new feature for review

```bash
jj bookmark create my-feature -r @
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
jj git push --bookmark my-feature --allow-delete
```
