self: { pkgs, riglib, ... }: {
  config.riglets.herdr = {
    tools = [ pkgs.herdr ];
    meta = {
      intent = "cookbook";
      description = "How to use the herdr terminal multiplexer";
      whenToUse = [
        "Manage worspaces, tabs and panes via CLI"
        "Start commands"
        "Read outputs"
        "Collaborate with use in common terminal environment"
      ];
      status = "stable";
    };
    docs = riglib.writeFileTree {
      "SKILL.md" = "${pkgs.herdr}/share/skills/herdr/herdr/SKILL.md";
    };
  };
}
