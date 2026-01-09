{
  description = "YPares agent-skills in riglets form";

  nixConfig = {
    extra-substituters = [ "https://cache.garnix.io" ];
    extra-trusted-public-keys = [ "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rigup.url = "github:YPares/rigup.nix/mcp";
    nushellWith.url = "github:YPares/nushellWith";
    agent-skills-context-eng = {
      url = "github:muratcankoylan/Agent-Skills-for-Context-Engineering";
      flake = false;
    };
  };

  outputs =
    {
      rigup,
      ...
    }@inputs:
    rigup {
      inherit inputs;
      checkRiglets = true;
      checkRigs = true;
    }
    // {
      inherit (rigup) packages;
    };
}
