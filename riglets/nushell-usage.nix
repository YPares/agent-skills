self:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.nushell-usage;
in
{
  imports = [ self.inputs.rigup.riglets.lsp-servers ];

  options.nushell-usage = {
    nushellPkg = lib.mkPackageOption pkgs "nushell" { };
    withMcp = lib.mkEnableOption "Add the nushell MCP server to the rig";
  };

  config.riglets.nushell-usage = {
    tools.unwrapped = [ pkgs.nushell ];

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

  config.lspServers = lib.optionalAttrs config.lspServersEnabled {
    nushell.command = pkgs.writeShellScriptBin "nu-mcp" ''
      ${lib.getExe cfg.nushellPkg} --lsp "$@"
    '';
    nushell.extensions = [ ".nu" ];
  };

  config.mcpServers = lib.optionalAttrs cfg.withMcp {
    nushell.command = pkgs.writeShellScriptBin "nu-mcp" ''
      ${lib.getExe cfg.nushellPkg} --mcp "$@"
    '';
  };
}
