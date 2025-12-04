# Parallel Agents with JJ Workspaces

**THIS PART OF THE SKILL IS STILL IN A BETA STATE. NEEDS MORE TESTING**

**TL;DR**: Use JJ workspaces to run multiple agents in parallel on different tasks. Each workspace gets its own working copy (`@`), preventing conflicts.

## The Problem

Running multiple agents concurrently on the same repo causes chaos:
- All agents compete for the same working copy (`@`)
- They do `jj restore` and `jj squash` to move changes around
- Files end up in wrong revisions
- Total mess

## The Solution: Workspaces

JJ workspaces are like git worktrees - isolated working copies of the same repo:
- Each workspace has its own `@`
- Changes made in one workspace don't affect others
- All workspaces share the same underlying revisions
- Perfect for parallel agent work

## When to Use This

✅ **Use workspaces when:**
- You have 3+ independent parallel tasks (e.g., Feature A, B, C from same parent)
- Tasks are truly independent (no shared files)
- Time savings justify the setup overhead
- Human user explicitly approves the complexity

❌ **Don't use workspaces when:**
- Tasks are sequential (just work through them linearly)
- Only 1-2 tasks (not worth the overhead)
- Tasks likely to conflict (same files)
- User hasn't agreed to the complexity

## Setup Workflow

### 1. Plan the Task DAG

First, create your TODO graph as usual:

```bash
# Create parallel branches
jj-todo-create @ "Core setup"
jj-parallel-todos <core-id> "Feature A" "Feature B" "Feature C"

# Create merge point
jj new --no-edit <A-id> <B-id> <C-id> -m "[task:todo] Integration"
```

### 2. Create Workspaces for Parallel Tasks

Create a workspace for each parallel task branch:

```bash
# From the main workspace, create named workspaces
jj workspace add ../workspace-feature-a --name feature-a
jj workspace add ../workspace-feature-b --name feature-b
jj workspace add ../workspace-feature-c --name feature-c

# List to verify
jj workspace list
```

**Note:** Workspace directories should be siblings of the main repo, not subdirectories.

### 3. Launch Agents in Their Workspaces

Launch each agent with instructions to work in its dedicated workspace:

**Agent A:**
```
You are working on Feature A in workspace-feature-a using JJ.

Working directory: /path/to/workspace-feature-a
JJ change-id for this task: <feature-a-id>

Workflow:
1. cd /path/to/workspace-feature-a
2. jj edit <feature-a-id>
3. jj log -r @ --no-graph -T description  # To read the specs of the task
4. /path/to/scripts/jj-flag-update @ wip
5. Implement Feature A
6. /path/to/scripts/jj-flag-update @ done # If task fully complete
7. Report completion or blockage

IMPORTANT: All commands must run in /path/to/workspace-feature-a
```

**Agent B, C:** Similar instructions with their respective workspace paths.

### 4. Monitor Progress

Check status across all workspaces:

```bash
# From main workspace, see all task statuses
jj-find-flagged wip
jj-find-flagged done

# Or check specific workspace
cd ../workspace-feature-a && jj status
```

### 5. Cleanup After Completion

Once all parallel tasks are done:

```bash
# Verify all tasks complete
jj-find-flagged | grep -E "Feature A|Feature B|Feature C"

# Remove workspaces (changes stay in revisions!)
jj workspace forget feature-a
jj workspace forget feature-b
jj workspace forget feature-c

# Delete workspace directories
rm -rf ../workspace-feature-a
rm -rf ../workspace-feature-b
rm -rf ../workspace-feature-c
```

## Complete Example

```bash
# 1. Setup TODO graph
jj-todo-create @ "Setup database schema"
db_id=$(jj log -r @ --no-graph -T 'change_id.shortest(8)')

jj-parallel-todos $db_id \
  "Implement user service" \
  "Implement product service" \
  "Implement order service"
# Read IDs from the output of jj-parallel-todos

# 2. Create workspaces
jj workspace add ../ws-user --name user-service
jj workspace add ../ws-product --name product-service
jj workspace add ../ws-order --name order-service

# 3. Launch agents (in parallel, single message with multiple Task tool calls)
# Agent 1: Work in ../ws-user on $user_id
# Agent 2: Work in ../ws-product on $product_id
# Agent 3: Work in ../ws-order on $order_id

# 4. After all complete, cleanup
jj workspace forget user-service
jj workspace forget product-service
jj workspace forget order-service

rm -rf ../ws-{user,product,order}
```

## Important Notes

### Workspace Paths

- **Absolute paths recommended**: `/tmp/project/workspace-a` vs `../workspace-a`
- **Scripts need full paths**: Helper scripts won't be in workspace PATH
- **Tell agents the workspace path**: They need to `cd` there for every command

### Agent Instructions Template

```
Working in isolated workspace for parallel execution.

Workspace: /absolute/path/to/workspace-name
Task: <task-id> - <task description>
Scripts: /absolute/path/to/agent-skills/jj-todo-workflow/scripts

Commands must use absolute paths and workspace directory:
  cd /absolute/path/to/workspace-name && jj edit <task-id>
  cd /absolute/path/to/workspace-name && /absolute/path/to/scripts/jj-flag-update @ wip
  cd /absolute/path/to/workspace-name && jj status

Complete the task following the specs in the revision description.
```

### Conflict Risk

Even with workspaces, conflicts can occur if:
- Multiple tasks modify the same files (python cache files, config, etc.)
- Tasks aren't truly independent
- Merge task will show conflicts when combining branches

**Mitigation:**
- Ensure `.gitignore` excludes generated files (`__pycache__/`, etc.)
- Design tasks to work on different files
- Review conflicts at merge time (expected and normal)

### When Agents Finish

- Changes stay in their task revisions (good!)
- Workspace `@` can be anywhere (doesn't matter)
- Forgetting workspace doesn't lose work
- Main workspace sees all completed revisions

## Troubleshooting

**"Workspace not found"**: Agent didn't `cd` to workspace directory first

**"Can't find scripts"**: Use absolute paths to helper scripts

**"Conflict on merge"**: Expected! Review and resolve at integration task

**"Changes in wrong revision"**: Agent worked in wrong workspace - check paths

## References

- JJ workspace docs: `jj help workspace`
- Git worktree equivalent: `git worktree add`
- Working-with-jj skill: For general JJ operations
