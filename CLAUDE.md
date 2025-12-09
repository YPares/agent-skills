# CLAUDE.md

This file provides guidance to AI agents when working with code in this repository.

## Project Overview

This repository is a curated collection of AI agent skills organized as a Claude Plugin marketplace. Each skill is a self-contained knowledge base combining:
- **Documentation** (SKILL.md + references/)
- **Helper scripts** (scripts/ directory)
- **Templates/boilerplate** (assets/ directory)

Refer to the [README.md](./README.md) for installation instructions and usage tips.

## Development Commands

### Running Claude Code with Agent Configuration

```bash
# Use the justfile recipe (recommended)
just claude [args]
```

**Why this matters:**
It sets the following env vars:
- `JJ_CONFIG`: Prevents Claude from trying to invoke interactive editors (see `.agent-space/jj-config.toml`)
- `AGENT_PROFILE`: Isolated Nix profile for agent-specific tool installations
- `PATH`: Ensures agent uses its own tool versions

### Listing Available Commands

```bash
just --list
```

## Repository Structure

### Plugin Organization

Skills are organized into 6 plugin bundles in `.claude-plugin/marketplace.json`:

1. **jujutsu-skills**: `working-with-jj`, `jj-todo-workflow`
2. **nix-skills**: `nix-profile-manager`, `package-npm-nix`
3. **python-skills**: `textual-builder`
4. **nushell-skills**: `nushell-plugin-builder`
5. **github-skills**: `github-pr-workflow`
6. **typst-skills**: `typst-writer`

### Skill Directory Pattern

Each skill follows this structure:

```
<skill-name>/
├── SKILL.md                 # Primary knowledge base (entry point)
├── scripts/                 # [Optional] Helper utilities
│   └── <utility-scripts>    # Bash/Python/Nushell scripts
├── assets/                  # [Optional] Templates and boilerplate
│   └── <template-name>/     # Reusable project templates
└── references/              # [Optional] Deep-dive technical documentation
    └── <topic>.md           # Supplementary reference materials
```

**Key principle**: SKILL.md is the starting point. References are for deep dives when needed.

## Architecture and Design Patterns

### 1. Self-Contained Skills

Each skill is **completely independent** and can be read/used without dependencies on other skills. Skills do not import or reference each other.

### 2. Layered Documentation

- **SKILL.md**: Quick reference, essential commands, common patterns
- **references/**: Detailed explanations, edge cases, advanced usage
- **scripts/**: Automation for repetitive tasks (not mandatory to understand the skill)

### 3. Version-Controlled Knowledge

This repository itself uses JJ (Jujutsu) version control colocated with Git. Changes to skills are tracked with granular commits showing:
- Documentation improvements
- New helper scripts
- Template updates
- Skill reorganizations

### 4. Agent-Friendly Configuration

The `.agent-space/` directory contains:
- **jj-config.toml**: Agent-specific JJ configuration that prevents editor invocations
- **profile/**: Local Nix profile for isolated tool installations (see `nix-profile-manager` skill)

## Working with Skills

### Creating or Updating Skills

When creating or modifying skills:

1. **SKILL.md requirements**:
   - Start with frontmatter (name, description, version targets)
   - Include quick reference tables for commands/syntax
   - Provide examples of common workflows
   - Link to reference docs for deep dives

2. **Reference documentation**:
   - Break complex topics into separate .md files
   - Use clear section headings
   - Include code examples with explanations
   - Cross-reference related topics

3. **Helper scripts**:
   - Add executable permissions (`chmod +x`)
   - Include usage comments at the top
   - Use bash/python/nushell depending on complexity
   - Keep scripts focused on single tasks

4. **Templates in assets/**:
   - Provide a complete working example
   - Include a README.md explaining customization
   - Use placeholder names that are easy to replace
   - Document any dependencies

### Testing Skills

Skills are primarily documentation, so "testing" means:
- **Accuracy**: Verify commands and examples work
- **Completeness**: Ensure key workflows are documented
- **Clarity**: Check that explanations are clear for agents
- **Scripts**: Test helper scripts with various inputs

### Updating Plugin Metadata

When adding/removing skills, update `.claude-plugin/marketplace.json`:
- Add skills to appropriate plugin bundle
- Update version numbers
- Keep keywords relevant for discovery

## Technology Stack

### Languages
- **Markdown**: All documentation (CommonMark/GFM)
- **Bash/Shell**: Most helper scripts
- **Python**: Complex scripts (e.g., template generators)
- **Rust**: Nushell plugin template
- **Nix**: Package management integration

### External Tools Referenced in Skills
- **jj** (Jujutsu v0.36.x): Version control
- **gh**: GitHub CLI
- **nix**: Package manager
- **nushell**: Shell with structured data
- **cargo**: Rust build system
- **uv/uvx**: Fast Python package installer

## Important Notes

### No Traditional Build Process

This is **not a software project** with tests or builds. It's a **knowledge repository**:
- Skills are documentation + reference implementations
- No test suite to run
- No compilation or bundling required
- Validation happens through practical use by agents

### Skill Frontmatter Format

When creating SKILL.md files, use this frontmatter template:

```markdown
---
name: skill-name
description: Brief description of what this skill provides
version: 1.0.0  # Skill version
targets:
  - tool-name: ">=1.2.3"  # Minimum versions of referenced tools
---
```

## Common Patterns When Working Here

### Reading Skills

When the user asks about working with a technology:
1. Check if a skill exists for it (see plugin list above)
2. Read the SKILL.md first
3. Read references/ if more depth needed
4. Examine scripts/ to understand automation available

### Improving Skills

When you learn something new while working on tasks:
1. Propose adding it to the relevant skill
2. If it's a complex workflow, suggest a new reference doc
3. If it's a repetitive task, suggest a helper script
4. If it's a common starting point, suggest a template
