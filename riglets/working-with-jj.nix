{ pkgs, ... }:
{
  config.riglets.working-with-jj = {
    tools = [ pkgs.jujutsu ];

    meta = {
      name = "Working with Jujutsu";
      description = "Expert guidance for using JJ (Jujutsu) version control system. Covers JJ commands, template system, evolog, operations log, and interoperability with git remotes.";
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
  };
}
