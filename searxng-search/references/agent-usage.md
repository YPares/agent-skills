# SearXNG for AI Agents

This guide explains how AI agents (like Claude) can use SearXNG for enhanced search capabilities.

## Why Use SearXNG?

**Problem**: Built-in WebSearch tools often have limitations:
- Limited to ~10 results per query
- Can't search specific package repositories (PyPI, npm, cargo)
- No direct control over search engines used
- May have rate limits or restrictions

**Solution**: SearXNG provides:
- Direct access to 100+ search engines
- Specialized package repository search
- Full control over categories and filters
- Unlimited local queries
- JSON API for programmatic access

## Agent Workflow

### 1. Start SearXNG (if not running)

```bash
# Check if running
curl -sf http://localhost:8888/ > /dev/null || \
  start-searxng --detach
```

**When to start:**
- At the beginning of a search-intensive task
- When user explicitly requests package searches
- When WebSearch tool returns insufficient results

### 2. Choose the Right Category

| User Request | Category | Example |
|--------------|----------|---------|
| "Find Rust crate for async" | `cargo` | `?q=async&categories=cargo` |
| "Search npm for React libs" | `packages` (filter npm) | `?q=react&categories=packages` |
| "Find Python ML library" | Use PyPI API workaround | See pypi-direct-search.md |
| "GitHub repos for Docker" | `repos` | `?q=docker&categories=repos` |
| "Academic papers on AI" | `scientific publications` | `?q=neural+networks&categories=scientific+publications` |
| "General tech search" | `it` | `?q=kubernetes&categories=it` |

### 3. Execute Search

**Option A: Direct curl (fast, scriptable)**
```bash
curl -s "http://localhost:8888/search?q=tokio&format=json&categories=cargo" | \
  jq '.results[0:5] | .[] | {title, url, content}'
```

**Option B: Nushell helper (formatted output)**
```bash
searx "tokio" --category cargo --limit 5
```

### 4. Parse and Present Results

Extract key information:
```bash
# Get titles and URLs
jq '.results[] | {title, url}'

# Filter by specific engine
jq '.results[] | select(.engines[] == "npm")'

# Get top N results
jq '.results[0:N]'

# Check which engines returned results
jq '.results[0].engines'
```

## Common Agent Use Cases

### Package Discovery

**User**: "Find a Rust crate for HTTP requests"

**Agent workflow:**
1. Start SearXNG if needed
2. Search cargo: `?q=http+requests&categories=cargo`
3. Parse top 5 results
4. Present: title, URL, description
5. Optionally fetch details from crates.io API

**Implementation:**
```bash
curl -s "http://localhost:8888/search?q=http+requests&format=json&categories=cargo" | \
  jq -r '.results[0:5] | .[] | "[\(.title)](\(.url))\n  \(.content)\n"'
```

### Multi-Repository Search

**User**: "What are the best logging libraries across different languages?"

**Agent workflow:**
1. Search `categories=packages` for general term
2. Group results by engine (npm, crates.io, hex, etc.)
3. Present organized by ecosystem

**Implementation:**
```bash
curl -s "http://localhost:8888/search?q=logging&format=json&categories=packages" | \
  jq 'group_by(.results[].engines[0]) |
      map({engine: .[0].engines[0], packages: map(.title)})'
```

### Academic Research

**User**: "Find recent papers on transformer architectures"

**Agent workflow:**
1. Search scientific publications category
2. Filter by date if needed
3. Extract: title, URL, published date
4. Provide links to arXiv/papers

**Implementation:**
```bash
curl -s "http://localhost:8888/search?q=transformer+architecture&format=json&categories=scientific+publications" | \
  jq '.results[] | {title, url, date: .publishedDate, source: .engines}'
```

### Code Examples Search

**User**: "Show me examples of async/await in Rust"

**Agent workflow:**
1. Use `code` category for code search
2. Filter GitHub results
3. Extract repository URLs

**Implementation:**
```bash
curl -s "http://localhost:8888/search?q=rust+async+await&format=json&categories=code" | \
  jq '.results[] | select(.engines[] == "github") | {title, url}'
```

## Best Practices for Agents

### 1. Always Check If SearXNG is Running

```bash
if ! curl -sf http://localhost:8888/ > /dev/null 2>&1; then
  echo "Starting SearXNG..."
  start-searxng --detach
fi
```

### 2. Use Appropriate Categories

- Don't use `general` for package searches - use `packages`, `cargo`, etc.
- Use `it` for broad tech searches
- Use `repos` specifically for GitHub/GitLab
- Use `code` for searching within code files

### 3. Handle Empty Results

```bash
RESULTS=$(curl -s "..." | jq '.results | length')
if [ "$RESULTS" -eq 0 ]; then
  echo "No results found. Trying broader search..."
  # Try different category or broader terms
fi
```

### 4. Combine with Other Tools

- Use SearXNG to find packages
- Then use package-specific APIs (crates.io, npm) for details
- For PyPI: always use direct API or qypi (PyPI engine doesn't work)

### 5. Respect Resources

- Don't spam queries in tight loops
- Reuse results when possible
- Stop SearXNG when done with search-intensive tasks:
  ```bash
  podman stop searxng
  ```

## Error Handling

### SearXNG Not Responding

```bash
# Check if container is running
podman ps | grep searxng

# Check logs
podman logs searxng

# Restart
podman stop searxng
start-searxng --detach
```

### Empty Results

1. Check `unresponsive_engines` in response
2. Try broader search terms
3. Try different category
4. Check if specific engine is down

### PyPI Not Working

PyPI engine is enabled but returns no results. **Always use workaround**:

```bash
# Option 1: Direct API
curl -s "https://pypi.org/pypi/requests/json" | jq '.info | {name, summary, version}'

# Option 2: qypi CLI
uvx qypi search pandas --json
uvx qypi info requests --json
```

## Performance Tips

### Limit Results

```bash
# Default returns many results
curl -s "...&format=json" | jq '.results[0:10]'
```

### Parallel Searches

For multiple queries, run in parallel:
```bash
curl -s "...cargo..." > cargo.json &
curl -s "...packages..." > packages.json &
wait
```

### Cache Results

Store frequently-used searches:
```bash
# Cache popular packages
curl -s "...?q=tokio&categories=cargo" > /tmp/tokio-search.json
```

## Integration Examples

### Bash Function

```bash
searx_pkg() {
  local query="$1"
  local category="${2:-packages}"
  curl -s "http://localhost:8888/search?q=${query}&format=json&categories=${category}" | \
    jq -r '.results[0:5] | .[] | "\(.title): \(.url)"'
}

# Usage
searx_pkg "express" "packages"
searx_pkg "tokio" "cargo"
```

### Python Integration

```python
import requests

def searxng_search(query, category='general', limit=10):
    resp = requests.get('http://localhost:8888/search', params={
        'q': query,
        'format': 'json',
        'categories': category
    })
    results = resp.json()['results'][:limit]
    return [{'title': r['title'], 'url': r['url'], 'content': r.get('content', '')}
            for r in results]

# Usage
packages = searxng_search('async', category='cargo', limit=5)
for pkg in packages:
    print(f"{pkg['title']}: {pkg['url']}")
```

### Nushell Function

```nu
def searx-api [
  query: string,
  --category (-c): string = "general",
  --limit (-l): int = 10
] {
  http get $"http://localhost:8888/search?q=($query | url encode)&format=json&categories=($category)"
  | get results
  | first $limit
  | select title url content engines
}

# Usage
searx-api "serde" --category cargo --limit 5
```

## When to Use SearXNG vs. Built-in Tools

### Use SearXNG When:
- Searching package repositories (cargo, npm, etc.)
- Need more than 10 results
- Need to filter by specific engines
- Searching academic papers
- Need full control over search categories
- Rate limits hit on other tools

### Use Built-in WebSearch When:
- General web queries
- Current events/news
- Quick fact-checking
- Don't need specialized filtering
- SearXNG not available/running

## Cleanup

When done with search tasks:
```bash
# Stop SearXNG
podman stop searxng

# Container auto-removes (--rm flag)
# Temp config auto-deleted by OS
```
