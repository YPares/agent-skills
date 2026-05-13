self:
{ pkgs, ... }:
{
  imports = with self.riglets; [read-bin-docs searxng-search];
  
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

    docs = ../research-assistant;
  };
}
