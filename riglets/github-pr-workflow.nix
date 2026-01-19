_:
{ pkgs, riglib, ... }:
{
  config.riglets.github-pr-workflow = {
    # These tools are to be used _unwrapped_:
    # they will _not_ see the rig's XDG_CONFIG_HOME, they are to _directly_
    # use the user's config files (notably to reuse their stored GitHub auth tokens)
    tools.unwrapped = [ pkgs.gh ] ++ riglib.useScriptFolder ../github-pr-workflow/scripts;

    meta = {
      description = "Working with GitHub Pull Requests using the gh CLI";
      intent = "playbook";
      whenToUse = [
        "WHENEVER THE USER ASKS YOU to fetch PR details, review comments, CI status"
        "Needing to obtain BOTH PR-level comments and inline code review comments"
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
      status = "stable";
      version = "0.1.0";
    };

    docs = riglib.filterFileTree ["md"] ../github-pr-workflow;
  };
}
