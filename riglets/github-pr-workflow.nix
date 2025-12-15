{ pkgs, ... }:
{
  config.riglets.github-pr-workflow = {
    tools = [ pkgs.gh ];

    meta = {
      name = "GitHub PR Workflow";
      description = "Working with GitHub Pull Requests using the gh CLI. ";
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

    docs = ../github-pr-workflow;
  };
}
