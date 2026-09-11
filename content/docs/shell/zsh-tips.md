---
title: "Zsh tips"
date: 2026-03-11
tags: ["shell", "zsh", "vi-mode"]
source: doc/pages/shell/zsh-tips.md
source_sha: ffe525bccf20
---

> Zsh vi-mode, completion, history, and useful shell tricks.

## Vi mode (zsh-vi-mode)

- Default mode on prompt: insert mode
- Enter normal mode: `Escape`
- Return to insert mode: `i` or `a`
- In normal mode, navigate: `h/j/k/l`, `w/b/e`, `0/$`
- Delete word: `dw`, change word: `cw`
- Paste: `p`, yank: `y`

## History

- Search history with fzf: `Ctrl+R` (works in both insert and normal mode)
- History is shared across all sessions (inc_append_history + share_history)
- History size: 1,000,000 entries
- Commands starting with a space are NOT saved to history
- Consecutive duplicates are NOT saved (HISTCONTROL=ignoreboth)
- History file: `~/.cache/zsh_history`

## Completion

- Tab to complete; completion is case-insensitive
- No menu selection — completion inserts common prefix and lists matches below
- Dotfiles are included in completions (globdots)
- `/*/` expands correctly (squeeze-slashes disabled)

## Useful shell options

- `interactive_comments` — allows `# comments` directly in the prompt
- `extended_glob` — enables `~`, `#`, `^` glob operators
- `globdots` — include hidden files in glob patterns
- `auto_param_slash` — appends `/` after directory completions
- `Ctrl+S` is unbound (stty stop undef) — won't accidentally freeze terminal

## Prompt

Format: `[user@host] HH:MM ~/path (git-branch)`
- Time is shown in green
- Path in blue
- Git branch in red (via vcs_info)
- `user@host` only shown in SSH sessions

## Plugins

- `zsh-syntax-highlighting` — colors commands as you type
- `zsh-vi-mode` — better vi keybindings than built-in zle vi mode
- `fzf --zsh` — enables Ctrl+R history widget and other fzf shell integrations
- `zoxide init zsh` — hooks into `cd`
