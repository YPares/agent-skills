{
  description = "YPares agent-skills in riglets form";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rigup.url = "github:YPares/rigup.nix";
  };

  outputs =
    { self, rigup, ... }@inputs:
    let
      system = "x86_64-linux";
      rigs = self.rigs.${system};
    in
    rigup { inherit inputs; }
    // {
      packages.${system} = {
        default = rigs.default.home;
        complete = rigs.complete.home;
      };
      devShells.${system} = {
        default = rigs.default.shell;
        complete = rigs.complete.shell;
      };
    };
}
