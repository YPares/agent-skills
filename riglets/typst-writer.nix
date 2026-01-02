_:
{ pkgs, ... }:
{
  config.riglets.typst-writer = {
    tools = [ pkgs.typst ];

    meta = {
      description = "Write correct and idiomatic Typst code for document typesetting";
      intent = "cookbook";
      whenToUse = [
        "Creating or editing Typst documents"
        "Understanding Typst syntax and features"
        "Generating PDFs with Typst"
        "Styling and bibliography in Typst"
      ];
      keywords = [
        "typst"
        "document"
        "markup"
        "pdf"
        "publishing"
      ];
      status = "stable";
      version = "0.1.0";
    };

    docs = ../typst-writer;
  };
}
