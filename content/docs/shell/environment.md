---
title: "Shell environment"
date: 2026-05-23
tags: ["shell", "environment", "xdg"]
source: doc/pages/shell/environment.md
source_sha: 978b5be39f44
---

> Shell startup order, env vars, PATH, XDG, locale, chsh.

## Bash startup order

```
Login shell (ssh, tty, bash --login):
  /etc/profile
    → /etc/profile.d/*.sh
  ~/.bash_profile (or ~/.bash_login, or ~/.profile — first found)
    → usually sources ~/.bashrc

Interactive non-login (terminal emulator):
  /etc/bash.bashrc
  ~/.bashrc

Non-interactive (script):
  $BASH_ENV (if set)
```

## Zsh startup order

```
Always (every zsh, incl. scripts):
  /etc/zshenv ; ~/.zshenv

Login:
  /etc/zprofile ; ~/.zprofile

Interactive:
  /etc/zshrc ; ~/.zshrc

After zshrc on login:
  /etc/zlogin ; ~/.zlogin

On logout:
  ~/.zlogout ; /etc/zlogout
```

## Quick reference

| File | Bash | Zsh | When |
|------|------|-----|------|
| `/etc/profile` | login | — | system-wide login |
| `/etc/bash.bashrc` | interactive | — | system-wide bash |
| `/etc/zshenv` | — | always | system-wide zsh env |
| `/etc/zshrc` | — | interactive | system-wide zsh |
| `~/.bash_profile` | login | — | user login |
| `~/.bashrc` | interactive | — | user bash |
| `~/.zshenv` | — | always | user zsh env |
| `~/.zprofile` | — | login | user zsh login |
| `~/.zshrc` | — | interactive | user zsh |
| `~/.profile` | login fallback | — | generic login |

Where to put env vars:
- Bash: `~/.bash_profile` (login) or `~/.bashrc` (if profile sources it).
- Zsh: `~/.zshenv` (everywhere) or `~/.zprofile` (login).
- Both shells: `~/.profile` and source from both. Or `~/.config/environment.d/` for systemd user sessions.

## Environment variables

- View all:
  `env` / `printenv`

- One variable:
  `echo $HOME` / `printenv PATH`

- Set + export:
  `export MY_VAR="value"`

- Single-command only:
  `MY_VAR=value command`

- Unset:
  `unset MY_VAR`

- Persist (example):
  `echo 'export MY_VAR="value"' >> ~/.bashrc`

### Common variables

| Var | Purpose | Example |
|-----|---------|---------|
| `HOME` | home dir | `/home/jo` |
| `USER` | username | `jo` |
| `SHELL` | login shell | `/bin/zsh` |
| `PATH` | exec search path | colon-separated |
| `EDITOR` | default editor | `vim` |
| `VISUAL` | visual editor | `vim` |
| `PAGER` | pager | `less` |
| `TERM` | terminal type | `xterm-256color` |
| `LANG` | locale | `en_US.UTF-8` |
| `TZ` | timezone | `Europe/Paris` |
| `DISPLAY` | X11 | `:0` |
| `WAYLAND_DISPLAY` | wayland | `wayland-0` |
| `XDG_SESSION_TYPE` | session | `wayland` / `x11` |
| `XDG_CURRENT_DESKTOP` | DE | `GNOME` |
| `DBUS_SESSION_BUS_ADDRESS` | dbus | `unix:path=/run/user/1000/bus` |

### System-wide

- `/etc/environment` — simple `KEY=VALUE` (no expansion, no export):
  ```
  EDITOR=vim
  PATH="/usr/local/bin:/usr/bin:/bin"
  ```

- `/etc/profile.d/custom.sh` — shell scripts at login:
  ```
  export GOPATH="$HOME/go"
  export PATH="$PATH:$GOPATH/bin"
  ```

### systemd user environment

`~/.config/environment.d/50-custom.conf`:
```
EDITOR=vim
PATH=${HOME}/.local/bin:${PATH}
```

- Show / set / import:
  ```
  systemctl --user show-environment
  systemctl --user set-environment MY_VAR=value
  systemctl --user import-environment
  ```

## PATH

- View one per line:
  `echo $PATH | tr ':' '\n'`

- Prepend (higher priority):
  `export PATH="$HOME/.local/bin:$PATH"`

- Append:
  `export PATH="$PATH:/opt/custom/bin"`

- Conditional (avoid dupes):
  `[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH="$HOME/.local/bin:$PATH"`

- Resolve which binary:
  `which python` / `type python` / `command -v python`

- Show all matches:
  `which -a python` / `type -a python`

## XDG base directories

- Defaults:
  ```
  export XDG_CONFIG_HOME="$HOME/.config"
  export XDG_DATA_HOME="$HOME/.local/share"
  export XDG_STATE_HOME="$HOME/.local/state"
  export XDG_CACHE_HOME="$HOME/.cache"
  # XDG_RUNTIME_DIR set by systemd (typically /run/user/$UID)
  ```

| App | Path |
|-----|------|
| git | `~/.config/git/config` |
| ssh | `~/.ssh/` (does NOT use XDG) |
| npm | `~/.config/npm/npmrc` |
| docker | `~/.config/docker/` |
| systemd user units | `~/.config/systemd/user/` |
| fontconfig | `~/.config/fontconfig/` |
| GTK-3 | `~/.config/gtk-3.0/` |
| environment.d | `~/.config/environment.d/` |

- Create dirs:
  `mkdir -p ~/.config ~/.local/share ~/.local/state ~/.cache ~/.local/bin`

## Minimal bash config

`~/.bash_profile`:
```bash
export EDITOR=vim
export VISUAL=vim
export PAGER=less
export PATH="$HOME/.local/bin:$PATH"
[[ -f ~/.bashrc ]] && source ~/.bashrc
```

`~/.bashrc`:
```bash
[[ $- != *i* ]] && return

export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth
shopt -s histappend globstar checkwinsize cdspell dirspell

alias ls='ls --color=auto'
alias ll='ls -lah'
alias grep='grep --color=auto'
alias ..='cd ..'

PS1='\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\$ '

[[ -f /usr/share/bash-completion/bash_completion ]] && source /usr/share/bash-completion/bash_completion
```

## Minimal zsh config

`~/.zshenv`:
```bash
export EDITOR=vim
export VISUAL=vim
export PAGER=less
export PATH="$HOME/.local/bin:$PATH"
```

`~/.zshrc`:
```bash
HISTSIZE=10000
SAVEHIST=20000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY APPEND_HISTORY
setopt AUTO_CD CORRECT GLOB_DOTS EXTENDED_GLOB

alias ls='ls --color=auto'
alias ll='ls -lah'
alias grep='grep --color=auto'
alias ..='cd ..'

bindkey -e
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select

autoload -Uz promptinit && promptinit
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%# '
```

## Change default shell

- List allowed:
  `cat /etc/shells`

- Change own:
  `chsh -s /bin/zsh`

- Change other (root):
  `sudo chsh -s /bin/zsh otheruser`

- Install zsh:
  `sudo pacman -S zsh zsh-completions`

- Verify:
  `echo $SHELL`

## Locale

- Show / list:
  `locale` / `locale -a`

- Generate (after editing `/etc/locale.gen`):
  `sudo locale-gen`

- Set system locale + keymap:
  `sudo localectl set-locale LANG=en_US.UTF-8`
  `sudo localectl set-keymap us`

- Status:
  `localectl status`

- Per-session overrides:
  ```
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
  export LC_TIME=en_GB.UTF-8       # 24-hour, DD/MM/YYYY
  export LC_NUMERIC=en_US.UTF-8    # 1,000.00
  export LC_COLLATE=C              # sort by byte value
  ```
