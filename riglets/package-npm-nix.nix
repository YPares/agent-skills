_:
{
  config.riglets.package-npm-nix = {
    meta = {
      description = "Package npm/TypeScript/Bun CLI tools for Nix";
      intent = "cookbook";
      whenToUse = [
        "Packaging Node.js applications with Nix"
        "Creating Nix derivations for npm packages"
        "Managing Node.js project dependencies"
      ];
      keywords = [
        "nix"
        "npm"
        "node"
        "packaging"
        "nodejs"
      ];
      status = "stable";
      version = "0.1.0";
    };

    docs = ../package-npm-nix;
  };
}
