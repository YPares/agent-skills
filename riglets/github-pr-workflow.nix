_:
{ pkgs, riglib, ... }:
{
  config.riglets.github-pr-workflow = {
    tools = [ pkgs.gh ] ++ riglib.useScriptFolder ../github-pr-workflow/scripts;

    meta = {
      description = "Working with GitHub Pull Requests using the gh CLI. ";
      intent = "playbook";
      whenToUse = [
        "Fetching PR details, review comments, CI status"
        "Understanding the difference between PR-level comments vs inline code review comments."
        "Working with GitHub API"
      ];
      keywords = [
        "github"
        "git"
        "pull-request"
        "pr"
        "workflow"
        "automation"
      ];
      status = "experimental";
      version = "0.1.0";
    };

    docs = riglib.writeFileTree {
      "SKILL.md" = ../github-pr-workflow/SKILL.md;
    };
  };
}
