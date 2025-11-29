# Nix Registry

## What is the Registry?

The Nix registry is a local mapping of **aliases** to **flake URLs**. It allows you to use short names instead of full URLs:

```bash
# Without registry (full URL)
nix profile add --profile ~/profile github:nixos/nixpkgs/nixpkgs-unstable#git

# With registry alias
nix search nixpkgs git  # "nixpkgs" is a registry alias
nix profile add --profile ~/profile nixpkgs#git
```

## Default Registry

Nix ships with default aliases:

```
nixpkgs                → github:nixos/nixpkgs/... (whatever branch was set by the Nix installer)
nixpkgs/nixos-24.11    → github:nixos/nixpkgs/nixos-24.11
nixpkgs/nixos-unstable → github:nixos/nixpkgs/nixos-unstable
```

Check your system's defaults:

```bash
nix registry list
```

Example output:
```
system: flake:nixpkgs from git+ssh://git@github.com/nixos/nixpkgs
global flake:nixpkgs from github:nixos/nixpkgs (pinned to 699ba2a)
home flake:nixpkgs from git+ssh://git@github.com/... (if user added)
```

## Registry Scopes

Nix searches registries in order:

1. **Home** (`$XDG_CONFIG_HOME/nix/registry.json`)
   - User-level overrides (highest priority)
   - Persist across sessions

2. **Global** (`/etc/nix/registry.json`)
   - System-wide defaults
   - Usually set by NixOS or Nix installer

3. **System** (built-in)
   - Fallback defaults

## Managing Registry Entries

### List all entries

```bash
nix registry list
```

Shows all registry entries with their scope and pinned status.

### Add a custom alias (user-level)

```bash
# Simple alias
nix registry add myflake github:user/repo

# With specific branch
nix registry add myflake github:user/repo/develop

# Pin to specific commit (most reproducible)
nix registry add myflake github:user/repo/abc1234def5678
```

These are stored in `~/.config/nix/registry.json`.

### Remove an alias

```bash
nix registry remove myflake
```

## Advanced Registry Configuration

### Direct JSON editing

If you prefer, edit `~/.config/nix/registry.json` directly:

```json
{
  "version": 2,
  "flakes": [
    {
      "from": {
        "type": "indirect",
        "id": "myproject"
      },
      "to": {
        "type": "github",
        "owner": "myorg",
        "repo": "myproject",
        "rev": "abc1234def567890",
        "dir": ""
      }
    }
  ]
}
```

Then verify with:

```bash
nix registry list
```

### Dynamic registry for development

Instead of modifying the global registry, create a `flake.nix` locally:

```bash
cd ~/myproject
nix flake init

# Edit flake.nix, then:
nix flake update

# Then install the local flake in a profile:
nix profile add "~/myproject#packages.x86_64-linux.mytool"
```

## Common Registry Patterns

### Stable vs Unstable

```bash
# Use stable for production
nix registry add stable github:nixos/nixpkgs/nixos-24.11

# Use unstable for latest features
nix registry add unstable github:nixos/nixpkgs/nixos-unstable

# In usage
nix profile add --profile ~/profile stable#git           # 2.42.0
nix profile add --profile ~/profile unstable#neovim     # 0.10.0 (newer)
```

### Organization-specific packages

```bash
# Company internal tools
nix registry add company-tools github:mycompany/nix-packages

# Use in profile
nix profile add --profile ~/profile company-tools#internal-cli
```

### Local development flake

```bash
# Point to local directory during development (must be absolute path)
nix registry add mydev /home/user/myproject

# Once merged to main, switch to GitHub
nix registry add mydev github:user/myproject
```

## For Agents

### Best practices for registry usage:

1. **Check available registries first**
   ```bash
   nix registry list | grep -E "^(home|global)"
   ```

2. **Assume nixpkgs exists** - it's always available
   ```bash
   nix profile add --profile ~/profile nixpkgs#<package>
   ```

3. **Ask user before adding registry entries** - avoid polluting their configuration
   ```bash
   echo "Would you like me to add a registry entry for <flake>?"
   ```

4. **Use absolute paths or GitHub URLs** for clarity
   - Good: `github:nixos/nixpkgs/nixos-24.11`
   - Okay: `nixpkgs` (if already registered)
   - Bad: `~/my-flake` (local paths break on different machines)

5. **Document custom registries** - note what was added:
   ```bash
   echo "Added registry entry: nix registry add myflake github:user/repo"
   ```

## Troubleshooting

### Alias not resolving

```bash
# Check if it exists
nix registry list | grep myflake

# Try explicit URL
nix search github:user/repo <package>

# If works, register it
nix registry add myflake github:user/repo
```

### Multiple versions of same flake

```bash
# You can have different aliases for different versions
nix registry add nixpkgs-stable github:nixos/nixpkgs/nixos-24.11
nix registry add nixpkgs-latest github:nixos/nixpkgs/nixos-unstable

# Use different aliases in profiles
nix profile add --profile ~/stable nixpkgs-stable#git
nix profile add --profile ~/latest nixpkgs-latest#git
```

### Registry entry gone after update

If you removed an entry by accident:

```bash
# It's still in git history (if using NixOS/Home Manager)
# Or re-add it
nix registry add myflake github:user/repo
```
