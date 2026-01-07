# SearXNG Search Skill

Enhanced web and package repository search capabilities using SearXNG metasearch engine.

**Fully portable** - works on any machine with podman or docker, no external dependencies.

## What This Provides

- **Unified search interface** across multiple package repositories (npm, Cargo, Docker Hub, etc.)
- **Category-based filtering** for targeted searches (IT, repos, scientific publications, etc.)
- **JSON output** for programmatic consumption
- **Workarounds for PyPI** (direct API + qypi CLI tool)
- **Nushell helper script** for convenient command-line usage

## Quick Start

**1. Start SearXNG:**
```bash
start-searxng --detach
```

**2. Use the search helper:**
```bash
searx "tokio" --category cargo
searx "express" --category packages
searx "rust async" --category it --limit 5
```

**3. Or use curl directly:**
```bash
curl -s "http://localhost:8888/search?q=serde&format=json&categories=cargo" | jq '.results[0:3]'
```

**4. Stop when done:**
```bash
podman stop searxng  # or: docker stop searxng
```

## Files

- **SKILL.md**: Main documentation with quick reference and common patterns
- **references/package-engine-status.md**: Test results for all 14 package repositories ⭐
- **references/category-guide.md**: Comprehensive guide to all search categories
- **references/pypi-direct-search.md**: PyPI workarounds (API + qypi CLI)
- **references/agent-usage.md**: Guide for AI agents using SearXNG
- **scripts/start-searxng**: Bash script to start SearXNG container (portable!)
- **scripts/searx**: Nushell helper script with colored output

## What Works

✅ **13/14 package repositories working**, including:
- **Haskell (Hoogle/Hackage)** - packages & functions ⭐
- **JavaScript (npm)**
- **Rust (crates.io, lib.rs)**
- **Ruby (RubyGems)**
- **PHP (Packagist)**
- **Erlang/Elixir (Hex)**
- **Perl (MetaCPAN)**
- **Dart/Flutter (pub.dev)**
- **Go (pkg.go.dev)**
- **Docker Hub**
- **Alpine/Void Linux packages**

✅ **General web search**: Multiple engines (DuckDuckGo, Startpage, etc.)
✅ **GitHub/GitLab**: Repository and code search
✅ **Academic papers**: arXiv, PubMed, Google Scholar, etc.

❌ **PyPI (Python)**: Broken due to bot protection - use direct API or qypi CLI instead

**See `references/package-engine-status.md` for detailed test results!**

## Requirements

- **podman** or **docker** (auto-detected)
- **curl** (for API access)
- **jq** (optional, for JSON parsing)
- **nushell** (optional, for the `searx` helper script)

No installation needed - runs in a container!

## Next Steps

1. Try the helper script for common searches
2. Explore different categories (see category-guide.md)
3. For PyPI searches, use `uvx qypi search <term>` or direct API

## Tips

- Use `categories=packages` for multi-repo package search
- Use `categories=cargo` specifically for Rust crates
- Combine categories: `categories=packages,it,repos`
- Filter results by engine in jq: `select(.engines[] == "npm")`
