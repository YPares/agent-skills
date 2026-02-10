self:
{
  system,
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (self.inputs.nushellWith.packages.${system}) nushellMCP;
in
{
  options.nushell-usage = {
    withMcp = lib.mkEnableOption "Add the nushell MCP server to the rig";
  };

  config.riglets.nushell-usage = {
    tools.unwrapped = [ nushellMCP ];

    meta = {
      description = "Essential patterns, idioms, and gotchas for writing Nushell code.";
      intent = "cookbook";
      whenToUse = [
        "Writing Nushell scripts or libraries"
        "Working with Nushell's type system, pipelines, and data structures"
        "Working with structured data in shells"
        "Understanding Nushell type system"
        "Advanced shell scripting patterns"
      ];
      keywords = [
        "nushell"
        "nu"
        "shell"
        "script"
        "structured-data"
      ];
      status = "stable";
      version = "0.1.0";
    };

    docs = ../nushell-usage;
  };

  config.mcpServers = lib.optionalAttrs config.nushell-usage.withMcp {
    nushell.command = pkgs.writeShellScriptBin "nu-mcp" ''
      ${lib.getExe nushellMCP} --mcp "$@"
    '';
  };
}
