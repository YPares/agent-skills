# agent-skills

Various skills for AI agents (in claude skills format).

## Installation

### Claude Code/Desktop

Add this marketplace to Claude Code:

```bash
/plugin marketplace add YPares/agent-skills
```

### Other Agent Harnesses

Besides Claude Code/Desktop, you can use these skills in any agent harness via
[openskills](https://github.com/numman-ali/openskills), which is also
Nix-packaged in [nix-ai-tools](https://github.com/numtide/nix-ai-tools).

## Tips about using them

### working-with-jj

Did you know your agent can have its own jj config?

Just create some `agent-jj-config.toml`:

```toml
[user]
name = "Claude"
email = "claude@clau.de"
```

and then start the harness (e.g. claude-code) with:

```sh
JJ_CONFIG=/abs/path/to/agent-jj-config.toml claude ...
```

This way your agent will use vanilla JJ, with default templates etc. Pretty
useful if you have a heavily templated `jj log` that the agent is not used to.

(The `just claude` recipe in the [`justfile`](./justfile) does just that)

### EDITOR

To prevent Claude from trying to open your interactive EDITOR (e.g. to
edit commit messages), you can set `$EDITOR` to a dummy script like [this
one](.agent-space/fake-editor.sh).

**IMPORTANT:** If your `.bashrc`, `.profile` etc. set the `$EDITOR` env var,
remember the agent runs commands in a shell that **sources** these files,
so you want them to set `$EDITOR` ONLY if it does not exist already:

```bash
export EDITOR=${EDITOR:-vim}
```

instead of just `EDITOR=vim`.

### nix-profile-manager

Also see the `just claude` recipe in the [`justfile`](./justfile).
