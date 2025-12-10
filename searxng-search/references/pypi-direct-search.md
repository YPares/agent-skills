# PyPI Direct Search

## Why SearXNG's PyPI Engine Doesn't Work

**Root cause:** PyPI now serves a JavaScript "Client Challenge" page for bot protection, breaking SearXNG's HTML scraper.

**Details:**
- SearXNG's PyPI engine scrapes HTML from `https://pypi.org/search/?q=...`
- As of late 2024/early 2025, PyPI returns a JS challenge page instead of search results
- The HTML parser can't find expected elements (XPath selectors fail)
- Reported in [SearXNG issue #4093](https://github.com/searxng/searxng/issues/4093) (December 2024)
- Status: **OPEN** as of December 2025 - no fix yet

**The engine needs to be rewritten** to use PyPI's JSON API instead of web scraping.

## Alternative Methods

Since SearXNG's PyPI engine is broken, use these direct methods:

## Method 1: PyPI JSON API

PyPI provides a JSON API for package metadata.

### Get Package Info

```bash
curl -s "https://pypi.org/pypi/<package>/json"
```

**Response structure:**
```json
{
  "info": {
    "name": "package-name",
    "version": "1.2.3",
    "summary": "Package description",
    "description": "Long description (often in markdown)",
    "author": "Author Name",
    "author_email": "author@example.com",
    "home_page": "https://github.com/...",
    "license": "MIT",
    "keywords": "keyword1, keyword2",
    "classifiers": [...],
    "requires_python": ">=3.8",
    ...
  },
  "urls": [...],  // Download URLs for wheels, sdist, etc.
  "releases": {...},  // All versions
  "vulnerabilities": [...]
}
```

### Extract Specific Fields

```bash
# Get summary
curl -s "https://pypi.org/pypi/requests/json" | jq '.info.summary'

# Get version
curl -s "https://pypi.org/pypi/requests/json" | jq '.info.version'

# Get homepage
curl -s "https://pypi.org/pypi/requests/json" | jq '.info.home_page'

# Check Python version requirement
curl -s "https://pypi.org/pypi/requests/json" | jq '.info.requires_python'
```

### Nushell Helper

```nu
def pypi [package: string] {
  http get $"https://pypi.org/pypi/($package)/json"
  | get info
  | select name version summary home_page license requires_python
}

# Usage
pypi requests
```

## Method 2: qypi CLI

Install via `uvx`:
```bash
uvx qypi search <term>
uvx qypi info <package>
```

### Search

```bash
# Search with JSON output
uvx qypi search pandas --json

# Search with boolean operators
uvx qypi search --and machine learning --json
uvx qypi search --or pandas numpy --json

# Search for packages or releases
uvx qypi search --packages scikit --json
uvx qypi search --releases torch --json
```

**Output format:**
```json
[
  {
    "name": "package-name",
    "version": "1.2.3",
    "summary": "Description"
  },
  ...
]
```

### Get Package Info

```bash
uvx qypi info requests --json
```

**Output includes:**
- Name, version, summary
- Author, maintainer
- License
- Homepage, documentation, source URLs
- Dependencies
- Keywords, classifiers

### List Releases

```bash
uvx qypi releases flask --json
```

Returns all available versions of a package.

### List Package Owners

```bash
uvx qypi owner requests --json
```

## Method 3: pip search Alternative (Disabled)

`pip search` has been disabled by PyPI since 2021 due to abuse. Use the methods above instead.

## Comparison

| Method | Pros | Cons |
|--------|------|------|
| **PyPI JSON API** | Direct, no install, fast | No search (must know exact package name) |
| **qypi** | Search capability, comprehensive info | Requires Python 3.10+, extra tool |
| **SearXNG PyPI** | Integrated with other searches | Currently not working |

## Troubleshooting SearXNG PyPI (Archived)

**Note:** These troubleshooting steps won't fix the PyPI engine because the issue is on PyPI's side (bot protection), not SearXNG's.

### If you want to verify the issue yourself:

1. **Test PyPI search page directly:**
   ```bash
   curl -s "https://pypi.org/search/?q=requests" | head -50
   ```
   You'll see a "Client Challenge" page requiring JavaScript, not search results.

2. **Check SearXNG logs** (no errors will appear):
   ```bash
   podman logs searxng | grep -i pypi
   ```

3. **The engine won't be listed as "unresponsive"** because it successfully fetches the page - it just can't parse it:
   ```bash
   curl -s "http://localhost:8888/search?q=test&engines=pypi&format=json" | jq '.unresponsive_engines'
   # Returns: []
   ```

### Monitoring for a Fix

Watch [SearXNG issue #4093](https://github.com/searxng/searxng/issues/4093) for updates. The fix will likely involve:
- Rewriting the engine to use PyPI's JSON API (`https://pypi.org/pypi/<package>/json`)
- Removing HTML scraping entirely
- Possibly requiring package name exact match instead of search

## Configuration Location

Your SearXNG config: `/home/ypares/Config/.config/searxng/settings.yml`

PyPI engine config (lines 1742-1744):
```yaml
- name: pypi
  shortcut: pypi
  engine: pypi
```

To modify engine settings, add parameters like:
```yaml
- name: pypi
  shortcut: pypi
  engine: pypi
  timeout: 10.0  # Increase timeout
  disabled: false  # Ensure it's enabled
```

Then restart SearXNG container.
