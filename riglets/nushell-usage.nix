{ pkgs, ... }:
{
  config.riglets.nushell-usage = {
    tools = [ pkgs.nushell ];

    meta = {
      name = "Nushell Usage";
      description = "Essential patterns, idioms, and gotchas for writing Nushell code.";
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
  };
}
