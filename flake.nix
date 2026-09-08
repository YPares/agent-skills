{
  description = "YPares agent-skills in riglets form";

  inputs = {
    rigup.url = "github:YPares/rigup.nix";
    nixpkgs.follows = "rigup/nixpkgs";
    llm-agents.follows = "rigup/llm-agents";
    agent-skills-context-eng = {
      url = "github:muratcankoylan/Agent-Skills-for-Context-Engineering";
      flake = false;
    };
    herdr.url = "github:ogulcancelik/herdr";
  };

  outputs =
    {
      rigup,
      ...
    }@inputs:
    rigup {
      inherit inputs;
      projectUri = "YPares/agent-skills";
      checkRiglets = true;
      # checkRigs = true;
    }
    // {
      inherit (rigup) packages;
    };
}
