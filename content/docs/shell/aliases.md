---
title: "Shell aliases"
date: 2026-03-11
tags: ["shell", "aliases", "zsh"]
source: doc/pages/shell/aliases.md
source_sha: cc7deca20453
---

> All shell aliases defined in ~/.config/shell/alias.

## Navigation & files

- Exit shell:
  `e` → `exit`

- Clear terminal:
  `c` → `clear`

- Open neovim:
  `v` → `nvim`

- Open yazi file manager:
  `f` → `yazi`

- List files (long, dirs first, icons):
  `ls` → `eza -l --group-directories-first --icons`

- List all files including hidden:
  `lsa` → `eza -la --group-directories-first --icons`

- List directories only:
  `lsd` → `eza -laD --group-directories-first --icons`

- List with git status:
  `lsg` → `eza -la --group-directories-first --icons --git`

- Grep with color:
  `grep` → `grep --color=auto`

- Move with confirmation prompt:
  `mv` → `mv -i`

- Remove with verbose + confirmation:
  `rm` → `rm -Iv`

- cd using zoxide (frecency-based):
  `cd` → `z`

- Interactive zoxide selection:
  `ci` → `zi`
