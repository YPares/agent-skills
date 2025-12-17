self:
{ pkgs, ... }:
{
  imports = [ self.riglets.nushell-usage ];

  config.riglets.nushell-plugin-builder = {
    tools = [
      pkgs.nushell
      pkgs.cargo
      pkgs.rustc
    ];

    meta = {
      name = "Nushell Plugin Builder";
      description = "Guide for creating Nushell plugins in Rust using nu_plugin and nu_protocol crates. Covers project setup, command implementation, streaming data, custom values, and testing.";
      whenToUse = [
        "Creating Nushell plugins"
        "Extending Nushell functionality"
        "Understanding the Nushell plugin protocol"
        "Building and testing Nushell plugins"
        "Integrate external tools/APIs into Nushell"
      ];
      keywords = [
        "nushell"
        "nu"
        "plugin"
        "rust"
        "cargo"
      ];
      status = "experimental";
      version = "0.1.0";
    };

    docs = ../nushell-plugin-builder;
  };
}
