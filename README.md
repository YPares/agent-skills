# agent-skills

Various skills for AI agents (in claude skills format).

Besides Claude Code/Desktop, you can use them in any agent harness via
[https://github.com/numman-ali/openskills](openskills), which is also Nix-packaged
in [https://github.com/numtide/nix-ai-tools](nix-ai-tools).

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
JJ_CONFIG=/abs/path/to/agent-jj-config.toml claude-code ...
```

This way your agent will use vanilla JJ, with default templates etc. Pretty useful if you have
a heavily templated `jj log` that the agent is not used to.
