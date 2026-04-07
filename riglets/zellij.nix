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
      description = "Rename Zellij tab to reflect current work";
      whenToUse = [
        "Running inside Zellij terminal multiplexer"
      ];
      disclosure = lib.mkDefault "eager";
      status = "stable";
    };
    docs = riglib.writeFileTree {
      "SKILL.md" = ''
        # Zellij Tab Name Management

        If the $ZELLIJ env var is defined, it means you are running inside zellij.

        The commands to run is `zellij action rename-tab "..."`

        Group both into one call to avoid back-and-forth. E.g.:

        ```bash
        [ -n "$ZELLIJ" ] && zellij action rename-tab "..." || echo "Not in zellij"
        ```

        ## When to rename the tab

        At the beginning of the conversation or when resuming a conversation, using the following convention: `[<issue_number>:]<label>`.
        Where:
          - `issue_number` is the numeric part of some issue identifier (without prefix) if you have any
          - `label` is a 1 or 2 word description of the task at hand (using dash as separator)

        You can rename several times if you get new information, but besides that the tab name is not supposed to be dynamic.
      '';
    };
  };
}
