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

Did you know your agent can have its own jj config? This can be useful to ensure:

- It sees regular git diffs (instead of the more compact jj `color-words` default diff formatter which it isn't used to)
- It uses the default and more usual `builtin_log_compact` template instead of your custom log template
- It does not try to use your `$EDITOR`

See [`this file`](.agent-space/jj-config.toml) as an example. You can just start the harness (e.g. claude-code) with:

```sh
JJ_CONFIG=/abs/path/to/agent/jj-config.toml claude ...
```

(The `just claude` recipe in the [`justfile`](./justfile) does that)

### nix-profile-manager

Also see the `just claude` recipe in the [`justfile`](./justfile).
