---
title: "Personal manual"
date: 2026-03-11
tags: ["tools", "documentation", "fzf"]
source: doc/pages/tools/manual.md
source_sha: db1a9a37be0e
---

> Personal TLDR-style system manual — fzf-powered, searchable, living reference.

## Open the manual

- Open floating manual window (from sway):
  `Super+Home`

- Open from terminal:
  `~/Dotfiles/doc/man.sh`

## Navigation

- Default mode is ripgrep content search — type to search across all pages
- `Tab` — toggle between grep (content search) and files (browse by name) mode
- `Enter` — open page in nvim at the matched line
- `Ctrl+E` — same as Enter (edit in place), then reload list
- `Ctrl+N` — create a new manual entry interactively
- `Ctrl+J` / `Ctrl+K` — move down/up

## Create a new entry

Interactive prompt (from within the manual or directly):
```
~/Dotfiles/doc/man-new.sh
```

Direct creation (no prompt):
```
~/Dotfiles/doc/man-new.sh <category>/<page-name>
```

Examples:
```
~/Dotfiles/doc/man-new.sh tools/git-rebase
~/Dotfiles/doc/man-new.sh shell/fzf-tricks
~/Dotfiles/doc/man-new.sh system/fonts
```

- If the file does not exist, it is created from a template and opened in nvim
- If it already exists, it opens the existing file
- Categories can be new or existing

## Pages location

```
~/Dotfiles/doc/pages/<category>/<page-name>.md
```

## Page format

```markdown
# page-name

> One-line description of what this covers.

- What this action does:
  `command --args`

- Another tip:
  `command`
```
