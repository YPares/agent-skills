_:
{ pkgs, riglib, ... }:
{
  config.riglets.nushell-usage = {
    tools = [ pkgs.nushell ];

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
      status = "experimental";
      version = "0.1.0";
    };

    docs = ../nushell-usage;

    config-files = riglib.writeFileTree {
      # If does not exist, nu will try to create it and it will fail because in the rig, XDG_CONFIG_HOME is readonly
      nushell."config.nu" = "";
    };
  };
}
