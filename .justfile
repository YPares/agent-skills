_default:
    @just --list

# Run Claude Code with the needed env vars so it had its own jj config and nix profile
[positional-arguments]
claude *args:
    JJ_CONFIG=.jj-agent-config.toml AGENT_PROFILE=$(readlink -f .agent-nix-profile) PATH=$AGENT_PROFILE/bin:$PATH claude "$@"
