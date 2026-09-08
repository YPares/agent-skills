# agent-skills

Various skills for AI agents (in claude skills format).

## Installation

### Claude Code/Desktop

**Step 1:** Add this marketplace to Claude Code:

```bash
/plugin marketplace add ypares/agent-skills
   # Lowercase here. GitHub is case-insensitive, claude marketplaces aren't
```

**Step 2:** Activate the plugins you want to use:

```bash
/plugin   # Opens a TUI to choose which ones to activate
```

### Other Agent Harnesses

Besides Claude Code/Desktop, you can use these skills in any agent harness via
[openskills](https://github.com/numman-ali/openskills), which is also
Nix-packaged in [nix-ai-tools](https://github.com/numtide/nix-ai-tools).

### Using `rigup.nix`

This repository also exposes the Skills via Nix, as **riglet** modules for the `rigup` Agent Rig System.
See [`rigup.nix`](https://github.com/YPares/rigup.nix) for more information.
