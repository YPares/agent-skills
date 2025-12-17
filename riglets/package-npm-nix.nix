_:
{
  config.riglets.package-npm-nix = {
    meta = {
      name = "Package NPM with Nix";
      description = "Package npm/TypeScript/Bun CLI tools for Nix";
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
      status = "experimental";
      version = "0.1.0";
    };

    docs = ../package-npm-nix;
  };
}
