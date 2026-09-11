---
title: "Config files"
date: 2026-05-23
tags: ["system", "config", "paths"]
source: doc/pages/system/config-files.md
source_sha: 3fe1a21c87cb
---

> Lookup of common configuration file paths by area.

## System

| Path | Purpose |
|------|---------|
| `/etc/hostname` | system hostname |
| `/etc/hosts` | static hostname → IP |
| `/etc/locale.conf` | system locale (`LANG`, `LC_*`) |
| `/etc/locale.gen` | available locales (uncomment then `locale-gen`) |
| `/etc/vconsole.conf` | virtual console keymap + font |
| `/etc/timezone` | timezone (symlink target) |
| `/etc/localtime` | symlink → `/usr/share/zoneinfo/...` |
| `/etc/machine-id` | unique machine identifier |
| `/etc/os-release` | distribution identification |
| `/etc/sysctl.conf` | kernel parameters (legacy) |
| `/etc/sysctl.d/*.conf` | kernel parameters (drop-in, preferred) |
| `/etc/environment` | system-wide env (simple `KEY=VALUE`) |
| `/etc/profile` | login shell init (all users) |
| `/etc/profile.d/*.sh` | drop-in login scripts |
| `/etc/bash.bashrc` | system-wide bash interactive config |
| `/etc/motd` | message-of-the-day (post-login) |
| `/etc/issue` | pre-login message |

## Boot & bootloader

| Path | Purpose |
|------|---------|
| `/boot/loader/loader.conf` | systemd-boot main config |
| `/boot/loader/entries/*.conf` | systemd-boot entry files |
| `/etc/mkinitcpio.conf` | initramfs config (hooks, modules, files) |
| `/etc/mkinitcpio.d/*.preset` | initramfs presets |
| `/etc/cmdline.d/*.conf` | kernel cmdline fragments |
| `/etc/modprobe.d/*.conf` | module options + blacklists |
| `/etc/modules-load.d/*.conf` | modules to auto-load at boot |
| `/proc/cmdline` | current kernel command line |

## Pacman & packages

| Path | Purpose |
|------|---------|
| `/etc/pacman.conf` | pacman config |
| `/etc/pacman.d/mirrorlist` | mirror URLs (order = priority) |
| `/etc/pacman.d/gnupg/` | pacman GPG keyring |
| `/etc/makepkg.conf` | makepkg build config |
| `/var/cache/pacman/pkg/` | package cache |
| `/var/lib/pacman/` | pacman database |
| `/var/log/pacman.log` | transaction log |

## Network

| Path | Purpose |
|------|---------|
| `/etc/resolv.conf` | DNS resolver (often managed) |
| `/etc/nsswitch.conf` | resolution order |
| `/etc/NetworkManager/` | NM main config |
| `/etc/NetworkManager/system-connections/` | saved profiles (WiFi PSKs) |
| `/etc/systemd/network/*.network` | networkd config |
| `/etc/systemd/network/*.netdev` | networkd virtual devices |
| `/etc/systemd/resolved.conf` | resolved config |
| `/etc/nftables.conf` | firewall rules |
| `/etc/iproute2/rt_tables` | routing table names |

## Authentication & security

| Path | Purpose |
|------|---------|
| `/etc/passwd` | user accounts |
| `/etc/shadow` | password hashes + expiry |
| `/etc/group` | group definitions |
| `/etc/gshadow` | group password hashes |
| `/etc/sudoers` | sudo rules (edit with `visudo`) |
| `/etc/sudoers.d/` | drop-in sudo rules |
| `/etc/pam.d/` | PAM config per service |
| `/etc/security/limits.conf` | resource limits |
| `/etc/security/faillock.conf` | login lockout |
| `/etc/security/pwquality.conf` | password rules |
| `/etc/login.defs` | login defaults |
| `/etc/skel/` | new home dir template |
| `/etc/ssh/sshd_config` | SSH server config |
| `/etc/ssh/sshd_config.d/` | SSH server drop-ins |
| `/etc/polkit-1/` | polkit rules |

## Services & systemd

| Path | Purpose |
|------|---------|
| `/usr/lib/systemd/system/` | package units (don't edit) |
| `/etc/systemd/system/` | admin units + overrides |
| `~/.config/systemd/user/` | per-user units |
| `/etc/systemd/system.conf` | system manager config |
| `/etc/systemd/user.conf` | user session config |
| `/etc/systemd/journald.conf` | journal logging |
| `/etc/systemd/logind.conf` | login manager (lid, power, idle) |
| `/etc/systemd/timesyncd.conf` | NTP time sync |
| `/etc/systemd/resolved.conf` | DNS resolver |
| `/etc/systemd/coredump.conf` | core dump handling |
| `/etc/tmpfiles.d/*.conf` | admin tmpfiles rules |
| `/usr/lib/tmpfiles.d/*.conf` | package tmpfiles rules |

## Shell configuration

| Path | Purpose |
|------|---------|
| `~/.bashrc` | bash interactive |
| `~/.bash_profile` | bash login |
| `~/.bash_logout` | bash logout |
| `~/.zshrc` | zsh interactive |
| `~/.zprofile` | zsh login |
| `~/.zshenv` | zsh env (always loaded) |
| `~/.inputrc` | readline (bindings, completion) |
| `~/.profile` | generic login fallback |
| `/etc/shells` | valid login shells (used by `chsh`) |
| `~/.local/share/bash-completion/` | user bash completions |

## Logging

| Path | Purpose |
|------|---------|
| `/var/log/` | log directory |
| `/var/log/pacman.log` | pacman transactions |
| `/var/log/Xorg.0.log` | X server log |
| `/var/log/journal/` | systemd journal persistent storage |
| `/var/log/wtmp` | login records (`last`) |
| `/var/log/btmp` | failed logins (`lastb`) |
| `/var/log/lastlog` | last login per user (`lastlog`) |

## XDG directories

| Variable | Default | Purpose |
|----------|---------|---------|
| `XDG_CONFIG_HOME` | `~/.config` | configuration |
| `XDG_DATA_HOME` | `~/.local/share` | data |
| `XDG_STATE_HOME` | `~/.local/state` | state (logs, history) |
| `XDG_CACHE_HOME` | `~/.cache` | cache (safe to delete) |
| `XDG_RUNTIME_DIR` | `/run/user/$UID` | runtime (sockets, PIDs) |

## Hardware & devices

| Path | Purpose |
|------|---------|
| `/etc/fstab` | mount table |
| `/etc/crypttab` | LUKS encrypted volumes |
| `/etc/udev/rules.d/` | custom udev rules |
| `/usr/lib/udev/rules.d/` | package udev rules |
| `/etc/X11/xorg.conf.d/` | X server config fragments |
| `/sys/` | kernel device interface (sysfs) |
| `/proc/` | process + kernel info (procfs) |

## Application

| Path | Purpose |
|------|---------|
| `~/.ssh/config` | SSH client |
| `~/.ssh/authorized_keys` | accepted public keys |
| `~/.ssh/known_hosts` | known host fingerprints |
| `~/.gitconfig` | git config |
| `~/.config/git/config` | git config (XDG path) |
| `~/.gnupg/` | GPG keyring |
| `/etc/docker/daemon.json` | docker daemon |
