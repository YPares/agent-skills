self:
{
  pkgs,
  ...
}:
{
  config.riglets.agent-tool-design = {
    # Include Python for using the demonstration scripts in docs/scripts/
    tools = [ pkgs.python3 ];

    meta = {
      description = "Principles for designing effective tools for AI agents - consolidation, architectural reduction, error messages, and MCP integration";
      intent = "cookbook";
      whenToUse = [
        "Designing tools for agents"
        "Creating MCP servers"
        "Debugging tool-related failures"
        "Deciding whether to consolidate multiple tools"
        "Writing tool descriptions"
        "Packaging scripts with riglets"
        "Evaluating third-party tools for agent integration"
      ];
      keywords = [
        "tools"
        "mcp"
        "consolidation"
        "architecture"
        "design"
        "tool-description"
        "error-messages"
      ];
      status = "stable";
      version = "1.0.0";
    };

    docs = self.inputs.agent-skills-context-eng.claudePlugins.agent-architecture.skills.tool-design.source;
  };
}
