{
  description = "YPares agent-skills in riglets form";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rigup.url = "github:YPares/rigup.nix/dev";
  };

  outputs =
    { self, rigup, ... }@inputs:
    let
      system = "x86_64-linux";
    in
    rigup { inherit inputs; }
    // {
      packages.${system} = {
        default = self.rigs.${system}.default.home;
        complete = self.rigs.${system}.complete.home;
      };
    };
}
