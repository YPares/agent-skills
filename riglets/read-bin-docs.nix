{ pkgs, ... }:
{
  config.riglets.read-bin-docs = {
    tools = [ pkgs.uv ];

    meta = {
      name = "Read Binary Docs";
      description = "Straightforward text extraction from document files (text-based PDF only for now, no OCR or docx)";
      whenToUse = [
        "Extracting text from PDF files"
        "Reading binary document formats"
        "Processing document content programmatically"
      ];
      keywords = [
        "pdf"
        "documents"
        "binary"
        "extraction"
        "text"
      ];
      status = "experimental";
      version = "0.1.0";
    };

    docs = ../read-bin-docs;
  };
}
