---
title: "Packages"
date: 2026-06-15
tags: ["system", "pacman", "packages"]
source: doc/pages/system/packages.md
source_sha: 6aedcc8ca957
---

> Pacman and yay package management on Arch.

## Install

- Single package:
  `sudo pacman -S <pkg>`

- Multiple packages:
  `sudo pacman -S firefox chromium vlc`

- Skip already up-to-date:
  `sudo pacman -S --needed <pkg>`

- No confirmation:
  `sudo pacman -S --noconfirm <pkg>`

- From a local `.pkg.tar.zst`:
  `sudo pacman -U /path/to/package.pkg.tar.zst`

- From a specific repo:
  `sudo pacman -S extra/<pkg>`

## Remove

- Package + deps + config (cleanest):
  `sudo pacman -Rns <pkg>`

- Package + deps (keep config):
  `sudo pacman -Rs <pkg>`

- Only the package:
  `sudo pacman -R <pkg>`

- Orphans (installed as deps, no longer needed):
  `sudo pacman -Rns $(pacman -Qdtq)`

- List orphans without removing:
  `pacman -Qdt`

## Update

- Full system upgrade:
  `sudo pacman -Syu`

- Force database refresh + upgrade:
  `sudo pacman -Syyu`

- Download only, don't install:
  `sudo pacman -Syuw`

> **Warning:** Never run `pacman -Sy <pkg>` (partial upgrade). Always full `-Syu`.

## Search & query

- Search remote repos:
  `pacman -Ss <keyword>`

- Info on remote package:
  `pacman -Si <pkg>`

- Search installed:
  `pacman -Qs <keyword>`

- Info on installed package:
  `pacman -Qi <pkg>`

- List files in installed package:
  `pacman -Ql <pkg>`

- Which package owns file:
  `pacman -Qo /usr/bin/vim`

- Find file in remote pkg (requires `pkgfile`):
  `pkgfile <filename>`

## List installed

> For a full, committed snapshot of this machine, see
> the package inventory kept in the dotfiles — regenerate it any time with `pkglist`
> (see [tools/pkglist](/docs/tools/pkglist/)).

- Explicitly installed:
  `pacman -Qe`

- Explicit, excluding base/base-devel:
  `pacman -Qet`

- Foreign (AUR / manual):
  `pacman -Qm`

- Native (official repos):
  `pacman -Qn`

- Recent installs (needs `expac`):
  `expac --timefmt='%Y-%m-%d %T' '%l\t%n' | sort | tail -20`

- Check broken deps:
  `sudo pacman -Dk`

## Cache

- Cache size:
  `du -sh /var/cache/pacman/pkg/`

- Clean cache, keep 3 latest (needs `pacman-contrib`):
  `sudo paccache -r`

- Keep only latest:
  `sudo paccache -rk1`

- Remove cache for uninstalled pkgs:
  `sudo paccache -ruk0`

- Remove all cache:
  `sudo pacman -Scc`

- Downgrade from cache:
  `sudo pacman -U /var/cache/pacman/pkg/<pkg>-<oldver>.pkg.tar.zst`

- Enable weekly cleanup timer:
  `sudo systemctl enable --now paccache.timer`

## Mirrors

- Edit mirror list:
  `sudo $EDITOR /etc/pacman.d/mirrorlist`

- Best 10 HTTPS mirrors with reflector:
  ```
  sudo reflector --country France,Germany --age 12 --protocol https \
      --sort rate --latest 10 --save /etc/pacman.d/mirrorlist
  ```

- Auto mirror updates:
  `sudo systemctl enable --now reflector.timer`

## Configuration

- Main file: `/etc/pacman.conf`
- Common tweaks:
  ```
  Color
  ILoveCandy
  ParallelDownloads = 5

  [multilib]
  Include = /etc/pacman.d/mirrorlist
  ```

- Ignore package on upgrade (in `pacman.conf`):
  `IgnorePkg = linux linux-headers`

## yay (AUR)

- Bootstrap (first time):
  ```
  sudo pacman -S --needed git base-devel
  git clone https://aur.archlinux.org/yay.git
  cd yay && makepkg -si
  ```

- Search AUR + repos:
  `yay <keyword>`

- Install from AUR:
  `yay -S <pkg>`

- Update everything (repos + AUR):
  `yay -Syu`

- AUR-only update:
  `yay -Sua`

- Remove leftover build deps:
  `yay -Yc`

- Edit PKGBUILD before build:
  `yay -S --editmenu <pkg>`

- Skip check phase:
  `yay -S <pkg> --mflags=--nocheck`

## Manual AUR install

- Clone, review, build:
  ```
  git clone https://aur.archlinux.org/<pkg>.git
  cd <pkg>
  less PKGBUILD
  makepkg -si
  ```

## Troubleshooting

- Lock left over (only when no pacman running):
  `sudo rm /var/lib/pacman/db.lck`

- Re-sync corrupted DB:
  `sudo pacman -Syy`

- Fix PGP signature errors:
  ```
  sudo pacman -S archlinux-keyring
  sudo pacman-key --init
  sudo pacman-key --populate archlinux
  ```

- Reinstall all native packages:
  `sudo pacman -S $(pacman -Qnq)`

- Verify package files:
  `pacman -Qkk`

- Force overwrite conflicts:
  `sudo pacman -S --overwrite '*' <pkg>`

- Recent upgrades from log:
  `grep -i upgraded /var/log/pacman.log | tail -20`

## Useful aliases

```
alias pacup='sudo pacman -Syu'
alias pacin='sudo pacman -S'
alias pacrm='sudo pacman -Rns'
alias pacss='pacman -Ss'
alias pacqs='pacman -Qs'
alias pacown='pacman -Qo'
alias pacorph='sudo pacman -Rns $(pacman -Qdtq)'
alias paclog='grep -i "installed\|upgraded\|removed" /var/log/pacman.log | tail -30'
```

## Useful installed packages (reference)

| Tool | Package |
|------|---------|
| File listing | `eza` |
| Fuzzy finder | `fzf` |
| Smart cd | `zoxide` |
| File manager | `yazi` |
| Git TUI | `lazygit` |
| PDF viewer | `zathura` + `zathura-pdf-mupdf` |
| Document compiler | `typst` |
| Screenshot | `grimshot` (sway-contrib) |
| Notifications | `mako` |
| Bar | `waybar` |
| Launcher | `fuzzel` |
| Brightness | `brightnessctl` |
| Bluetooth | `blueman` |
| Bat (cat with colors) | `bat` |
| System monitor | `btop` |
| Image viewer | `imv` |
| Vi zsh plugin | `zsh-vi-mode` (AUR) |
| Syntax highlight zsh | `zsh-syntax-highlighting` |
