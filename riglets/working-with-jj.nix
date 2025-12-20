self:
{ config, pkgs, riglib, ... }:
{
  imports = [self.inputs.rigup.riglets.agent-identity];
  
  config.riglets.working-with-jj = {
    tools = [ pkgs.jujutsu ] ++ riglib.useScriptFolder ../working-with-jj/scripts;

    meta = {
      description = "Expert guidance for using JJ (Jujutsu) version control system. Covers JJ commands, template system, evolog, operations log, and interoperability with git remotes.";
      intent = "sourcebook";
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
      status = "experimental";
      version = "0.1.0";
    };

    docs = ../working-with-jj;

    config-files = riglib.writeFileTree {
      jj."config.toml" = (pkgs.formats.toml {}).generate "jj-config.toml" {
        user.name = config.agent.identity.name;
        user.email = config.agent.identity.email;
        ui.editor = "TRIED_TO_RUN_AN_INTERACTIVE_EDITOR";
        ui.diff-formatter = ":git";
      };
    };
  };
}
