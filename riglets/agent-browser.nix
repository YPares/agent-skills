self:
{ riglib, system, ... }:
let
  agentBrowser = self.inputs.llm-agents.packages.${system}.agent-browser;
in
{
  config.riglets.agent-browser = {
    # agent-browser stores its sessions, auth vault and state under the user's
    # `~/.agent-browser` (home dir, not XDG_CONFIG_HOME), so it is used
    # _unwrapped_ to reuse the user's existing state across projects,
    # like github-pr-workflow does for `gh` auth tokens.
    tools.unwrapped = [ agentBrowser ];

    meta = {
      description = "Browser automation CLI for AI agents (Chrome/Chromium via CDP)";
      intent = "cookbook";
      whenToUse = [
        "Opening websites, filling forms, clicking buttons, taking screenshots or scraping data"
        "Testing or dogfooding web apps, exploratory testing, QA or bug hunts"
        "Automating Electron desktop apps (VS Code, Slack, Discord, Figma, Notion, Spotify)"
        "Automating Slack (checking unreads, sending messages, searching conversations)"
        "Running browser automation in Vercel Sandbox microVMs or AWS Bedrock AgentCore cloud browsers"
      ];
      keywords = [
        "browser"
        "automation"
        "web"
        "chrome"
        "chromium"
        "cdp"
        "screenshot"
        "scrape"
        "electron"
        "slack"
      ];
      status = "stable";
      version = "0.1.0";
    };

    # Repackage the official agent-browser skill (a discovery stub that points at
    # `agent-browser skills get core`, which the CLI serves from the installed
    # version, so it always matches the binary in this rig).
    docs = riglib.writeFileTree {
      "SKILL.md" = agentBrowser + "/share/agent-browser/skills/agent-browser/SKILL.md";
    };
  };
}
