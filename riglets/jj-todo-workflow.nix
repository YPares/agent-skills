self:
{ riglib, ... }:
{
  imports = [ self.riglets.working-with-jj ];

  config.riglets.jj-todo-workflow = {
    tools = riglib.useScriptFolder ../jj-todo-workflow/scripts;

    meta = {
      name = "JJ TODO Workflow";
      description = "Structured TODO commit workflow using JJ (Jujutsu). Enforces completion discipline. Enables to divide work between Planners and Workers";
      intent = "playbook";
      whenToUse = [
        "Managing development work through TODO markers"
        "Plan tasks as empty commits with [task:*] flags"
        "Track progess though status transitions"
        "manage parallel task DAGs with dependency checking"
        "Coordinating parallel development with agents"
      ];
      keywords = [
        "jujutsu"
        "jj"
        "TODO"
        "workflow"
        "development"
      ];
      status = "experimental";
      version = "0.1.0";
    };

    docs = ../jj-todo-workflow;
  };
}
