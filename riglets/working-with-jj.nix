self:
{
  config,
  pkgs,
  riglib,
  ...
}:
let
  jj = riglib.wrapWithEnv {
    name = "jj-wrapped";
    tools = [ pkgs.jujutsu ];
    env.JJ_CONFIG = riglib.toTOML {
      user.name = config.agent.identity.name;
      user.email = config.agent.identity.email;
      ui.editor = "TRIED_TO_RUN_AN_INTERACTIVE_EDITOR";
      ui.diff-formatter = ":git";
      ui.default-command = "log";
    };
  };
in
{
  imports = [ self.inputs.rigup.riglets.agent-identity ];

  config.riglets.working-with-jj = {
    tools.unwrapped = [ jj ] ++ riglib.useScriptFolder ../working-with-jj/scripts;

    meta = {
      description = "Expert guidance for using JJ (Jujutsu) version control system. Covers JJ commands, template system, evolog, operations log, and interoperability with git remotes.";
      intent = "cookbook";
      whenToUse = [
        "Learning Jujutsu version control basics"
        "Managing commits and changes with jj"
        "Performing complex operations like rebasing and resolving conflicts"
        "Collaborating with Git repositories"
        "Advanced VCS workflows and patterns"
      ];
      keywords = [
        "jujutsu"
        "jj"
        "version-control"
        "vcs"
        "git"
      ];
      status = "stable";
      version = "0.1.0";
    };

    docs = riglib.filterFileTree [ "md" ] ../working-with-jj;

    promptCommands = {
      review-revset = {
        description = "Review revset passed as $1, focusing on $2";
        template = ''
          Review JJ revset '$1', focusing on the following aspects:
          $2
        '';
      };
    };
  };
}
