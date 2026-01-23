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
        "review"
      ];
      status = "stable";
      version = "0.1.0";
    };

    docs = riglib.filterFileTree [ "md" ] ../github-pr-workflow;

    promptCommands = {
      study-pr-comments = {
        description = "Study comments from PR(s) given as $ARGUMENTS";
        template = ''
          Fetch all the comments of PR(s) $ARGUMENTS and analyze them:

          - how relevant they are (critical, spot-on, useful, nitpick, off-topic...) 
          - how applicable they are, given the intended scope of the PR(s) (immediately, with some effort, not without massive rework...)

          PAY ATTENTION to whether comments are already resolved or not, and to whether you are correctly getting the inline code comments too (that's what the aforementioned tools are for).
          
          Give your report, then suggest a short plan for what should be done next.
          If any information you need (notably intended PR scope) is missing, ask the user.
        '';
      };
    };
  };
}
