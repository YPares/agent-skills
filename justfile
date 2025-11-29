_default:
    @just --list

# Run Claude Code with the needed env vars so it has its own jj config and nix profile
[positional-arguments]
@claude *args:
    # Using readlink to resolve absolute paths so we don't break if claude cd's to other folders
    JJ_CONFIG=$(readlink -f .agent-space/jj-config.toml) \
    EDITOR=$(readlink -f .agent-space/fake-editor.sh) \
    AGENT_PROFILE=$(readlink -f .agent-space/profile) \
    PATH=$AGENT_PROFILE/bin:$PATH \
    claude "$@"
