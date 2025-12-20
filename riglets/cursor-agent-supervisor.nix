_:
{
  config.riglets.cursor-agent-supervisor = {
    meta = {
      description = "Offloading tasks with a well-defined scope to sub-agents, for instance to use a sub-agent to implement a set of specs";
      intent = "playbook";
      whenToUse = [
        "Whenever a task should not need a broad knowledge of the whole project"
        "Supervising AI-assisted code generation"
        "Managing agent behavior and output quality"
      ];
      keywords = [
        "cursor"
        "ide"
        "agent"
        "supervision"
        "ai"
      ];
      status = "experimental";
      version = "0.1.0";
    };

    docs = ../cursor-agent-supervisor;
  };
}
