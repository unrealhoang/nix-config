# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Multi-system Nix flake configuration managing NixOS system configurations and home-manager user environments across multiple machines:

| Host | OS | Arch | User | Purpose |
|------|----|----|------|---------|
| unrealPc | NixOS | x86_64 | unreal | Desktop with Hyprland |
| macAir | macOS | aarch64 | unreal | Apple Silicon laptop |
| hanode | NixOS | x86_64 | bing | Home server (HA, Immich, Grafana) |

## Common Commands

```bash
# Development shell
nix develop

# Format Nix files
nix fmt

# Home-manager switch (standalone)
home-manager --flake .#unreal@unrealPc switch
home-manager --flake .#unreal@macAir switch
home-manager --flake .#hanode-bing switch

# NixOS rebuild (requires sudo, run on target machine)
sudo nixos-rebuild --flake .#unrealPc switch

# Deploy hanode remotely (build locally, deploy via SSH)
nixos-rebuild --flake .#hanode --target-host bing@home.binginu.homes --sudo switch

# Build custom packages
nix build .#archcraft-font
nix build .#fcitx5-bamboo
```

## Architecture

### Entry Point
- `flake.nix` - Main configuration defining inputs, outputs, and system configurations

### Directory Structure
- `home-manager/` - User environment configs
  - `home.nix` - Linux base config (unrealPc)
  - `mac-air.nix` - macOS config
  - `hanode-bing.nix` - Server user config
  - `features/` - Modular feature configs (git, neovim, zsh, hyprland, etc.)
- `nixos/` - unrealPc NixOS system config
- `hanode/` - hanode server NixOS config
- `pkgs/` - Custom packages (archcraft-font, fcitx5-bamboo)
- `overlays/` - Package modifications and unstable channel access
- `modules/` - Reusable NixOS/home-manager modules

### Key Patterns

**Feature Modules**: Each feature in `home-manager/features/` is self-contained and imported as needed. User-configurable options are defined in `features/user-configurations/`.

**Overlays**: Custom packages are exposed via `overlays.additions`. Access unstable packages via `pkgs.unstable.*`.

**Theming**: Catppuccin Mocha theme is used consistently across applications (tmux, starship, alacritty, hyprland, grub).

**Git SSH Signing**: Commits use SSH keys for signing. macOS uses 1Password's `op-ssh-sign`, Linux uses direct ed25519 key.

**Impermanence**: unrealPc uses ephemeral root with persistent data at `/mnt/data2/persist/`.

**Remote Deployment**: hanode is deployed remotely using `nixos-rebuild --target-host` which builds locally and copies the closure via SSH to activate on the target.

### State Versions
- unrealPc: 24.05
- macAir: 23.05
- hanode: 24.05

## Rules for Claude

**Never cite hashes, cachix public keys, sha256 sums, store-path-shaped strings, or upstream version numbers from memory.** Always look them up from an authoritative source before pasting:
- Cachix public keys: grep the upstream flake source (e.g. `grep -rn 'trusted-public-keys' <flake-src>`) or fetch from the cache's own `/nix-cache-info` endpoint.
- `sha256`/`hash` for `fetchFromGitHub` and friends: let Nix compute it (`nix-prefetch-...`, or set a fake hash and read the error).
- Store paths: derive via `nix eval --raw ...drvPath` / `...outPath`, never reconstruct.
- Package / upstream versions: check the actual source — `curl -s https://api.github.com/repos/<owner>/<repo>/releases/latest`, the project's tags, or `nix eval` on the relevant attribute. Do not guess "the latest is X.Y.Z" from training data.

Even if a value "looks right" from prior context, verify before writing it into a file or telling the user it's the correct value.
