{ pkgs, ... }:
{
  config.riglets.textual-builder = {
    tools = [
      pkgs.python3
      pkgs.python3Packages.textual
    ];

    meta = {
      name = "Textual Builder";
      description = "Build Text User Interface (TUI) applications using the Textual Python framework (v0.86.0+)";
      whenToUse = [
        "Creating terminal user interfaces"
        "Building TUI applications with Python"
        "Understanding Textual widgets and layouts"
        "Styling and theming TUI applications"
      ];
      keywords = [
        "textual"
        "tui"
        "terminal"
        "python"
        "ui"
      ];
      status = "experimental";
      version = "0.1.0";
    };

    docs = ../textual-builder;
  };
}
