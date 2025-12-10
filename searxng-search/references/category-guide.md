# SearXNG Category Search Guide

This document details all available categories and which engines serve them.

## Available Categories

Get the full list:
```bash
curl -s "http://localhost:8888/config" | jq -r '.categories[]'
```

Current categories (as of testing):
- general
- videos
- social media
- images
- music
- **packages** ⭐
- **it** ⭐
- files
- books
- news
- apps
- software wikis
- science
- scientific publications
- web
- **repos** ⭐
- other
- currency
- weather
- map
- dictionaries
- shopping
- lyrics
- **code** ⭐
- icons
- **cargo** ⭐
- movies
- translate
- radio

(⭐ = Most useful for development work)

## Development-Focused Categories

### 1. `packages` - Multi-Repository Package Search

**Engines included:**
- npm (JavaScript/Node.js)
- crates.io (Rust)
- hex (Erlang/Elixir)
- hoogle (Haskell)
- metacpan (Perl)
- packagist (PHP/Composer)
- docker hub (Container images)
- alpine linux packages
- lib.rs (Rust alternative registry)
- pypi (Python - configured but not working, see workarounds)

**Example:**
```bash
curl -s "http://localhost:8888/search?q=express&format=json&categories=packages" | \
  jq '.results[] | {title, url, engine: .engines[0], content}'
```

**Use cases:**
- Finding packages across multiple ecosystems
- Comparing implementations in different languages
- Discovering container images for tools

### 2. `cargo` - Rust Crates Only

**Engines included:**
- crates.io

**Example:**
```bash
curl -s "http://localhost:8888/search?q=tokio&format=json&categories=cargo" | \
  jq '.results[] | {title, url, content}'
```

**Use cases:**
- Finding Rust crates
- Browsing crates.io search results
- Getting crate descriptions

### 3. `it` - IT/Tech Resources

**Engines included:**
- GitHub
- Docker Hub
- Stack Overflow
- crates.io
- GitLab
- And many more tech-focused sources

**Example:**
```bash
curl -s "http://localhost:8888/search?q=kubernetes+helm&format=json&categories=it" | \
  jq '.results[0:5] | .[] | {title, url, engines}'
```

**Use cases:**
- Broad tech searches
- Finding GitHub repos, Docker images, and tech docs in one query
- Stack Overflow Q&A

### 4. `repos` - Code Repositories

**Engines included:**
- GitHub
- GitLab
- Codeberg
- Gitea instances

**Example:**
```bash
curl -s "http://localhost:8888/search?q=machine+learning&format=json&categories=repos" | \
  jq '.results[] | select(.engines[] == "github") | {title, url, content}'
```

**Use cases:**
- Finding source code repositories
- Discovering open-source projects
- Searching for code examples

### 5. `code` - Code Search

**Engines included:**
- GitHub Code Search
- Sourcehut
- Other code-specific engines

**Example:**
```bash
curl -s "http://localhost:8888/search?q=async+fn+main&format=json&categories=code" | \
  jq '.results[] | {title, url, content}'
```

**Use cases:**
- Searching within code files
- Finding specific function implementations
- Discovering code patterns

## Research-Focused Categories

### `scientific publications`

**Engines included:**
- arXiv
- CrossRef
- Google Scholar
- PubMed
- Semantic Scholar
- And more

**Example:**
```bash
curl -s "http://localhost:8888/search?q=neural+networks&format=json&categories=scientific+publications" | \
  jq '.results[0:3] | .[] | {title, url, content, publishedDate}'
```

### `science`

General science resources and databases.

**Example:**
```bash
curl -s "http://localhost:8888/search?q=quantum+computing&format=json&categories=science"
```

## Multi-Category Searches

Combine categories with commas:

```bash
curl -s "http://localhost:8888/search?q=docker&format=json&categories=packages,it,repos" | \
  jq '.results[] | {title, url, engines, category}'
```

This searches across Docker Hub, GitHub, and other IT resources simultaneously.

## Filtering Results by Engine

After searching, filter by specific engine:

```bash
# Search packages, filter to npm only
curl -s "http://localhost:8888/search?q=react&format=json&categories=packages" | \
  jq '.results[] | select(.engines[] == "npm")'

# Search IT, filter to GitHub only
curl -s "http://localhost:8888/search?q=rust&format=json&categories=it" | \
  jq '.results[] | select(.engines[] == "github")'

# Search packages, filter to crates.io only
curl -s "http://localhost:8888/search?q=serde&format=json&categories=packages" | \
  jq '.results[] | select(.engines[] == "crates.io")'
```

## Checking Engine Availability

See which engines are configured for a category:

```bash
# Check all engines in packages category
curl -s "http://localhost:8888/config" | \
  jq '.engines[] | select(.categories[] | contains("packages")) | .name'

# Check all engines in cargo category
curl -s "http://localhost:8888/config" | \
  jq '.engines[] | select(.categories[] | contains("cargo")) | .name'
```

Check if specific engine is enabled:

```bash
curl -s "http://localhost:8888/config" | \
  jq '.engines[] | select(.name == "pypi")'
```

## Advanced: Engine-Specific Search

Force search using only specific engines:

```bash
# Use only npm
curl -s "http://localhost:8888/search?q=typescript&format=json&engines=npm" | \
  jq '.results[]'

# Use only crates.io
curl -s "http://localhost:8888/search?q=async&format=json&engines=crates.io" | \
  jq '.results[]'
```

## Nushell Helpers

```nu
# Search packages and group by engine
def search-packages [query: string] {
  http get $"http://localhost:8888/search?q=($query | url encode)&format=json&categories=packages"
  | get results
  | group-by { $in.engines | first }
  | transpose engine results
  | each { |row|
      {
        engine: $row.engine,
        count: ($row.results | length),
        results: ($row.results | select title url content)
      }
    }
}

# Search specific category
def searx-cat [
  query: string,
  category: string,
  --limit (-l): int = 10
] {
  http get $"http://localhost:8888/search?q=($query | url encode)&format=json&categories=($category)"
  | get results
  | first $limit
  | select title url content engines
}

# Multi-category search
def searx-multi [
  query: string,
  categories: list<string>,
  --limit (-l): int = 10
] {
  let cats = ($categories | str join ',')
  http get $"http://localhost:8888/search?q=($query | url encode)&format=json&categories=($cats)"
  | get results
  | first $limit
  | select title url content engines category
}
```

Usage:
```nu
search-packages "express"
searx-cat "tokio" "cargo" --limit 5
searx-multi "docker" ["packages", "it", "repos"] --limit 10
```

## Common Patterns

### Finding a package across all ecosystems:
```bash
curl -s "http://localhost:8888/search?q=http+client&format=json&categories=packages" | \
  jq '.results | group_by(.engines[0]) | map({engine: .[0].engines[0], packages: map(.title)})'
```

### Tech documentation search:
```bash
curl -s "http://localhost:8888/search?q=rust+async+programming&format=json&categories=it" | \
  jq '.results[] | select(.url | contains("doc")) | {title, url}'
```

### Academic research:
```bash
curl -s "http://localhost:8888/search?q=transformer+architecture&format=json&categories=scientific+publications" | \
  jq '.results[] | {title, url, date: .publishedDate, content}'
```
