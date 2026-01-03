self:
{
  pkgs,
  riglib,
  ...
}:
{
  config.riglets.context-engineering-fundamentals = {
    # Include Python for using the demonstration scripts in docs/scripts/
    tools = [ pkgs.python3 ];

    meta = {
      description = "Context engineering principles - progressive disclosure, attention budgets, degradation patterns, and optimization strategies for AI agent systems";
      intent = "sourcebook";
      whenToUse = [
        "Designing agent systems architecture"
        "Debugging context-related failures"
        "Understanding why riglet structure matters"
        "Optimizing context usage and token efficiency"
        "Diagnosing lost-in-middle issues"
        "Understanding attention mechanics"
        "Learning progressive disclosure patterns"
      ];
      keywords = [
        "context"
        "attention"
        "progressive-disclosure"
        "optimization"
        "degradation"
        "context-window"
        "token-efficiency"
      ];
      status = "stable";
      version = "1.0.0";
    };

    # Combine multiple context-engineering skills into one comprehensive riglet
    docs = riglib.writeFileTree {
      "SKILL.md" = ''
        # Context Engineering

        Context engineering is managing the language model's limited attention budget. This riglet combines four foundational skills covering the complete context engineering lifecycle.

        ## Core Concepts

        **Progressive Disclosure**: Load information only when needed (metadata → full content → references)
        **Attention Budget**: Context windows are constrained by attention mechanics, not token limits
        **Quality Over Quantity**: Find the smallest high-signal token set that achieves desired outcomes

        ## Topics

        This riglets composes together several skills from the context-engineering-fundamentals plugin from `github:muratcankoylan/Agent-Skills-for-Context-Engineering`.
        Each skill is included in full with all original references and scripts:

        - **[context-fundamentals](references/context-fundamentals/SKILL.md)** - Context anatomy, attention mechanics, progressive disclosure
        - **[context-degradation](references/context-degradation/SKILL.md)** - Lost-in-middle, poisoning, distraction, confusion, clash patterns
        - **[context-optimization](references/context-optimization/SKILL.md)** - Compaction, masking, caching, partitioning strategies
        - **[context-compression](references/context-compression/SKILL.md)** - Long-running session management, structured summarization

        ## Why This Matters for Rigup

        Rigup's structure applies these principles:
        - Progressive disclosure (RIG.md → SKILL.md → references/)
        - Attention budget (concise SKILL.md, details in references)
        - Degradation awareness (critical info at top)
        - File-system access (load on demand)
      '';

      # Import full skills as subdirectories to preserve their internal structure
      references = pkgs.lib.mapAttrs (
        _: val: val.source
      ) self.inputs.agent-skills-context-eng.claudePlugins.context-engineering-fundamentals.skills;
    };
  };
}
