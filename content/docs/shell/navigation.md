---
title: "Shell navigation"
date: 2026-03-11
tags: ["shell", "navigation", "zoxide"]
source: doc/pages/shell/navigation.md
source_sha: 773bfde71bde
---

> Directory navigation with zoxide, yazi, and fzf.

## zoxide (smart cd)

- Jump to most frecent match:
  `z <partial-name>`

- Interactive picker (fzf-style):
  `zi`

- Since `cd` is aliased to `z`, normal `cd` works with frecency:
  `cd projects` (jumps to best match, e.g. ~/code/projects)

- Add current directory to database:
  `zoxide add .`

- Query database:
  `zoxide query <name>`

## yazi (file manager)

- Open yazi in current directory:
  `f` (alias) or `yazi`

- Navigate: `h/j/k/l` (vim-style)
- Open file: `Enter`
- Go up a directory: `h` or `Backspace`
- Open in editor: `e`
- Quit: `q`
- See `tools/yazi` page for full keybindings.

## fzf

- Fuzzy-find files and open in editor:
  `fzf | xargs nvim`

- History search:
  `Ctrl+R` (in shell, both insert and normal mode)

- File preview (bat):
  Default FZF_DEFAULT_OPTS includes bat preview for files.

- Bindings in fzf:
  `Ctrl+j` / `Ctrl+k` → move down/up in list
