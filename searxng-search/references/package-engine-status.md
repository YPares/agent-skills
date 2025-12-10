# SearXNG Package Search Engine Status

Comprehensive test results for all package repository search engines in SearXNG.

**Test date:** December 2025
**SearXNG version:** 2025.10.23+e363db970

## Summary

| Status | Count | Engines |
|--------|-------|---------|
| ✅ Working | 13 | npm, cargo, rubygems, packagist, hoogle, hex, metacpan, pub.dev, pkg.go.dev, docker hub, alpine, voidlinux, lib.rs |
| ❌ Broken | 1 | pypi |

## Detailed Results

### ✅ **Haskell - Hoogle** (Hackage)

**Status:** ✅ Working perfectly

**Test results:**
```bash
# Query: aeson
Results: 25 packages/functions
First result: package aeson
```

**Example search:**
```bash
curl -s "http://localhost:8888/search?q=lens&format=json&engines=hoogle" | jq .
```

**What it returns:**
- Package listings
- Function signatures
- Module documentation
- Links to Hackage documentation

**Notes:**
- Searches both package names and function names
- Returns direct links to Hackage
- Very comprehensive results

---

### ✅ **JavaScript/Node.js - npm**

**Status:** ✅ Working perfectly

**Test results:**
```bash
# Query: express
Results: 25 packages
First result: express
```

**Example search:**
```bash
curl -s "http://localhost:8888/search?q=react&format=json&engines=npm"
```

---

### ✅ **Rust - crates.io**

**Status:** ✅ Working perfectly

**Test results:**
```bash
# Query: tokio
Results: 10 crates
First result: tokio
```

**Example search:**
```bash
curl -s "http://localhost:8888/search?q=serde&format=json&engines=crates.io"
```

**Notes:**
- Also accessible via `lib.rs` engine (alternative Rust registry frontend)

---

### ✅ **Ruby - RubyGems**

**Status:** ✅ Working perfectly

**Test results:**
```bash
# Query: rails
Results: 30 gems
First result: rails 8.1.1
```

**Example search:**
```bash
curl -s "http://localhost:8888/search?q=sinatra&format=json&engines=rubygems"
```

---

### ✅ **PHP - Packagist**

**Status:** ✅ Working perfectly

**Test results:**
```bash
# Query: symfony
Results: 15 packages
First result: symfony/yaml
```

**Example search:**
```bash
curl -s "http://localhost:8888/search?q=laravel&format=json&engines=packagist"
```

---

### ✅ **Erlang/Elixir - Hex**

**Status:** ✅ Working perfectly

**Test results:**
```bash
# Query: http
Results: 10 packages
First result: cowboy
```

**Example search:**
```bash
curl -s "http://localhost:8888/search?q=phoenix&format=json&engines=hex"
```

---

### ✅ **Perl - MetaCPAN**

**Status:** ✅ Working perfectly

**Test results:**
```bash
# Query: http
Results: 20 modules
First result: HTTP
```

**Example search:**
```bash
curl -s "http://localhost:8888/search?q=mojolicious&format=json&engines=metacpan"
```

---

### ✅ **Dart/Flutter - pub.dev**

**Status:** ✅ Working perfectly

**Test results:**
```bash
# Query: http
Results: 10 packages
```

**Example search:**
```bash
curl -s "http://localhost:8888/search?q=flutter&format=json&engines=pub.dev"
```

---

### ✅ **Go - pkg.go.dev**

**Status:** ✅ Working perfectly

**Test results:**
```bash
# Query: http
Results: 50 packages
```

**Example search:**
```bash
curl -s "http://localhost:8888/search?q=gin&format=json&engines=pkg.go.dev"
```

**Notes:**
- Very comprehensive results (up to 50)
- Official Go package registry

---

### ✅ **Docker - Docker Hub**

**Status:** ✅ Working perfectly

**Test results:**
```bash
# Query: docker
Results: 10 images
First result: docker
```

**Example search:**
```bash
curl -s "http://localhost:8888/search?q=nginx&format=json&engines=docker+hub"
```

---

### ✅ **Alpine Linux Packages**

**Status:** ✅ Working perfectly

**Test results:**
```bash
# Query: linux
Results: 50 packages
```

**Example search:**
```bash
curl -s "http://localhost:8888/search?q=python&format=json&engines=alpine+linux+packages"
```

---

### ✅ **Void Linux Packages**

**Status:** ✅ Working (enabled by default)

**Example search:**
```bash
curl -s "http://localhost:8888/search?q=vim&format=json&engines=voidlinux"
```

---

### ✅ **lib.rs (Rust Alternative)**

**Status:** ✅ Working perfectly

**Notes:**
- Alternative frontend for crates.io
- Provides enhanced search and categorization

---

### ❌ **Python - PyPI**

**Status:** ❌ **BROKEN**

**Issue:** PyPI returns JavaScript "Client Challenge" page for bot protection

**Details:**
- Engine scrapes HTML from `https://pypi.org/search/`
- PyPI now requires JavaScript to display results
- Parser finds no expected HTML elements
- Returns 0 results (no error shown)
- Reported: [SearXNG issue #4093](https://github.com/searxng/searxng/issues/4093) (December 2024)
- Status: OPEN as of December 2025, no fix yet

**Workarounds:**
- Use PyPI JSON API: `https://pypi.org/pypi/<package>/json` (exact name only)
- Use `qypi` CLI: `uvx qypi search <term>`

See `pypi-direct-search.md` for detailed workarounds.

---

## Multi-Language Search

You can search across all package repositories at once:

```bash
# Search all package repos
curl -s "http://localhost:8888/search?q=http&format=json&categories=packages" | \
  jq '.results | group_by(.engines[0])'
```

This searches:
- npm (JS)
- crates.io (Rust)
- rubygems (Ruby)
- packagist (PHP)
- hoogle (Haskell)
- hex (Erlang/Elixir)
- metacpan (Perl)
- pub.dev (Dart)
- pkg.go.dev (Go)
- docker hub (containers)
- alpine/void (Linux packages)
- ~~pypi (Python)~~ - broken

## Usage Tips

### Search Specific Language

```bash
# Haskell packages
curl -s "http://localhost:8888/search?q=aeson&format=json&engines=hoogle"

# Ruby gems
curl -s "http://localhost:8888/search?q=rails&format=json&engines=rubygems"

# Go packages
curl -s "http://localhost:8888/search?q=gin&format=json&engines=pkg.go.dev"
```

### Filter Multi-Category Search by Engine

```bash
# Search packages category, filter to specific engine
curl -s "http://localhost:8888/search?q=web&format=json&categories=packages" | \
  jq '.results[] | select(.engines[] == "hoogle")'
```

### Nushell Helper Function

```nu
def search-pkg [
  query: string,
  language: string  # hoogle, npm, rubygems, etc.
] {
  http get $"http://localhost:8888/search?q=($query | url encode)&format=json&engines=($language)"
  | get results
  | select title url content
}

# Usage
search-pkg "lens" "hoogle"
search-pkg "express" "npm"
```

## Configuration Notes

All engines tested with **default SearXNG configuration** (`use_default_settings: true`).

Some engines may be disabled by default in certain configs. To enable:

```yaml
engines:
  - name: hoogle
    disabled: false
```

Check current engine status:
```bash
curl -s "http://localhost:8888/config" | jq '.engines[] | select(.name == "hoogle")'
```

## Why Most Engines Work

Unlike PyPI, most package registries either:
1. **Provide stable HTML structures** that haven't changed
2. **Offer search APIs** that SearXNG uses
3. **Don't have aggressive bot protection**

Only PyPI added JavaScript challenges that break HTML scraping.

## Monitoring for Updates

- **PyPI fix:** Watch [issue #4093](https://github.com/searxng/searxng/issues/4093)
- **SearXNG releases:** https://github.com/searxng/searxng/releases
- **Engine changes:** Check `searx/engines/` in SearXNG repo

## Related Documentation

- [category-guide.md](./category-guide.md) - All search categories
- [pypi-direct-search.md](./pypi-direct-search.md) - PyPI workarounds
- [agent-usage.md](./agent-usage.md) - AI agent integration guide
