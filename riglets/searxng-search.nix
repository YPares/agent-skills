_:
{ pkgs, riglib, ... }:
{
  config.riglets.searxng-search = {
    tools = [
      pkgs.curl
      pkgs.podman
      ../searxng-search/scripts/start-searxng
      (pkgs.writeShellScriptBin "searx" "${pkgs.nushell}/bin/nu -n ${../searxng-search/scripts/searx}")
    ];

    meta = {
      description = "Enhanced web and package repository search using local SearXNG instance";
      intent = "toolbox";
      whenToUse = [
        "Searching package repositories (PyPI, NPM, Crates, etc.)"
        "Needing more powerful web search capabilities than WebSearch tool"
        "Integrating search into agent workflows"
      ];
      keywords = [
        "search"
        "searxng"
        "web"
        "packages"
        "pypi"
        "npm"
        "cargo"
      ];
      status = "experimental";
      version = "0.1.0";
    };

    docs = riglib.filterFileTree [ "md" ] ../searxng-search;
  };
}
