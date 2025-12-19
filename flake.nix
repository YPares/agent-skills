{
  description = "YPares agent-skills in riglets form";

  nixConfig = {
    extra-substituters = [ "https://cache.garnix.io" ];
    extra-trusted-public-keys = [ "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rigup.url = "github:YPares/rigup.nix";
  };

  outputs =
    {
      self,
      rigup,
      flake-utils,
      nixpkgs,
      ...
    }@inputs:
    rigup { inherit inputs; }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        rigs = self.rigs.${system};
      in
      {
        # Make the rig(s) directly buildable
        packages = nixpkgs.lib.mapAttrs' (name: rig: {
          name = "${name}-rig";
          value = rig.home;
        }) rigs;
        # Make the rig(s) exposable in sub shell
        devShells = nixpkgs.lib.mapAttrs' (name: rig: {
          name = "${name}-rig";
          value = rig.shell;
        }) rigs;
      }
    );
}
