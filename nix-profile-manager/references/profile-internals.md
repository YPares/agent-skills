# Profile Internals

## Profile Structure

When you create a profile at `~/.local/profile`, Nix creates:

```
~/.local/profile/
├── manifest.json       # List of installed packages
├── manifest.json.lock  # Lock file (auto-generated)
├── bin/               # Symlinks to executables
│   ├── git -> /nix/store/xyz-git-2.42.0/bin/git
│   ├── python -> /nix/store/abc-python3-3.11/bin/python
│   └── ...
```

## Manifest Format

The `manifest.json` tracks what's installed:

```json
{
  "version": 6,
  "elements": [
    {
      "inputs": {
        "nixpkgs": {
          "id": "nixpkgs",
          "originalRef": "flake:nixpkgs",
          "lastModified": 1699300000,
          "narHash": "sha256-xxx..."
        }
      },
      "attrPath": "legacyPackages.x86_64-linux.git",
      "originalUrl": "flake:nixpkgs",
      "storePath": "/nix/store/xyz-git-2.42.0"
    }
  ]
}
```

### Key fields:

- **inputs**: Which flake and version this package comes from
- **attrPath**: The full attribute path in the flake
- **storePath**: Where in the Nix store the package lives
- **narHash**: Content hash for verification

## How nix profile add Works

1. **Resolve flake reference**: `nixpkgs#git` → look up actual flake URL
2. **Evaluate flake**: Run Nix evaluation to get package
3. **Build if needed**: Download or build the package
4. **Read manifest.json**: Load existing profile state
5. **Add new element**: Append package info to manifest
6. **Recompute symlinks**: Create/update symlinks in profile directory
7. **Verify**: Check that binaries are accessible

## Profile Updates with nix profile upgrade

When you run `nix profile upgrade --all`:

1. Re-evaluate all flakes referenced in manifest
2. Check for newer versions available
3. Download/build newer versions
4. Update manifest with new package info
5. Recompute symlinks to point to new versions
6. Keep old versions in Nix store (safe to keep, but takes disk space)

## Why Symlinks?

Nix keeps all package versions in the store (`/nix/store/`) which is:
- **Immutable**: Packages never change
- **Content-addressed**: Same content = same path
- **Garbage-collected**: Unused packages can be deleted by calling just one command

Profiles create symlinks to selected packages, so you can have multiple versions installed and switch between them by updating the profile.

## Profiles are Versioned

```bash
# Check history
nix profile history --profile ~/.local/profile

# Rollback to previous state
nix profile rollback --profile ~/.local/profile
```

## Path Considerations

### Profile path is metadata, not binaries

```bash
nix profile add --profile ~/.local/profile "nixpkgs#git"
```

- `~/.local/profile` is where Nix stores profile metadata
- Actual binaries are symlinks in `~/.local/profile/bin/`

To use the binaries, either:
1. Add `~/.local/profile/bin` to PATH
2. Create symlinks from some other folder in PATH to `~/.local/profile/bin/*`

### User Convention

Most users set up:
```bash
nix profile add --profile ~/.nix-profile "nixpkgs#git"
export PATH="$HOME/.nix-profile/bin:$PATH"
```

## Multiple Profiles

You can have multiple profiles for different purposes:

```bash
# Development tools
nix profile add --profile ~/.my-profiles/dev "nixpkgs#python311" "nixpkgs#nodejs"

# Utilities
nix profile add --profile ~/.my-profiles/util "nixpkgs#ripgrep" "nixpkgs#jq"

# In your shell
export PATH="$HOME/.my-profiles/dev/bin:$HOME/.my-profiles/util/bin:$PATH"
```

Each profile has its own manifest and can be updated independently.

## Lock Files

The `manifest.json.lock` is auto-generated and contains:
- Resolved flake URLs
- Exact commit hashes
- Content hashes

Don't edit manually. It ensures reproducibility across sessions.
