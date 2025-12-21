{
  description = "YPares agent-skills in riglets form";

  nixConfig = {
    extra-substituters = [ "https://cache.garnix.io" ];
    extra-trusted-public-keys = [ "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rigup.url = "github:YPares/rigup.nix/dev";
  };

  outputs =
    {
      self,
      rigup,
      nixpkgs,
      ...
    }@inputs:
    rigup {
      inherit inputs;
      checkRigs = true;
    }
    // (with nixpkgs.lib; {
      packages = genAttrs systems.flakeExposed (
        system:
        mapAttrs' (name: rig: {
          name = "${name}-rig";
          value = rig.home;
        }) self.rigs.${system}
        // {
          rigup = rigup.packages.${system}.rigup;
        }
      );
      devShells = genAttrs systems.flakeExposed (
        system:
        mapAttrs' (name: rig: {
          name = "${name}-rig";
          value = rig.shell;
        }) self.rigs.${system}
      );
    });
}
