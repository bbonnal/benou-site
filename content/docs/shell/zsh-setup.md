---
title: "Zsh setup"
date: 2026-05-23
tags: ["shell", "zsh", "config"]
source: doc/pages/shell/zsh-setup.md
source_sha: 620a7d51040b
---

> Zsh config layout, env vars, FZF, and colored man pages. See `shell/zsh-tips` for runtime behavior.

## File layout (XDG)

- `$ZDOTDIR` = `~/.config/zsh` (set in a tiny `~/.zshenv`)
- `.zprofile` → `~/.config/zsh/.zprofile` — login shells (env, paths)
- `.zshrc` → `~/.config/zsh/.zshrc` — interactive shells (completion, prompt, plugins, keys)
- History file: `~/.cache/zsh_history`
- Completion cache: `~/.cache/zsh/zcompdump-$ZSH_VERSION`

`.zprofile` runs first (login), `.zshrc` after (interactive). Put env in `.zprofile`, behavior in `.zshrc`.

## XDG dirs (set in .zprofile)

```sh
XDG_CONFIG_HOME=$HOME/.config
XDG_DATA_HOME=$HOME/.local/share
XDG_STATE_HOME=$HOME/.local/state
XDG_CACHE_HOME=$HOME/.cache
```

App-specific relocations:

- `LESSHISTFILE=$XDG_CACHE_HOME/less_history`
- `PYTHON_HISTORY=$XDG_DATA_HOME/python/history`
- `WORKON_HOME=$XDG_DATA_HOME/.virtualenvs`

## Default editor

- `EDITOR=nvim` — used by `visudo`, `crontab -e`, git, etc.

## PATH

- Custom scripts dir is on PATH:
  `PATH=$XDG_CONFIG_HOME/scripts:$PATH`

## FZF env

- `FZF_DEFAULT_OPTS="--style minimal --color 16 --layout=reverse --height 30% --preview='bat -p --color=always {}'"`
- `FZF_CTRL_R_OPTS="--style minimal --color 16 --info inline --no-sort --no-preview"`

`Ctrl+R` history widget set up via `source <(fzf --zsh)`.

## Colored man pages

Set in `.zprofile`:

```sh
LESS='-R'
MANPAGER='sh -c "less"'
GROFF_NO_SGR=0
MANROFFOPT='-c'
```

ANSI escape colors for man formatting:

- Blink → bright red `\e[1;91m`
- Bold → magenta `\e[1;95m`
- Underline → bright green `\e[1;92m`
- Standout → gray bg / white fg `\e[48;5;238;38;5;15m`
- Line numbers → dim gray `\e[38;5;240m`

## Dependencies

- `zoxide` — smart `cd`
- `fzf` + `bat` — fuzzy search with previews
- `zsh-syntax-highlighting` — real-time command highlighting
- `zsh-vi-mode` (AUR) — replaces built-in zle vi-mode

## Reload

- `source ~/.config/zsh/.zshrc` (or just open a new shell)
