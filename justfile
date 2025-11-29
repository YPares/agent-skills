_default:
    @just --list

# Run Claude Code with the needed env vars so it had its own jj config and nix profile
[positional-arguments]
claude *args:
    JJ_CONFIG=.agent-space/jj-config.toml \
    EDITOR=.agent-space/fake-editor.sh \
    AGENT_PROFILE=$(readlink -f .agent-space/profile) \
    PATH=$AGENT_PROFILE/bin:$PATH \
    claude "$@"
