# Package Search Techniques

## Basic Search

```bash
nix search nixpkgs git
```

This searches package names and descriptions. Returns multiple results if any match.

## JSON Output for Parsing

```bash
nix search nixpkgs git --json
```

Output format:
```json
{
  "nixpkgs#git": {
    "pname": "git",
    "version": "2.42.0",
    "description": "Distributed version control system",
    "longDescription": "...",
    "outputs": ["out"],
    "stdenv": "..."
  }
}
```

Key fields:
- **pname**: Exact package name
- **version**: Current version in flake
- **description**: Short summary

## Advanced Search Patterns

### Search in specific flake

```bash
nix search github:user/repo mypackage
```

### Narrow down results

```bash
# Search with multiple terms
nix search nixpkgs python 3.11

# Use partial names
nix search nixpkgs "^git$"  # Exact match (regex supported)
```

### Find packages by attribute path

If you know the full attribute path:

```bash
# Direct lookup (faster than search)
nix eval --raw nixpkgs#git
```

## Common Package Name Gotchas

### Dashes vs underscores

```bash
# These are equivalent:
nix search nixpkgs python_3_11
nix search nixpkgs python-3-11
nix search nixpkgs python311  # Also works
```

Nix automatically handles these variations.

### Version numbers in names

```bash
nix search nixpkgs python3.11  # Specific version
nix search nixpkgs python311   # Same thing
nix search nixpkgs python      # All python variants
```

### Using the exact pname field

When search returns multiple results, look for exact `pname` match:

```bash
nix search nixpkgs --json python | jq -r '.[].pname'
```

Output might show:
- python3
- python3-minimal
- python311
- python312
- python310-pip

Use the exact pname with the flake: `nixpkgs#python3.11`

## Checking Package Availability Across Flakes

Some packages exist only in certain flakes:

```bash
# Try multiple registries
nix search nixpkgs <package> 2>/dev/null && echo "In nixpkgs"
nix search nixpkgs/nixos-unstable <package> 2>/dev/null && echo "In unstable"
nix search github:nix-community/nixpkgs-firefox-release <package> 2>/dev/null && echo "In firefox-release"
```

## Interactive Discovery

```bash
# List all available packages (large output)
nix search nixpkgs . | less

# List with descriptions
nix search nixpkgs --json | jq -r '.[] | "\(.pname) (\(.version)): \(.description)"'

# Find packages by description pattern
nix search nixpkgs --json | jq -r '.[] | select(.description | contains("web browser"))'
```

## Performance Considerations

- `nix search` may take a few seconds on first run
- Results are cached locally
- For repeated searches, store results in variable:

```bash
SEARCH_RESULT=$(nix search nixpkgs git --json)
# Use $SEARCH_RESULT multiple times without re-searching
```

## What Happens When Package Isn't Found

1. **Package doesn't exist in flake**
   - Solution: Try another flake, or report to user

2. **Typo in package name**
   - Solution: Use `nix search` with partial match

3. **Package in different output**
   - Some flakes (nixpkgs notably) organize as `flake#scope.package`
   - Solution: Check the full attribute path returned by `nix search`, or check with `nix flake show <flake>`

4. **System-specific availability**
   - Package may only exist for certain architectures
   - Solution: Check error message, may need different flake

## For Agents

### Safe search workflow:

1. Always search before installing: `nix search <flake> <partial-name>`
2. Extract exact pname from JSON: `jq -r '.[] | .pname' | head -1`
3. Build full reference: `echo "<flake>#<pname>"`
4. Verify before install: `nix search <flake> "<pname>"` (verify exact match)
5. Install with full reference: `nix profile add --profile <path> "<flake>#<pname>"`
