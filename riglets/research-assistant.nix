self:
{ pkgs, lib, riglib, config, ... }:
{
  imports = with self.riglets; [read-bin-docs searxng-search];

  options.research-assistant = {
    interactive = lib.mkEnableOption "Tell the agent to conduct the search in collaboration with the user rather than autonomously";
    rigletReminders = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Integrate a reminder to use specific riglets during the search";
      default = ["read-bin-docs" "searxng-search"];
    };
  };
  
  config.riglets.research-assistant = {
    meta = {
      description = "How to conduct good research and write exploitable reports, whatever the format of the sources and of the final report";
      intent = "playbook";
      whenToUse = [
        "Researching a topic"
        "Producing a report about a subject"
        "Asked a non-trivial question by the user"
      ];
      keywords = [
        "research"
        "reporting"
        "sourcing"
        "reading"
      ];
      status = "stable";
      version = "0.1.0";
    };

    docs = riglib.writeFileTree {
      "SKILL.md" = riglib.renderMinijinja {
        template = ../research-assistant/SKILL.md;
        data = config.research-assistant;
      };
    };
  };
}
