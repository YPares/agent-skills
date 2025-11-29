# Flakes: Deep Dive

## What is a Flake?

A flake is a directory with a `flake.nix` file that defines:
- **Inputs**: Dependencies on other flakes
- **Outputs**: What this flake provides (packages, modules, functions, etc.)
- **Lock file**: `flake.lock` that pins exact versions

Flakes are the modern way to version and distribute Nix packages reproducibly.

## Flake References

### Format

```
<flake-ref>[/<path>][?<query>[=<value>]...]
```

### Types

#### 1. Registry Aliases (Recommended for agents)

```bash
nixpkgs#git        # Resolves via nix registry
unstable#python3   # If configured as registry entry
```

Registry entries are defined locally and resolve to underlying flake references.

#### 2. GitHub References

```bash
github:user/repo               # Latest commit on default branch
github:user/repo/branch-name   # Specific branch
github:user/repo/commit-hash   # Specific commit
github:user/repo/v1.0.0        # Tag reference
```

#### 3. Flake URLs

```bash
git+https://github.com/user/repo.git    # Git URL
file:///home/user/my-flake              # Local path
```

#### 4. Pinning Versions

```bash
# By tag (recommended for stable)
github:user/repo/v1.0

# By commit hash (most reproducible)
github:user/repo/abc1234def5678

# By branch (least stable, not recommended)
github:user/repo/main
```

## Important: nixpkgs Variations

### Main variants:

- `nixpkgs` - Latest release of nixpkgs (stable)
- `nixpkgs/nixos-24.11` - Specific NixOS release (stable)
- `nixpkgs/nixos-unstable` - Cutting-edge but reviewed
- `nixpkgs/master` - Bleeding edge, use with caution

### When to use each:

- **nixpkgs**: Default for most tools, new packages added regularly (corresponds to the `nixpkgs-unstable` branch usually)
- **Custom flakes**: Need specific configuration or unpublished packages

## Flake Outputs

A flake can output multiple things:

```nix
{
  outputs = {
    packages.x86_64-linux.git = ...;      # Package for Linux x86_64
    packages.aarch64-darwin.python3 = ... # Package for macOS ARM
    overlays.default = ...;               # Overlay for custom modifications
    modules.default = ...;                # NixOS module
  };
}
```

When using `nix search` or `nix profile add`, Nix picks the appropriate output for your system.

## Checking What a Flake Provides

```bash
# List all outputs in a flake
nix flake show nixpkgs

# Show attributes in packages
nix flake show github:user/repo | grep packages
```

## For Agents

### Safe defaults:

- Use `nixpkgs#<package>` for most tools
- Use registry aliases defined by the user
- Use search before installing to get exact package names

### When a package can't be found:

1. Search across different flakes if user has configured alternatives in the registry
2. Check if package name contains dashes (e.g., `python3-pip` vs `python3`)
3. Ask user which flake to use, or to add custom flake to the registry if needed
