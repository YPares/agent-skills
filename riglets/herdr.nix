self: { riglib, system, ... }: {
  config.riglets.herdr = {
    tools = [ self.inputs.llm-agents.packages.${system}.herdr ];
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
      "SKILL.md" = self.inputs.herdr + /SKILL.md;
    };
  };
}
