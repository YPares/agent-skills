_:
{
  riglib,
  lib,
  pkgs,
  ...
}:
{
  config.riglets.zellij = {
    tools = [ pkgs.zellij ];
    meta = {
      intent = "playbook";
      description = "How to maintain Zellij tab/pane names up to date";
      whenToUse = [
        "Running inside Zellij terminal multiplexer"
      ];
      disclosure = lib.mkDefault "eager";
      status = "stable";
    };
    docs = riglib.writeFileTree {
      "SKILL.md" = ''
        # Zellij Tab/Pane Name Management

        The commands to run are:

        - `zellij action rename-pane "..."`
        - `zellij action rename-tab "..."`

        ## When to rename the Tab

        At the beginning of the conversation, using the following convention: `[<issue_number>:]<label>` where:
          - `issue_number` is only the numeric part of some issue identifier (without prefix) if you have any
          - `label` is a 1 or 2 word description of the task at hand (using dash as separator)

        You can rename several times if you get new information, but besides that the tab name is not dynamic.

        ## When to rename the Pane

        The pane name is to be trated more dynamically and should represent a short description of the current step you are currently undergoing. It can be a few words long.
      '';
    };
  };
}
